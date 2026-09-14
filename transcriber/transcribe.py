#!/usr/bin/env python3
"""
Prototype: live, local speech-to-text (and translation) for a single radio
station.

Opens ONE persistent connection to the stream with ffmpeg and reads it as a
continuous raw PCM feed, slicing off fixed-size chunks as they arrive in
real time and transcribing each locally with faster-whisper (no external
API, no network dependency once the models are downloaded). Each chunk is
also translated locally with Helsinki-NLP/opus-mt-en-es (MarianMT) unless
--no-translate is passed. Both are POSTed to the Rails app together, which
stores them and serves them to the station's page.

Earlier version reconnected fresh (`ffmpeg -i url -t 10 ...`) for every
chunk. That turned out to be a real bug, not just inefficient: many live
stream CDNs (including this one) serve a burst of already-buffered content
rapidly on a brand new connection rather than only real-time bytes, so a
fresh "10 second" capture could finish in ~1 real second - each chunk was
mostly re-grabbing overlapping, already-buffered audio rather than
sequential live content, which is why chunks arrived every ~2-4s instead of
~10s and why consecutive lines overlapped so much. Reading continuously off
one persistent connection doesn't have that problem: ffmpeg naturally
blocks for more data at whatever pace the live stream actually delivers it.

This is intentionally a standalone script rather than a Rails background
job: it needs a long-lived ffmpeg subprocess and a loaded Whisper model,
which doesn't fit the request/response lifecycle, and this app has no job
queue (Sidekiq/etc.) set up to run persistent workers.

Usage:
  source transcriber/venv/bin/activate
  TRANSCRIBE_TOKEN=... python3 transcriber/transcribe.py \
      --radio-id 21 \
      --stream-url "http://stream.live.vc.bbcmedia.co.uk/bbc_world_service"
"""
import argparse
import os
import subprocess
import sys
import time
from datetime import datetime, timezone

import numpy as np
import requests
from faster_whisper import WhisperModel
from transformers import MarianMTModel, MarianTokenizer

SAMPLE_RATE = 16000
BYTES_PER_SAMPLE = 2  # s16le


def start_ffmpeg(stream_url):
    return subprocess.Popen(
        [
            "ffmpeg", "-loglevel", "error",
            "-i", stream_url,
            "-ar", str(SAMPLE_RATE), "-ac", "1",
            "-f", "s16le", "-",
        ],
        stdout=subprocess.PIPE,
    )


def read_exact(pipe, n):
    """Blocks until exactly n bytes are read, or returns None if the stream ended."""
    buf = bytearray()
    while len(buf) < n:
        piece = pipe.read(n - len(buf))
        if not piece:
            return None
        buf.extend(piece)
    return bytes(buf)


def pcm_to_float32(raw_bytes):
    return np.frombuffer(raw_bytes, dtype=np.int16).astype(np.float32) / 32768.0


def translate(tokenizer, model, text):
    batch = tokenizer([text], return_tensors="pt", padding=True)
    generated = model.generate(**batch)
    return tokenizer.batch_decode(generated, skip_special_tokens=True)[0]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--radio-id", type=int, required=True)
    parser.add_argument("--stream-url", required=True)
    parser.add_argument("--base-url", default=os.environ.get("RAILS_BASE_URL", "http://localhost:3000"))
    parser.add_argument("--model", default=os.environ.get("WHISPER_MODEL", "base.en"))
    parser.add_argument("--chunk-seconds", type=int, default=10)
    parser.add_argument("--translation-model", default=os.environ.get("TRANSLATION_MODEL", "Helsinki-NLP/opus-mt-en-es"))
    parser.add_argument("--no-translate", action="store_true", help="Skip loading the translation model entirely")
    args = parser.parse_args()

    token = os.environ.get("TRANSCRIBE_TOKEN")
    if not token:
        sys.exit("TRANSCRIBE_TOKEN env var is required (must match the Rails app's TRANSCRIBE_TOKEN)")

    chunk_bytes = args.chunk_seconds * SAMPLE_RATE * BYTES_PER_SAMPLE

    print(f"Loading Whisper model '{args.model}'...", flush=True)
    model = WhisperModel(args.model, device="cpu", compute_type="int8")

    translator = None
    if not args.no_translate:
        print(f"Loading translation model '{args.translation_model}'...", flush=True)
        translator_tokenizer = MarianTokenizer.from_pretrained(args.translation_model)
        translator = MarianMTModel.from_pretrained(args.translation_model)

    print("Model(s) loaded. Starting transcription loop (Ctrl-C to stop).", flush=True)

    endpoint = f"{args.base_url}/radios/{args.radio_id}/transcript_chunks"

    proc = start_ffmpeg(args.stream_url)
    try:
        while True:
            started_at = datetime.now(timezone.utc)
            raw = read_exact(proc.stdout, chunk_bytes)
            ended_at = datetime.now(timezone.utc)

            if raw is None:
                print("Stream connection ended; reconnecting in 3s...", file=sys.stderr, flush=True)
                proc.wait()
                time.sleep(3)
                proc = start_ffmpeg(args.stream_url)
                continue

            audio = pcm_to_float32(raw)
            segments, info = model.transcribe(audio, beam_size=5)
            text = " ".join(seg.text.strip() for seg in segments).strip()

            if not text:
                continue

            translated_text = None
            if translator:
                translated_text = translate(translator_tokenizer, translator, text)

            print(f"[{started_at.strftime('%H:%M:%S')}] {text}", flush=True)
            if translated_text:
                print(f"           -> {translated_text}", flush=True)

            try:
                requests.post(
                    endpoint,
                    json={
                        "text": text,
                        "translated_text": translated_text,
                        "started_at": started_at.isoformat(),
                        "ended_at": ended_at.isoformat(),
                    },
                    headers={"X-Transcribe-Token": token},
                    timeout=10,
                )
            except requests.RequestException as e:
                print(f"Failed to post transcript chunk: {e}", file=sys.stderr, flush=True)
    finally:
        proc.terminate()


if __name__ == "__main__":
    main()
