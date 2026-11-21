extends Node
## All game sounds & 4-station Kampala FM Radio, generated in code at start-up.
## Distinct vehicle horns (boda, matatu taxi, car), traffic police whistle,
## low-fuel dashboard chime, engine sputter, radio tuning sound, ambient street
## murmur, and 4 Ugandan radio stations (Afrobeat, Kadongo Kamu, Luga-Flow, Highlife).

const RATE := 22050
const VoiceBank = preload("res://scripts/voice_bank.gd")

## Recorded files (from tools/audio, ElevenLabs) that replace the code-made sounds.
## id in audio/sfx/<id>.mp3  ->  sound key in this script, or a looping player.
const RECORDED_SFX := {
	"boda_horn": ["horn_boda", "horn"], "taxi_horn": ["horn_taxi"], "car_horn": ["horn_car"],
	"police_whistle": ["whistle"], "crash": ["crash"], "momo_ding": ["chime"], "boda_rev": ["start"],
	"taxi_door": ["taxi_door"], "sms_tone": ["sms"], "coins": ["coins"], "tv_goal_cheer": ["goal_cheer"],
	"rooster_dawn": ["rooster"],
}
const RECORDED_LOOPS := {"boda_idle_loop": "engine", "street_day_loop": "city", "rain_roof_loop": "rain"}
## Real songs (ElevenLabs Music) dropped into these folders become "PlayKampala FM".
const MUSIC_DIRS := ["res://audio/theme songs", "res://audio/instrumental", "res://audio/music"]
const MUSIC_DB := -13.0          # recorded songs
const SYNTH_DB := -14.5          # code-made stations
const STATIONS := [
	"106.5 PlayKampala FM",
	"91.3 Afrobeat FM",
	"88.8 Kadongo Kamu",
	"97.7 Luga-Flow Beat",
	"100.4 Lake Highlife",
	"OFF",
]

var engine: AudioStreamPlayer
var rain: AudioStreamPlayer
var city: AudioStreamPlayer
var music: AudioStreamPlayer
var street_speaker: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var sounds := {}
var station_streams: Array[AudioStreamWAV] = []
var street_streams := {}
var _street_kind := ""
var _near_street_music := false
var _whoosh_cd := {}
var _tts_voice := ""
var _tts_cd := 0.0
var station_idx := 0
var enabled := true
var music_enabled := true
signal now_playing(title: String)
var playlist: Array = []          # [{path, title, vocal}]
var _pl_order: Array = []
var _pl_pos := -1
var current_title := ""
var _duck_t := 0.0
var use_device_tts := false   # the phone's robot voice is NOT Ugandan; only used if you switch it on
var _voice_players: Array[AudioStreamPlayer3D] = []
var _voice_cd := 0.0
var recorded_voice_count := 0


func _ready() -> void:
	sounds["chime"] = _tones([[988.0, 0.0, 0.16], [1319.0, 0.11, 0.38]], 0.55, 0.32)
	sounds["bonus"] = _tones([
		[523.25, 0.0, 0.12], [659.25, 0.09, 0.12], [783.99, 0.18, 0.14], [1046.50, 0.27, 0.38]
	], 0.70, 0.34)
	sounds["intro"] = _tones([
		[349.23, 0.0, 0.35], [440.0, 0.12, 0.35], [523.25, 0.24, 0.42],
		[698.46, 0.38, 0.65], [880.0, 0.52, 0.75]
	], 1.35, 0.26)
	sounds["fuel"] = _tones([[660.0, 0.0, 0.07], [784.0, 0.11, 0.07], [990.0, 0.22, 0.24]], 0.5, 0.25)
	sounds["low_fuel"] = _tones([
		[880.0, 0.0, 0.11], [659.25, 0.14, 0.11], [880.0, 0.28, 0.18]
	], 0.52, 0.32)
	sounds["radio_tune"] = _radio_tune()
	sounds["sputter"] = _engine_sputter()
	sounds["horn_boda"] = _horn_boda()
	sounds["horn_taxi"] = _horn_taxi()
	sounds["horn_car"] = _horn_car()
	sounds["horn"] = sounds["horn_boda"]
	sounds["whistle"] = _police_whistle()
	sounds["crash"] = _crash()
	sounds["start"] = _engine_start()
	sounds["pop"] = _tones([[520.0, 0.0, 0.06]], 0.08, 0.24)
	sounds["whoosh_car"] = _pass_whoosh(false)
	sounds["whoosh_taxi"] = _pass_whoosh(true)

	station_streams = [
		_music_afrobeat(),
		_music_kadongo(),
		_music_lugaflow(),
		_music_highlife(),
	]
	street_streams = {
		"bar": station_streams[2],      # booming Kampala Afrobeat / club bass outside bars
		"shop": station_streams[1],     # upbeat Kadongo Kamu / radio speaker at hardware & shops
		"market": station_streams[3],   # lively highlife / market radios
		"church": _music_church_hymn(), # warm choir/organ chords outside churches
	}
	engine = _loop_player(_engine_loop())
	rain = _loop_player(_rain_loop())
	city = _loop_player(_city_loop())
	music = _loop_player(station_streams[0])
	music.volume_db = SYNTH_DB
	music.finished.connect(_on_music_finished)
	street_speaker = _loop_player(street_streams["shop"])
	street_speaker.volume_db = -60.0
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_apply_recorded_audio()
	_scan_playlist()
	_wire_street_songs()
	if playlist.is_empty():
		station_idx = 1   # no songs yet: start on the first code-made station
	_apply_station()
	var en_voices := DisplayServer.tts_get_voices_for_language("en")
	if not en_voices.is_empty():
		_tts_voice = str(en_voices[0])
	else:
		var all_v := DisplayServer.tts_get_voices()
		if not all_v.is_empty():
			_tts_voice = str(all_v[0].get("id", ""))


func _loop_player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = -60.0
	add_child(p)
	p.play()
	return p


func set_enabled(on: bool) -> void:
	enabled = on
	AudioServer.set_bus_mute(0, not on)
	if not on and DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()


func speak_street(line: String, pitch := 1.02, rate := 1.06) -> void:
	if not enabled or _tts_voice == "" or _tts_cd > 0.0:
		return
	if DisplayServer.tts_is_speaking():
		return
	_tts_cd = 6.5
	DisplayServer.tts_speak(line, _tts_voice, 92, clampf(pitch, 0.7, 1.4), clampf(rate, 0.8, 1.3), 0, false)


const OFF_IDX := 5


func set_music_enabled(on: bool) -> void:
	music_enabled = on
	if not on:
		station_idx = OFF_IDX
	elif station_idx == OFF_IDX:
		station_idx = 0 if not playlist.is_empty() else 1
	_apply_station()


func cycle_radio() -> String:
	station_idx = (station_idx + 1) % STATIONS.size()
	if station_idx == 0 and playlist.is_empty():
		station_idx = 1
	music_enabled = (station_idx != OFF_IDX)
	_apply_station()
	if music_enabled:
		play("radio_tune", -4.0, 1.0)
	else:
		play("pop", -5.0, 0.85)
	if station_idx == 0 and current_title != "":
		return "%s  •  ♪ %s" % [STATIONS[0], current_title]
	return STATIONS[station_idx]


func radio_short_label() -> String:
	match station_idx:
		0: return "FM: 106.5 PK"
		1: return "FM: 91.3 Beat"
		2: return "FM: 88.8 Kadongo"
		3: return "FM: 97.7 Flow"
		4: return "FM: 100.4 Jazz"
		_: return "FM: OFF"


func _apply_station() -> void:
	if music == null:
		return
	if station_idx == 0 and not playlist.is_empty():
		_play_next_song(_pl_pos < 0)
	elif station_idx >= 1 and station_idx < OFF_IDX and station_idx - 1 < station_streams.size():
		music.stream = station_streams[station_idx - 1]
		music.volume_db = SYNTH_DB
		music.play()
	else:
		music.volume_db = -60.0
		music.stop()


# ------------------------------------------------------------------ PlayKampala FM (real songs)
const FALLBACK_SONGS := [
	"res://audio/theme songs/Play_Kampala_2026-11-13T071922.mp3",
	"res://audio/theme songs/Play_Kampala_2026-11-13T071922 (1).mp3",
	"res://audio/instrumental/Kampala_Welcome_2026-11-13T072838.mp3",
	"res://audio/instrumental/Playkampala_Menu_Groove_2026-11-13T072838.mp3",
]


func _scan_playlist() -> void:
	playlist.clear()
	var seen := {}
	for dir in MUSIC_DIRS:
		# list_directory sees through the .import/.remap files of an exported APK
		var files := ResourceLoader.list_directory(dir)
		for f in files:
			var path := "%s/%s" % [dir, f]
			if not (f.get_extension().to_lower() in ["mp3", "ogg", "wav"]) or seen.has(path):
				continue
			seen[path] = true
			playlist.append({"path": path, "title": _song_title(f), "vocal": dir.ends_with("theme songs")})
	if playlist.is_empty():
		for path in FALLBACK_SONGS:
			if ResourceLoader.exists(path) and not seen.has(path):
				seen[path] = true
				playlist.append({"path": path, "title": _song_title(path.get_file()), "vocal": path.find("theme songs") >= 0})
	playlist.sort_custom(func(x, y): return str(x.path) < str(y.path))
	_pl_order.clear()
	_pl_pos = -1


## Wire the real songs/instrumentals into spatial street speakers (bars, shops, markets).
func _wire_street_songs() -> void:
	var kind_paths := {
		"bar": "res://audio/theme songs/Play_Kampala_2026-11-13T071922 (1).mp3",
		"shop": "res://audio/instrumental/Playkampala_Menu_Groove_2026-11-13T072838.mp3",
		"market": "res://audio/instrumental/Kampala_Welcome_2026-11-13T072838.mp3",
	}
	for kind in kind_paths.keys():
		var p: String = kind_paths[kind]
		if ResourceLoader.exists(p):
			var st = load(p)
			if st != null:
				var st_copy = st.duplicate()
				if st_copy is AudioStreamMP3:
					(st_copy as AudioStreamMP3).loop = true
				elif st_copy is AudioStreamOggVorbis:
					(st_copy as AudioStreamOggVorbis).loop = true
				street_streams[kind] = st_copy


## "Play_Kampala_2026-11-13T071922 (1).mp3"  ->  "Play Kampala (Street Mix)"
static func _song_title(f: String) -> String:
	var raw := f.get_basename()
	var is_mix := raw.find("(1)") >= 0
	var t := raw
	var cut := t.find("_20")
	if cut > 0:
		t = t.substr(0, cut)
	t = t.replace("_", " ").strip_edges()
	t = t.replace("Playkampala", "PlayKampala")
	if is_mix:
		t += " (Street Mix)"
	return t


func skip_song() -> String:
	if playlist.is_empty():
		return cycle_radio()
	station_idx = 0
	music_enabled = true
	play("radio_tune", -5.0, 1.05)
	_play_next_song(false)
	return "106.5 PlayKampala FM  •  ♪ %s" % current_title


func _reshuffle() -> void:
	# Vocal theme song first, then the rest mixed, alternating vocal / instrumental where possible
	var vocal: Array = []
	var inst: Array = []
	for i in playlist.size():
		(vocal if playlist[i].vocal else inst).append(i)
	vocal.shuffle()
	inst.shuffle()
	_pl_order.clear()
	while not vocal.is_empty() or not inst.is_empty():
		if not vocal.is_empty():
			_pl_order.append(vocal.pop_back())
		if not inst.is_empty():
			_pl_order.append(inst.pop_back())
	_pl_pos = -1


func _play_next_song(first := false) -> void:
	if playlist.is_empty():
		return
	if first or _pl_order.is_empty():
		_reshuffle()
	_pl_pos += 1
	if _pl_pos >= _pl_order.size():
		var last: int = _pl_order[-1]
		_reshuffle()
		if _pl_order.size() > 1 and _pl_order[0] == last:   # never the same song twice in a row
			_pl_order.push_back(_pl_order.pop_front())
		_pl_pos = 0
	var song: Dictionary = playlist[_pl_order[_pl_pos]]
	var st = load(song.path)
	if st == null:
		return
	if st is AudioStreamMP3:
		(st as AudioStreamMP3).loop = false
	elif st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = false
	music.stream = st
	music.volume_db = MUSIC_DB
	music.play()
	current_title = str(song.title)
	now_playing.emit(current_title)


func _on_music_finished() -> void:
	if station_idx == 0 and music_enabled:
		_play_next_song()


## Lower the radio for a moment so a street voice can be heard.
func duck_music(seconds: float) -> void:
	_duck_t = maxf(_duck_t, seconds)


func play(name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not enabled:
		return
	var key := name if sounds.has(name) else "pop"
	pitch = clampf(pitch, 0.5, 2.0)
	for p in _pool:
		if not p.playing:
			p.stream = sounds[key]
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return


## speed01: 0 = idle, 1 = flat out
func update_engine(on: bool, speed01: float, delta: float) -> void:
	var target_db := -60.0 if not on else lerpf(-18.0, -7.5, speed01)
	engine.volume_db = lerpf(engine.volume_db, target_db, clampf(delta * 6.0, 0.0, 1.0))
	engine.pitch_scale = clampf(lerpf(engine.pitch_scale, 0.75 + speed01 * 1.15, clampf(delta * 5.0, 0.0, 1.0)), 0.5, 2.0)


func update_ambience(raining: bool, night: float, delta: float) -> void:
	var k := clampf(delta * 1.5, 0.0, 1.0)
	rain.volume_db = lerpf(rain.volume_db, -9.5 if raining else -60.0, k)
	city.volume_db = lerpf(city.volume_db, lerpf(-22.0, -31.0, night), k)
	if music:
		_duck_t = maxf(_duck_t - delta, 0.0)
		var base_music: float = (MUSIC_DB if station_idx == 0 else SYNTH_DB) - (2.0 if raining else 0.0)
		if _duck_t > 0.0:
			base_music -= 7.0
		if _near_street_music:
			base_music -= 7.5   # gently duck FM radio when passing a loud street speaker
		var target_music := base_music if music_enabled else -60.0
		music.volume_db = lerpf(music.volume_db, target_music, k)


## Spatial distance-fading street music (bars, hardware/shops, markets, churches) + Doppler "vuuuum" for passing cars/taxis
func update_spatial_audio(player_pos: Vector3, vehicles: Array, music_spots: Array, delta: float) -> void:
	if not enabled:
		return
	if _tts_cd > 0.0:
		_tts_cd = maxf(0.0, _tts_cd - delta)
	# 1. Nearest street music source (fades smoothly from -8 dB at <=4m down to -60 dB at >=28m)
	var best_d2 := 28.0 * 28.0
	var best_kind := ""
	for sp in music_spots:
		var p: Vector3 = sp["pos"]
		var d2 := (p.x - player_pos.x) * (p.x - player_pos.x) + (p.z - player_pos.z) * (p.z - player_pos.z)
		if d2 < best_d2:
			best_d2 = d2
			best_kind = str(sp["kind"])
	if best_kind != "" and street_streams.has(best_kind):
		if best_kind != _street_kind:
			_street_kind = best_kind
			street_speaker.stream = street_streams[best_kind]
			street_speaker.play()
		var dist := sqrt(best_d2)
		var atten := clampf(1.0 - (dist - 4.0) / 24.0, 0.0, 1.0)
		var target_db := lerpf(-60.0, -7.5 if best_kind == "bar" else -10.5, atten * atten)
		street_speaker.volume_db = lerpf(street_speaker.volume_db, target_db, clampf(delta * 5.0, 0.0, 1.0))
		_near_street_music = atten > 0.28
	else:
		street_speaker.volume_db = lerpf(street_speaker.volume_db, -60.0, clampf(delta * 3.5, 0.0, 1.0))
		_near_street_music = false

	# 2. Passing taxis & cars "vuuuum!" Doppler whoosh
	for vid in _whoosh_cd.keys():
		_whoosh_cd[vid] = float(_whoosh_cd[vid]) - delta
		if float(_whoosh_cd[vid]) <= 0.0:
			_whoosh_cd.erase(vid)
	for v in vehicles:
		if not is_instance_valid(v):
			continue
		var spd: float = float(v.get("cur_speed")) if v.get("cur_speed") != null else 0.0
		if spd < 4.5:
			continue
		var vp: Vector3 = v.global_position
		var dx := vp.x - player_pos.x
		var dz := vp.z - player_pos.z
		var d2 := dx * dx + dz * dz
		if d2 < 9.0 * 9.0:
			var vid: int = v.get_instance_id()
			if not _whoosh_cd.has(vid):
				_whoosh_cd[vid] = 2.6
				var dist := sqrt(d2)
				var is_heavy: bool = str(v.get("kind")) == "taxi"
				var vol := lerpf(-4.0, -15.0, clampf(dist / 9.0, 0.0, 1.0))
				var pitch := clampf(0.82 + spd * 0.032, 0.78, 1.35)
				play("whoosh_taxi" if is_heavy else "whoosh_car", vol, pitch)


# ------------------------------------------------------------------ synthesis
const TAIL := 1024

func _wav(s: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var n := s.size()
	var data := PackedByteArray()
	data.resize((n + TAIL) * 2)
	for i in n + TAIL:
		var v := 0.0
		if i < n:
			v = s[i]
		elif loop:
			v = s[(i - n) % n]
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = n
	return w


func _tones(notes: Array, total: float, vol: float) -> AudioStreamWAV:
	var n := int(total * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for note in notes:
		var f: float = note[0]
		var st := int(float(note[1]) * RATE)
		var ln := int(float(note[2]) * RATE)
		for i in ln:
			if st + i >= n:
				break
			var t := float(i) / RATE
			var env := minf(1.0, t * 200.0) * exp(-t * 7.0)
			s[st + i] += (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)) * env * vol
	return _wav(s)


func _radio_tune() -> AudioStreamWAV:
	var n := int(0.22 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var sweep := sin(TAU * lerpf(600.0, 1450.0, t / 0.22) * t) * 0.15
		var hiss := randf_range(-0.12, 0.12) * exp(-t * 14.0)
		s[i] = (sweep + hiss) * exp(-t * 6.0)
	return _wav(s)


func _horn_boda() -> AudioStreamWAV:
	var n := int(0.36 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var on := (t < 0.09) or (t > 0.14 and t < 0.33)
		if not on:
			continue
		var w := sin(TAU * 495.0 * t) * 0.55 + sin(TAU * 622.0 * t) * 0.45 + sin(TAU * 990.0 * t) * 0.25
		s[i] = clampf(w * 1.3, -1.0, 1.0) * 0.17
	return _wav(s)


func _horn_taxi() -> AudioStreamWAV:
	var n := int(0.56 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var on := (t < 0.15) or (t > 0.21 and t < 0.52)
		if not on:
			continue
		var f1 := 233.08
		var f2 := 293.66
		var brass := (
			sin(TAU * f1 * t) * 0.50 + sin(TAU * f1 * 2.0 * t) * 0.28 + sin(TAU * f1 * 3.0 * t) * 0.14 +
			sin(TAU * f2 * t) * 0.45 + sin(TAU * f2 * 2.0 * t) * 0.24
		)
		s[i] = clampf(brass, -1.0, 1.0) * 0.22
	return _wav(s)


func _horn_car() -> AudioStreamWAV:
	var n := int(0.34 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := minf(1.0, t * 80.0) * clampf((0.34 - t) * 25.0, 0.0, 1.0)
		var w := sin(TAU * 349.23 * t) * 0.52 + sin(TAU * 440.0 * t) * 0.48 + sin(TAU * 698.46 * t) * 0.18
		s[i] = w * env * 0.20
	return _wav(s)


func _police_whistle() -> AudioStreamWAV:
	var n := int(0.48 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var env := minf(1.0, t * 70.0) * clampf((0.48 - t) * 16.0, 0.0, 1.0)
		var trill := 0.65 + 0.35 * sin(TAU * 28.0 * t)
		var f := 2780.0 + 95.0 * sin(TAU * 28.0 * t)
		ph += f / RATE
		s[i] = sin(TAU * ph) * trill * env * 0.22
	return _wav(s)


func _engine_sputter() -> AudioStreamWAV:
	var n := int(0.85 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var rate := lerpf(26.0, 5.0, clampf(t / 0.85, 0.0, 1.0))
		ph += rate / RATE
		var cough := exp(-fmod(ph, 1.0) * 7.5) * exp(-t * 2.2)
		s[i] = cough * (sin(TAU * 82.0 * t) * 0.6 + randf_range(-0.35, 0.35)) * 0.65
	return _wav(s)


func _crash() -> AudioStreamWAV:
	var n := int(0.7 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp = lerpf(lp, randf_range(-1.0, 1.0), 0.35)
		s[i] = (lp * 0.8 + sin(TAU * 55.0 * t) * 0.6) * exp(-t * 6.0)
	return _wav(s)


func _engine_start() -> AudioStreamWAV:
	var n := int(0.6 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var rate := lerpf(12.0, 42.0, minf(1.0, t / 0.4))
		ph += rate / RATE
		var pulse := exp(-fmod(ph, 1.0) * 6.0)
		s[i] = pulse * (sin(TAU * 110.0 * t) * 0.5 + randf_range(-0.3, 0.3)) * 0.6
	return _wav(s)


func _engine_loop() -> AudioStreamWAV:
	var n := int(0.5 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-fmod(t * 40.0, 1.0) * 5.0)
		var tone := sin(TAU * 110.0 * t) * 0.5 + sin(TAU * 220.0 * t) * 0.22 + sin(TAU * 40.0 * t) * 0.35
		s[i] = (tone + randf_range(-0.25, 0.25)) * env * 0.55
	return _wav(s, true)


func _rain_loop() -> AudioStreamWAV:
	var n := int(2.0 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	for i in n:
		lp = lerpf(lp, randf_range(-1.0, 1.0), 0.25)
		var drop := randf_range(-1.0, 1.0) * 0.6 if randf() < 0.002 else 0.0
		s[i] = lp * 0.35 + drop
	return _wav(s, true)


func _city_loop() -> AudioStreamWAV:
	var n := int(4.0 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	var bp := 0.0
	for i in n:
		var raw := randf_range(-1.0, 1.0)
		lp = lerpf(lp, raw, 0.025)
		bp = lerpf(bp, raw - lp, 0.08)
		s[i] = lp * 0.72 + bp * 0.18
	return _wav(s, true)


func _render_groove(melody: Array, bass: Array, kick_mod: int, tempo_beat := 0.5) -> AudioStreamWAV:
	var total := 8.0
	var n := int(total * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for note in melody:
		var f: float = note[0]
		var st := int(float(note[1]) * RATE)
		var ln := int(float(note[2]) * RATE)
		var amp: float = note[3]
		for i in ln:
			var idx := (st + i) % n
			var t := float(i) / RATE
			var env := minf(1.0, t * 180.0) * exp(-t * 6.0)
			var w := sin(TAU * f * t) + 0.28 * sin(TAU * f * 2.0 * t) + 0.09 * sin(TAU * f * 3.0 * t)
			s[idx] += w * env * amp
	for bnote in bass:
		var bf: float = bnote[0]
		var bst := int(float(bnote[1]) * RATE)
		var bln := int(float(bnote[2]) * RATE)
		for i in bln:
			var idx := (bst + i) % n
			var t := float(i) / RATE
			var env := minf(1.0, t * 90.0) * exp(-t * 4.5)
			s[idx] += (sin(TAU * bf * t) * 0.75 + sin(TAU * bf * 2.0 * t) * 0.25) * env * 0.24
	var beats := int(total / tempo_beat)
	for beat in beats:
		var bt := beat * tempo_beat
		var kst := int(bt * RATE)
		if beat % kick_mod == 0 or beat % 4 == 3:
			var kln := int(0.14 * RATE)
			for i in kln:
				var idx := (kst + i) % n
				var t := float(i) / RATE
				var f_drop := lerpf(118.0, 48.0, minf(1.0, t / 0.09))
				s[idx] += sin(TAU * f_drop * t) * exp(-t * 22.0) * 0.18
		var sst := int((bt + tempo_beat * 0.5) * RATE)
		var sln := int(0.06 * RATE)
		for i in sln:
			var idx := (sst + i) % n
			var t := float(i) / RATE
			s[idx] += randf_range(-1.0, 1.0) * exp(-t * 45.0) * 0.045
	return _wav(s, true)


func _music_afrobeat() -> AudioStreamWAV:
	# Station 1: 91.3 Afrobeat FM (F-major pentatonic kalimba & guitar groove)
	var melody := [
		[349.23, 0.00, 0.42, 0.22], [523.25, 0.25, 0.38, 0.20], [440.00, 0.50, 0.35, 0.19],
		[587.33, 0.75, 0.45, 0.21], [523.25, 1.25, 0.40, 0.20], [440.00, 1.50, 0.45, 0.18],
		[392.00, 2.00, 0.42, 0.22], [587.33, 2.25, 0.38, 0.20], [523.25, 2.50, 0.35, 0.19],
		[698.46, 2.75, 0.48, 0.22], [587.33, 3.25, 0.40, 0.20], [523.25, 3.50, 0.45, 0.18],
		[440.00, 4.00, 0.42, 0.22], [523.25, 4.25, 0.38, 0.20], [587.33, 4.50, 0.38, 0.21],
		[698.46, 4.75, 0.45, 0.22], [587.33, 5.25, 0.38, 0.19], [440.00, 5.50, 0.45, 0.19],
		[392.00, 6.00, 0.42, 0.21], [440.00, 6.25, 0.38, 0.20], [523.25, 6.50, 0.45, 0.21],
		[440.00, 7.00, 0.40, 0.19], [349.23, 7.25, 0.65, 0.22], [523.25, 7.50, 0.45, 0.17],
	]
	var bass := [
		[87.31, 0.00, 0.45], [87.31, 0.75, 0.40], [130.81, 1.50, 0.45],
		[116.54, 2.00, 0.45], [116.54, 2.75, 0.40], [98.00, 3.50, 0.45],
		[87.31, 4.00, 0.45], [87.31, 4.75, 0.40], [130.81, 5.50, 0.45],
		[130.81, 6.00, 0.45], [98.00, 6.75, 0.40], [87.31, 7.25, 0.65],
	]
	return _render_groove(melody, bass, 2, 0.5)


func _music_kadongo() -> AudioStreamWAV:
	# Station 2: 88.8 Kadongo Kamu (Ugandan acoustic guitar & walking storytelling bass in G major)
	var melody := [
		[392.00, 0.00, 0.35, 0.22], [493.88, 0.33, 0.35, 0.20], [587.33, 0.66, 0.40, 0.21],
		[523.25, 1.00, 0.35, 0.20], [493.88, 1.33, 0.35, 0.19], [440.00, 1.66, 0.35, 0.19],
		[392.00, 2.00, 0.35, 0.22], [587.33, 2.33, 0.35, 0.21], [659.25, 2.66, 0.40, 0.22],
		[587.33, 3.00, 0.35, 0.20], [493.88, 3.33, 0.35, 0.19], [440.00, 3.66, 0.35, 0.18],
		[523.25, 4.00, 0.35, 0.22], [659.25, 4.33, 0.35, 0.21], [783.99, 4.66, 0.40, 0.21],
		[659.25, 5.00, 0.35, 0.20], [587.33, 5.33, 0.35, 0.20], [493.88, 5.66, 0.35, 0.19],
		[440.00, 6.00, 0.35, 0.21], [493.88, 6.33, 0.35, 0.20], [587.33, 6.66, 0.40, 0.21],
		[493.88, 7.00, 0.35, 0.19], [392.00, 7.33, 0.60, 0.22],
	]
	var bass := [
		[98.00, 0.00, 0.32], [123.47, 0.33, 0.32], [146.83, 0.66, 0.32], [130.81, 1.00, 0.45], [146.83, 1.50, 0.45],
		[98.00, 2.00, 0.32], [123.47, 2.33, 0.32], [146.83, 2.66, 0.32], [130.81, 3.00, 0.45], [110.00, 3.50, 0.45],
		[130.81, 4.00, 0.32], [164.81, 4.33, 0.32], [196.00, 4.66, 0.32], [146.83, 5.00, 0.45], [123.47, 5.50, 0.45],
		[110.00, 6.00, 0.45], [146.83, 6.50, 0.45], [98.00, 7.00, 0.85],
	]
	return _render_groove(melody, bass, 1, 0.5)


func _music_lugaflow() -> AudioStreamWAV:
	# Station 3: 97.7 Luga-Flow Beat (Energetic Kampala Kidandali / Dancehall in D minor)
	var melody := [
		[587.33, 0.00, 0.22, 0.23], [587.33, 0.375, 0.22, 0.21], [698.46, 0.75, 0.30, 0.23],
		[659.25, 1.25, 0.25, 0.20], [523.25, 1.50, 0.35, 0.21],
		[587.33, 2.00, 0.22, 0.23], [587.33, 2.375, 0.22, 0.21], [783.99, 2.75, 0.30, 0.23],
		[698.46, 3.25, 0.25, 0.21], [659.25, 3.50, 0.35, 0.20],
		[587.33, 4.00, 0.22, 0.23], [698.46, 4.375, 0.22, 0.22], [880.00, 4.75, 0.32, 0.23],
		[783.99, 5.25, 0.25, 0.21], [698.46, 5.50, 0.35, 0.20],
		[659.25, 6.00, 0.22, 0.22], [587.33, 6.375, 0.22, 0.21], [523.25, 6.75, 0.30, 0.21],
		[440.00, 7.25, 0.25, 0.20], [587.33, 7.50, 0.45, 0.23],
	]
	var bass := [
		[73.42, 0.00, 0.35], [73.42, 0.75, 0.35], [87.31, 1.50, 0.40],
		[65.41, 2.00, 0.35], [65.41, 2.75, 0.35], [82.41, 3.50, 0.40],
		[73.42, 4.00, 0.35], [73.42, 4.75, 0.35], [98.00, 5.50, 0.40],
		[87.31, 6.00, 0.35], [65.41, 6.75, 0.35], [73.42, 7.25, 0.65],
	]
	return _render_groove(melody, bass, 1, 0.375)


func _music_highlife() -> AudioStreamWAV:
	# Station 4: 100.4 Lake Highlife (Smooth Ggaba Beach guitar & warm Rhodes chords in C major)
	var melody := [
		[523.25, 0.00, 0.55, 0.20], [659.25, 0.50, 0.55, 0.19], [783.99, 1.00, 0.65, 0.21], [659.25, 1.50, 0.45, 0.18],
		[587.33, 2.00, 0.55, 0.20], [698.46, 2.50, 0.55, 0.19], [880.00, 3.00, 0.65, 0.21], [783.99, 3.50, 0.45, 0.18],
		[659.25, 4.00, 0.55, 0.20], [783.99, 4.50, 0.55, 0.20], [1046.50, 5.00, 0.65, 0.20], [783.99, 5.50, 0.45, 0.18],
		[698.46, 6.00, 0.55, 0.20], [659.25, 6.50, 0.55, 0.19], [587.33, 7.00, 0.50, 0.19], [523.25, 7.50, 0.50, 0.21],
	]
	var bass := [
		[130.81, 0.00, 0.65], [98.00, 1.00, 0.65],
		[146.83, 2.00, 0.65], [87.31, 3.00, 0.65],
		[130.81, 4.00, 0.65], [110.00, 5.00, 0.65],
		[87.31, 6.00, 0.65], [98.00, 7.00, 0.85],
	]
	return _render_groove(melody, bass, 2, 0.5)


func _pass_whoosh(heavy: bool) -> AudioStreamWAV:
	# Realistic Doppler "vuuuum!" as a taxi or car zooms past the player
	var dur := 0.72 if heavy else 0.56
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var u := t / dur
		var env := sin(PI * u) * sin(PI * u)
		var f := lerpf(155.0 if heavy else 210.0, 68.0 if heavy else 96.0, u)
		ph += f / RATE
		lp = lerpf(lp, randf_range(-1.0, 1.0), 0.16)
		var engine_hum := sin(TAU * ph) * 0.55 + sin(TAU * ph * 2.0) * 0.24
		s[i] = (engine_hum * 0.65 + lp * 0.55) * env * (0.48 if heavy else 0.38)
	return _wav(s)


func _music_church_hymn() -> AudioStreamWAV:
	# Warm church choir/organ chords fading cleanly outside church doors
	var melody := [
		[261.63, 0.00, 1.80, 0.14], [329.63, 0.00, 1.80, 0.12], [392.00, 0.00, 1.80, 0.12],
		[293.66, 2.00, 1.80, 0.14], [349.23, 2.00, 1.80, 0.12], [440.00, 2.00, 1.80, 0.12],
		[246.94, 4.00, 1.80, 0.14], [329.63, 4.00, 1.80, 0.12], [392.00, 4.00, 1.80, 0.12],
		[261.63, 6.00, 1.90, 0.15], [329.63, 6.00, 1.90, 0.13], [523.25, 6.00, 1.90, 0.11],
	]
	var bass := [
		[130.81, 0.00, 1.75], [174.61, 2.00, 1.75], [196.00, 4.00, 1.75], [130.81, 6.00, 1.85],
	]
	return _render_groove(melody, bass, 2, 1.0)



# =================================================================== recorded Ugandan voices & SFX
static func _load_mp3(path: String, loop := false) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	var st = load(path)
	if st is AudioStreamMP3:
		(st as AudioStreamMP3).loop = loop
	elif st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = loop
	return st


## Swap code-made sounds for recorded ones wherever a file exists.
func _apply_recorded_audio() -> void:
	for id in RECORDED_SFX:
		var st := _load_mp3("res://audio/sfx/%s.mp3" % id)
		if st:
			for k in RECORDED_SFX[id]:
				sounds[k] = st
	for id in RECORDED_LOOPS:
		var lst := _load_mp3("res://audio/sfx/%s.mp3" % id, true)
		if lst:
			var p: AudioStreamPlayer = get(RECORDED_LOOPS[id])
			if p:
				p.stream = lst
				p.play()
	for cat in VoiceBank.LINES:
		for l in VoiceBank.LINES[cat]:
			if ResourceLoader.exists("res://audio/voice/%s.mp3" % l[0]):
				recorded_voice_count += 1


## A random line of a category from the voice script: [id, speaker, text]
func pick_line(cat: String) -> Array:
	var lines: Array = VoiceBank.LINES.get(cat, [])
	if lines.is_empty():
		return []
	return lines[randi() % lines.size()]


func line_text(cat: String) -> String:
	var l := pick_line(cat)
	return str(l[2]) if not l.is_empty() else ""


## Speak a line from the voice script at a place in the world.
## Plays the recorded Ugandan voice if it exists; returns the words (for subtitles).
func say(cat: String, where: Vector3, volume_db := 2.0) -> String:
	if not enabled:
		return ""
	var l := pick_line(cat)
	if l.is_empty():
		return ""
	var path := "res://audio/voice/%s.mp3" % l[0]
	if ResourceLoader.exists(path):
		var vp: AudioStreamPlayer3D = null
		for p in _voice_players:
			if not p.playing:
				vp = p
				break
		if vp == null and _voice_players.size() < 3:
			vp = AudioStreamPlayer3D.new()
			vp.unit_size = 9.0
			vp.max_distance = 55.0
			vp.attenuation_filter_cutoff_hz = 12000.0
			add_child(vp)
			_voice_players.append(vp)
		if vp:
			vp.stream = _load_mp3(path)
			vp.global_position = where + Vector3(0, 1.6, 0)
			vp.volume_db = volume_db
			vp.pitch_scale = randf_range(0.97, 1.03)
			vp.play()
			duck_music(maxf(vp.stream.get_length(), 2.0) + 0.6)
	elif use_device_tts:
		speak_street(str(l[2]))
	return str(l[2])
