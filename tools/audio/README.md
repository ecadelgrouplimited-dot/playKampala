# PlayKampala audio pipeline (ElevenLabs + faster-whisper)

Everything the street says lives in `voice_lines.csv`. Edit lines there, never in the .gd files.

## One-time setup
```bash
pip install requests faster-whisper
export ELEVENLABS_API_KEY=sk_...        # never commit this
```
Put a voice ID for each speaker in `voices.json` (Voice Library search "Ugandan",
or Voice Design using the `design_prompt` already written for each speaker).

## Generate
```bash
python3 tools/audio/generate_audio.py --bank          # rebuild scripts/voice_bank.gd after editing the CSV
python3 tools/audio/generate_audio.py --voices --sfx  # writes audio/voice/*.mp3 and audio/sfx/*.mp3
python3 tools/audio/check_voices.py --delete-failed   # Whisper checks each take, deletes bad ones
python3 tools/audio/generate_audio.py --voices        # regenerates only the deleted ones
```
Useful flags: `--only c01,c02` and `--force`.

Then open the project in Godot once so the new MP3s get imported, and export the APK.

## How the game uses it
- `sfx.say(category, position)` picks a line, plays `audio/voice/<id>.mp3` in 3D at the speaker,
  and returns the text for the subtitle. With no file it shows the subtitle only
  (the phone's robot TTS is off: `sfx.use_device_tts = false`).
- Any `audio/sfx/<id>.mp3` listed in `sfx.gd` `RECORDED_SFX` / `RECORDED_LOOPS` replaces
  the code-made sound (horns, whistle, crash, engine loop, city loop, rain).
- Conductor and vendor speech bubbles in `life.gd` use the same lines.
