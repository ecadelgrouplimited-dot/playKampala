#!/usr/bin/env python3
"""
Checks every generated voice line with faster-whisper: did the voice actually
say the words in the script (and nothing extra, no garbling)?

  pip install faster-whisper
  python3 tools/audio/check_voices.py                    # report only
  python3 tools/audio/check_voices.py --delete-failed    # remove bad takes, then
  python3 tools/audio/generate_audio.py --voices         # ...re-generate just those

Luganda words (tugende, nyabo, webale...) are often mis-heard by Whisper, so
they are left out of the score: the check is that the English and the overall
line came out right. Always give the final pass a human (Ugandan) listen too.
"""
import argparse, csv, re, sys
from difflib import SequenceMatcher
from pathlib import Path

try:
    from faster_whisper import WhisperModel
except ImportError:
    sys.exit("Please install it:  pip install faster-whisper")

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
VOICE = ROOT / "audio" / "voice"

LOCAL_WORDS = {
    "tugende", "nyabo", "sebo", "jangu", "ekifo", "kimu", "kisigadde", "eriyo", "abali", "muyingire",
    "gwe", "ogenda", "banange", "webale", "nnyo", "kikomando", "gonja", "muchomo", "matooke",
    "sukuma", "wiki", "oli", "otya", "bulungi", "nawe", "gyebale", "ko", "kale", "paaka", "ggaba",
    "kireka", "ntinda", "wandegeya", "makerere", "nakawa", "kisaasi", "kyanja", "rolex", "boda", "thou",
}


def words(s: str):
    return re.findall(r"[a-z']+", s.lower())


def score(expected: str, heard: str):
    e = [w for w in words(expected) if w not in LOCAL_WORDS]
    h = [w for w in words(heard) if w not in LOCAL_WORDS]
    if not e:
        return 1.0
    return SequenceMatcher(None, e, h).ratio()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="small", help="tiny, base, small, medium, large-v3")
    ap.add_argument("--threshold", type=float, default=0.7)
    ap.add_argument("--delete-failed", action="store_true")
    a = ap.parse_args()

    rows = list(csv.DictReader(open(HERE / "voice_lines.csv", newline="", encoding="utf-8")))
    model = WhisperModel(a.model, device="auto", compute_type="int8")
    report, bad = [], []
    for r in rows:
        f = VOICE / f"{r['id']}.mp3"
        if not f.exists():
            report.append([r["id"], "MISSING", "", r["text"], ""])
            continue
        segs, info = model.transcribe(str(f), language="en", beam_size=5, vad_filter=True)
        heard = " ".join(s.text.strip() for s in segs).strip()
        sc = score(r["text"], heard)
        status = "OK" if sc >= a.threshold else "CHECK"
        if info.duration > 9.0 or info.duration < 0.4:
            status = "CHECK"
        report.append([r["id"], status, f"{sc:.2f}", r["text"], heard])
        print(f"{status:6} {sc:.2f}  {r['id']}  expected: {r['text']}\n                 heard:    {heard}")
        if status == "CHECK":
            bad.append(f)
    out = HERE / "voice_report.csv"
    with open(out, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["id", "status", "score", "expected", "heard"])
        w.writerows(report)
    ok = sum(1 for x in report if x[1] == "OK")
    print(f"\n{ok}/{len(rows)} lines OK. Report: {out}")
    if a.delete_failed and bad:
        for f in bad:
            f.unlink()
        print(f"Deleted {len(bad)} takes. Run generate_audio.py --voices to re-generate them.")


if __name__ == "__main__":
    main()
