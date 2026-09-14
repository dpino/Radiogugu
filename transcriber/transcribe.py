#!/usr/bin/env python3
"""
Prototype: live, local speech-to-text for a single radio station.

Loops forever: captures a short chunk of the stream with ffmpeg, transcribes
it locally with faster-whisper (no external API, no network dependency once
the model is downloaded), and POSTs the resulting text to the Rails app,
which stores it and serves it to the station's page.

This is intentionally a standalone script rather than a Rails background job:
it needs a long-lived ffmpeg subprocess and a loaded Whisper model, which
doesn't fit the request/response lifecycle, and this app has no job queue
(Sidekiq/etc.) set up to run persistent workers.

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
import tempfile
import time
from datetime import datetime, timezone

import requests
from faster_whisper import WhisperModel


def capture_chunk(stream_url, seconds, wav_path):
    """Blocks for ~`seconds` while ffmpeg pulls that much audio from the stream."""
    subprocess.run(
        [
            "ffmpeg", "-y", "-loglevel", "error",
            "-i", stream_url,
            "-t", str(seconds),
            "-ar", "16000", "-ac", "1",
            "-f", "wav", wav_path,
        ],
        check=True,
        timeout=seconds + 15,
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--radio-id", type=int, required=True)
    parser.add_argument("--stream-url", required=True)
    parser.add_argument("--base-url", default=os.environ.get("RAILS_BASE_URL", "http://localhost:3000"))
    parser.add_argument("--model", default=os.environ.get("WHISPER_MODEL", "base.en"))
    parser.add_argument("--chunk-seconds", type=int, default=10)
    args = parser.parse_args()

    token = os.environ.get("TRANSCRIBE_TOKEN")
    if not token:
        sys.exit("TRANSCRIBE_TOKEN env var is required (must match the Rails app's TRANSCRIBE_TOKEN)")

    print(f"Loading Whisper model '{args.model}'...", flush=True)
    model = WhisperModel(args.model, device="cpu", compute_type="int8")
    print("Model loaded. Starting transcription loop (Ctrl-C to stop).", flush=True)

    endpoint = f"{args.base_url}/radios/{args.radio_id}/transcript_chunks"

    while True:
        with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
            started_at = datetime.now(timezone.utc)
            try:
                capture_chunk(args.stream_url, args.chunk_seconds, tmp.name)
            except subprocess.CalledProcessError as e:
                print(f"ffmpeg failed ({e}); retrying in 5s", file=sys.stderr, flush=True)
                time.sleep(5)
                continue
            except subprocess.TimeoutExpired:
                print("ffmpeg timed out; retrying", file=sys.stderr, flush=True)
                continue

            ended_at = datetime.now(timezone.utc)

            segments, info = model.transcribe(tmp.name, beam_size=5)
            text = " ".join(seg.text.strip() for seg in segments).strip()

            if not text:
                continue

            print(f"[{started_at.strftime('%H:%M:%S')}] {text}", flush=True)

            try:
                requests.post(
                    endpoint,
                    json={
                        "text": text,
                        "started_at": started_at.isoformat(),
                        "ended_at": ended_at.isoformat(),
                    },
                    headers={"X-Transcribe-Token": token},
                    timeout=10,
                )
            except requests.RequestException as e:
                print(f"Failed to post transcript chunk: {e}", file=sys.stderr, flush=True)


if __name__ == "__main__":
    main()
