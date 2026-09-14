# Live transcription + translation prototype

Local, real-time speech-to-text for a single radio station, using
[faster-whisper](https://github.com/SYSTRAN/faster-whisper) (CPU, no
external API/cost), plus a local English->Spanish translation of each line
using [Helsinki-NLP/opus-mt-en-es](https://huggingface.co/Helsinki-NLP/opus-mt-en-es)
(MarianMT, also CPU/local - pass `--no-translate` to skip it). Currently
prototyped against **BBC World Service** (radio id may differ per database -
check `Radio.find_by(name: "BBC World Service").id`).

This is intentionally a standalone script, not a Rails background job: it
needs a long-lived ffmpeg subprocess and a loaded Whisper model, and this
app has no job queue (Sidekiq etc.) set up for persistent workers.

## Setup (one-time)

```
python3 -m venv transcriber/venv
source transcriber/venv/bin/activate
pip install -r transcriber/requirements.txt
```

Also needs `ffmpeg` on PATH (`sudo apt install ffmpeg` if you don't have it).

## Running

The Rails server needs `TRANSCRIBE_TOKEN` set to the same value the script
uses, so it can authenticate the POSTs:

```
TRANSCRIBE_TOKEN=some-shared-secret bin/rails server
```

Then, in another terminal:

```
source transcriber/venv/bin/activate
TRANSCRIBE_TOKEN=some-shared-secret python3 transcriber/transcribe.py \
  --radio-id 21 \
  --stream-url "http://stream.live.vc.bbcmedia.co.uk/bbc_world_service"
```

Open that station's page and hit play - a transcript panel (and its Spanish
translation, right below it) appears below the player once the first chunk
comes back (every ~10s).

## Known limitations (it's a prototype)

- Only works for whichever single station you point it at.
- Sequential 10s chunks aren't perfectly seamless, so consecutive lines
  overlap somewhat rather than reading as one clean transcript.
- No speaker diarization, punctuation is Whisper's best guess.
- CPU-only; `base.en` keeps up comfortably in real time on a modern
  multi-core machine, but a slower machine may want `tiny.en`.
- Translation is per-chunk MarianMT, with no cross-chunk context, so it can
  read a little disjointed where a sentence spans a chunk boundary - same
  character as the English transcript itself.
- Loading both models takes ~1 minute on first run (translation model
  weights get cached locally after that).
