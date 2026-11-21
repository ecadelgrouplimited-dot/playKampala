#!/usr/bin/env python3
"""
PlayKampala audio generator (ElevenLabs).

  export ELEVENLABS_API_KEY=sk_...           # your key (never commit it)
  python3 tools/audio/generate_audio.py --bank      # rebuild scripts/voice_bank.gd from the CSV
  python3 tools/audio/generate_audio.py --voices    # voice lines  -> audio/voice/<id>.mp3
  python3 tools/audio/generate_audio.py --sfx       # sound effects -> audio/sfx/<id>.mp3
  python3 tools/audio/generate_audio.py --voices --only c01,c02 --force

Existing files are skipped unless --force, so re-running only fills gaps
(e.g. after check_voices.py --delete-failed removed the bad takes).
"""
import argparse, csv, json, os, sys, time
from pathlib import Path

try:
    import requests
except ImportError:
    sys.exit("Please install requests:  pip install requests")

ROOT = Path(__file__).resolve().parents[2]          # the Godot project folder
HERE = Path(__file__).resolve().parent
API = "https://api.elevenlabs.io/v1"
VOICE_OUT = ROOT / "audio" / "voice"
SFX_OUT = ROOT / "audio" / "sfx"


def key() -> str:
    k = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not k:
        sys.exit("Set your key first:  export ELEVENLABS_API_KEY=sk_...")
    return k


def read_csv(name):
    with open(HERE / name, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def post(url, body, retries=3):
    for attempt in range(retries):
        r = requests.post(url, headers={"xi-api-key": key(), "Content-Type": "application/json"},
                          json=body, timeout=120)
        if r.status_code == 200:
            return r.content
        if r.status_code in (429, 500, 502, 503):
            time.sleep(4 * (attempt + 1))
            continue
        return r
    return r


def gen_voices(only, force):
    cfg = json.loads((HERE / "voices.json").read_text())
    speakers = cfg["speakers"]
    missing = sorted({s for s, v in speakers.items() if not v.get("voice_id")})
    VOICE_OUT.mkdir(parents=True, exist_ok=True)
    done = skipped = failed = 0
    for row in read_csv("voice_lines.csv"):
        if only and row["id"] not in only:
            continue
        out = VOICE_OUT / f"{row['id']}.mp3"
        if out.exists() and not force:
            skipped += 1
            continue
        sp = speakers.get(row["speaker"], {})
        vid = sp.get("voice_id")
        if not vid:
            print(f"  ! {row['id']}: no voice_id for '{row['speaker']}' in voices.json")
            failed += 1
            continue
        model = cfg.get("model_id", "eleven_v3")
        # eleven_v3 understands audio tags like [shouting]; older models would read them aloud
        text = f"{row['tag']} {row['text']}" if model == "eleven_v3" and row.get("tag") else row["text"]
        body = {"text": text, "model_id": model,
                "voice_settings": {"stability": 0.4, "similarity_boost": 0.8, "style": 0.35, "use_speaker_boost": True}}
        res = post(f"{API}/text-to-speech/{vid}?output_format=mp3_44100_128", body)
        if isinstance(res, (bytes, bytearray)):
            out.write_bytes(res)
            done += 1
            print(f"  + {row['id']}  {row['text']}")
        else:
            # fall back to the multilingual model (plain text, no tags)
            body["model_id"] = cfg.get("fallback_model_id", "eleven_multilingual_v2")
            body["text"] = row["text"]
            res2 = post(f"{API}/text-to-speech/{vid}?output_format=mp3_44100_128", body)
            if isinstance(res2, (bytes, bytearray)):
                out.write_bytes(res2)
                done += 1
                print(f"  + {row['id']}  (fallback model)  {row['text']}")
            else:
                failed += 1
                print(f"  ! {row['id']}: HTTP {res.status_code} {res.text[:200]}")
    print(f"Voices: {done} generated, {skipped} already there, {failed} failed.")
    if missing:
        print("Speakers still without a voice_id:", ", ".join(missing))


def gen_sfx(only, force):
    SFX_OUT.mkdir(parents=True, exist_ok=True)
    done = skipped = failed = 0
    for row in read_csv("sfx_list.csv"):
        if only and row["id"] not in only:
            continue
        out = SFX_OUT / f"{row['id']}.mp3"
        if out.exists() and not force:
            skipped += 1
            continue
        body = {"text": row["prompt"], "duration_seconds": float(row["seconds"]),
                "prompt_influence": 0.45, "loop": row["loop"].strip().lower() == "true"}
        res = post(f"{API}/sound-generation?output_format=mp3_44100_128", body)
        if isinstance(res, (bytes, bytearray)):
            out.write_bytes(res)
            done += 1
            print(f"  + {row['id']}")
        else:
            failed += 1
            print(f"  ! {row['id']}: HTTP {res.status_code} {res.text[:200]}")
    print(f"Sound effects: {done} generated, {skipped} already there, {failed} failed.")


def gd_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def build_bank():
    """Writes scripts/voice_bank.gd so the game shows exactly the words it plays."""
    rows = read_csv("voice_lines.csv")
    cats = {}
    for r in rows:
        cats.setdefault(r["category"], []).append(r)
    lines = [
        "extends RefCounted",
        "## GENERATED by tools/audio/generate_audio.py --bank from tools/audio/voice_lines.csv.",
        "## Edit the CSV, not this file. Each line: [id, speaker, text].",
        "",
        "const LINES := {",
    ]
    for c, rs in cats.items():
        lines.append(f"\t{gd_str(c)}: [")
        for r in rs:
            lines.append(f"\t\t[{gd_str(r['id'])}, {gd_str(r['speaker'])}, {gd_str(r['text'])}],")
        lines.append("\t],")
    lines.append("}")
    (ROOT / "scripts" / "voice_bank.gd").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote scripts/voice_bank.gd ({len(rows)} lines in {len(cats)} categories).")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--voices", action="store_true")
    ap.add_argument("--sfx", action="store_true")
    ap.add_argument("--bank", action="store_true")
    ap.add_argument("--only", default="")
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()
    only = set(x.strip() for x in a.only.split(",") if x.strip())
    if not (a.voices or a.sfx or a.bank):
        ap.print_help()
    if a.bank:
        build_bank()
    if a.voices:
        build_bank()
        gen_voices(only, a.force)
    if a.sfx:
        gen_sfx(only, a.force)
