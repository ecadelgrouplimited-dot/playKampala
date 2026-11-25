extends Node3D
## PlayKampala street test.
## One Kampala crossroads, built entirely from code in a low-poly,
## Townscaper-like style: arcades and shop fronts, a market, a taxi park,
## muzigo rentals, a boda stage, a rolex stand, a dusty football pitch,
## traffic driving on the LEFT, people walking, day/night, rain and power cuts.
##
## Static scenery is merged into a handful of big meshes (see mesh_baker.gd)
## so the whole street costs only a few dozen draw calls on a cheap phone.

const Baker = preload("res://scripts/mesh_baker.gd")
const MeshSculpt = preload("res://scripts/mesh_sculpt.gd")
const Mover = preload("res://scripts/mover.gd")
const CameraRig = preload("res://scripts/camera_rig.gd")
const Hud = preload("res://scripts/hud.gd")
const Player = preload("res://scripts/player.gd")
const Jobs = preload("res://scripts/jobs.gd")
const Car = preload("res://scripts/car.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Person = preload("res://scripts/person.gd")
const Life = preload("res://scripts/life.gd")
const EndlessWorld = preload("res://scripts/endless_world.gd")
const PERSON_SCALE := 1.42   # bold, readable character scale on both phone and desktop screens

# ---------------------------------------------------------------- city layout
const N := 6                 # blocks per side
const BLOCK := 64.0          # metres from one road's centre line to the next
const HALF := N * BLOCK / 2.0
const JUNCTION_R := 7.0      # stop line distance from a junction centre
const SPAWN := Vector3(2.6, 0.04, 21.0)
const DISTRICT_NAMES := {
	"downtown": "Kikuubo & Arcades", "market": "Owino Market", "taxi": "Old Taxi Park",
	"pitch": "Nakivubo Stadium", "workshops": "Katwe Workshops", "mixed": "Wandegeya",
	"estates": "Ntinda & Suburbs", "fuel": "Fuel Station", "nakasero": "Nakasero Hill",
}
const NAME_A := [
	"God's Grace", "Blessed", "Divine", "Trust in God", "Mukama Wange", "Tusubira", "Tukole",
	"Victory", "Smart", "Prime", "City", "Golden", "Royal", "New Hope", "Nakato", "Ssemakula",
	"Mama Kevina", "Kasirye", "Okello", "Auma", "Twegatte", "Mulungi", "Jjajja", "Bright Star",
	"Faith", "Destiny", "Ebenezer", "Emmanuel", "Kampala Best", "Pearl", "Nalubega", "Wasswa",
	"Kato & Sons", "Simba", "Nile", "Sunrise", "Hope", "Amani", "Unity", "Upendo",
]
const NAME_B := [
	"Hardware", "Supermarket", "Saloon", "Boutique", "Pharmacy", "Spare Parts", "Restaurant",
	"Mobile Money & Airtime", "Electronics", "Wholesalers", "Phone Repair", "Stationery", "Butchery",
	"Bar & Lodge", "Clinic", "Fashions", "Agro Supplies", "Mattress Centre", "Chapati Corner",
	"Tailoring", "Shoe Repair", "Video Library", "Printing & Photocopy", "Furniture", "Bakery",
	"Juice Point", "General Merchandise", "Cosmetics", "Driving School", "Forex Bureau",
]
const RESIDENTS := ["Nakato", "Okello", "Auma", "Ssemakula", "Namubiru", "Kato", "Achieng", "Mugisha", "Nabirye", "Opio", "Wasswa", "Babirye", "Tumusiime", "Kyomuhendo", "Lubega"]

# ---------------------------------------------------------------- colours (Warm Sunlit Stylized Kampala Illustration Palette)
const MURRAM := Color(0.74, 0.38, 0.21)        # Sunlit Ugandan laterite red earth
const EARTH := Color(0.58, 0.40, 0.26)
const ASPHALT := Color(0.25, 0.26, 0.31)       # Cool slate tarmac (matches reference street!)
const PAVEMENT := Color(0.84, 0.67, 0.50)      # Warm sunlit terracotta-sandstone walkways
const PAINT := Color(0.97, 0.94, 0.86)         # Crisp warm cream road markings
const GLASS := Color(0.16, 0.26, 0.38)
const DARK := Color(0.11, 0.11, 0.14)
const GREY := Color(0.52, 0.54, 0.58)
const WOOD := Color(0.48, 0.31, 0.18)
const SHUTTER := Color(0.42, 0.48, 0.56)
const SHOP_DARK := Color(0.14, 0.12, 0.13)
const TAXI_WHITE := Color(0.96, 0.96, 0.95)
const TAXI_BLUE := Color(0.12, 0.42, 0.78)
const LEAF := Color(0.16, 0.50, 0.20)
const LEAF2 := Color(0.34, 0.66, 0.22)
const JACARANDA := Color(0.56, 0.40, 0.80)
const CURB_YELLOW := Color(0.94, 0.74, 0.18)
const DRAIN_DARK := Color(0.15, 0.14, 0.15)

const WALLS := [
	Color(0.88, 0.52, 0.35), Color(0.94, 0.84, 0.70), Color(0.91, 0.68, 0.48),
	Color(0.84, 0.44, 0.31), Color(0.95, 0.89, 0.78), Color(0.86, 0.60, 0.42),
	Color(0.76, 0.84, 0.88), Color(0.92, 0.76, 0.52), Color(0.80, 0.48, 0.36),
	Color(0.74, 0.36, 0.28), Color(0.76, 0.82, 0.72), Color(0.93, 0.82, 0.64),
]
const ROOFS := [
	Color(0.62, 0.26, 0.18), Color(0.54, 0.57, 0.62), Color(0.20, 0.44, 0.28),
	Color(0.68, 0.24, 0.18), Color(0.24, 0.38, 0.52), Color(0.48, 0.26, 0.17),
]
const CLOTHES := [
	Color(0.86, 0.46, 0.16), Color(0.90, 0.72, 0.18), Color(0.18, 0.54, 0.32),
	Color(0.52, 0.24, 0.56), Color(0.18, 0.42, 0.74), Color(0.80, 0.20, 0.22),
	Color(0.94, 0.92, 0.88), Color(0.16, 0.18, 0.22), Color(0.26, 0.62, 0.72),
	Color(0.84, 0.42, 0.52), Color(0.46, 0.34, 0.22), Color(0.26, 0.30, 0.48),
]
const SKINS := [
	Color(0.38, 0.23, 0.15), Color(0.46, 0.29, 0.19), Color(0.31, 0.19, 0.12),
	Color(0.52, 0.35, 0.22), Color(0.26, 0.16, 0.11),
]
const SIGNS := [
	Color(0.90, 0.68, 0.14), Color(0.78, 0.20, 0.18), Color(0.16, 0.38, 0.70),
	Color(0.16, 0.50, 0.30), Color(0.24, 0.28, 0.36), Color(0.84, 0.44, 0.14),
]
const GOODS := [
	Color(1.00, 0.85, 0.15), Color(0.85, 0.15, 0.15), Color(0.20, 0.50, 0.85),
	Color(0.95, 0.95, 0.95), Color(0.30, 0.65, 0.30), Color(0.60, 0.40, 0.25),
]
const PRODUCE := [
	Color(0.85, 0.15, 0.10), Color(0.35, 0.60, 0.20), Color(0.95, 0.80, 0.20),
	Color(0.50, 0.20, 0.45), Color(0.90, 0.55, 0.15), Color(0.55, 0.40, 0.25),
]
const VESTS := [Color(0.98, 0.88, 0.10), Color(0.98, 0.54, 0.08), Color(0.78, 0.96, 0.14)]
const NS_STREETS := [
	"Kafumbe Mukasa Rd",
	"Ben Kiwanuka St",
	"Luwum Street",
	"Entebbe Road",
	"William Street",
	"Yusuf Lule Rd",
	"Ntinda Road",
]
const EW_STREETS := [
	"Makerere Hill Rd",
	"Bombo Road",
	"Nakasero Road",
	"Kampala Road",
	"Jinja Road",
	"Katwe Road",
	"Ggaba Road",
]
const BIKE_PAINTS := [
	["Boxer Crimson Red", Color(0.84, 0.11, 0.16)],
	["Kampala Gold", Color(0.96, 0.76, 0.08)],
	["Electric Blue", Color(0.10, 0.44, 0.92)],
	["Emerald Viper", Color(0.12, 0.76, 0.34)],
	["SafeBoda Orange", Color(0.96, 0.44, 0.08)],
	["Stealth Black", Color(0.15, 0.16, 0.20)],
]
const RIDER_OUTFITS := [
	["Kampala Yellow Vest", Color(0.98, 0.88, 0.10), Color(0.16, 0.28, 0.46)],
	["SafeBoda Orange", Color(0.96, 0.45, 0.08), Color(0.14, 0.18, 0.28)],
	["Kampala Red", Color(0.84, 0.14, 0.16), Color(0.18, 0.22, 0.34)],
	["Royal Blue", Color(0.14, 0.42, 0.92), Color(0.18, 0.20, 0.26)],
	["Sunday White", Color(0.95, 0.95, 0.96), Color(0.14, 0.18, 0.26)],
]
const KAMPALA_STAGES := [
	"Old Taxi Park Stage",
	"Kikuubo Arcade Stage",
	"Wandegeya Stage",
	"Nakasero Market Stage",
	"Clock Tower Stage",
	"Nakawa Junction Stage",
	"Kololo Airstrip Stage",
	"Ggaba Beach Stage",
]
const ACHIEVEMENTS := [
	{"id": "first_trip", "title": "First Hustle", "desc": "Complete your first Kampala trip", "reward": 3000},
	{"id": "five_trips", "title": "Stage Regular", "desc": "Complete 5 trips across Kampala", "reward": 8000},
	{"id": "mud_warrior", "title": "Murram & Mud Warrior", "desc": "Ride onto a suburb red murram road", "reward": 5000},
	{"id": "highway_explorer", "title": "Upcountry Highway Rider", "desc": "Reach any Inter-District Highway", "reward": 6000},
	{"id": "clean_boda", "title": "Sparkling Clean", "desc": "Wash your boda at a Kampala Washing Bay", "reward": 3000},
	{"id": "five_star", "title": "Five-Star Legend", "desc": "Reach a 4.9★ Rider Rating", "reward": 10000},
	{"id": "boda_boss", "title": "Boda Boss", "desc": "Own your own Bajaj Boxer logbook", "reward": 25000},
	{"id": "lake_swimmer", "title": "Lake Victoria Swimmer", "desc": "Take a swim at Ggaba Beach", "reward": 4000},
]

# ---------------------------------------------------------------- state
var rng := RandomNumberGenerator.new()
var bakers := {}
var _mesh_cache := {}

var mat_solid: Material
var mat_road: StandardMaterial3D
var mat_window: StandardMaterial3D
var mat_window_gen: StandardMaterial3D
var mat_lamp: StandardMaterial3D
var mat_neon_pink: StandardMaterial3D
var mat_neon_cyan: StandardMaterial3D
var mat_ember: StandardMaterial3D
var mat_tv_screen: StandardMaterial3D
var mat_agent: Material
var mat_water: StandardMaterial3D
var mat_murram: StandardMaterial3D
var mud_zones: Array = []          # Array of Rect2 in XZ for Ugandan red murram / mud roads
var highway_routes: Array = []     # Array of {a, b, label, kind} for map rendering

var sun: DirectionalLight3D
var env: Environment
var sky_mat: ProceduralSkyMaterial
var light_pools: Array[MeshInstance3D] = []       # street-light & neon ground glow (power-dependent)
var gen_light_pools: Array[MeshInstance3D] = []   # charcoal sigiri & solar-bulb glow (stays on in power cuts)
var vehicles: Array = []
var obstacles: Array = []   # what traffic brakes for: vehicles, the player, people on the zebra
var rain: CPUParticles3D
var walkers: Array = []
var people: Array = []        # all spawned people (walkers + idle + police + hawkers) for solid personal space
var umbrellas: Array = []
var rig: Node3D
var hud: CanvasLayer
var player: CharacterBody3D
var jobs: Node3D
var life: Node          # Kampala Life: needs, places, routes, rides, citizens
var endless_world: Node3D
var horizon_hills: Node3D
var collider_body: StaticBody3D
var sfx: Node
var built := false
var night_amount := 0.0

# road graph: junction positions, their neighbours, and the roads between them
var nodes: Array[Vector3] = []
var adj: Array = []
var edges: Array = []
var junction_owner := {}
var junction_time := {}
var district_of := {}
var places: Array = []        # job spots: {name, pos, district}
var pumps: Array[Vector3] = []
var checkpoints: Array[Vector3] = []
var roundabouts: Array[Vector3] = []
var rolex_stands: Array[Vector3] = []
var momo_kiosks: Array[Vector3] = []
var muchomo_stands: Array[Vector3] = []
var fruit_carts: Array[Vector3] = []
var boda_fundis: Array[Vector3] = []
var airtime_tables: Array[Vector3] = []
var tv_stands: Array[Vector3] = []
var billboards: Array = []
var tv_displays: Array = []
var market_centres: Array[Vector3] = []
var taxi_parks: Array[Vector3] = []
var music_spots: Array = []
var roadwork_zones: Array = []
var wash_bays: Array[Vector3] = []
var _roadwork_warn_cd := 0.0
var _wash_cooldown := 0.0
var pitch_ball: MeshInstance3D
var pitch_center := Vector3.ZERO
var _pitch_t := 0.0
var lake_swimmers: Array[Node3D] = []
var _used_names := {}
var _loading: CanvasLayer
var _screen_timer := 0.0
var _ad_index := 0
var _match_min := 64

var money := 5000
var day := 1
var paused := false
var day_stats := {}
var has_helmet := false
var has_vest := false
var has_permit := false
var has_rain_jacket := false
var has_big_tank := false
var bike_level := 0
var owns_boda := false
var hired_riders := 0
var owns_rolex_stand := false
var owns_kibanda_tv := false
var owns_momo_kiosk := false
var owns_matatu := false
var bike_paint := 0
var rider_name := "Kato"
var home_stage := 0
var rider_outfit := 0
var rider_female := false
var total_trips := 0
var unlocked_achievements := {}
var street_event := {}
var event_marker: Node3D
var _event_cooldown := 6.0
var rating := 4.6
var regulars := {}
var momo_log: Array = []
var sms_list: Array = []
var save_slot := 1
var tutorial_step := 0
var district_rep := {}
var daily_spin_day := 0
var vip_ticket := false
var active_encounter := {}
var _encounter_t := 48.0
var _voice_t := 4.5
var _police_cooldown := 0.0
var _hustle_cooldown := 0.0

const GOAL := 500000          # deposit to own your boda (hire purchase)
const DAILY_RENT := 10000     # what you pay the boda's owner every evening
const HIRED_REMIT := 15000    # daily Mobile Money remit from each boda rider you hire
const FUEL_PRICE := 5000      # UGX per litre
const DAY_START := 7.0
const DAY_END := 23.0         # extended to 23:00 so players enjoy Kampala's vibrant night lights & nightlife
const SAVE_PATH := "user://playkampala_save.json"

var time_of_day := DAY_START
var time_speed := 1          # 1 = one game hour every 20 seconds
var raining := false
var power_on := true

var _shot_frames := -1
var _shot_path := ""


# =============================================================== setup
func _make_noise_textures(freq: float, contrast: float, bump_strength: float, seed_val: int) -> Array:
	var n := FastNoiseLite.new()
	n.seed = seed_val
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_octaves = 3
	var img := n.get_seamless_image(128, 128)
	var alb := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var v := img.get_pixel(x, y).r
			var c := clampf(1.0 + (v - 0.5) * contrast, 0.78, 1.08)
			alb.set_pixel(x, y, Color(c, c, c, 1.0))
	alb.generate_mipmaps()
	var nrm := img.duplicate()
	nrm.bump_map_to_normal_map(bump_strength)
	nrm.generate_mipmaps()
	return [ImageTexture.create_from_image(alb), ImageTexture.create_from_image(nrm)]


func _make_materials() -> void:
	var solid_tex := _make_noise_textures(0.08, 0.16, 1.4, 101)
	var road_tex := _make_noise_textures(0.16, 0.24, 2.2, 202)
	var murram_tex := _make_noise_textures(0.11, 0.34, 3.6, 303)
	var water_tex := _make_noise_textures(0.05, 0.14, 2.4, 404)

	# Stylized Sunlit Kampala Architecture Shader: warm golden sunlight, soft cerulean sky shadow bounce,
	# plaster micro-grain, and lower-wall terracotta ground-contact AO!
	var arch_sh := Shader.new()
	arch_sh.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D detail_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 dust_col = vec3(0.66, 0.38, 0.24);
varying vec3 v_wpos;
varying vec3 v_wnrm;
void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 an = abs(v_wnrm);
	vec2 uv = (an.y > 0.7) ? v_wpos.xz : ((an.x > an.z) ? v_wpos.zy : v_wpos.xy);
	float grain = texture(detail_tex, uv * 0.26).r;
	vec3 col = COLOR.rgb * mix(0.93, 1.06, grain);
	// Warm golden top-bounce & cool sky-violet shadow tint (matches PlayKampala illustration style!)
	float sky_up = clamp(v_wnrm.y * 0.5 + 0.5, 0.0, 1.0);
	col *= mix(vec3(0.92, 0.89, 0.98), vec3(1.05, 1.01, 0.95), sky_up);
	float wall_mask = 1.0 - smoothstep(0.35, 0.85, an.y);
	float h = clamp(v_wpos.y, 0.0, 2.5);
	float base_ao = mix(0.74, 1.0, smoothstep(0.0, 0.55, h));
	float dust = (1.0 - smoothstep(0.02, 0.62, h)) * wall_mask * 0.22;
	col = mix(col * mix(1.0, base_ao, wall_mask), dust_col, dust);
	ALBEDO = col;
	ROUGHNESS = 0.80;
	SPECULAR = 0.30;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = arch_sh
	sm.set_shader_parameter("detail_tex", solid_tex[0])
	mat_solid = sm

	mat_road = _mat()
	mat_road.roughness = 0.72
	mat_road.metallic_specular = 0.48
	mat_road.albedo_texture = road_tex[0]
	mat_road.normal_enabled = true
	mat_road.normal_texture = road_tex[1]
	mat_road.normal_scale = 0.42
	mat_road.uv1_triplanar = true
	mat_road.uv1_scale = Vector3(0.45, 0.45, 0.45)

	mat_murram = _mat()
	mat_murram.roughness = 0.88
	mat_murram.metallic_specular = 0.22
	mat_murram.albedo_texture = murram_tex[0]
	mat_murram.normal_enabled = true
	mat_murram.normal_texture = murram_tex[1]
	mat_murram.normal_scale = 0.85
	mat_murram.uv1_triplanar = true
	mat_murram.uv1_scale = Vector3(0.32, 0.32, 0.32)

	mat_water = _mat()
	mat_water.roughness = 0.14
	mat_water.metallic = 0.18
	mat_water.metallic_specular = 0.85
	mat_water.albedo_texture = water_tex[0]
	mat_water.normal_enabled = true
	mat_water.normal_texture = water_tex[1]
	mat_water.normal_scale = 0.65
	mat_water.uv1_triplanar = true
	mat_water.uv1_scale = Vector3(0.10, 0.10, 0.10)

	# Stylized Character & Vehicle Illustration Shader: smooth wrap lighting, warm sun sheen,
	# rich sky-blue shadow bounce (never flat grey!), and crisp golden edge rim-highlight!
	var agent_sh := Shader.new()
	agent_sh.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec3 v_wnrm;
void vertex() {
	v_wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float up = clamp(v_wnrm.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 hemi = mix(vec3(0.88, 0.86, 0.96), vec3(1.04, 1.01, 0.96), up);
	vec3 base_c = COLOR.rgb * hemi;
	ALBEDO = base_c + mix(base_c, vec3(1.0, 0.94, 0.80), 0.55) * fresnel * 0.24;
	ROUGHNESS = 0.36;
	METALLIC = 0.08;
	SPECULAR = 0.68;
}
"""
	var am := ShaderMaterial.new()
	am.shader = agent_sh
	mat_agent = am

	mat_window = _mat(Color(1.0, 0.78, 0.45))
	mat_window_gen = _mat(Color(1.0, 0.94, 0.78))
	mat_lamp = _mat(Color(1.0, 0.85, 0.55))
	mat_neon_pink = _mat(Color(1.0, 0.22, 0.68))
	mat_neon_cyan = _mat(Color(0.18, 0.90, 1.0))
	mat_ember = _mat(Color(1.0, 0.36, 0.08))
	mat_tv_screen = _mat(Color(0.82, 0.95, 1.0))


func _mat(emission := Color.BLACK) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 0.92
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 0.0
	return m


func _make_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sun_angle_max = 12.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.72
	env.ambient_light_energy = 1.08
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.04
	env.tonemap_white = 6.0
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.07
	env.adjustment_saturation = 1.14
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_curve = 1.5
	env.fog_density = 0.85
	env.glow_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 82.0
	sun.shadow_opacity = 0.76
	sun.shadow_bias = 0.04
	sun.shadow_blur = 1.4
	add_child(sun)


# =============================================================== mesh helpers
func _box_mesh(s: Vector3) -> BoxMesh:
	var k := "b%s" % s
	if not _mesh_cache.has(k):
		var m := BoxMesh.new()
		m.size = s
		_mesh_cache[k] = m
	return _mesh_cache[k]


func _cyl(top: float, bottom: float, h: float, segs := 8) -> CylinderMesh:
	var k := "c%f_%f_%f_%d" % [top, bottom, h, segs]
	if not _mesh_cache.has(k):
		var m := CylinderMesh.new()
		m.top_radius = top
		m.bottom_radius = bottom
		m.height = h
		m.radial_segments = segs
		m.rings = 0
		_mesh_cache[k] = m
	return _mesh_cache[k]


func _sphere(r: float, h: float, segs := 8, rings := 4) -> SphereMesh:
	var k := "s%f_%f_%d_%d" % [r, h, segs, rings]
	if not _mesh_cache.has(k):
		var m := SphereMesh.new()
		m.radius = r
		m.height = h
		m.radial_segments = segs
		m.rings = rings
		_mesh_cache[k] = m
	return _mesh_cache[k]


func _capsule(r: float, h: float, segs := 8) -> CapsuleMesh:
	var k := "k%f_%f_%d" % [r, h, segs]
	if not _mesh_cache.has(k):
		var m := CapsuleMesh.new()
		m.radius = r
		m.height = h
		m.radial_segments = segs
		m.rings = 2
		_mesh_cache[k] = m
	return _mesh_cache[k]


func _prism(s: Vector3) -> PrismMesh:
	var k := "p%s" % s
	if not _mesh_cache.has(k):
		var m := PrismMesh.new()
		m.size = s
		_mesh_cache[k] = m
	return _mesh_cache[k]


## One coloured part of a model: [mesh, local transform, colour]
func part(mesh: Mesh, pos: Vector3, col: Color, b := Basis.IDENTITY) -> Array:
	return [mesh, Transform3D(b, pos), col]


func _add(layer: String, mesh: Mesh, xf: Transform3D, col: Color) -> void:
	var key := layer
	if layer != "far":
		key = "%s|%d|%d" % [layer, floori(xf.origin.x / 64.0), floori(xf.origin.z / 64.0)]
	if not bakers.has(key):
		bakers[key] = Baker.new()
	bakers[key].add(mesh, xf, col)


func box(pos: Vector3, size: Vector3, col: Color, xf := Transform3D.IDENTITY, layer := "solid") -> void:
	_add(layer, _box_mesh(size), xf * Transform3D(Basis.IDENTITY, pos), col)


## Invisible solid box so the player can't walk through things.
func collide(xf: Transform3D, center: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.transform = xf * Transform3D(Basis.IDENTITY, center)
	collider_body.add_child(cs)


func tree(kind: int, xf: Transform3D) -> void:
	bake_parts(model_tree(kind), xf)
	collide(xf, Vector3(0, 1.5, 0), Vector3(0.6, 3.0, 0.6))


func bake_parts(parts: Array, xf: Transform3D, layer := "solid") -> void:
	for p in parts:
		_add(layer, p[0], xf * (p[1] as Transform3D), p[2])


func _finish_bakers() -> int:
	var n := 0
	for key in bakers:
		var b = bakers[key]
		if b.is_empty():
			continue
		var mi := MeshInstance3D.new()
		var layer: String = (key as String).split("|")[0]
		if layer == "far":
			mi.mesh = b.build()
		else:
			var centre: Vector3 = b.centre()
			mi.mesh = b.build(centre)
			mi.position = centre
			mi.visibility_range_end = 280.0   # far chunks are simply not drawn
		match layer:
			"road":
				mi.material_override = mat_road
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			"murram":
				mi.material_override = mat_murram
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			"water":
				mi.material_override = mat_water
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			"win":
				mi.material_override = mat_window
			"gen":
				mi.material_override = mat_window_gen
			"lamp":
				mi.material_override = mat_lamp
			"neon_pink":
				mi.material_override = mat_neon_pink
			"neon_cyan":
				mi.material_override = mat_neon_cyan
			"ember":
				mi.material_override = mat_ember
			"tv":
				mi.material_override = mat_tv_screen
			_:
				mi.material_override = mat_solid
		add_child(mi)
		n += 1
	bakers.clear()
	return n


func _pick(arr: Array) -> Variant:
	return arr[rng.randi() % arr.size()]


# =============================================================== models
# All models face -Z (Godot's "forward") and stand on y = 0.

func _human_meshes() -> Dictionary:
	return {
		"torso_m": MeshSculpt.lathe_profile("hum_torso_m", [
			Vector2(0.158, -0.02), Vector2(0.168, 0.08), Vector2(0.194, 0.22),
			Vector2(0.222, 0.34), Vector2(0.205, 0.43), Vector2(0.082, 0.47)
		], 14, Vector2(1.06, 0.72)),
		"torso_f": MeshSculpt.lathe_profile("hum_torso_f", [
			Vector2(0.155, -0.02), Vector2(0.132, 0.10), Vector2(0.178, 0.26),
			Vector2(0.184, 0.34), Vector2(0.168, 0.42), Vector2(0.072, 0.46)
		], 14, Vector2(1.02, 0.74)),
		"pelvis_m": MeshSculpt.lathe_profile("hum_pelvis_m", [
			Vector2(0.115, -0.11), Vector2(0.168, -0.02), Vector2(0.164, 0.08), Vector2(0.156, 0.13)
		], 14, Vector2(1.04, 0.76)),
		"pelvis_f": MeshSculpt.lathe_profile("hum_pelvis_f", [
			Vector2(0.118, -0.11), Vector2(0.184, -0.01), Vector2(0.176, 0.07), Vector2(0.148, 0.13)
		], 14, Vector2(1.08, 0.80)),
		"skirt": MeshSculpt.lathe_profile("hum_skirt", [
			Vector2(0.258, -0.27), Vector2(0.232, -0.10), Vector2(0.194, 0.08), Vector2(0.152, 0.24)
		], 14, Vector2(1.04, 0.88)),
		"thigh": MeshSculpt.lathe_profile("hum_thigh", [
			Vector2(0.068, -0.23), Vector2(0.084, -0.10), Vector2(0.104, 0.08), Vector2(0.098, 0.22), Vector2(0.070, 0.26)
		], 12, Vector2(0.96, 1.04)),
		"calf": MeshSculpt.lathe_profile("hum_calf", [
			Vector2(0.048, -0.21), Vector2(0.056, -0.10), Vector2(0.076, 0.06), Vector2(0.070, 0.19), Vector2(0.058, 0.23)
		], 12, Vector2(0.95, 1.04)),
		"sleeve": MeshSculpt.lathe_profile("hum_sleeve_v2", [
			Vector2(0.066, -0.09), Vector2(0.076, 0.0), Vector2(0.084, 0.07),
			Vector2(0.068, 0.13), Vector2(0.012, 0.168)
		], 12),
		"forearm": MeshSculpt.lathe_profile("hum_forearm", [
			Vector2(0.042, -0.14), Vector2(0.054, -0.02), Vector2(0.062, 0.08), Vector2(0.055, 0.15)
		], 12),
		"head": MeshSculpt.lathe_profile("hum_head", [
			Vector2(0.055, -0.13), Vector2(0.104, -0.07), Vector2(0.128, 0.01),
			Vector2(0.134, 0.09), Vector2(0.112, 0.15), Vector2(0.052, 0.18)
		], 14, Vector2(0.94, 1.04)),
		"shoe": MeshSculpt.extrude_profile("hum_shoe", [
			Vector2(0.018, -0.14), Vector2(0.062, -0.12), Vector2(0.086, -0.03),
			Vector2(0.082, 0.08), Vector2(0.018, 0.08)
		], 0.108, 0.024, 0.015),
		"sole": MeshSculpt.extrude_profile("hum_sole", [
			Vector2(0.0, -0.145), Vector2(0.022, -0.145), Vector2(0.022, 0.085), Vector2(0.0, 0.085)
		], 0.114, 0.015, 0.008),
		"helmet_open": MeshSculpt.lathe_profile("boda_open_helmet_v2", [
			Vector2(0.148, -0.08), Vector2(0.166, 0.01), Vector2(0.168, 0.09),
			Vector2(0.138, 0.16), Vector2(0.005, 0.198)
		], 14, Vector2(0.98, 1.06), PI * 1.44, -PI * 0.22),
		"helmet_visor": MeshSculpt.lathe_profile("boda_visor_front", [
			Vector2(0.174, 0.02), Vector2(0.178, 0.09), Vector2(0.162, 0.13)
		], 10, Vector2(1.0, 1.06), PI * 0.72, -PI * 0.86),
	}


func model_person(female: bool, scale := 1.0, carry := true) -> Array:
	var hm := _human_meshes()
	var skin: Color = _pick(SKINS)
	var top: Color = _pick(CLOTHES)
	var bottom: Color = top if (female and rng.randf() < 0.5) else _pick(CLOTHES)
	var p := [
		part(hm["torso_f" if female else "torso_m"], Vector3(0, 1.02, 0), top),
		part(hm["skirt" if female else "pelvis_m"], Vector3(0, 0.74 if female else 0.94, 0), bottom),
		part(hm["head"], Vector3(0, 1.66, 0), skin),
		part(_sphere(0.138, 0.18, 10, 5), Vector3(0, 1.73, 0.015), _pick(CLOTHES) if (female and rng.randf() < 0.55) else DARK),
	]
	for sx in [-1.0, 1.0]:
		p.append(part(hm["thigh"], Vector3(sx * 0.105, 0.69, 0), skin if female else bottom))
		p.append(part(hm["calf"], Vector3(sx * 0.105, 0.28, 0), skin if female else bottom))
		p.append(part(hm["shoe"], Vector3(sx * 0.105, 0.0, -0.02), DARK))
		p.append(part(hm["sleeve"], Vector3(sx * 0.225, 1.33, 0), top))
		p.append(part(hm["forearm"], Vector3(sx * 0.245, 1.08, -0.03), skin))
	if carry and rng.randf() < 0.18:
		p.append(part(_box_mesh(Vector3(0.26, 0.34, 0.17)), Vector3(0, 1.96, 0), Color(0.98, 0.84, 0.12)))
	if scale != 1.0:
		var s := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), Vector3.ZERO)
		for q in p:
			q[1] = s * (q[1] as Transform3D)
	return p


## Sculpted, anatomical, expressive Kampala citizens & player (zero stick limbs!)
func model_human(female: bool, style := "casual", carry := false, custom_top: Variant = null, custom_bottom: Variant = null, custom_skin: Variant = null, custom_shoe: Variant = null, wear_vest := false) -> Array:
	var hm := _human_meshes()
	var skin: Color = custom_skin if custom_skin != null else _pick(SKINS)
	var top: Color = custom_top if custom_top != null else _pick(CLOTHES)
	var bottom: Color = custom_bottom if custom_bottom != null else _pick([Color(0.16, 0.26, 0.44), DARK, Color(0.38, 0.32, 0.25), Color(0.20, 0.28, 0.24), Color(0.52, 0.44, 0.36)])
	var shoe: Color = custom_shoe if custom_shoe != null else _pick([Color(0.16, 0.14, 0.14), Color(0.38, 0.22, 0.12), Color(0.88, 0.88, 0.92)])
	var hair := Color(0.06, 0.05, 0.05)
	if style == "school":
		top = _pick([Color(0.95, 0.95, 0.95), Color(0.75, 0.85, 0.95), Color(0.95, 0.85, 0.5)])
		bottom = _pick([Color(0.55, 0.45, 0.3), Color(0.15, 0.25, 0.5), Color(0.2, 0.4, 0.25)])
	elif style == "police":
		top = Color(0.97, 0.97, 0.99)
		bottom = Color(0.10, 0.14, 0.24)
		shoe = DARK
	elif style == "attendant":
		top = Color(0.10, 0.62, 0.30)
		bottom = Color(0.12, 0.16, 0.22)
		shoe = DARK
	elif style == "team_red":
		top = Color(0.88, 0.16, 0.16)
		bottom = Color(0.95, 0.95, 0.95)
	elif style == "team_blue":
		top = Color(0.14, 0.40, 0.92)
		bottom = Color(0.95, 0.95, 0.95)
	elif style == "pastor":
		top = Color(0.14, 0.14, 0.18)
		bottom = Color(0.12, 0.12, 0.15)
		shoe = DARK
	elif style == "swim":
		top = skin
		bottom = _pick([Color(0.12, 0.58, 0.92), Color(0.95, 0.35, 0.18), Color(0.18, 0.78, 0.45), Color(0.95, 0.80, 0.15)])
		shoe = skin

	var long_robe := style == "gomesi" or style == "kanzu"
	var skirt := female and not long_robe and style != "swim" and custom_bottom == null and rng.randf() < 0.65
	var leg_col: Color = skin if (skirt or long_robe or style == "swim") else bottom
	var tshirt_col: Color = Color(0.14, 0.15, 0.18) if wear_vest else (Color(0.15, 0.15, 0.2) if style == "kanzu" else top)
	var arm_x := 0.205 if female else 0.232
	var leg_x := 0.096 if female else 0.108
	var p := []

	for sx in [-1.0, 1.0]:
		var thigh := Person.THIGH_L if sx < 0 else Person.THIGH_R
		var shin := Person.SHIN_L if sx < 0 else Person.SHIN_R
		var arm := Person.ARM_L if sx < 0 else Person.ARM_R
		var fore := Person.FORE_L if sx < 0 else Person.FORE_R
		if style != "swim":
			p.append([hm["sole"], Transform3D(Basis.IDENTITY, Vector3(sx * leg_x, 0.0, -0.01)), Color(0.94, 0.94, 0.92), shin])
		p.append([hm["shoe"], Transform3D(Basis.IDENTITY, Vector3(sx * leg_x, 0.005, -0.01)), shoe, shin])
		# Sculpted muscular calves & thighs with seamless overlapping joints (no sticks!)
		var l_sc := Vector3(0.90, 1.0, 0.92) if female else Vector3(1.0, 1.0, 1.0)
		p.append([hm["calf"], Transform3D(Basis.IDENTITY.scaled(l_sc), Vector3(sx * leg_x, 0.27, 0)), leg_col, shin])
		p.append([hm["thigh"], Transform3D(Basis.IDENTITY.scaled(l_sc), Vector3(sx * leg_x, 0.69, 0)), leg_col, thigh])
		# Sculpted short-sleeve deltoid/bicep + bare muscular forearm + hand
		var a_sc := Vector3(0.86, 1.0, 0.86) if female else Vector3(1.0, 1.0, 1.0)
		p.append([hm["sleeve"], Transform3D(Basis.IDENTITY.scaled(a_sc), Vector3(sx * arm_x, 1.32, 0)), tshirt_col, arm])
		p.append([_capsule(0.052 if female else 0.060, 0.22), Transform3D(Basis.IDENTITY, Vector3(sx * (arm_x + 0.006), 1.21, 0)), skin, arm])
		p.append([hm["forearm"], Transform3D(Basis.IDENTITY.scaled(a_sc), Vector3(sx * (arm_x + 0.015), 1.01, 0)), skin, fore])
		p.append([_sphere(0.050 if female else 0.058, 0.105, 8, 4), Transform3D(Basis.IDENTITY, Vector3(sx * (arm_x + 0.018), 0.85, -0.01)), skin, fore])
		if style == "gomesi":
			p.append([_sphere(0.118, 0.20, 8, 4), Transform3D(Basis.IDENTITY, Vector3(sx * 0.19, 1.43, 0)), top, Person.SPINE])

	# Hips / Skirt / Robe
	if long_robe:
		var robe: Color = top if style == "gomesi" else Color(0.96, 0.95, 0.90)
		p.append([_cyl(0.16, 0.28, 0.88, 12), Transform3D(Basis.IDENTITY, Vector3(0, 0.50, 0)), robe, Person.HIPS])
	elif skirt:
		var sk_col: Color = bottom if rng.randf() < 0.5 else top
		p.append([hm["skirt"], Transform3D(Basis.IDENTITY, Vector3(0, 0.74, 0)), sk_col, Person.HIPS])
		p.append([_cyl(0.245, 0.262, 0.07, 14), Transform3D(Basis.IDENTITY.scaled(Vector3(1.04, 1.0, 0.88)), Vector3(0, 0.49, 0)), _pick(CLOTHES), Person.HIPS])
	elif female:
		p.append([hm["pelvis_f"], Transform3D(Basis.IDENTITY, Vector3(0, 0.94, 0)), bottom, Person.HIPS])
	else:
		p.append([hm["pelvis_m"], Transform3D(Basis.IDENTITY, Vector3(0, 0.94, 0)), bottom, Person.HIPS])
		if style != "swim":
			p.append([_cyl(0.168, 0.168, 0.045, 12), Transform3D(Basis.IDENTITY.scaled(Vector3(1.04, 1.0, 0.76)), Vector3(0, 1.01, 0)), DARK, Person.HIPS])
			p.append([_box_mesh(Vector3(0.055, 0.048, 0.02)), Transform3D(Basis.IDENTITY, Vector3(0, 1.01, -0.132)), Color(0.88, 0.74, 0.24), Person.HIPS])

	# Sculpted Organic Torso + Optional Open High-Vis Boda Reflector Vest with Silver Stripes!
	p.append([hm["torso_f" if female else "torso_m"], Transform3D(Basis.IDENTITY, Vector3(0, 1.02, 0)), tshirt_col, Person.SPINE])
	if wear_vest:
		var silver := Color(0.86, 0.90, 0.94)
		# Open front panels + full bright high-vis yellow back + crisp silver reflective bands!
		p.append([hm["torso_f" if female else "torso_m"], Transform3D(Basis.IDENTITY.scaled(Vector3(1.05, 0.93, 1.06)), Vector3(0, 1.03, 0.006)), top, Person.SPINE])
		p.append([_box_mesh(Vector3(0.095, 0.38, 0.05)), Transform3D(Basis.IDENTITY, Vector3(0, 1.23, -0.155)), tshirt_col, Person.SPINE])
		for sy_band in [1.11, 1.22]:
			p.append([_cyl(0.214, 0.202, 0.032, 14), Transform3D(Basis.IDENTITY.scaled(Vector3(1.07, 1.0, 0.77)), Vector3(0, sy_band, 0.006)), silver, Person.SPINE])
		for sx_band in [-0.10, 0.10]:
			p.append([_box_mesh(Vector3(0.034, 0.16, 0.30)), Transform3D(Basis.IDENTITY, Vector3(sx_band, 1.38, 0.005)), silver, Person.SPINE])
	if female and style == "casual" and custom_top == null and rng.randf() < 0.45:
		p.append([_box_mesh(Vector3(0.09, 0.20, 0.22)), Transform3D(Basis.IDENTITY, Vector3(0.24, 0.96, 0.02)), _pick([DARK, Color(0.58, 0.24, 0.14), Color(0.78, 0.56, 0.22)]), Person.SPINE])
	if style == "gomesi":
		p.append([_cyl(0.165, 0.175, 0.085, 12), Transform3D(Basis.IDENTITY, Vector3(0, 1.02, 0)), _pick(CLOTHES), Person.SPINE])
	if style == "vendor":
		p.append([_box_mesh(Vector3(0.28, 0.44, 0.03)), Transform3D(Basis.IDENTITY, Vector3(0, 1.0, -0.14)), _pick([PAINT, Color(0.9, 0.5, 0.2)]), Person.SPINE])
	if style == "police":
		p.append([_cyl(0.205, 0.185, 0.08, 12), Transform3D(Basis.IDENTITY.scaled(Vector3(1.05, 1, 0.76)), Vector3(0, 1.06, 0)), Color(0.75, 0.98, 0.15), Person.SPINE])
		p.append([_box_mesh(Vector3(0.32, 0.34, 0.03)), Transform3D(Basis.IDENTITY, Vector3(0, 1.25, -0.15)), Color(0.75, 0.98, 0.15), Person.SPINE])
		p.append([_box_mesh(Vector3(0.44, 0.05, 0.12)), Transform3D(Basis.IDENTITY, Vector3(0, 1.46, 0)), Color(0.10, 0.18, 0.45), Person.SPINE])

	# Sculpted Neck, Jawline/Head, Expressive Smiling Face & Hairstyles
	p.append([_cyl(0.052, 0.062, 0.12, 10), Transform3D(Basis.IDENTITY, Vector3(0, 1.50, 0)), skin, Person.HEAD])
	p.append([hm["head"], Transform3D(Basis.IDENTITY, Vector3(0, 1.66, 0)), skin, Person.HEAD])
	for ear_x in [-0.126, 0.126]:
		p.append([_sphere(0.025, 0.048, 6, 3), Transform3D(Basis.IDENTITY, Vector3(ear_x, 1.66, 0.005)), skin.darkened(0.08), Person.HEAD])
	p.append([_sphere(0.020, 0.038, 6, 3), Transform3D(Basis.IDENTITY, Vector3(0, 1.645, -0.132)), skin.darkened(0.10), Person.HEAD])
	# Bright warm smile (white teeth + lip line, matching the joyful rider in the reference art!)
	p.append([_box_mesh(Vector3(0.052, 0.018, 0.016)), Transform3D(Basis.IDENTITY, Vector3(0, 1.598, -0.122)), Color(0.97, 0.97, 0.96), Person.HEAD])
	for ex in [-0.044, 0.044]:
		p.append([_sphere(0.022, 0.028, 6, 3), Transform3D(Basis.IDENTITY, Vector3(ex, 1.685, -0.116)), Color(0.97, 0.97, 0.95), Person.HEAD])
		p.append([_sphere(0.013, 0.019, 6, 3), Transform3D(Basis.IDENTITY, Vector3(ex, 1.685, -0.128)), Color(0.06, 0.05, 0.05), Person.HEAD])
		p.append([_box_mesh(Vector3(0.036, 0.010, 0.012)), Transform3D(Basis.IDENTITY, Vector3(ex, 1.714, -0.120)), hair, Person.HEAD])
	if not female and style != "school":
		# Subtle neat chin beard line tucked cleanly along the jaw
		p.append([_box_mesh(Vector3(0.056, 0.016, 0.018)), Transform3D(Basis.IDENTITY, Vector3(0, 1.565, -0.098)), hair, Person.HEAD])
	if style == "police":
		p.append([_cyl(0.158, 0.138, 0.09, 12), Transform3D(Basis.IDENTITY, Vector3(0, 1.81, 0)), Color(0.98, 0.98, 1.0), Person.HEAD])
		p.append([_cyl(0.142, 0.142, 0.04, 12), Transform3D(Basis.IDENTITY, Vector3(0, 1.76, 0)), Color(0.10, 0.22, 0.55), Person.HEAD])
		p.append([_box_mesh(Vector3(0.18, 0.02, 0.12)), Transform3D(Basis.IDENTITY, Vector3(0, 1.75, -0.12)), DARK, Person.HEAD])
	elif female and (style == "gomesi" or (custom_top == null and rng.randf() < 0.42)):
		var wrap_col: Color = _pick(CLOTHES)
		p.append([_sphere(0.150, 0.23, 10, 5), Transform3D(Basis.IDENTITY, Vector3(0, 1.75, 0.016)), wrap_col, Person.HEAD])
		p.append([_sphere(0.076, 0.13, 8, 4), Transform3D(Basis.IDENTITY, Vector3(0, 1.80, 0.095)), wrap_col.lightened(0.1), Person.HEAD])
	elif female:
		p.append([_sphere(0.140, 0.20, 10, 5), Transform3D(Basis.IDENTITY, Vector3(0, 1.735, 0.018)), hair, Person.HEAD])
		if custom_top != null or rng.randf() < 0.55:
			for bx in [-0.075, -0.026, 0.026, 0.075]:
				p.append([_capsule(0.026, 0.25), Transform3D(Basis.IDENTITY, Vector3(bx, 1.57, 0.105)), hair, Person.HEAD])
		else:
			p.append([_sphere(0.092, 0.16, 8, 4), Transform3D(Basis.IDENTITY, Vector3(0, 1.82, 0.065)), hair, Person.HEAD])
	else:
		p.append([_sphere(0.142, 0.24, 12, 6), Transform3D(Basis.IDENTITY, Vector3(0, 1.755, 0.014)), hair, Person.HEAD])
		if style == "kanzu" and rng.randf() < 0.55:
			p.append([_cyl(0.126, 0.136, 0.10, 10), Transform3D(Basis.IDENTITY, Vector3(0, 1.83, 0)), Color(0.95, 0.95, 0.92), Person.HEAD])
	if carry:
		match randi() % 3:
			0: p.append([_box_mesh(Vector3(0.26, 0.34, 0.17)), Transform3D(Basis.IDENTITY, Vector3(0, 1.98, 0)), Color(1.0, 0.85, 0.1), Person.HEAD])
			1: p.append([_sphere(0.22, 0.32, 8, 4), Transform3D(Basis.IDENTITY, Vector3(0, 1.94, 0)), Color(0.3, 0.55, 0.2), Person.HEAD])
			2: p.append([_cyl(0.26, 0.18, 0.2, 10), Transform3D(Basis.IDENTITY, Vector3(0, 1.92, 0)), Color(0.75, 0.6, 0.35), Person.HEAD])
	return p


func _person_style(female: bool) -> String:
	var r := randf()
	if female:
		return "gomesi" if r < 0.2 else ("vendor" if r < 0.3 else "casual")
	return "kanzu" if r < 0.12 else ("vendor" if r < 0.2 else "casual")


func make_person(female: bool, style: String, carry: bool, pos: Vector3, scale := 1.0) -> Node3D:
	var person: Node3D = Person.new()
	person.build(model_human(female, style, carry), mat_agent)
	person.scale = Vector3.ONE * PERSON_SCALE * scale
	var a: Node3D = Mover.new()
	a.main = self
	a.add_child(person)
	a.body = person
	a.position = pos
	a.add_to_group("agents")
	add_child(a)
	people.append(a)
	return a


func model_boda(rider := true, passenger := false, custom_col: Variant = null) -> Array:
	var frame: Color = (custom_col as Color) if custom_col is Color else _pick([Color(0.84, 0.11, 0.16), Color(0.84, 0.11, 0.16), Color(0.12, 0.40, 0.86), Color(0.16, 0.17, 0.20)])
	var fork_tilt := Basis(Vector3.RIGHT, 0.36)
	var chrome := Color(0.84, 0.87, 0.92)
	var alloy := Color(0.78, 0.82, 0.88)
	var rubber := Color(0.13, 0.13, 0.16)
	var wpair_f := MeshSculpt.spoked_wheel_pair("boda_wheel_f", 0.35, 0.092, 0.11, 5)
	var wpair_r := MeshSculpt.spoked_wheel_pair("boda_wheel_r", 0.35, 0.098, 0.12, 5)
	var tank_mesh := MeshSculpt.extrude_profile("boda_tank_v2", [
		Vector2(0.75, -0.47), Vector2(0.96, -0.40), Vector2(1.06, -0.20),
		Vector2(0.98, 0.04), Vector2(0.79, 0.06), Vector2(0.71, -0.22)
	], 0.38, 0.08, 0.045)
	var side_cover := MeshSculpt.extrude_profile("boda_side_panel", [
		Vector2(0.58, -0.04), Vector2(0.78, 0.0), Vector2(0.81, 0.36), Vector2(0.64, 0.28)
	], 0.29, 0.03, 0.02)
	var tail_cowl := MeshSculpt.extrude_profile("boda_tail_cowl", [
		Vector2(0.76, 0.34), Vector2(0.84, 0.38), Vector2(0.89, 0.84), Vector2(0.79, 0.86)
	], 0.27, 0.03, 0.02)
	var seat_mesh := MeshSculpt.extrude_profile("boda_seat_v2", [
		Vector2(0.82, -0.02), Vector2(0.94, 0.06), Vector2(0.98, 0.58),
		Vector2(0.93, 0.78), Vector2(0.82, 0.76), Vector2(0.79, 0.08)
	], 0.31, 0.05, 0.03)
	var fender_f := MeshSculpt.extrude_profile("boda_fender_v2", [
		Vector2(0.54, -0.86), Vector2(0.69, -0.72), Vector2(0.71, -0.50),
		Vector2(0.57, -0.38), Vector2(0.53, -0.44), Vector2(0.63, -0.64)
	], 0.16, 0.025, 0.012)
	var p := [
		# Real 3D Torus Rubber Tyres + Open 5-Spoke Silver Cast-Alloy Wheels!
		part(wpair_f[0], Vector3(0, 0.35, -0.66), rubber),
		part(wpair_f[1], Vector3(0, 0.35, -0.66), alloy),
		part(wpair_r[0], Vector3(0, 0.35, 0.62), rubber),
		part(wpair_r[1], Vector3(0, 0.35, 0.62), alloy),
		# Sculpted front mudguard, raked telescopic chrome forks & triple-clamp
		part(fender_f, Vector3.ZERO, frame),
		part(_cyl(0.028, 0.030, 0.76, 10), Vector3(-0.095, 0.70, -0.55), chrome, fork_tilt),
		part(_cyl(0.028, 0.030, 0.76, 10), Vector3(0.095, 0.70, -0.55), chrome, fork_tilt),
		part(_box_mesh(Vector3(0.24, 0.04, 0.08)), Vector3(0, 0.92, -0.47), DARK),
		# Glossy sculpted teardrop fuel tank + white highlight stripe + red side cover & tail cowl
		part(tank_mesh, Vector3.ZERO, frame),
		part(_box_mesh(Vector3(0.39, 0.028, 0.24)), Vector3(0, 0.92, -0.22), Color(0.98, 0.92, 0.92), Basis(Vector3.RIGHT, 0.18)),
		part(side_cover, Vector3.ZERO, frame.darkened(0.06)),
		part(tail_cowl, Vector3.ZERO, frame),
		part(seat_mesh, Vector3.ZERO, Color(0.14, 0.14, 0.17)),
		# Detailed Bajaj Boxer Engine: silver round crankcase + dark finned cylinder barrel + tubular chrome crash-bar!
		part(_cyl(0.12, 0.12, 0.25, 10), Vector3(0, 0.42, -0.05), alloy, Basis(Vector3.FORWARD, PI * 0.5)),
		part(_box_mesh(Vector3(0.18, 0.21, 0.18)), Vector3(0, 0.58, -0.14), Color(0.24, 0.26, 0.30), Basis(Vector3.RIGHT, 0.20)),
		for_fin_bar(0.54), for_fin_bar(0.59), for_fin_bar(0.64),
		# Tubular silver engine crash-guard loops (left & right, just like the icon!)
		part(_cyl(0.016, 0.016, 0.32, 8), Vector3(-0.21, 0.56, -0.28), chrome),
		part(_cyl(0.016, 0.016, 0.32, 8), Vector3(0.21, 0.56, -0.28), chrome),
		part(_cyl(0.016, 0.016, 0.42, 8), Vector3(0, 0.70, -0.28), chrome, Basis(Vector3.FORWARD, PI * 0.5)),
		part(_cyl(0.016, 0.016, 0.42, 8), Vector3(0, 0.41, -0.26), chrome, Basis(Vector3.FORWARD, PI * 0.5)),
		# Swingarm, chain case & upswept chrome exhaust muffler
		part(_box_mesh(Vector3(0.22, 0.055, 0.52)), Vector3(0, 0.36, 0.34), Color(0.22, 0.24, 0.28)),
		part(_cyl(0.048, 0.060, 0.92, 10), Vector3(0.18, 0.39, 0.35), chrome, Basis(Vector3.RIGHT, PI / 2 - 0.11)),
		# Twin orange/copper coil rear shocks + rear footrest guard frames
		part(_cyl(0.036, 0.036, 0.42, 10), Vector3(-0.13, 0.60, 0.54), Color(0.88, 0.40, 0.12), Basis(Vector3.RIGHT, -0.26)),
		part(_cyl(0.036, 0.036, 0.42, 10), Vector3(0.13, 0.60, 0.54), Color(0.88, 0.40, 0.12), Basis(Vector3.RIGHT, -0.26)),
		part(_box_mesh(Vector3(0.36, 0.024, 0.28)), Vector3(0, 0.46, 0.56), chrome),
		# Twin black round speedometer/tachometer pods + swept black handlebars + angled mirrors
		part(_cyl(0.056, 0.052, 0.08, 10), Vector3(-0.065, 1.07, -0.55), DARK, Basis(Vector3.RIGHT, 0.45)),
		part(_cyl(0.056, 0.052, 0.08, 10), Vector3(0.065, 1.07, -0.55), DARK, Basis(Vector3.RIGHT, 0.45)),
		part(_cyl(0.020, 0.020, 0.78, 8), Vector3(0, 1.08, -0.45), DARK, Basis(Vector3.FORWARD, PI * 0.5)),
		part(_cyl(0.030, 0.030, 0.15, 8), Vector3(-0.34, 1.08, -0.44), Color(0.14, 0.14, 0.16), Basis(Vector3.FORWARD, PI * 0.5)),
		part(_cyl(0.030, 0.030, 0.15, 8), Vector3(0.34, 1.08, -0.44), Color(0.14, 0.14, 0.16), Basis(Vector3.FORWARD, PI * 0.5)),
		part(_cyl(0.010, 0.010, 0.18, 6), Vector3(-0.27, 1.17, -0.45), DARK, Basis(Vector3.FORWARD, 0.32)),
		part(_cyl(0.010, 0.010, 0.18, 6), Vector3(0.27, 1.17, -0.45), DARK, Basis(Vector3.FORWARD, -0.32)),
		part(_box_mesh(Vector3(0.13, 0.075, 0.035)), Vector3(-0.33, 1.25, -0.45), DARK),
		part(_box_mesh(Vector3(0.13, 0.075, 0.035)), Vector3(0.33, 1.25, -0.45), DARK),
		# Large chrome-rimmed round headlamp + glowing warm lens + round amber turn signals on stalks!
		part(_cyl(0.125, 0.105, 0.14, 14), Vector3(0, 0.95, -0.60), DARK, Basis(Vector3.RIGHT, PI / 2)),
		part(_cyl(0.128, 0.128, 0.03, 14), Vector3(0, 0.95, -0.65), chrome, Basis(Vector3.RIGHT, PI / 2)),
		part(_cyl(0.112, 0.112, 0.035, 14), Vector3(0, 0.95, -0.665), Color(1.0, 0.95, 0.74), Basis(Vector3.RIGHT, PI / 2)),
		part(_sphere(0.044, 0.078, 8, 4), Vector3(-0.18, 0.93, -0.59), Color(1.0, 0.58, 0.06)),
		part(_sphere(0.044, 0.078, 8, 4), Vector3(0.18, 0.93, -0.59), Color(1.0, 0.58, 0.06)),
		# Chrome rear pillion grab-rail hoop, carrier rack, mudflap & tail-lamp
		part(_cyl(0.016, 0.016, 0.34, 8), Vector3(-0.16, 0.94, 0.72), chrome, Basis(Vector3.RIGHT, PI * 0.42)),
		part(_cyl(0.016, 0.016, 0.34, 8), Vector3(0.16, 0.94, 0.72), chrome, Basis(Vector3.RIGHT, PI * 0.42)),
		part(_cyl(0.016, 0.016, 0.34, 8), Vector3(0, 1.00, 0.87), chrome, Basis(Vector3.FORWARD, PI * 0.5)),
		part(_box_mesh(Vector3(0.14, 0.08, 0.05)), Vector3(0, 0.84, 0.90), Color(0.92, 0.12, 0.12)),
		part(_box_mesh(Vector3(0.15, 0.18, 0.03)), Vector3(0, 0.68, 0.88), DARK, Basis(Vector3.RIGHT, 0.22)),
	]
	if rider:
		p.append_array(_seated(0.10, _pick(VESTS), rng.randf() < 0.85, null, null, null, false, true))
	if passenger:
		p.append_array(_seated(0.56, _pick(CLOTHES), false, null, null, null, rng.randf() < 0.5, false))
	return p


func for_fin_bar(y_pos: float) -> Array:
	return part(_box_mesh(Vector3(0.21, 0.018, 0.21)), Vector3(0, y_pos, -0.14), Color(0.56, 0.60, 0.66), Basis(Vector3.RIGHT, 0.20))


func _seated(z: float, top: Color, helmet: bool, custom_skin: Variant = null, custom_legs: Variant = null, custom_helmet_col: Variant = null, female := false, boda_vest := false) -> Array:
	var hm := _human_meshes()
	var skin: Color = custom_skin if custom_skin != null else _pick(SKINS)
	var legs: Color = custom_legs if custom_legs != null else Color(0.16, 0.28, 0.46)
	var tshirt: Color = Color(0.13, 0.14, 0.18) if boda_vest else top
	var silver := Color(0.86, 0.90, 0.94)
	var hair := Color(0.06, 0.05, 0.05)
	var lean := Basis(Vector3.RIGHT, -0.15)
	var p := [
		# Sculpted athletic torso leaning slightly forward + dark T-shirt base
		part(hm["torso_f" if female else "torso_m"], Vector3(0, 1.12, z + 0.03), tshirt, lean),
		part(hm["pelvis_f" if female else "pelvis_m"], Vector3(0, 1.04, z + 0.05), legs),
		part(_cyl(0.052, 0.062, 0.12, 10), Vector3(0, 1.60, z - 0.05), skin),
		part(hm["head"], Vector3(0, 1.75, z - 0.06), skin),
		# Expressive smiling face on the rider!
		part(_box_mesh(Vector3(0.050, 0.018, 0.016)), Vector3(0, 1.69, z - 0.182), Color(0.97, 0.97, 0.96)),
		part(_sphere(0.020, 0.026, 6, 3), Vector3(-0.042, 1.775, z - 0.175), Color(0.97, 0.97, 0.95)),
		part(_sphere(0.020, 0.026, 6, 3), Vector3(0.042, 1.775, z - 0.175), Color(0.97, 0.97, 0.95)),
		part(_sphere(0.012, 0.018, 6, 3), Vector3(-0.042, 1.775, z - 0.188), hair),
		part(_sphere(0.012, 0.018, 6, 3), Vector3(0.042, 1.775, z - 0.188), hair),
	]
	if not female:
		p.append(part(_box_mesh(Vector3(0.054, 0.016, 0.018)), Vector3(0, 1.658, z - 0.155), hair))
	if boda_vest:
		# Open V-neck high-vis yellow/orange reflector vest OVER dark T-shirt + twin silver reflective bands!
		p.append(part(hm["torso_f" if female else "torso_m"], Vector3(0, 1.13, z + 0.036), top, lean.scaled(Vector3(1.05, 0.93, 1.06))))
		p.append(part(_box_mesh(Vector3(0.095, 0.36, 0.05)), Vector3(0, 1.36, z - 0.135), tshirt, lean))
		for sy_b in [1.21, 1.32]:
			p.append(part(_cyl(0.214, 0.202, 0.032, 14), Vector3(0, sy_b, z + 0.022), silver, lean.scaled(Vector3(1.07, 1.0, 0.77))))
		for sx_b in [-0.105, 0.105]:
			p.append(part(_box_mesh(Vector3(0.034, 0.15, 0.30)), Vector3(sx_b, 1.48, z - 0.025), silver, lean))

	for sx in [-1.0, 1.0]:
		# Sculpted bent blue-jeans thighs hugging tank -> rounded knee -> calf angled to footpeg -> sneaker with white sole!
		p.append(part(hm["thigh"], Vector3(sx * 0.16, 1.00, z - 0.14), legs, Basis(Vector3.RIGHT, 1.18) * Basis(Vector3.FORWARD, sx * 0.14)))
		p.append(part(_sphere(0.074, 0.14, 8, 4), Vector3(sx * 0.185, 0.91, z - 0.34), legs))
		p.append(part(hm["calf"], Vector3(sx * 0.185, 0.69, z - 0.27), legs, Basis(Vector3.RIGHT, -0.32)))
		p.append(part(hm["sole"], Vector3(sx * 0.19, 0.46, z - 0.22), Color(0.95, 0.95, 0.93), Basis(Vector3.RIGHT, 0.18)))
		p.append(part(hm["shoe"], Vector3(sx * 0.19, 0.465, z - 0.22), Color(0.16, 0.14, 0.14), Basis(Vector3.RIGHT, 0.18)))
		if boda_vest:
			# Two-segment bent muscular rider arms: dark short sleeve out to elbow + bare brown forearm forward to handlebar grip!
			var u_basis := Basis(Vector3.FORWARD, -sx * 0.42) * Basis(Vector3.RIGHT, 0.48)
			p.append(part(hm["sleeve"], Vector3(sx * 0.23, 1.44, z - 0.08), tshirt, u_basis))
			p.append(part(_capsule(0.056, 0.22), Vector3(sx * 0.27, 1.34, z - 0.15), skin, u_basis))
			var f_basis := Basis(Vector3.UP, sx * 0.14) * Basis(Vector3.RIGHT, 1.32)
			p.append(part(hm["forearm"], Vector3(sx * 0.305, 1.19, z - 0.35), skin, f_basis))
			p.append(part(_sphere(0.054, 0.10, 8, 4), Vector3(sx * 0.32, 1.09, z - 0.54), skin))
		else:
			# Passenger holding waist/grab-rail
			p.append(part(hm["sleeve"], Vector3(sx * 0.21, 1.42, z + 0.02), tshirt))
			p.append(part(hm["forearm"], Vector3(sx * 0.21, 1.18, z - 0.10), skin, Basis(Vector3.RIGHT, 0.85)))

	if helmet:
		# Iconic Open-Face Golden-Yellow Kampala Boda Helmet with black inner liner & front-only clear curved visor!
		var hcol: Color = custom_helmet_col if custom_helmet_col != null else Color(0.98, 0.74, 0.12)
		p.append(part(hm["helmet_open"], Vector3(0, 1.77, z - 0.055), hcol))
		p.append(part(hm["helmet_visor"], Vector3(0, 1.77, z - 0.055), Color(0.76, 0.90, 0.98)))
		p.append(part(_cyl(0.012, 0.012, 0.18, 6), Vector3(0, 1.62, z - 0.09), DARK, Basis(Vector3.FORWARD, PI * 0.5)))
	else:
		p.append(part(_sphere(0.140, 0.19, 10, 5), Vector3(0, 1.82, z - 0.045), hair))
	return p


func model_taxi() -> Array:
	var wpair := MeshSculpt.spoked_wheel_pair("taxi_wheel", 0.37, 0.105, 0.22, 6)
	var body_mesh := MeshSculpt.extrude_profile("taxi_hiace_body_v2", [
		Vector2(0.40, -2.36), Vector2(1.12, -2.38), Vector2(1.94, -1.80),
		Vector2(2.05, -1.24), Vector2(2.05, 2.22), Vector2(1.88, 2.36),
		Vector2(0.40, 2.36)
	], 1.94, 0.10, 0.06)
	var wind_mesh := MeshSculpt.extrude_profile("taxi_hiace_wind_v2", [
		Vector2(1.22, -2.31), Vector2(1.88, -1.83), Vector2(1.88, -1.68), Vector2(1.22, -2.16)
	], 1.74, 0.03, 0.015)
	var p := [
		part(body_mesh, Vector3.ZERO, TAXI_WHITE),
		part(wind_mesh, Vector3.ZERO, GLASS),
		# Framed dark-tinted side window bays with crisp white B/C/D pillars!
		part(_box_mesh(Vector3(1.97, 0.54, 1.08)), Vector3(0, 1.56, -1.08), GLASS),
		part(_box_mesh(Vector3(1.97, 0.54, 1.16)), Vector3(0, 1.56, 0.22), GLASS),
		part(_box_mesh(Vector3(1.97, 0.54, 1.12)), Vector3(0, 1.56, 1.54), GLASS),
		part(_box_mesh(Vector3(1.72, 0.54, 0.08)), Vector3(0, 1.56, 2.34), GLASS),
		# Front & rear sculpted bumpers, slatted black grille, headlamps, amber corner indicators & roof TAXI sign!
		part(_box_mesh(Vector3(1.98, 0.24, 0.20)), Vector3(0, 0.50, -2.38), DARK),
		part(_box_mesh(Vector3(1.98, 0.24, 0.20)), Vector3(0, 0.50, 2.38), DARK),
		part(_box_mesh(Vector3(0.36, 0.18, 0.08)), Vector3(-0.62, 0.86, -2.37), Color(1.0, 0.97, 0.84)),
		part(_box_mesh(Vector3(0.36, 0.18, 0.08)), Vector3(0.62, 0.86, -2.37), Color(1.0, 0.97, 0.84)),
		part(_box_mesh(Vector3(0.14, 0.18, 0.08)), Vector3(-0.86, 0.86, -2.36), Color(1.0, 0.58, 0.08)),
		part(_box_mesh(Vector3(0.14, 0.18, 0.08)), Vector3(0.86, 0.86, -2.36), Color(1.0, 0.58, 0.08)),
		part(_box_mesh(Vector3(0.84, 0.24, 0.07)), Vector3(0, 0.84, -2.37), DARK),
		part(_box_mesh(Vector3(0.46, 0.13, 0.05)), Vector3(0, 0.50, -2.49), TAXI_WHITE),
		part(_box_mesh(Vector3(0.46, 0.13, 0.05)), Vector3(0, 0.50, 2.49), CURB_YELLOW),
		part(_box_mesh(Vector3(0.14, 0.20, 0.09)), Vector3(-1.05, 1.34, -1.90), DARK),
		part(_box_mesh(Vector3(0.14, 0.20, 0.09)), Vector3(1.05, 1.34, -1.90), DARK),
		part(_box_mesh(Vector3(0.64, 0.18, 0.22)), Vector3(0, 2.13, -1.25), TAXI_WHITE),
		part(_box_mesh(Vector3(0.28, 0.24, 0.07)), Vector3(-0.78, 0.92, 2.36), Color(0.92, 0.14, 0.12)),
		part(_box_mesh(Vector3(0.28, 0.24, 0.07)), Vector3(0.78, 0.92, 2.36), Color(0.92, 0.14, 0.12)),
		part(_box_mesh(Vector3(0.55, 0.18, 0.04)), Vector3(-0.55, 0.72, 2.37), CURB_YELLOW),
		part(_box_mesh(Vector3(0.55, 0.18, 0.04)), Vector3(0.55, 0.72, 2.37), Color(0.92, 0.22, 0.10)),
		part(_box_mesh(Vector3(1.52, 0.06, 2.55)), Vector3(0, 2.09, 0.35), GREY),
	]
	if rng.randf() < 0.65:
		p.append(part(_box_mesh(Vector3(0.62, 0.30, 0.80)), Vector3(-0.28, 2.26, 0.45), _pick(GOODS)))
		p.append(part(_sphere(0.30, 0.42, 7, 3), Vector3(0.30, 2.26, -0.15), Color(0.28, 0.58, 0.18)))
	for wx in [-0.88, 0.88]:
		for wz in [-1.45, 1.48]:
			p.append(part(wpair[0], Vector3(wx, 0.37, wz), DARK))
			p.append(part(wpair[1], Vector3(wx, 0.37, wz), Color(0.80, 0.83, 0.88)))
	# Iconic Kampala blue-and-white checkered matatu band + lower blue skirt
	p.append(part(_box_mesh(Vector3(1.96, 0.24, 4.55)), Vector3(0, 0.66, 0.0), TAXI_BLUE.lightened(0.08)))
	for side in [-1.0, 1.0]:
		for i in 22:
			for row in 2:
				var c := TAXI_BLUE if (i + row) % 2 == 0 else TAXI_WHITE
				p.append(part(_box_mesh(Vector3(0.03, 0.16, 0.20)), Vector3(side * 0.98, 0.94 + row * 0.16, -2.05 + i * 0.20), c))
	return p


func model_car(col: Color) -> Array:
	var wpair := MeshSculpt.spoked_wheel_pair("car_wheel", 0.34, 0.095, 0.20, 5)
	var car_body := MeshSculpt.extrude_profile("sedan_sculpt_body_v2", [
		Vector2(0.34, -2.08), Vector2(0.76, -2.06), Vector2(0.94, -1.08),
		Vector2(1.50, -0.40), Vector2(1.50, 0.90), Vector2(0.96, 1.56),
		Vector2(0.88, 2.06), Vector2(0.34, 2.06)
	], 1.82, 0.11, 0.07)
	# Glass cabin slightly wider than beveled roof sides + framed front/rear windshields so windows show crisply!
	var car_side_win_f := MeshSculpt.extrude_profile("sedan_win_f", [
		Vector2(0.98, -0.96), Vector2(1.42, -0.36), Vector2(1.42, 0.18), Vector2(0.98, 0.18)
	], 1.85, 0.02, 0.01)
	var car_side_win_r := MeshSculpt.extrude_profile("sedan_win_r", [
		Vector2(0.98, 0.30), Vector2(1.42, 0.30), Vector2(1.42, 0.84), Vector2(0.98, 1.38)
	], 1.85, 0.02, 0.01)
	var p := [
		part(car_body, Vector3.ZERO, col),
		part(car_side_win_f, Vector3.ZERO, GLASS),
		part(car_side_win_r, Vector3.ZERO, GLASS),
		part(_box_mesh(Vector3(1.54, 0.56, 0.06)), Vector3(0, 1.22, -0.74), GLASS, Basis(Vector3.RIGHT, -0.78)),
		part(_box_mesh(Vector3(1.50, 0.54, 0.06)), Vector3(0, 1.22, 1.22), GLASS, Basis(Vector3.RIGHT, 0.78)),
		part(_box_mesh(Vector3(1.86, 0.20, 0.18)), Vector3(0, 0.42, -2.06), DARK),
		part(_box_mesh(Vector3(1.86, 0.20, 0.18)), Vector3(0, 0.42, 2.06), DARK),
		part(_box_mesh(Vector3(0.36, 0.15, 0.08)), Vector3(-0.62, 0.68, -2.07), Color(1.0, 0.97, 0.84)),
		part(_box_mesh(Vector3(0.36, 0.15, 0.08)), Vector3(0.62, 0.68, -2.07), Color(1.0, 0.97, 0.84)),
		part(_box_mesh(Vector3(0.70, 0.17, 0.07)), Vector3(0, 0.64, -2.07), DARK),
		part(_box_mesh(Vector3(0.34, 0.16, 0.08)), Vector3(-0.62, 0.72, 2.07), Color(0.92, 0.14, 0.12)),
		part(_box_mesh(Vector3(0.34, 0.16, 0.08)), Vector3(0.62, 0.72, 2.07), Color(0.92, 0.14, 0.12)),
		part(_box_mesh(Vector3(0.42, 0.11, 0.05)), Vector3(0, 0.44, -2.15), TAXI_WHITE),
		part(_box_mesh(Vector3(0.42, 0.11, 0.05)), Vector3(0, 0.44, 2.15), CURB_YELLOW),
		part(_box_mesh(Vector3(0.14, 0.10, 0.08)), Vector3(-0.98, 1.04, -0.52), col),
		part(_box_mesh(Vector3(0.14, 0.10, 0.08)), Vector3(0.98, 1.04, -0.52), col),
	]
	for wx in [-0.82, 0.82]:
		for wz in [-1.32, 1.32]:
			p.append(part(wpair[0], Vector3(wx, 0.34, wz), DARK))
			p.append(part(wpair[1], Vector3(wx, 0.34, wz), Color(0.80, 0.83, 0.88)))
	return p


func model_bus(col: Color, accent: Color) -> Array:
	var wheel := Basis(Vector3.FORWARD, PI / 2)
	var p := [
		# Long regional/city coach body (9.2m long)
		part(_box_mesh(Vector3(2.35, 2.15, 9.2)), Vector3(0, 1.55, 0), col),
		part(_box_mesh(Vector3(2.38, 0.28, 9.22)), Vector3(0, 0.92, 0), accent),
		part(_box_mesh(Vector3(2.25, 0.14, 8.8)), Vector3(0, 2.68, 0), Color(0.92, 0.92, 0.94)),
		# Panoramic side windows & tall front windshield
		part(_box_mesh(Vector3(2.38, 0.78, 8.2)), Vector3(0, 2.02, 0.15), GLASS),
		part(_box_mesh(Vector3(2.12, 0.92, 0.08)), Vector3(0, 1.98, -4.61), GLASS),
		part(_box_mesh(Vector3(1.55, 0.28, 0.08)), Vector3(0, 2.52, -4.61), Color(0.98, 0.82, 0.14)),
		# Bumpers, headlights, taillights & yellow Uganda plates
		part(_box_mesh(Vector3(2.38, 0.30, 0.16)), Vector3(0, 0.56, -4.64), DARK),
		part(_box_mesh(Vector3(2.38, 0.30, 0.16)), Vector3(0, 0.56, 4.64), DARK),
		part(_box_mesh(Vector3(0.38, 0.18, 0.06)), Vector3(-0.82, 0.86, -4.62), Color(0.98, 0.96, 0.82)),
		part(_box_mesh(Vector3(0.38, 0.18, 0.06)), Vector3(0.82, 0.86, -4.62), Color(0.98, 0.96, 0.82)),
		part(_box_mesh(Vector3(0.32, 0.22, 0.06)), Vector3(-0.85, 0.95, 4.62), Color(0.90, 0.12, 0.12)),
		part(_box_mesh(Vector3(0.32, 0.22, 0.06)), Vector3(0.85, 0.95, 4.62), Color(0.90, 0.12, 0.12)),
		part(_box_mesh(Vector3(0.46, 0.14, 0.05)), Vector3(0, 0.56, -4.73), CURB_YELLOW),
		part(_box_mesh(Vector3(0.46, 0.14, 0.05)), Vector3(0, 0.56, 4.73), CURB_YELLOW),
		# Roof AC pods & luggage rack
		part(_box_mesh(Vector3(1.45, 0.24, 1.8)), Vector3(0, 2.82, -1.6), GREY.lightened(0.2)),
		part(_box_mesh(Vector3(1.65, 0.26, 2.6)), Vector3(0, 2.82, 2.2), WOOD),
	]
	for wx in [-1.05, 1.05]:
		for wz in [-2.9, 2.0, 3.1]:
			p.append(part(_cyl(0.44, 0.44, 0.28), Vector3(wx, 0.44, wz), DARK, wheel))
			p.append(part(_cyl(0.24, 0.24, 0.30), Vector3(wx, 0.44, wz), GREY.lightened(0.25), wheel))
	return p


func model_trailer(cab_col: Color, box_col: Color) -> Array:
	var wheel := Basis(Vector3.FORWARD, PI / 2)
	var p := [
		# Heavy tractor cab (front, -z)
		part(_box_mesh(Vector3(2.25, 1.95, 2.6)), Vector3(0, 1.48, -4.4), cab_col),
		part(_box_mesh(Vector3(2.22, 1.05, 1.35)), Vector3(0, 1.02, -5.65), cab_col),
		part(_box_mesh(Vector3(1.98, 0.68, 0.08)), Vector3(0, 2.05, -5.71), GLASS),
		part(_box_mesh(Vector3(1.25, 0.52, 0.08)), Vector3(0, 1.05, -6.34), DARK),
		part(_box_mesh(Vector3(0.38, 0.18, 0.06)), Vector3(-0.82, 0.85, -6.34), Color(0.98, 0.96, 0.82)),
		part(_box_mesh(Vector3(0.38, 0.18, 0.06)), Vector3(0.82, 0.85, -6.34), Color(0.98, 0.96, 0.82)),
		part(_cyl(0.06, 0.06, 1.4), Vector3(-1.05, 2.65, -3.25), GREY),
		part(_cyl(0.06, 0.06, 1.4), Vector3(1.05, 2.65, -3.25), GREY),
		# Chassis & 40ft shipping container trailer (rear, +z)
		part(_box_mesh(Vector3(2.15, 0.26, 9.2)), Vector3(0, 0.78, 1.0), DARK),
		part(_box_mesh(Vector3(2.36, 2.45, 8.2)), Vector3(0, 2.12, 1.6), box_col),
		# Rear hazard stripes & taillights
		part(_box_mesh(Vector3(2.38, 0.28, 0.08)), Vector3(0, 0.92, 5.72), CURB_YELLOW),
		part(_box_mesh(Vector3(0.36, 0.20, 0.06)), Vector3(-0.88, 0.88, 5.74), Color(0.90, 0.12, 0.12)),
		part(_box_mesh(Vector3(0.36, 0.20, 0.06)), Vector3(0.88, 0.88, 5.74), Color(0.90, 0.12, 0.12)),
	]
	for rib in [-1.8, -0.4, 1.0, 2.4, 3.8, 5.0]:
		p.append(part(_box_mesh(Vector3(2.40, 2.38, 0.10)), Vector3(0, 2.12, rib), box_col.darkened(0.14)))
	for wx in [-1.05, 1.05]:
		for wz in [-5.1, -3.4, 3.2, 4.3, 5.2]:
			p.append(part(_cyl(0.46, 0.46, 0.28), Vector3(wx, 0.46, wz), DARK, wheel))
			p.append(part(_cyl(0.24, 0.24, 0.30), Vector3(wx, 0.46, wz), GREY.lightened(0.25), wheel))
	return p


func model_umbrella(col: Color, height := 2.3, radius := 1.3) -> Array:
	return [
		part(_cyl(0.03, 0.03, height), Vector3(0, height / 2, 0), GREY),
		part(_cyl(0.02, radius, 0.45, 8), Vector3(0, height, 0), col),
	]


func model_tree(kind: int) -> Array:
	match kind:
		0:  # Iconic Ringed Curved Kampala Boulevard Palm Tree with 12 lush arched tropical fronds!
			var palm_frond := MeshSculpt.curved_frond("palm_frond_lush", 2.95, 0.96)
			var palm_inner := MeshSculpt.curved_frond("palm_frond_inner", 2.15, 0.76)
			var p := []
			var cur := Vector3.ZERO
			for seg in 7:
				var t := float(seg) / 6.0
				var r_bot := lerpf(0.26, 0.12, t)
				var r_top := lerpf(0.23, 0.105, t)
				var tilt := -0.14 + t * 0.08
				var seg_h := 0.78
				var b_seg := Basis(Vector3.FORWARD, tilt)
				var up_dir: Vector3 = (b_seg * Vector3.UP).normalized()
				var mid := cur + up_dir * (seg_h * 0.5)
				var bark := Color(0.50, 0.33, 0.20) if seg % 2 == 0 else Color(0.42, 0.27, 0.16)
				p.append(part(_cyl(r_top, r_bot, seg_h + 0.05, 10), mid, bark, b_seg))
				p.append(part(_cyl(r_top * 1.06, r_top * 1.06, 0.045, 10), cur + up_dir * seg_h, Color(0.36, 0.23, 0.14), b_seg))
				cur += up_dir * seg_h
			for ci in 3:
				var ca := ci * TAU / 3.0
				p.append(part(_sphere(0.11, 0.20, 7, 4), cur + Vector3(cos(ca) * 0.14, -0.10, sin(ca) * 0.14), Color(0.38, 0.28, 0.12)))
			for i in 8:
				var a := i * TAU / 8.0 + 0.18
				var col := Color(0.15, 0.52, 0.18) if i % 2 == 0 else Color(0.32, 0.68, 0.18)
				p.append(part(palm_frond, cur + Vector3(0, 0.05, 0), col, Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, 0.08)))
			for i in 4:
				var a2 := i * TAU / 4.0 + 0.55
				p.append(part(palm_inner, cur + Vector3(0, 0.16, 0), Color(0.42, 0.74, 0.20), Basis(Vector3.UP, a2) * Basis(Vector3.RIGHT, -0.32)))
			return p
		1:  # Lush multi-canopy Mango / Jacaranda shade tree with sculpted trunk
			var c_big := MeshSculpt.faceted_canopy("tree_canopy_big_v2", 2.25, 0.76, 11)
			var c_sm := MeshSculpt.faceted_canopy("tree_canopy_sm_v2", 1.45, 0.80, 23)
			var trunk_m := MeshSculpt.lathe_profile("tree_trunk_m", [
				Vector2(0.34, 0.0), Vector2(0.24, 0.9), Vector2(0.20, 2.0), Vector2(0.16, 2.8)
			], 10)
			var is_jac := rng.randf() < 0.35
			var col1 := JACARANDA if is_jac else Color(0.18, 0.54, 0.18)
			var col2 := JACARANDA.lightened(0.14) if is_jac else Color(0.36, 0.70, 0.20)
			return [
				part(trunk_m, Vector3.ZERO, WOOD),
				part(c_big, Vector3(0, 3.75, 0), col1),
				part(c_sm, Vector3(1.20, 3.30, 0.55), col2),
				part(c_sm, Vector3(-1.10, 3.40, -0.75), col1.lightened(0.08)),
				part(c_sm, Vector3(0.20, 4.35, -0.35), col2),
			]
		_:  # Lush Kampala Matooke Banana Plant with wide arched fronds & purple flower heart
			var b_frond := MeshSculpt.curved_frond("banana_frond_v2", 2.45, 0.84)
			var p := [
				part(_cyl(0.12, 0.20, 2.3, 9), Vector3(0, 1.15, 0), Color(0.38, 0.52, 0.20)),
				part(_sphere(0.24, 0.42, 8, 4), Vector3(0.24, 1.82, 0.12), Color(0.34, 0.64, 0.18)),
				part(_sphere(0.08, 0.18, 6, 4), Vector3(0.30, 1.52, 0.16), Color(0.52, 0.16, 0.30)),
			]
			for i in 7:
				var a := i * TAU / 7.0 + rng.randf() * 0.28
				var col := Color(0.20, 0.58, 0.16) if i % 2 == 0 else Color(0.40, 0.74, 0.20)
				p.append(part(b_frond, Vector3(0, 2.22, 0), col, Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, 0.18)))
			return p


# =============================================================== the street
func shop_house(xf: Transform3D, w: float, d: float, floors: int, lit := "win", arcade_p := 0.76, name := "", district := "") -> void:
	var wall: Color = _pick(WALLS)
	var trim: Color = Color(0.95, 0.89, 0.80) if wall.get_luminance() < 0.65 else wall.darkened(0.20)
	var fh := 3.1
	var h := floors * fh
	box(Vector3(0, h / 2, -d / 2), Vector3(w, h, d), wall, xf)
	collide(xf, Vector3(0, h / 2, -d / 2), Vector3(w, h, d))
	box(Vector3(0, h + 0.12, -d / 2 + 0.12), Vector3(w + 0.34, 0.24, d + 0.34), trim, xf)

	# roof: flat with parapet + black water tank, or painted iron sheets (mabati)
	if floors >= 2 and rng.randf() < 0.6:
		box(Vector3(0, h + 0.32, -d / 2), Vector3(w + 0.15, 0.28, d + 0.15), wall.darkened(0.12), xf)
		var tx := rng.randf_range(-w / 2 + 1.0, w / 2 - 1.0)
		box(Vector3(tx, h + 0.75, -d * 0.6), Vector3(1.2, 0.6, 1.2), GREY, xf)
		_add("solid", _cyl(0.55, 0.55, 1.2), xf * Transform3D(Basis.IDENTITY, Vector3(tx, h + 1.65, -d * 0.6)), DARK)
	else:
		_add("solid", _prism(Vector3(d + 0.8, 1.7, w + 0.3)),
			xf * Transform3D(Basis(Vector3.UP, PI / 2), Vector3(0, h + 0.95, -d / 2)), _pick(ROOFS))

	var arcade := floors >= 2 and rng.randf() < arcade_p
	var sign_col: Color = _pick(SIGNS)
	var bays := maxi(1, int(w / 3.0))
	var bw := w / bays
	for i in bays:
		var bx := -w / 2 + bw * (i + 0.5)
		var open := rng.randf() < 0.75
		if open:
			box(Vector3(bx, 1.35, 0.03), Vector3(bw - 0.5, 2.5, 0.08), SHOP_DARK, xf, lit)
			box(Vector3(bx, 1.05, 0.07), Vector3(0.98, 2.08, 0.06), Color(0.26, 0.17, 0.11), xf)
			box(Vector3(bx, 1.15, 0.10), Vector3(0.72, 1.45, 0.03), GLASS, xf, lit)
			box(Vector3(bx + 0.36, 1.02, 0.12), Vector3(0.06, 0.18, 0.05), Color(0.92, 0.78, 0.25), xf)
			if rng.randf() < 0.55 and name == "":
				for g in rng.randi_range(2, 4):
					var s := rng.randf_range(0.3, 0.52)
					box(Vector3(bx + rng.randf_range(-bw / 2 + 0.4, bw / 2 - 0.4), 0.18 + s / 2, rng.randf_range(0.4, 1.2)),
						Vector3(s, s, s), _pick(GOODS), xf)
		else:
			box(Vector3(bx, 1.35, 0.03), Vector3(bw - 0.5, 2.5, 0.08), SHUTTER, xf)
		for f in range(1, floors):
			var wy := f * fh + 1.55
			box(Vector3(bx, wy, 0.04), Vector3(minf(1.4, bw - 0.78), 1.35, 0.1), GLASS, xf, lit)
			box(Vector3(bx, wy - 0.74, 0.12), Vector3(minf(1.65, bw - 0.55), 0.12, 0.24), trim, xf)

	# 3D Arched Kampala Veranda Colonnade & Upper Loggia Railings (matches reference street art!)
	var s_z := 2.32 if arcade else 0.1
	var s_y := fh + 0.05 if arcade else 2.95
	if arcade:
		box(Vector3(0, fh, 1.15), Vector3(w, 0.22, 2.32), trim, xf)
		var arch_bays := maxi(2, roundi(w / 3.0))
		var abw := w / float(arch_bays)
		var arch_m := MeshSculpt.arch_spandrel("arch_bay_%d" % int(roundf(abw * 10.0)), abw, fh - 0.05, 0.30, 0.22)
		for ai in arch_bays:
			var ax := -w * 0.5 + abw * (ai + 0.5)
			_add("solid", arch_m, xf * Transform3D(Basis.IDENTITY, Vector3(ax, 0.0, 2.15)), trim)
			box(Vector3(ax - abw * 0.5 + 0.13, 0.18, 2.15), Vector3(0.32, 0.36, 0.36), trim.darkened(0.08), xf)
		if floors >= 2:
			box(Vector3(0, fh + 0.92, 2.22), Vector3(w - 0.2, 0.06, 0.06), DARK, xf)
			var n_bars := int(w * 2.5)
			for bi in n_bars:
				var brx := -w * 0.5 + 0.25 + float(bi) / float(maxi(1, n_bars - 1)) * (w - 0.5)
				box(Vector3(brx, fh + 0.48, 2.22), Vector3(0.035, 0.84, 0.035), DARK, xf)
		if rng.randf() < 0.55:
			var pot_x := -w * 0.5 + 0.55
			_add("solid", _cyl(0.24, 0.18, 0.38, 8), xf * Transform3D(Basis.IDENTITY, Vector3(pot_x, 0.20, 1.75)), Color(0.68, 0.34, 0.20))
			_add("solid", MeshSculpt.faceted_canopy("pot_plant", 0.34, 1.35, 9), xf * Transform3D(Basis.IDENTITY, Vector3(pot_x, 0.62, 1.75)), LEAF2)
		box(Vector3(0, fh + 0.05, 2.34), Vector3(w, 0.48, 0.06), sign_col, xf)
		box(Vector3(0, fh - 0.12, 1.15), Vector3(w * 0.72, 0.04, 0.14), Color(1.0, 0.94, 0.80), xf, "lamp")
	else:
		var awn_mesh := MeshSculpt.extrude_profile("shop_awning_%d" % int(roundf(w * 2.0)), [
			Vector2(2.65, 0.04), Vector2(2.74, 0.04), Vector2(2.24, 1.38), Vector2(2.14, 1.38)
		], w - 0.30, 0.04, 0.02)
		_add("solid", awn_mesh, xf, sign_col.lerp(Color(0.95, 0.52, 0.22), 0.35))
		box(Vector3(0, 2.95, 0.1), Vector3(w - 0.4, 0.52, 0.1), sign_col, xf)
	if name != "":
		sign_text(name, sign_col, xf * Transform3D(Basis.IDENTITY, Vector3(0, fh + 0.05, 2.36) if arcade else Vector3(0, 2.95, 0.16)), w)
		add_place(name, xf * Vector3(0, 0, 1.6), district)
		var nl := name.to_lower()
		if "bar" in nl or "saloon" in nl or "boutique" in nl or "fashions" in nl or "cosmetics" in nl:
			# Vibrant magenta/pink neon strip along the signboard top & bottom
			box(Vector3(0, s_y + 0.28, s_z + 0.04), Vector3(w - 0.5, 0.06, 0.06), Color(1.0, 0.28, 0.75), xf, "neon_pink")
			box(Vector3(0, s_y - 0.28, s_z + 0.04), Vector3(w - 0.5, 0.06, 0.06), Color(1.0, 0.28, 0.75), xf, "neon_pink")
			if "bar" in nl:
				music_spots.append({"pos": xf * Vector3(0, 0, 1.5), "kind": "bar"})
				_light_pool(xf * Vector3(0, 0.06, 2.2), 7.5, Color(0.88, 0.20, 0.60))
				# Outdoor bar tables, stools & patrons hanging out
				for tx in [-1.5, 1.5]:
					box(Vector3(tx, 0.72, 1.35), Vector3(0.75, 0.08, 0.75), WOOD, xf)
					_add("solid", _cyl(0.06, 0.08, 0.72), xf * Transform3D(Basis.IDENTITY, Vector3(tx, 0.36, 1.35)), DARK)
					box(Vector3(tx - 0.14, 0.86, 1.32), Vector3(0.08, 0.22, 0.08), Color(0.18, 0.65, 0.25), xf)
					box(Vector3(tx + 0.12, 0.84, 1.40), Vector3(0.08, 0.18, 0.08), Color(0.95, 0.72, 0.15), xf)
					_add("solid", _cyl(0.20, 0.20, 0.45), xf * Transform3D(Basis.IDENTITY, Vector3(tx - 0.55, 0.22, 1.35)), DARK)
					_add("solid", _cyl(0.20, 0.20, 0.45), xf * Transform3D(Basis.IDENTITY, Vector3(tx + 0.55, 0.22, 1.35)), DARK)
				_idle_person(xf * Vector3(-1.3, 0.02, 1.85), (xf.basis * Vector3(0.2, 0, -1)).angle_to(Vector3.FORWARD))
				_idle_person(xf * Vector3(1.4, 0.02, 1.85), (xf.basis * Vector3(-0.2, 0, -1)).angle_to(Vector3.FORWARD))
			elif "boutique" in nl or "fashions" in nl or "tailor" in nl:
				# Outdoor clothing rack with colourful hanging shirts/dresses + 2 mannequins + attendant
				box(Vector3(-1.1, 1.38, 1.05), Vector3(1.8, 0.05, 0.05), GREY, xf)
				for px in [-1.95, -0.25]:
					box(Vector3(px, 0.70, 1.05), Vector3(0.05, 1.40, 0.05), GREY, xf)
				for ci in 5:
					box(Vector3(-1.7 + ci * 0.30, 1.02, 1.05), Vector3(0.24, 0.64, 0.06), CLOTHES[ci % CLOTHES.size()], xf)
				for mx in [1.1, 1.8]:
					box(Vector3(mx, 0.10, 1.05), Vector3(0.42, 0.20, 0.42), PAINT, xf)
					_add("solid", _cyl(0.14, 0.18, 0.85), xf * Transform3D(Basis.IDENTITY, Vector3(mx, 0.62, 1.05)), _pick(CLOTHES))
					_add("solid", _sphere(0.11, 0.22, 6, 3), xf * Transform3D(Basis.IDENTITY, Vector3(mx, 1.22, 1.05)), PAINT)
				make_person(true, "casual", false, xf * Vector3(0.35, 0.02, 0.95))
		elif "hardware" in nl or "spare" in nl or "saloon" in nl or "boutique" in nl or "fashions" in nl or "electronics" in nl or "phone" in nl:
			music_spots.append({"pos": xf * Vector3(0, 0, 1.5), "kind": "shop"})
		elif "juice" in nl:
			music_spots.append({"pos": xf * Vector3(0, 0, 1.5), "kind": "shop"})
			# Juice counter, colourful mango & watermelon dispenser jars, blender, fruit crates & attendant
			box(Vector3(0, 0.48, 1.15), Vector3(2.1, 0.96, 0.75), WOOD, xf)
			_add("solid", _cyl(0.18, 0.18, 0.46), xf * Transform3D(Basis.IDENTITY, Vector3(-0.55, 1.19, 1.15)), Color(1.0, 0.72, 0.10))
			_add("solid", _cyl(0.18, 0.18, 0.46), xf * Transform3D(Basis.IDENTITY, Vector3(-0.05, 1.19, 1.15)), Color(0.95, 0.22, 0.35))
			_add("solid", _cyl(0.12, 0.15, 0.38), xf * Transform3D(Basis.IDENTITY, Vector3(0.48, 1.15, 1.15)), Color(0.85, 0.92, 0.95))
			for fi in 4:
				_add("solid", _sphere(0.16, 0.32, 6, 3), xf * Transform3D(Basis.IDENTITY, Vector3(-0.8 + fi * 0.48, 0.22, 1.72)), PRODUCE[fi % PRODUCE.size()])
			make_person(true, "vendor", false, xf * Vector3(0.0, 0.02, 0.55))
		elif "pharmacy" in nl or "clinic" in nl or "electronics" in nl or "phone" in nl or "forex" in nl or "supermarket" in nl:
			# Crisp cyan/emerald LED strip along the signboard
			box(Vector3(0, s_y + 0.28, s_z + 0.04), Vector3(w - 0.5, 0.06, 0.06), Color(0.20, 0.95, 1.0), xf, "neon_cyan")
			if "pharmacy" in nl or "clinic" in nl:
				# Glowing 3D Pharmacy/Clinic cross projecting from the facade
				box(Vector3(-w * 0.5 + 0.35, 2.45, s_z + 0.32), Vector3(0.14, 0.56, 0.18), Color(0.18, 1.0, 0.55), xf, "neon_cyan")
				box(Vector3(-w * 0.5 + 0.35, 2.45, s_z + 0.32), Vector3(0.14, 0.18, 0.56), Color(0.18, 1.0, 0.55), xf, "neon_cyan")

	# balcony with washing hanging out
	if floors >= 3 and rng.randf() < 0.5:
		var by := 2 * fh
		box(Vector3(0, by, 0.6), Vector3(w - 0.6, 0.15, 1.2), trim, xf)
		box(Vector3(0, by + 0.5, 1.15), Vector3(w - 0.6, 0.9, 0.08), trim, xf)
		for c in rng.randi_range(2, 5):
			box(Vector3(rng.randf_range(-w / 2 + 0.8, w / 2 - 0.8), by + 0.75, 1.22), Vector3(0.5, 0.6, 0.03), _pick(CLOTHES), xf)


func muzigo(xf: Transform3D, rooms: int) -> void:
	var w := rooms * 3.4
	var d := 4.2
	var h := 2.8
	var wall: Color = _pick(WALLS)
	box(Vector3(0, h / 2, -d / 2), Vector3(w, h, d), wall, xf)
	collide(xf, Vector3(0, h / 2, -d / 2), Vector3(w, h, d))
	_add("solid", _prism(Vector3(d + 1.4, 1.3, w + 0.4)),
		xf * Transform3D(Basis(Vector3.UP, PI / 2), Vector3(0, h + 0.65, -d / 2 + 0.3)), _pick(ROOFS))
	box(Vector3(0, 0.1, 0.6), Vector3(w, 0.2, 1.2), PAVEMENT.darkened(0.15), xf)
	var door: Color = _pick([Color(0.2, 0.45, 0.3), Color(0.2, 0.3, 0.6), Color(0.45, 0.25, 0.15), Color(0.6, 0.15, 0.15)])
	for i in rooms:
		var rx := -w / 2 + 3.4 * (i + 0.5)
		box(Vector3(rx - 0.6, 1.0, 0.03), Vector3(0.9, 2.0, 0.08), door, xf)
		box(Vector3(rx + 0.7, 1.5, 0.03), Vector3(0.8, 0.8, 0.08), GLASS, xf, "win")
	# washing line
	for px in [-w / 2 + 1, w / 2 - 1]:
		box(Vector3(px, 0.9, 3.0), Vector3(0.08, 1.8, 0.08), WOOD, xf)
	box(Vector3(0, 1.75, 3.0), Vector3(w - 2, 0.02, 0.02), DARK, xf)
	for c in rng.randi_range(3, 7):
		box(Vector3(rng.randf_range(-w / 2 + 1.5, w / 2 - 1.5), 1.45, 3.0), Vector3(0.55, 0.6, 0.03), _pick(CLOTHES), xf)


func _build_market(c: Vector3) -> void:
	market_centres.append(c)
	music_spots.append({"pos": c, "kind": "market"})
	box(c + Vector3(0, 0.01, 0), Vector3(24, 0.02, 24), EARTH)
	# big shed with an iron-sheet roof
	for px in [-7.0, 7.0]:
		for pz in [-5.0, 5.0]:
			box(c + Vector3(px, 2.0, pz), Vector3(0.25, 4.0, 0.25), GREY)
	_add("solid", _prism(Vector3(11.5, 1.8, 15.0)), Transform3D(Basis(Vector3.UP, PI / 2), c + Vector3(0, 4.9, 0)), ROOFS[0])
	# stalls with varied Kampala market produce (matooke, tomatoes, pineapples, grain sacks) & vendor aprons
	for gx in 4:
		for gz in 3:
			var p := c + Vector3(-7.5 + gx * 5.0, 0, -7.0 + gz * 7.0)
			box(p + Vector3(0, 0.43, 0), Vector3(2.2, 0.86, 1.2), WOOD)
			collide(Transform3D.IDENTITY, p + Vector3(0, 0.43, 0), Vector3(2.2, 0.86, 1.2))
			var produce: Color = PRODUCE[(gx + gz) % PRODUCE.size()]
			for k in 6:
				_add("solid", _sphere(0.22, 0.4, 6, 3), Transform3D(Basis.IDENTITY,
					p + Vector3(-0.8 + (k % 3) * 0.8, 1.02, -0.3 + (k / 3) * 0.6)), produce)
			# Extra woven produce sack beside stall
			_add("solid", _cyl(0.26, 0.30, 0.62), Transform3D(Basis.IDENTITY, p + Vector3(1.35, 0.31, 0)), Color(0.78, 0.68, 0.48))
			if rng.randf() < 0.5 and absf(p.z - c.z) > 4.0:
				bake_parts(model_umbrella(_pick(SIGNS), 2.4, 1.5), Transform3D(Basis.IDENTITY, p + Vector3(1.0, 0, 0.6)))
			var vend := make_person(rng.randf() < 0.65, "vendor", false, p + Vector3(0, 0, 1.0))
			vend.rotation.y = PI
	for i in 8:
		var pts := PackedVector3Array()
		for k in 4:
			pts.append(c + Vector3(rng.randf_range(-9.5, 9.5), 0.02, rng.randf_range(-3.5, -2.5) + (k % 2) * 7.0))
		_walker(pts)


func _build_taxi_park(c: Vector3) -> void:
	taxi_parks.append(c)
	box(c + Vector3(0, 0.01, 0), Vector3(26, 0.02, 24), MURRAM.darkened(0.12))
	for r in 3:
		for k in 6:
			var p := c + Vector3(-9.0 + k * 3.4, 0, -7.0 + r * 7.0)
			var txf := Transform3D(Basis(Vector3.UP, rng.randf_range(-0.08, 0.08)), p)
			bake_parts(model_taxi(), txf)
			collide(txf, Vector3(0, 1.0, 0), Vector3(1.9, 2.0, 4.7))
	# stage office kiosk
	box(c + Vector3(11, 1.3, -9), Vector3(3, 2.6, 2.4), WALLS[8])
	collide(Transform3D.IDENTITY, c + Vector3(11, 1.3, -9), Vector3(3, 2.6, 2.4))
	_add("solid", _prism(Vector3(3.2, 0.8, 3.0)), Transform3D(Basis.IDENTITY, c + Vector3(11, 3.0, -9)), ROOFS[1])
	for i in 3:
		var pts := PackedVector3Array()
		for k in 4:
			pts.append(c + Vector3(rng.randf_range(-10, 10), 0.02, -10.5 + rng.randi_range(0, 2) * 7.0 + 3.5))
		_walker(pts)
	_idle_person(c + Vector3(9.5, 0.02, -7.5), 0.8)
	_idle_person(c + Vector3(10.3, 0.02, -7.0), -2.0)


func _build_residential(c: Vector3) -> void:
	for r in 3:
		muzigo(Transform3D(Basis.IDENTITY, c + Vector3(rng.randf_range(-2, 2), 0, -10.0 + r * 8.0)), 5)
	for i in 6:
		tree((2), Transform3D(Basis(Vector3.UP, rng.randf() * TAU), c + Vector3(rng.randf_range(-11, -9), 0, -12 + i * 4.5)))
	tree((0), Transform3D(Basis.IDENTITY, c + Vector3(10.5, 0, 2)))
	_idle_person(c + Vector3(-3, 0.2, -9.0), 0.0)
	_idle_person(c + Vector3(4, 0.2, -1.0), 0.0)
	_idle_person(c + Vector3(0, 0.2, 7.0), 0.0)


func _build_pitch(c: Vector3) -> void:
	# Nakivubo Stadium pitch: green turf infield + white chalk touchlines
	box(c + Vector3(0, 0.015, 0), Vector3(21, 0.03, 13.5), LEAF.lerp(EARTH, 0.25))
	for lz in [-6.4, 6.4]:
		box(c + Vector3(0, 0.035, lz), Vector3(20, 0.01, 0.14), PAINT)
	for lx in [-9.9, 0.0, 9.9]:
		box(c + Vector3(lx, 0.035, 0), Vector3(0.14, 0.01, 13), PAINT)
	for gx in [-9.9, 9.9]:   # goalposts + nets
		for gz in [-1.6, 1.6]:
			box(c + Vector3(gx, 1.0, gz), Vector3(0.12, 2.0, 0.12), PAINT)
		box(c + Vector3(gx, 2.0, 0), Vector3(0.12, 0.12, 3.3), PAINT)
		var net_x: float = float(gx) + (-0.55 if gx < 0 else 0.55)
		box(c + Vector3(net_x, 1.0, 0), Vector3(1.0, 1.9, 3.2), Color(0.92, 0.92, 0.92, 0.45), Transform3D.IDENTITY, "glass")
	# Corner flags
	for cx_f in [-9.9, 9.9]:
		for cz_f in [-6.4, 6.4]:
			box(c + Vector3(cx_f, 0.45, cz_f), Vector3(0.05, 0.9, 0.05), PAINT)
			box(c + Vector3(cx_f + 0.14, 0.82, cz_f), Vector3(0.28, 0.18, 0.03), Color(0.95, 0.78, 0.10))
	# Animated live football on the pitch
	pitch_center = c
	pitch_ball = MeshInstance3D.new()
	pitch_ball.mesh = _sphere(0.18, 0.36)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = PAINT
	pitch_ball.material_override = bmat
	pitch_ball.position = c + Vector3(0, 0.18, 0)
	add_child(pitch_ball)
	# Tiered Nakivubo Stadium spectator stands on north and south sides
	for side: float in [-1.0, 1.0]:
		var sz_base: Vector3 = c + Vector3(0, 0, side * 9.8)
		# outer stadium wall
		box(sz_base + Vector3(0, 2.2, side * 1.9), Vector3(22.0, 4.4, 0.45), WALLS[0])
		# 3 concrete spectator tiers stepping up away from the pitch
		for tier in 3:
			var ty: float = 0.55 + tier * 0.75
			var tz: float = side * (8.4 + tier * 0.95)
			box(c + Vector3(0, ty * 0.5, tz), Vector3(21.4, ty, 0.95), PAVEMENT.lightened(0.08 * tier))
		# cantilevered corrugated stadium roof canopy + support pillars
		box(sz_base + Vector3(0, 4.55, -side * 0.2), Vector3(22.4, 0.22, 4.4), ROOFS[3])
		for px in [-9.5, -3.2, 3.2, 9.5]:
			box(sz_base + Vector3(px, 2.3, side * 1.5), Vector3(0.28, 4.5, 0.28), GREY)
		collide(Transform3D.IDENTITY, sz_base + Vector3(0, 2.0, 0), Vector3(22.0, 4.0, 3.8))
	sign_text("NAKIVUBO WAR MEMORIAL STADIUM", Color(0.14, 0.45, 0.85), Transform3D(Basis(Vector3.UP, PI), c + Vector3(0, 3.8, -11.98)), 14.0)
	# 4v4 Red vs Blue Footballers actively playing on the pitch + Referee
	for ti in 4:
		var pts_r := PackedVector3Array()
		var pts_b := PackedVector3Array()
		for k in 4:
			pts_r.append(c + Vector3(rng.randf_range(-8.0, 2.5), 0.03, rng.randf_range(-5.2, 5.2)))
			pts_b.append(c + Vector3(rng.randf_range(-2.5, 8.0), 0.03, rng.randf_range(-5.2, 5.2)))
		var pr := make_person(false, "team_red", false, pts_r[0], 0.92)
		pr.points = pts_r; pr.mode = 1; pr.speed = rng.randf_range(3.2, 4.4); walkers.append(pr)
		var pb := make_person(false, "team_blue", false, pts_b[0], 0.92)
		pb.points = pts_b; pb.mode = 1; pb.speed = rng.randf_range(3.2, 4.4); walkers.append(pb)
	var ref := make_person(false, "pastor", false, c + Vector3(0, 0.03, 0), 0.92)
	ref.points = PackedVector3Array([c + Vector3(-4, 0.03, -2), c + Vector3(4, 0.03, 2)])
	ref.mode = 1; ref.speed = 2.6; walkers.append(ref)
	# Spectators seated/cheering on both concrete stadium stands
	for side_sp: float in [-1.0, 1.0]:
		for si in 5:
			var sp_pos := c + Vector3(-8.0 + si * 4.0 + rng.randf_range(-0.6, 0.6), 0.55 + (si % 3) * 0.75, side_sp * (8.4 + (si % 3) * 0.95))
			_idle_person(sp_pos, 0.0 if side_sp > 0 else PI)
	for i in 3:
		tree((1), Transform3D(Basis.IDENTITY, c + Vector3(-12.5, 0, -6 + i * 6)))


func _build_rolex_stand(p: Vector3) -> void:
	rolex_stands.append(p)
	box(p + Vector3(0, 0.45, 0), Vector3(1.6, 0.9, 0.8), WOOD)
	collide(Transform3D.IDENTITY, p + Vector3(0.4, 0.45, 0), Vector3(2.4, 0.9, 0.9))
	# Glass chapati/egg display box + tray of eggs & sliced tomatoes
	box(p + Vector3(-0.3, 1.1, 0), Vector3(0.62, 0.42, 0.52), Color(0.75, 0.85, 0.9))
	box(p + Vector3(0.35, 0.94, 0), Vector3(0.44, 0.06, 0.38), Color(0.95, 0.82, 0.48))
	# Charcoal sigiri stove with glowing red-orange embers + cast-iron frying pan (kikalayi)
	_add("solid", _cyl(0.26, 0.2, 0.5), Transform3D(Basis.IDENTITY, p + Vector3(1.1, 0.25, 0)), DARK)
	_add("ember", _cyl(0.23, 0.23, 0.06), Transform3D(Basis.IDENTITY, p + Vector3(1.1, 0.52, 0)), Color(1.0, 0.38, 0.08))
	box(p + Vector3(1.1, 0.58, 0), Vector3(0.52, 0.03, 0.52), DARK)
	# Hanging solar night bulb under the umbrella so the rolex stand glows even in a power cut
	_add("gen", _sphere(0.09, 0.16, 6, 3), Transform3D(Basis.IDENTITY, p + Vector3(0.4, 2.15, -0.5)), Color(1.0, 0.92, 0.68))
	bake_parts(model_umbrella(Color(0.95, 0.5, 0.1), 2.5, 1.6), Transform3D(Basis.IDENTITY, p + Vector3(0.4, 0, -0.5)))
	_light_pool(p + Vector3(0.5, -0.11, 0.2), 6.2, Color(0.95, 0.46, 0.14), true)
	_idle_person(p + Vector3(0.3, 0, -0.75), 0.0)
	_idle_person(p + Vector3(0.0, 0, 1.0), PI)
	_idle_person(p + Vector3(0.9, 0, 1.3), PI + 0.4)


func _build_momo_kiosk(p: Vector3) -> void:
	momo_kiosks.append(p)
	var is_mtn := rng.randf() < 0.55
	var col: Color = Color(1.0, 0.80, 0.05) if is_mtn else Color(0.88, 0.12, 0.14)
	box(p + Vector3(0, 1.05, 0), Vector3(1.4, 2.1, 1.4), col)
	box(p + Vector3(0, 1.35, 0.71), Vector3(1.0, 0.75, 0.05), SHOP_DARK, Transform3D.IDENTITY, "win")
	# Glowing night fascia strip around the kiosk roof
	box(p + Vector3(0, 2.08, 0), Vector3(1.46, 0.10, 1.46), col, Transform3D.IDENTITY, "lamp")
	_add("solid", _prism(Vector3(1.7, 0.45, 1.7)), Transform3D(Basis.IDENTITY, p + Vector3(0, 2.32, 0)), ROOFS[1])
	collide(Transform3D.IDENTITY, p + Vector3(0, 1.05, 0), Vector3(1.4, 2.1, 1.4))
	bake_parts(model_umbrella(col, 2.4, 1.4), Transform3D(Basis.IDENTITY, p + Vector3(1.1, 0, 0.5)))
	_light_pool(p + Vector3(0, -0.11, 0.8), 5.8, Color(0.95, 0.75, 0.20) if is_mtn else Color(0.95, 0.30, 0.25))
	_idle_person(p + Vector3(0.0, 0, 1.15), PI)
	add_place("the Mobile Money kiosk", p + Vector3(0, 0, 1.8), district_at(p))


func _build_muchomo_stand(p: Vector3, theta := 0.0) -> void:
	muchomo_stands.append(p)
	var xf := Transform3D(Basis(Vector3.UP, theta), p)
	# Half-drum steel charcoal grill (muchomo sigiri) + legs
	box(Vector3(-0.45, 0.42, 0), Vector3(0.95, 0.18, 0.55), DARK, xf)
	for lx in [-0.85, -0.05]:
		for lz in [-0.22, 0.22]:
			box(Vector3(lx, 0.20, lz), Vector3(0.05, 0.40, 0.05), GREY, xf)
	# Glowing red-orange charcoal bed + sizzling beef skewers & golden roasted gonja (plantain)
	box(Vector3(-0.45, 0.52, 0), Vector3(0.88, 0.04, 0.48), Color(1.0, 0.34, 0.06), xf, "ember")
	for sk in 5:
		var sx := -0.80 + sk * 0.17
		box(Vector3(sx, 0.57, 0), Vector3(0.06, 0.05, 0.46), Color(0.48, 0.22, 0.12) if sk % 2 == 0 else Color(0.96, 0.78, 0.20), xf)
	# Wooden chopping table with kachumbari salad bowls & salt shaker
	box(Vector3(0.55, 0.42, 0), Vector3(0.95, 0.84, 0.65), WOOD, xf)
	box(Vector3(0.45, 0.88, -0.1), Vector3(0.28, 0.08, 0.28), Color(0.88, 0.18, 0.14), xf)
	box(Vector3(0.78, 0.88, 0.1), Vector3(0.24, 0.08, 0.24), Color(0.25, 0.72, 0.22), xf)
	# Painted roadside signboard + hanging solar bulb
	box(Vector3(0.55, 1.45, -0.32), Vector3(1.25, 0.36, 0.06), Color(0.88, 0.26, 0.08), xf)
	sign_text("MUCHOMO & ROASTED GONJA", Color(0.88, 0.26, 0.08), xf * Transform3D(Basis.IDENTITY, Vector3(0.55, 1.45, -0.27)), 1.2)
	_add("gen", _sphere(0.09, 0.16, 6, 3), xf * Transform3D(Basis.IDENTITY, Vector3(0.1, 2.15, 0)), Color(1.0, 0.90, 0.62))
	bake_parts(model_umbrella(Color(0.88, 0.22, 0.12), 2.5, 1.55), xf * Transform3D(Basis.IDENTITY, Vector3(0.1, 0, -0.25)))
	collide(xf, Vector3(0.05, 0.45, 0), Vector3(2.1, 0.9, 0.85))
	_light_pool(p + Vector3(0, -0.11, 0), 6.8, Color(1.0, 0.42, 0.12), true)
	var chef := make_person(false, "vendor", false, xf * Vector3(0.0, 0, -0.68))
	chef.rotation.y = theta
	_idle_person(xf * Vector3(-0.3, 0, 0.88), theta + PI)
	add_place("the Muchomo & Gonja grill", xf * Vector3(0, 0, 1.35), district_at(p))


func _build_fruit_cart(p: Vector3, theta := 0.0) -> void:
	fruit_carts.append(p)
	var xf := Transform3D(Basis(Vector3.UP, theta), p)
	var wheel := Basis(Vector3.FORWARD, PI / 2)
	# Two-wheeled wooden Kampala fruit pushcart (kigaali)
	box(Vector3(0, 0.56, 0), Vector3(1.65, 0.24, 1.05), WOOD, xf)
	box(Vector3(0, 0.72, 0), Vector3(1.72, 0.10, 1.12), Color(0.22, 0.58, 0.28), xf)
	for wz in [-0.58, 0.58]:
		_add("solid", _cyl(0.32, 0.32, 0.08, 8), xf * Transform3D(wheel * Basis(Vector3.UP, PI / 2), Vector3(-0.1, 0.32, wz)), DARK)
	# Push handles & front prop leg
	box(Vector3(1.05, 0.56, -0.38), Vector3(0.55, 0.05, 0.05), WOOD, xf)
	box(Vector3(1.05, 0.56, 0.38), Vector3(0.55, 0.05, 0.05), WOOD, xf)
	box(Vector3(0.68, 0.28, 0), Vector3(0.06, 0.56, 0.06), GREY, xf)
	# Piled watermelons, yellow pineapples, mangoes & sugarcane stalks
	for mx in [-0.52, -0.16, 0.20]:
		_add("solid", _sphere(0.18, 0.34, 7, 4), xf * Transform3D(Basis.IDENTITY, Vector3(mx, 0.90, -0.20)), Color(0.16, 0.52, 0.20))
		_add("solid", _sphere(0.15, 0.28, 7, 4), xf * Transform3D(Basis.IDENTITY, Vector3(mx + 0.1, 0.88, 0.22)), Color(0.98, 0.78, 0.12))
	# Red watermelon slices + tall peeled sugarcane bundle
	box(Vector3(0.55, 0.86, -0.15), Vector3(0.28, 0.14, 0.22), Color(0.92, 0.16, 0.20), xf)
	_add("solid", _cyl(0.10, 0.12, 0.85, 6), xf * Transform3D(Basis(Vector3.FORWARD, 0.18), Vector3(-0.62, 1.12, 0.18)), Color(0.68, 0.82, 0.32))
	bake_parts(model_umbrella(Color(0.18, 0.68, 0.32), 2.4, 1.45), xf * Transform3D(Basis.IDENTITY, Vector3(0.0, 0, -0.2)))
	_add("gen", _sphere(0.08, 0.14, 6, 3), xf * Transform3D(Basis.IDENTITY, Vector3(0.0, 2.05, -0.2)), Color(1.0, 0.94, 0.70))
	collide(xf, Vector3(0, 0.55, 0), Vector3(1.85, 1.1, 1.15))
	var vendor := make_person(true, "vendor", false, xf * Vector3(1.15, 0, 0.0))
	vendor.rotation.y = theta - PI / 2
	add_place("the Sugarcane & Fruit Cart", xf * Vector3(0, 0, 1.25), district_at(p))


func _build_boda_fundi(p: Vector3, theta := 0.0) -> void:
	boda_fundis.append(p)
	var xf := Transform3D(Basis(Vector3.UP, theta), p)
	# Red compressed-air tank ("PRESSURE") on wheels + gauge
	_add("solid", _cyl(0.22, 0.22, 0.95, 8), xf * Transform3D(Basis(Vector3.FORWARD, PI / 2), Vector3(-0.55, 0.38, 0)), Color(0.86, 0.14, 0.12))
	box(Vector3(-0.55, 0.68, 0), Vector3(0.24, 0.18, 0.18), DARK, xf)
	# Stack of black boda spare tyres & red metal tool chest
	for ti in 3:
		_add("solid", _cyl(0.34, 0.34, 0.14, 8), xf * Transform3D(Basis.IDENTITY, Vector3(0.35, 0.08 + ti * 0.15, -0.15)), DARK)
	box(Vector3(0.85, 0.22, 0.12), Vector3(0.46, 0.28, 0.26), Color(0.85, 0.15, 0.15), xf)
	# Roadside wooden bench + signboard
	box(Vector3(-0.1, 0.24, -0.55), Vector3(1.3, 0.06, 0.35), WOOD, xf)
	box(Vector3(0.0, 1.25, -0.58), Vector3(1.55, 0.38, 0.06), Color(0.14, 0.38, 0.78), xf)
	sign_text("TYRE PRESSURE & BODA FUNDI", Color(0.14, 0.38, 0.78), xf * Transform3D(Basis.IDENTITY, Vector3(0.0, 1.25, -0.52)), 1.5)
	collide(xf, Vector3(0.1, 0.45, -0.1), Vector3(1.9, 0.9, 1.0))
	var fundi := make_person(false, "casual", false, xf * Vector3(-0.1, 0, 0.55))
	fundi.rotation.y = theta + PI
	add_place("the Boda Mechanic & Tyre Fundi", xf * Vector3(0, 0, 1.25), district_at(p))


func _build_airtime_table(p: Vector3, theta := 0.0) -> void:
	airtime_tables.append(p)
	var xf := Transform3D(Basis(Vector3.UP, theta), p)
	var col: Color = Color(0.95, 0.14, 0.16) if rng.randf() < 0.5 else Color(1.0, 0.80, 0.06)
	# Plastic vendor table + stacks of Bukedde / New Vision newspapers + cold soda icebox
	box(Vector3(0, 0.38, 0), Vector3(1.15, 0.76, 0.72), col, xf)
	box(Vector3(-0.26, 0.80, 0), Vector3(0.36, 0.08, 0.42), PAINT, xf)
	box(Vector3(-0.26, 0.85, 0.05), Vector3(0.32, 0.03, 0.14), Color(0.85, 0.12, 0.12), xf)
	box(Vector3(0.28, 0.94, 0), Vector3(0.42, 0.34, 0.36), Color(0.14, 0.48, 0.88), xf)
	bake_parts(model_umbrella(col, 2.35, 1.35), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, -0.2)))
	collide(xf, Vector3(0, 0.45, 0), Vector3(1.25, 0.9, 0.85))
	_idle_person(xf * Vector3(0, 0, -0.65), theta)
	add_place("the Newspaper & Cold Soda Stand", xf * Vector3(0, 0, 1.15), district_at(p))


func _build_roadside_tv(p: Vector3, theta: float, title: String) -> void:
	tv_stands.append(p)
	var xf := Transform3D(Basis(Vector3.UP, theta), p)
	# Corrugated kibanda TV shelter canopy + steel posts + wooden media cabinet
	for px in [-1.25, 1.25]:
		box(Vector3(px, 1.35, -0.45), Vector3(0.08, 2.7, 0.08), GREY, xf)
	box(Vector3(0, 2.72, 0.05), Vector3(2.8, 0.10, 1.65), ROOFS[3], xf)
	# Satellite dish on top of the canopy (classic Kampala Premier League screening setup!)
	_add("solid", _cyl(0.38, 0.08, 0.14, 10), xf * Transform3D(Basis(Vector3.RIGHT, 0.65), Vector3(0.85, 3.05, -0.2)), Color(0.95, 0.45, 0.12))
	# Media cabinet & speakers
	box(Vector3(0, 0.55, -0.42), Vector3(1.95, 1.1, 0.48), WOOD.darkened(0.2), xf)
	for sx in [-1.12, 1.12]:
		box(Vector3(sx, 1.45, -0.38), Vector3(0.28, 0.65, 0.32), DARK, xf)
	# Large 60-inch flat-screen LED TV bezel
	box(Vector3(0, 1.68, -0.36), Vector3(1.88, 1.12, 0.08), DARK, xf)
	# Illuminated live TV screen mesh (stored so it can flash/cycle live scores & movie nights)
	var scr := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(1.74, 0.98, 0.04)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(0.14, 0.68, 0.28)
	sm.material = smat
	scr.mesh = sm
	scr.transform = xf * Transform3D(Basis.IDENTITY, Vector3(0, 1.68, -0.32))
	scr.visibility_range_end = 95.0
	add_child(scr)
	# Live football pitch centre circle & score ticker Label3D on the TV screen
	var tlab := Label3D.new()
	tlab.text = "LIVE EPL • ARS 2 - 1 MUN  64'\n[  o  ]   KAMPALA SPORTS TV"
	tlab.font_size = 28
	tlab.outline_size = 6
	tlab.pixel_size = 0.0042
	tlab.modulate = Color(1.0, 0.98, 0.85)
	tlab.shaded = false
	tlab.double_sided = false
	tlab.visibility_range_end = 65.0
	tlab.transform = xf * Transform3D(Basis.IDENTITY, Vector3(0, 1.70, -0.28))
	add_child(tlab)
	tv_displays.append({"screen": scr, "mat": smat, "label": tlab, "pos": p})
	# Header sign above canopy
	box(Vector3(0, 2.96, 0.82), Vector3(2.6, 0.38, 0.06), Color(0.10, 0.22, 0.58), xf, "neon_cyan")
	sign_text(title.to_upper(), Color(0.10, 0.22, 0.58), xf * Transform3D(Basis.IDENTITY, Vector3(0, 2.96, 0.87)), 2.5)
	# Wooden spectator bench in front + excited fans watching the screen
	box(Vector3(0, 0.26, 1.05), Vector3(2.1, 0.08, 0.36), WOOD, xf)
	collide(xf, Vector3(0, 1.1, 0.15), Vector3(2.5, 2.2, 1.5))
	_light_pool(xf * Vector3(0, -0.11, 0.85), 7.2, Color(0.22, 0.72, 1.0))
	for fx in [-0.75, 0.0, 0.75]:
		var fan := make_person(rng.randf() < 0.3, "casual", false, xf * Vector3(fx, 0, 1.38))
		fan.rotation.y = theta
	add_place(title, xf * Vector3(0, 0, 2.0), district_at(p))


const BILLBOARD_ADS := [
	{"bg": Color(1.0, 0.78, 0.04), "fg": Color(0.06, 0.06, 0.08), "text": "MTN MoMo • SENT & PAID!\nZero Wahu Across Kampala • *165#"},
	{"bg": Color(0.88, 0.08, 0.12), "fg": Color(1.0, 0.98, 0.95), "text": "AIRTEL 5G SUPA FAST\nStream Live Football & Music Everywhere"},
	{"bg": Color(0.08, 0.42, 0.22), "fg": Color(1.0, 0.92, 0.28), "text": "NAKIVUBO LIVE TONIGHT • 19:00\nUganda Cranes vs Harambee Stars!"},
	{"bg": Color(0.12, 0.20, 0.48), "fg": Color(0.45, 0.95, 1.0), "text": "SAFE BODA KAMPALA\nWear Your Helmet & Reflector Vest!"},
	{"bg": Color(0.92, 0.42, 0.06), "fg": Color(1.0, 0.98, 0.90), "text": "UGANDA ROLEX FESTIVAL\nFresh Chapati, Eggs & Muchomo Daily!"},
	{"bg": Color(0.48, 0.10, 0.52), "fg": Color(1.0, 0.86, 0.25), "text": "KAMPALA NIGHTS • FRIDAY LIVE\nAfrobeats, Kadongo Kamu & Nyama Choma"},
]

const TV_CHANNELS := [
	{"bg": Color(0.14, 0.62, 0.26), "text": "LIVE EPL • ARS 2 - 1 MUN  %d'\n[  o  ]   KAMPALA SPORTS TV"},
	{"bg": Color(0.12, 0.56, 0.24), "text": "NAKIVUBO DERBY • KCCA 2 - 1 VIP  %d'\nGOAL!! Crowd goes wild!"},
	{"bg": Color(0.18, 0.22, 0.52), "text": "VJ JINGO ACTION THEATRE\n'Who Killed Captain Alex?' • Part 2"},
	{"bg": Color(0.55, 0.12, 0.28), "text": "NTV BEAT • NON-STOP UGANDAN HITS\nEddy Kenzo • Azawi • Jose Chameleone"},
]

func _build_billboards() -> void:
	var spots := [
		[Vector3(6.4, 0, 48.0), -0.35],
		[Vector3(-6.4, 0, 12.5), 0.35],
		[Vector3(-6.4, 0, -14.0), -0.25],
		[Vector3(-BLOCK + 6.4, 0, 14.0), 0.3],
		[Vector3(BLOCK - 6.4, 0, -14.0), -0.3],
		[Vector3(6.4, 0, -BLOCK + 14.0), 0.2],
		[Vector3(-6.4, 0, BLOCK - 14.0), -0.2],
		[Vector3(-BLOCK + 6.4, 0, -BLOCK + 14.0), 0.25],
		[Vector3(BLOCK - 6.4, 0, BLOCK - 14.0), -0.25],
	]
	for i in spots.size():
		var sp: Vector3 = spots[i][0]
		var th: float = spots[i][1]
		var xf := Transform3D(Basis(Vector3.UP, th), sp)
		# Heavy steel monopole column & base plinth (street-level height so it's always in view!)
		box(Vector3(0, 0.35, 0), Vector3(0.85, 0.70, 0.85), PAVEMENT.darkened(0.2), xf)
		_add("solid", _cyl(0.20, 0.28, 3.4, 8), xf * Transform3D(Basis.IDENTITY, Vector3(0, 1.8, 0)), DARK)
		collide(xf, Vector3(0, 1.8, 0), Vector3(0.8, 3.6, 0.8))
		# Outer LED billboard cabinet & maintenance catwalk
		box(Vector3(0, 4.45, 0), Vector3(5.6, 2.55, 0.38), DARK, xf)
		box(Vector3(0, 3.10, 0), Vector3(5.8, 0.10, 0.85), GREY, xf)
		# Glowing LED border trim & top floodlights
		box(Vector3(0, 5.76, 0), Vector3(5.7, 0.10, 0.44), Color(0.25, 0.92, 1.0), xf, "neon_cyan" if i % 2 == 0 else "neon_pink")
		box(Vector3(0, 3.16, 0), Vector3(5.7, 0.10, 0.44), Color(0.25, 0.92, 1.0), xf, "neon_cyan" if i % 2 == 0 else "neon_pink")
		for lx in [-1.8, 0.0, 1.8]:
			box(Vector3(lx, 5.92, 0), Vector3(0.38, 0.12, 0.85), Color(1.0, 0.94, 0.78), xf, "lamp")
		# Dynamic double-sided LED screen mesh
		var ad: Dictionary = BILLBOARD_ADS[i % BILLBOARD_ADS.size()]
		var bmesh := BoxMesh.new()
		bmesh.size = Vector3(5.2, 2.25, 0.42)
		var bmat := StandardMaterial3D.new()
		bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bmat.albedo_color = ad["bg"]
		bmesh.material = bmat
		var bmi := MeshInstance3D.new()
		bmi.mesh = bmesh
		bmi.transform = xf * Transform3D(Basis.IDENTITY, Vector3(0, 4.45, 0))
		bmi.visibility_range_end = 185.0
		add_child(bmi)
		var labels := []
		for side in [-1.0, 1.0]:
			var blab := Label3D.new()
			blab.text = str(ad["text"])
			blab.font_size = 38
			blab.outline_size = 6
			blab.pixel_size = 0.0058
			blab.modulate = ad["fg"]
			blab.shaded = false
			blab.double_sided = false
			blab.visibility_range_end = 135.0
			var lrot := Basis.IDENTITY if side > 0 else Basis(Vector3.UP, PI)
			blab.transform = xf * Transform3D(lrot, Vector3(0, 4.45, side * 0.24))
			add_child(blab)
			labels.append(blab)
		billboards.append({"mesh": bmi, "mat": bmat, "labels": labels, "offset": i})
		_light_pool(sp + Vector3(0, 0.06, 0), 9.5, Color(0.35, 0.75, 1.0) if i % 2 == 0 else Color(0.95, 0.45, 0.80))


func _update_screens(delta: float) -> void:
	_screen_timer += delta
	if _screen_timer < 7.5:
		return
	_screen_timer = 0.0
	_ad_index = (_ad_index + 1) % BILLBOARD_ADS.size()
	_match_min = 45 + ((_match_min - 44 + 3) % 45)
	for b in billboards:
		var idx: int = (_ad_index + int(b["offset"])) % BILLBOARD_ADS.size()
		var ad: Dictionary = BILLBOARD_ADS[idx]
		var bmat: StandardMaterial3D = b["mat"]
		bmat.albedo_color = (ad["bg"] as Color) * (1.0 if power_on else 0.15)
		for blab: Label3D in b["labels"]:
			blab.visible = power_on
			blab.text = str(ad["text"])
			blab.modulate = ad["fg"]
	for ti in tv_displays.size():
		var tv: Dictionary = tv_displays[ti]
		var ch: Dictionary = TV_CHANNELS[(_ad_index + ti) % TV_CHANNELS.size()]
		var smat: StandardMaterial3D = tv["mat"]
		var tlab: Label3D = tv["label"]
		smat.albedo_color = (ch["bg"] as Color) * (1.0 if power_on else 0.12)
		tlab.visible = power_on
		var raw: String = str(ch["text"])
		tlab.text = (raw % _match_min) if "%d" in raw else raw


## A soft glowing circle on the ground under a lamp, neon sign, billboard or charcoal stove.
## Cached by colour so it costs minimal draw calls and zero real light calculations.
var _pool_tex: GradientTexture2D
var _pool_mats := {}
func _light_pool(pos: Vector3, size: float, col := Color(0.75, 0.5, 0.22), stays_on_in_cut := false) -> void:
	if _pool_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		_pool_tex = GradientTexture2D.new()
		_pool_tex.gradient = g
		_pool_tex.fill = GradientTexture2D.FILL_RADIAL
		_pool_tex.fill_from = Vector2(0.5, 0.5)
		_pool_tex.fill_to = Vector2(1.0, 0.5)
		_pool_tex.width = 64
		_pool_tex.height = 64
	var key := "%d_%d_%d" % [int(col.r * 100), int(col.g * 100), int(col.b * 100)]
	if not _pool_mats.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = _pool_tex
		m.albedo_color = col
		_pool_mats[key] = m
	var pm := PlaneMesh.new()
	pm.size = Vector2(size, size)
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = _pool_mats[key]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.visible = false
	mi.visibility_range_end = 150.0
	add_child(mi)
	if stays_on_in_cut:
		gen_light_pools.append(mi)
	else:
		light_pools.append(mi)


# =============================================================== people & traffic
func make_agent(parts: Array, pos: Vector3) -> Node3D:
	var b = Baker.new()
	for p in parts:
		b.add(p[0], p[1], p[2])
	var mi := MeshInstance3D.new()
	mi.mesh = b.build()
	mi.material_override = mat_agent
	mi.visibility_range_end = 120.0
	var a: Node3D = Mover.new()
	a.add_child(mi)
	a.body = mi
	a.position = pos
	a.add_to_group("agents")
	add_child(a)
	return a


func _idle_person(pos: Vector3, facing: float) -> Node3D:
	var female := rng.randf() < 0.5
	var a := make_person(female, _person_style(female), false, pos)
	a.rotation.y = facing
	return a


func _walker(pts: PackedVector3Array, speed := -1.0, scale := 1.0) -> Node3D:
	var female := rng.randf() < 0.5
	var a := make_person(female, "school" if scale < 1.0 else _person_style(female), scale == 1.0 and rng.randf() < 0.18, pts[0], scale)
	a.points = pts
	a.mode = 1
	a.speed = speed if speed > 0 else rng.randf_range(1.0, 1.6)
	a.position = pts[0]
	if scale == 1.0 and rng.randf() < 0.55:
		var u := MeshInstance3D.new()
		var b = Baker.new()
		for p in model_umbrella(_pick([DARK, Color(0.15, 0.3, 0.7), Color(0.85, 0.15, 0.2), Color(0.95, 0.75, 0.1)]), 2.1, 0.75):
			b.add(p[0], p[1], p[2])
		u.mesh = b.build()
		u.material_override = mat_agent
		u.position = Vector3(0.25, 0, 0)
		u.visibility_range_end = 120.0
		u.visible = false
		a.body.add_child(u)
		umbrellas.append(u)
	walkers.append(a)
	return a


func _make_rain() -> void:
	rain = CPUParticles3D.new()
	rain.amount = 700
	rain.lifetime = 0.9
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(35, 1, 35)
	rain.direction = Vector3(0.15, -1, 0.05)
	rain.spread = 2.0
	rain.initial_velocity_min = 28.0
	rain.initial_velocity_max = 34.0
	rain.gravity = Vector3(0, -9.8, 0)
	var m := BoxMesh.new()
	m.size = Vector3(0.035, 0.8, 0.035)
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(0.78, 0.84, 0.95, 0.5)
	m.material = rm
	rain.mesh = m
	rain.local_coords = false
	rain.emitting = false
	rain.extra_cull_margin = 60.0
	add_child(rain)


# =============================================================== time, rain, power
func is_rush_hour() -> bool:
	return (time_of_day >= 7.0 and time_of_day <= 9.0) or (time_of_day >= 17.0 and time_of_day <= 20.0)


func _process(delta: float) -> void:
	if not built:
		return
	Person.focus = rig.target
	if horizon_hills and player:
		horizon_hills.position = Vector3(player.position.x, 0.0, minf(player.position.z, 0.0))
	sfx.update_engine(player.on_boda and player.fuel > 0.0, clampf(player.speed / player.BODA_MAX, 0.0, 1.0), delta)
	sfx.update_ambience(raining, night_amount, delta)
	sfx.update_spatial_audio(player.global_position, vehicles, music_spots, delta)
	if mat_water:
		mat_water.uv1_offset.x = fmod(mat_water.uv1_offset.x + delta * 0.018, 1.0)
		mat_water.uv1_offset.z = fmod(mat_water.uv1_offset.z + delta * 0.012, 1.0)
	if mat_road:
		mat_road.roughness = lerpf(mat_road.roughness, 0.24 if raining else 0.76, clampf(delta * 1.4, 0.0, 1.0))
	if mat_murram:
		mat_murram.roughness = lerpf(mat_murram.roughness, 0.36 if raining else 0.90, clampf(delta * 1.4, 0.0, 1.0))
	_police_cooldown = maxf(0.0, _police_cooldown - delta)
	_hustle_cooldown = maxf(0.0, _hustle_cooldown - delta)
	_roadwork_warn_cd = maxf(0.0, _roadwork_warn_cd - delta)
	_wash_cooldown = maxf(0.0, _wash_cooldown - delta)
	if not paused and player.on_boda and player.speed > 11.5 and _roadwork_warn_cd <= 0.0 and in_roadwork(player.position):
		_roadwork_warn_cd = 8.0
		sfx.play("whistle", -8.0, 0.95)
		if hud:
			hud.toast("🚧 ROAD WORKS AHEAD! Drive slowly past the KCCA repair crew.")
	if not paused and player:
		if not unlocked_achievements.has("mud_warrior") and in_mud_road(player.position):
			unlock_achievement("mud_warrior")
		if not unlocked_achievements.has("highway_explorer") and (absf(player.position.x) > HALF + 14.0 or player.position.z < -HALF - 14.0):
			unlock_achievement("highway_explorer")
		if not unlocked_achievements.has("lake_swimmer") and player.is_swimming:
			unlock_achievement("lake_swimmer")
	if tutorial_step == 0 and player.on_boda:
		tutorial_step = 1
	if not paused:
		var before := time_of_day
		var was_rush := is_rush_hour()
		time_of_day = fmod(time_of_day + delta * time_speed / 30.0, 24.0)
		if not was_rush and is_rush_hour() and hud:
			hud.toast("Kampala Rush Hour! Traffic is heavy, but fares pay +25%!")
		if before < DAY_END and time_of_day >= DAY_END:
			end_day()
		if player.on_boda and _police_cooldown <= 0.0:
			_check_police_stop()
		_update_screens(delta)
		_update_street_event(delta)
		_update_encounter(delta)
		_update_street_voices(delta)
		if pitch_ball:
			_pitch_t += delta
			var bx := sin(_pitch_t * 1.35) * 6.8 + cos(_pitch_t * 2.9) * 1.4
			var bz := cos(_pitch_t * 1.05) * 4.2
			var bounce := absf(sin(_pitch_t * 5.2)) * 0.65
			pitch_ball.position = pitch_center + Vector3(bx, 0.18 + bounce, bz)
		for si in lake_swimmers.size():
			var sw := lake_swimmers[si]
			if is_instance_valid(sw):
				var st := Time.get_ticks_msec() * 0.001 + si * 2.1
				sw.position.y = -0.35 + sin(st * 3.4) * 0.08
				sw.rotation.y = sin(st * 0.6) * 0.8
				if sw.body and sw.body.has_method("animate_swim"):
					sw.body.animate_swim(delta, true)
	_apply_time()
	if rig:
		rain.global_position = rig.target + Vector3(0, 24, 0)
	if _shot_frames > 0:
		_shot_frames -= 1
		if _shot_frames == 0:
			get_viewport().get_texture().get_image().save_png(_shot_path)
			print("saved ", _shot_path)
			get_tree().quit()


func _check_police_stop() -> void:
	for cp in checkpoints:
		if Vector2(player.position.x - cp.x, player.position.z - cp.z).length() < 6.0:
			if has_helmet and has_vest and has_permit:
				_police_cooldown = 18.0
				sfx.play("pop", -4.0, 1.2)
				hud.toast("Traffic Police Checkpoint: \"Helmet, reflector, permit — all smart! Safe journey, boss!\"")
				return
			var missing := PackedStringArray()
			if not has_helmet: missing.append("crash helmet")
			if not has_vest: missing.append("reflector vest")
			if not has_permit: missing.append("riding permit")
			_police_cooldown = 28.0
			player.speed = 0.0
			paused = true
			sfx.play("whistle", -1.0, 1.0)
			hud.show_police(", ".join(missing))
			return


func resolve_police(choice: int) -> void:
	paused = false
	hud.hide_police()
	match choice:
		0: # Official Express Receipt Fine (UGX 10,000)
			add_money(-10000, "Police Express Penalty receipt")
			day_stats["crashes"] += 10000
			sfx.play("chime", -4.0, 0.8)
			hud.toast("Paid UGX 10,000 Express Penalty receipt. Buy your gear at the Boda Stage to avoid stops!")
		1: # Settle on the spot ("kassente" / tea - UGX 5,000)
			add_money(-5000, "Checkpoint roadside settlement")
			day_stats["crashes"] += 5000
			sfx.play("pop", -2.0, 0.9)
			hud.toast("Officer took UGX 5,000 for \"soda\" and waved you through: \"Twende, go quickly!\"")
		2: # Talk your way out / Apologize
			if randf() < 0.55:
				sfx.play("pop", -2.0, 1.15)
				hud.toast("\"Okay, warning only today! Next time I impound the bike!\" — You got lucky!")
			else:
				add_money(-12000, "Police strict penalty fine")
				day_stats["crashes"] += 12000
				sfx.play("crash", -4.0, 1.2)
				hud.toast("\"No excuses today!\" — The officer wrote a strict UGX 12,000 penalty.")
	save_game()


func _apply_time() -> void:
	var t := time_of_day
	var day := sin((t - 6.0) / 12.0 * PI)          # 1 at noon, 0 at 6am/6pm, below 0 at night
	var light := smoothstep(-0.12, 0.3, day)        # 0 night .. 1 day
	var golden := clampf(1.0 - absf(day) * 3.5, 0.0, 1.0) if day > -0.1 else 0.0
	var night := 1.0 - smoothstep(-0.15, 0.12, day)
	night_amount = night

	if day > -0.05:
		var arc := clampf((t - 6.0) / 12.0, 0.0, 1.0)
		sun.rotation = Vector3(-deg_to_rad(lerpf(14.0, 58.0, maxf(day, 0.0))), lerpf(PI * 0.42, -PI * 0.42, arc), 0)
		sun.light_color = Color(1.0, 0.93, 0.78).lerp(Color(1.0, 0.68, 0.36), golden)
	else:  # moonlight
		sun.rotation = Vector3(deg_to_rad(-55.0), 0.7, 0)
		sun.light_color = Color(0.58, 0.70, 1.0)
	sun.light_energy = lerpf(0.24, 1.48, light) * (0.55 if raining else 1.0)

	var top := Color(0.05, 0.07, 0.16).lerp(Color(0.28, 0.62, 0.94), light)
	var hor := Color(0.12, 0.14, 0.24).lerp(Color(1.0, 0.88, 0.68), light).lerp(Color(1.0, 0.66, 0.36), golden * 0.75)
	if raining:
		var grey := Color(0.48, 0.52, 0.58) * maxf(light, 0.35)
		top = top.lerp(grey, 0.80)
		hor = hor.lerp(grey, 0.70)
	sky_mat.sky_top_color = top
	sky_mat.sky_horizon_color = hor
	sky_mat.ground_horizon_color = hor
	sky_mat.ground_bottom_color = hor.darkened(0.42)
	env.fog_light_color = hor
	var cam_d: float = rig.dist if rig else 20.0
	env.fog_depth_begin = cam_d + (18.0 if raining else 58.0)
	env.fog_depth_end = cam_d + (140.0 if raining else 380.0)
	env.fog_density = 0.65 if raining else 0.40
	# shadows only in clear daylight (they cost a lot on phones)
	sun.shadow_enabled = light > 0.30 and not raining
	env.ambient_light_color = top.lerp(hor, 0.72)
	env.ambient_light_energy = lerpf(0.48, 0.90, light)

	mat_window.emission_energy_multiplier = night * 0.52 if power_on else 0.0
	mat_window_gen.emission_energy_multiplier = night * 0.85
	mat_lamp.emission_energy_multiplier = night * 2.2 if power_on else 0.0
	mat_neon_pink.emission_energy_multiplier = (0.25 + night * 1.55) if power_on else 0.0
	mat_neon_cyan.emission_energy_multiplier = (0.25 + night * 1.55) if power_on else 0.0
	mat_ember.emission_energy_multiplier = 0.65 + night * 1.65
	mat_tv_screen.emission_energy_multiplier = (0.45 + night * 1.25) if power_on else 0.0
	var lights_on := power_on and night > 0.30
	for l in light_pools:
		l.visible = lights_on
	var gen_on := night > 0.28
	for gl in gen_light_pools:
		gl.visible = gen_on


func toggle_rain() -> bool:
	raining = not raining
	rain.emitting = raining
	for u in umbrellas:
		u.visible = raining
	for w in walkers:
		w.speed_mul = 1.7 if raining else 1.0   # everyone hurries when it pours
	mat_road.roughness = 0.2 if raining else 0.92
	mat_road.metallic_specular = 0.9 if raining else 0.4
	mat_road.albedo_color = Color(0.7, 0.7, 0.76) if raining else Color.WHITE
	if hud:
		hud.toast("It's raining! Roads are slippery, but new fares pay 1.5x" if raining else "The rain has stopped")
	_apply_time()
	return raining


func toggle_power() -> bool:
	power_on = not power_on
	_apply_time()
	return power_on


func skip_hours(h: float) -> void:
	time_of_day = fmod(time_of_day + h, 24.0)
	_apply_time()


func cycle_speed() -> int:
	match time_speed:
		1: time_speed = 4
		4: time_speed = 12
		12: time_speed = 0
		_: time_speed = 1
	return time_speed


## Used for testing on a computer, e.g.
## godot --path . -- --time=19 --rain --shot=/tmp/street.png
func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot_path = a.substr(7)
			_shot_frames = 90
			time_speed = 0
		elif a.begins_with("--time="):
			time_of_day = a.substr(7).to_float()
		elif a == "--rain":
			toggle_rain()
		elif a == "--ride":
			player.hop_on()
		elif a.begins_with("--player="):
			var pxz := a.substr(9).split(",")
			player.position = Vector3(pxz[0].to_float(), 0.2, pxz[1].to_float())
			player.parked_boda.position = player.position + Vector3(1.5, -0.16, 0)
			rig.target = Vector3(player.position.x, 0, player.position.z)
		elif a.begins_with("--fuel="):
			player.fuel = a.substr(7).to_float() * player.TANK_LITRES
		elif a.begins_with("--money="):
			money = a.substr(8).to_int()
		elif a.begins_with("--hour="):
			time_of_day = a.substr(7).to_float()
		elif a == "--map":
			hud.bigmap.visible = true
			hud.map_filter = "repair"
			hud._refresh_map_finder()
		elif a == "--route-fuel":
			route_to_nearest_pump(false)
		elif a == "--phone":
			hud.toggle_phone()
		elif a.begins_with("--tab="):
			hud.phone_tab = a.substr(6).to_int()
			hud._refresh_phone()
		elif a == "--urgent":
			jobs.new_job("urgent")
			if hud.phone_panel.visible:
				hud._refresh_phone()
		elif a == "--fragile":
			jobs.new_job("fragile")
			if hud.phone_panel.visible:
				hud._refresh_phone()
		elif a == "--vip":
			jobs.new_job("vip_tour")
			if hud.phone_panel.visible:
				hud._refresh_phone()
		elif a.begins_with("--paint="):
			bike_paint = a.substr(8).to_int() % BIKE_PAINTS.size()
			apply_bike_paint()
		elif a == "--event":
			_spawn_street_event()
		elif a == "--alerts":
			hud.toggle_messages_drawer()
		elif a == "--broken":
			player.bike_health = 0.0
			if player.on_boda:
				player.get_off()
			jobs.pause_dispatch("🔧 Boda broken down! Repair at Boda Fundi or Phone → Garage, or take a 🚶 Foot Errand.")
		elif a == "--skip-job":
			jobs.reject_job()
		elif a == "--encounter":
			tutorial_step = 4
			_encounter_t = 0.01
			_update_encounter(0.1)
		elif a == "--fuel-menu":
			hud.open_fuel_menu()
		elif a == "--settings":
			hud.open_settings()
		elif a == "--confrontation":
			trigger_accident_confrontation("taxi", 8000)
		elif a == "--title":
			hud.show_title_screen()
		elif a == "--min-job":
			hud.job_minimized = true
			hud.job_min_btn.text = "+"
		elif a == "--no-tut":
			tutorial_step = 4
		elif a.begins_with("--teleport="):
			var tp_parts := a.substr(11).split(",")
			if tp_parts.size() >= 2:
				var tpos := Vector3(tp_parts[0].to_float(), 0.0, tp_parts[1].to_float())
				player.position = tpos
				if not player.on_boda and player.parked_boda:
					player.parked_boda.position = tpos + Vector3(0.2, 0, -2.6)
				if absf(tpos.x) > absf(tpos.z) and tpos.x > HALF:
					player.heading = -PI * 0.5
					rig.yaw = -PI * 0.5
				elif absf(tpos.x) > absf(tpos.z) and tpos.x < -HALF:
					player.heading = PI * 0.5
					rig.yaw = PI * 0.5
				if player.boda_body:
					player.boda_body.rotation.y = player.heading
				if horizon_hills:
					horizon_hills.position = Vector3(tpos.x, 0.0, minf(tpos.z, 0.0))
				if endless_world and endless_world.has_method("force_sync"):
					endless_world.force_sync()
				rig.target = tpos + Vector3(0, 2.05, 0)
		elif a == "--power-off":
			toggle_power()
		elif a.begins_with("--dist="):
			rig.dist = a.substr(7).to_float()
			rig.base_dist = rig.dist
		elif a.begins_with("--yaw="):
			rig.yaw = deg_to_rad(a.substr(6).to_float())
		elif a.begins_with("--pitch="):
			rig.pitch = deg_to_rad(a.substr(8).to_float())
		elif a.begins_with("--target="):
			var xz := a.substr(9).split(",")
			rig.target = Vector3(xz[0].to_float(), 0, xz[1].to_float())
	rig._update()


# =============================================================== player & money
func _spawn_player(pos: Vector3) -> void:
	player = Player.new()
	player.main = self
	add_child(player)
	player.position = pos

	# the player: built cleanly once via apply_bike_paint() below
	var walk: Node3D = Person.new()
	walk.scale = Vector3.ONE * PERSON_SCALE
	player.add_child(walk)
	player.walk_body = walk

	var ride := MeshInstance3D.new()
	player.add_child(ride)
	player.boda_body = ride
	ride.scale = Vector3.ONE * 1.18
	ride.material_override = mat_agent
	ride.visible = false

	var pas := MeshInstance3D.new()
	pas.mesh = _agent_mesh(_seated(0.62, _pick(CLOTHES), false))
	pas.scale = Vector3.ONE * 1.18
	pas.material_override = mat_agent
	pas.visible = false
	player.add_child(pas)
	player.passenger_body = pas

	# cargo package shown on the carrier rack when delivering parcels/rolex/matooke/jerrycans
	var cargo := MeshInstance3D.new()
	var cparts := [
		part(_box_mesh(Vector3(0.42, 0.34, 0.38)), Vector3(0, 1.15, 0.72), Color(0.96, 0.80, 0.14)),
		part(_box_mesh(Vector3(0.44, 0.04, 0.40)), Vector3(0, 1.15, 0.72), DARK),
		part(_sphere(0.18, 0.28, 7, 3), Vector3(0, 1.38, 0.72), Color(0.28, 0.56, 0.20)),
	]
	cargo.mesh = _agent_mesh(cparts)
	cargo.scale = Vector3.ONE * 1.18
	cargo.material_override = mat_agent
	cargo.visible = false
	player.add_child(cargo)
	player.cargo_body = cargo

	# forward headlight glow cone on the road at night
	var beam := MeshInstance3D.new()
	var bm := PrismMesh.new()
	bm.size = Vector3(4.2, 8.5, 0.03)
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color = Color(1.0, 0.92, 0.65, 0.22)
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.material = bmat
	beam.mesh = bm
	beam.transform = Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0, 0.06, -5.0))
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.visible = false
	player.add_child(beam)
	player.headlight_beam = beam

	var parked := MeshInstance3D.new()
	parked.scale = Vector3.ONE * 1.18
	parked.material_override = mat_agent
	parked.position = pos + Vector3(0.2, 0, -2.6)
	parked.rotation.y = 0.0   # facing north up Entebbe Road toward Old Kampala Hill & golden sky
	add_child(parked)
	player.parked_boda = parked
	player.heading = 0.0
	_attach_contact_shadow(player, 1.15, 2.35)
	_attach_contact_shadow(parked, 1.05, 2.15)
	apply_bike_paint()

	rig.follow = player
	rig.target = Vector3(pos.x, pos.y + 2.05, pos.z)
	rig.yaw = deg_to_rad(0.0)
	rig.view_index = 0
	rig.dist = 9.0
	rig.base_dist = 9.0
	rig.pitch = deg_to_rad(-13.5)
	rig.base_pitch = deg_to_rad(-13.5)
	rig.base_fov = 50.0
	rig._update()


func _agent_mesh(parts: Array) -> ArrayMesh:
	var b = Baker.new()
	for p in parts:
		b.add(p[0], p[1], p[2])
	return b.build()


func near_boda_stage() -> bool:
	return Vector2(player.position.x - 5.25, player.position.z - 13.0).length() < 5.5


func near_rolex_stand() -> bool:
	for p in rolex_stands:
		if Vector2(player.position.x - p.x, player.position.z - p.z).length() < 3.6:
			return true
	return false


func near_momo_kiosk() -> bool:
	for p in momo_kiosks:
		if Vector2(player.position.x - p.x, player.position.z - p.z).length() < 3.6:
			return true
	return false


func near_muchomo_stand() -> bool:
	for p in muchomo_stands:
		if Vector2(player.position.x - p.x, player.position.z - p.z).length() < 3.6:
			return true
	return false


func near_fruit_cart() -> bool:
	for p in fruit_carts:
		if Vector2(player.position.x - p.x, player.position.z - p.z).length() < 3.6:
			return true
	return false


func near_boda_fundi() -> bool:
	for p in boda_fundis:
		if Vector2(player.position.x - p.x, player.position.z - p.z).length() < 4.2:
			return true
	for pl in places:
		var nl := str(pl.get("name", "")).to_lower()
		if "fundi" in nl or "mechanic" in nl or "garage" in nl or "spare" in nl:
			var p2: Vector3 = pl["pos"]
			if Vector2(player.position.x - p2.x, player.position.z - p2.z).length() < 5.2:
				return true
	return false


func near_airtime_table() -> bool:
	for p in airtime_tables:
		if Vector2(player.position.x - p.x, player.position.z - p.z).length() < 3.4:
			return true
	return false


func near_tv_stand() -> bool:
	for p in tv_stands:
		if Vector2(player.position.x - p.x, player.position.z - p.z).length() < 4.2:
			return true
	return false


func near_market_stall() -> bool:
	for p in market_centres:
		if Vector2(player.position.x - p.x, player.position.z - p.z).length() < 11.5:
			return true
	return false


func near_taxi_park() -> bool:
	for p in taxi_parks:
		if Vector2(player.position.x - p.x, player.position.z - p.z).length() < 13.5:
			return true
	return false


func near_wash_bay() -> bool:
	for p in wash_bays:
		if Vector2(player.position.x - p.x, player.position.z - p.z).length() < 5.6:
			return true
	return false


func in_roadwork(pos: Vector3) -> bool:
	for rz in roadwork_zones:
		var p: Vector3 = rz["pos"]
		var r: float = float(rz["radius"])
		if Vector2(pos.x - p.x, pos.z - p.z).length() <= r:
			return true
	return false


func next_gear_info() -> Dictionary:
	if not has_helmet:
		return {"key": "helmet", "name": "Crash Helmet", "cost": 15000}
	if not has_vest:
		return {"key": "vest", "name": "Reflector Vest", "cost": 10000}
	if not has_permit:
		return {"key": "permit", "name": "Riding Permit", "cost": 25000}
	if not has_rain_jacket:
		return {"key": "jacket", "name": "Rain Jacket", "cost": 20000}
	if not has_big_tank:
		return {"key": "tank", "name": "6.5L Fuel Tank", "cost": 35000}
	if bike_level < 1:
		return {"key": "engine", "name": "Boxer 150cc Engine", "cost": 60000}
	return {}


func daily_passive_income() -> int:
	var inc := hired_riders * HIRED_REMIT
	if owns_rolex_stand: inc += 6000
	if owns_kibanda_tv: inc += 10000
	if owns_momo_kiosk: inc += 14000
	if owns_matatu: inc += 35000
	return inc


func player_rank() -> String:
	var biz_count := int(owns_rolex_stand) + int(owns_kibanda_tv) + int(owns_momo_kiosk) + int(owns_matatu)
	if owns_boda and (owns_matatu or biz_count >= 3 or hired_riders >= 3):
		return "Kampala Tycoon"
	if owns_boda and (hired_riders >= 1 or biz_count >= 1):
		return "Stage Chairman"
	if owns_boda or biz_count >= 2 or hired_riders >= 1:
		return "Boda Boss"
	if (has_helmet and has_vest and has_permit) or biz_count >= 1:
		return "Smart Hustler"
	return "Stage Rider"


func bike_paint_name() -> String:
	return str(BIKE_PAINTS[bike_paint % BIKE_PAINTS.size()][0])


func rider_outfit_name() -> String:
	return str(RIDER_OUTFITS[rider_outfit % RIDER_OUTFITS.size()][0])


func home_stage_name() -> String:
	return str(KAMPALA_STAGES[home_stage % KAMPALA_STAGES.size()])


func apply_bike_paint() -> void:
	if player == null:
		return
	var pcol: Color = BIKE_PAINTS[bike_paint % BIKE_PAINTS.size()][1]
	var out: Array = RIDER_OUTFITS[rider_outfit % RIDER_OUTFITS.size()]
	var top_col: Color = Color(0.98, 0.88, 0.10) if has_vest else (out[1] as Color)
	var bot_col: Color = out[2] as Color
	var pskin: Color = SKINS[1]
	var helm_col: Color = Color(0.98, 0.74, 0.12) if bike_paint == 0 else pcol.lightened(0.10)
	if player.boda_body:
		var rparts := model_boda(false, false, pcol)
		# Always render the iconic open-face Kampala boda helmet + high-vis reflector vest over dark T-shirt!
		rparts.append_array(_seated(0.10, top_col, true, pskin, bot_col, helm_col, rider_female, true))
		player.boda_body.mesh = _agent_mesh(rparts)
	if player.parked_boda:
		player.parked_boda.mesh = _agent_mesh(model_boda(false, false, pcol))
	if player.walk_body and player.walk_body.has_method("build"):
		player.walk_body.build(model_human(rider_female, "casual", false, top_col, bot_col, pskin, Color(0.16, 0.14, 0.14), true), mat_agent)


func set_customization(new_name: String, stage_idx: int, paint_idx: int, outfit_idx: int, is_female := false) -> void:
	var clean := new_name.strip_edges()
	if clean != "":
		rider_name = clean.substr(0, 18)
	home_stage = posmod(stage_idx, KAMPALA_STAGES.size())
	bike_paint = posmod(paint_idx, BIKE_PAINTS.size())
	rider_outfit = posmod(outfit_idx, RIDER_OUTFITS.size())
	rider_female = is_female
	apply_bike_paint()
	save_game()


func cycle_bike_paint() -> void:
	var cost := 0 if bike_level >= 1 or owns_boda else 5000
	if cost > 0 and money < cost:
		hud.toast("Need UGX 5,000 for Katwe custom spray-paint (Free once you own Boxer 150cc or Boda Title!).")
		return
	if cost > 0:
		add_money(-cost, "Katwe custom boda paint")
	bike_paint = (bike_paint + 1) % BIKE_PAINTS.size()
	apply_bike_paint()
	sfx.play("pop", 0.0, 1.15)
	hud.toast("🎨 Katwe Custom Paint applied: %s!" % bike_paint_name())
	save_game()


func buy_upgrade(key: String) -> bool:
	var catalog := {
		"repair": {"name": "Boda Engine Repair (100%)", "cost": 4000, "owned": player.bike_health >= 99.0},
		"helmet": {"name": "Crash Helmet", "cost": 15000, "owned": has_helmet},
		"vest": {"name": "Reflector Vest", "cost": 10000, "owned": has_vest},
		"permit": {"name": "Riding Permit", "cost": 25000, "owned": has_permit},
		"jacket": {"name": "Waterproof Rain Jacket", "cost": 20000, "owned": has_rain_jacket},
		"tank": {"name": "6.5L Long-Range Tank", "cost": 35000, "owned": has_big_tank},
		"engine": {"name": "Bajaj Boxer 150cc HD", "cost": 60000, "owned": bike_level >= 1},
		"rolex_biz": {"name": "Own Corner Rolex Stand (+6k/day)", "cost": 45000, "owned": owns_rolex_stand},
		"tv_biz": {"name": "Own Kibanda Live TV Cinema (+10k/day)", "cost": 75000, "owned": owns_kibanda_tv},
		"momo_biz": {"name": "Own Mobile Money Kiosk (+14k/day)", "cost": 110000, "owned": owns_momo_kiosk},
		"hire_rider": {"name": "Hire Stage Rider & Bike (+15k/day)", "cost": 120000, "owned": hired_riders >= 5},
		"matatu_biz": {"name": "Own 14-Seater Matatu Taxi (+35k/day)", "cost": 350000, "owned": owns_matatu},
		"own_boda": {"name": "Full Boda Ownership Title (0 Rent!)", "cost": GOAL, "owned": owns_boda},
	}
	if not catalog.has(key):
		return false
	var item: Dictionary = catalog[key]
	if bool(item["owned"]):
		hud.toast("You already own %s!" % item["name"])
		return false
	var cost: int = int(item["cost"])
	if money < cost:
		hud.toast("Need UGX %s on Mobile Money for %s." % [ugx(cost), item["name"]])
		return false
	add_money(-cost, "Bought %s" % item["name"])
	match key:
		"repair":
			player.repair_bike()
		"helmet":
			has_helmet = true
			apply_bike_paint()
		"vest":
			has_vest = true
			apply_bike_paint()
		"permit": has_permit = true
		"jacket": has_rain_jacket = true
		"tank":
			has_big_tank = true
			player.fuel = player.max_tank()
		"engine": bike_level = 1
		"rolex_biz":
			owns_rolex_stand = true
			add_sms("Rolex Chef", "Boss! Your Rolex Stand is open. I'll send UGX 6,000 profit every evening, and your shifts pay 2x!")
		"tv_biz":
			owns_kibanda_tv = true
			add_sms("Kibanda Manager", "Match & VJ tickets are booming! Sending UGX 10,000 every evening on Mobile Money!")
		"momo_biz":
			owns_momo_kiosk = true
			add_sms("MoMo Attendant", "Your Mobile Money kiosk is active! Expect UGX 14,000 agent commission every evening!")
		"matatu_biz":
			owns_matatu = true
			add_sms("Taxi Driver", "Boss, the new 14-seater Matatu is on the Kampala-Ntinda route! Sending UGX 35,000 daily remit!")
		"own_boda":
			owns_boda = true
			add_sms("Boda Boss", "Congratulations! You paid off UGX 500,000. The logbook is yours — no more daily rent!")
			unlock_achievement("boda_boss")
		"hire_rider":
			hired_riders += 1
			add_sms("Rider #%d" % hired_riders, "Boss, thanks for the bike! I'll send UGX %s every evening on Mobile Money." % ugx(HIRED_REMIT))
	sfx.play("bonus")
	hud.toast("Purchased %s for UGX %s!  •  Rank: %s" % [item["name"], ugx(cost), player_rank()])
	save_game()
	return true


func action_label() -> String:
	if paused:
		return ""
	if (player.on_boda or player.near_parked_boda()) and player.speed < 3.0 and near_boda_fundi() and player.bike_health < 98.0:
		return "Repair Boda (UGX 4,000)"
	if (player.on_boda or player.near_parked_boda()) and player.speed < 3.0 and near_pump() and player.fuel_fraction() < 0.97:
		return "Buy fuel  (UGX %s/L)" % ugx(FUEL_PRICE)
	if (player.on_boda or player.near_parked_boda()) and player.speed < 3.0 and near_wash_bay() and _wash_cooldown <= 0.0:
		return "Wash Boda (UGX 2,000)"
	if player.on_boda:
		if player.speed < 3.0 and near_boda_stage():
			var g := next_gear_info()
			if not g.is_empty():
				return "Buy %s (UGX %s)" % [g["name"], ugx(g["cost"])]
		if player.is_pushing_boda():
			return "Park boda" if player.speed < 3.0 else ""
		return "Get off" if player.speed < 3.0 else ""
	if near_boda_stage() and not player.near_parked_boda():
		var g2 := next_gear_info()
		if not g2.is_empty():
			return "Buy %s (UGX %s)" % [g2["name"], ugx(g2["cost"])]
	if _hustle_cooldown <= 0.0:
		if near_rolex_stand():
			return "Fry Rolex (+UGX 3,500)"
		if near_muchomo_stand():
			return "Roast Muchomo (+UGX 4,000)"
		if near_momo_kiosk():
			return "Serve MoMo (+UGX 4,000)"
		if near_fruit_cart():
			return "Press Cane Juice (+UGX 3,000)"
		if near_boda_fundi():
			return "Fix Boda Tyre (+UGX 4,500)"
		if near_airtime_table():
			return "Sell Airtime & Papers (+UGX 3,500)"
		if near_tv_stand():
			return "Collect Kibanda TV Fee (+UGX 3,500)"
		if not player.near_parked_boda():
			if near_market_stall():
				return "Sell Produce (+UGX 4,000)"
			if near_taxi_park():
				return "Load Matatu (+UGX 4,500)"
	if player.near_parked_boda():
		if player.is_broken():
			return "Push boda (Broken!)"
		return "Roll boda (No Fuel)" if player.fuel <= 0.0 else "Ride boda"
	return ""


func player_action() -> void:
	if paused:
		return
	if (player.on_boda or player.near_parked_boda()) and player.speed < 3.0 and near_boda_fundi() and player.bike_health < 98.0:
		buy_upgrade("repair")
		return
	if (player.on_boda or player.near_parked_boda()) and player.speed < 3.0 and near_pump() and player.fuel_fraction() < 0.97:
		if money < 500:
			hud.toast("You need at least UGX 500 on Mobile Money to buy fuel.")
			return
		hud.open_fuel_menu()
		return
	if (player.on_boda or player.near_parked_boda()) and player.speed < 3.0 and near_wash_bay() and _wash_cooldown <= 0.0:
		_wash_boda()
		return
	if ((player.on_boda and player.speed < 3.0) or not player.near_parked_boda()) and near_boda_stage():
		var g := next_gear_info()
		if not g.is_empty():
			buy_upgrade(str(g["key"]))
			return
	if not player.on_boda and _hustle_cooldown <= 0.0 and (near_rolex_stand() or near_muchomo_stand() or near_momo_kiosk() or near_fruit_cart() or near_boda_fundi() or near_airtime_table() or near_tv_stand() or not player.near_parked_boda()):
		if _try_side_hustle():
			return
	if player.on_boda:
		if player.speed < 3.0:
			player.get_off()
	elif player.near_parked_boda():
		player.hop_on()
	elif _hustle_cooldown <= 0.0:
		_try_side_hustle()


func _wash_boda() -> void:
	if money < 2000:
		hud.toast("Washing bay costs UGX 2,000! Earn a fare or hustle first.")
		return
	_wash_cooldown = 45.0
	add_money(-2000, "Boda & Car Wash Bay")
	if life:
		life.mood = minf(100.0, life.mood + 16.0)
		life.energy = minf(100.0, life.energy + 4.0)
	if jobs:
		jobs.rating = minf(5.0, jobs.rating + 0.04)
	sfx.play("bonus", -4.0, 1.08)
	hud.toast("🫧 Boda washed sparkling clean at the Washing Bay!\n-UGX 2,000 • +16 Mood • +0.04 ★ Rating")
	unlock_achievement("clean_boda")
	save_game()


func buy_fuel_amount(budget_ugx := -1) -> void:
	if player == null:
		return
	if money < 500:
		hud.toast("Not enough Mobile Money! Earn a fare or side hustle first.")
		return
	if budget_ugx > 0 and money < budget_ugx:
		hud.toast("Need UGX %s on Mobile Money (you have UGX %s)." % [ugx(budget_ugx), ugx(money)])
		return
	var cost: int = player.refuel(FUEL_PRICE, budget_ugx)
	if cost <= 0:
		hud.toast("Your tank is already full!")
		return
	add_money(-cost, "Fuel refill at petrol station")
	day_stats["fuel"] += cost
	sfx.play("fuel")
	hud.toast("⛽ Paid UGX %s for fuel by MoMo!\nTank: %d%% — ready to ride!" % [ugx(cost), int(player.fuel_fraction() * 100)])
	save_game()


func _try_side_hustle() -> bool:
	var pay := 0
	var title := ""
	var msg := ""
	if near_rolex_stand():
		pay = 7000 if owns_rolex_stand else 3500
		title = "Rolex Stand shift"
		msg = "Fried chapati & 2-egg Ugandan rolex on the sigiri! Earned UGX %s%s." % [ugx(pay), " (2x Owner Bonus!)" if owns_rolex_stand else ""]
	elif near_muchomo_stand():
		pay = 4000
		title = "Muchomo Grill shift"
		msg = "Roasted sizzling beef skewers & golden gonja on the charcoal grill! Earned UGX 4,000."
	elif near_momo_kiosk():
		pay = 8000 if owns_momo_kiosk else 4000
		title = "MoMo Agent commission"
		msg = "Processed Mobile Money cash-in & airtime for customers! Earned UGX %s%s." % [ugx(pay), " (2x Owner Bonus!)" if owns_momo_kiosk else ""]
	elif near_fruit_cart():
		pay = 3000
		title = "Fruit Cart sales"
		msg = "Pressed cold sugarcane-ginger juice & sliced watermelon for passers-by! Earned UGX 3,000."
	elif near_boda_fundi():
		pay = 4500
		title = "Boda Mechanic fundi job"
		msg = "Patched a puncture, oiled the chain & pumped boda tyres! Earned UGX 4,500."
	elif near_airtime_table():
		pay = 3500
		title = "Newspaper & Airtime sales"
		msg = "Sold Bukedde newspapers, scratch airtime & cold sodas! Earned UGX 3,500."
	elif near_tv_stand():
		pay = 7000 if owns_kibanda_tv else 3500
		title = "Kibanda TV match entry"
		msg = "Tuned the satellite dish & collected Premier League screening fees! Earned UGX %s%s." % [ugx(pay), " (2x Owner Bonus!)" if owns_kibanda_tv else ""]
	elif near_market_stall():
		pay = 4000
		title = "Owino Market vendor sales"
		msg = "Sold bunches of matooke & fresh tomatoes at Owino Market! Earned UGX 4,000."
	elif near_taxi_park():
		pay = 4500
		title = "Taxi Park conductor fee"
		msg = "Called passengers & loaded a matatu at Old Taxi Park! Earned UGX 4,500."
	if pay > 0:
		_hustle_cooldown = 4.5
		time_of_day = minf(DAY_END - 0.1, time_of_day + 0.3)
		add_money(pay, title)
		day_stats["fares"] += pay
		day_stats["jobs"] += 1
		day_stats["hustles"] = int(day_stats.get("hustles", 0)) + 1
		adjust_rating(0.02)
		sfx.play("chime")
		hud.toast(msg)
		_check_daily_goals()
		save_game()
		return true
	return false


func on_job_completed(_kind: String, _total_paid: int, _streak: int) -> void:
	day_stats["boda_trips"] = int(day_stats.get("boda_trips", 0)) + 1
	_check_daily_goals()


func _check_daily_goals() -> void:
	# 3 Daily Hustle Challenges that award instant Mobile Money bonuses!
	if int(day_stats.get("boda_trips", 0)) >= 3 and int(day_stats.get("goal_trips", 0)) == 0:
		day_stats["goal_trips"] = 1
		add_money(8000, "Daily Goal Bonus: 3 Boda Trips")
		day_stats["tips"] += 8000
		sfx.play("bonus")
		add_sms("Stage Chairman", "Daily Goal Complete (3 Boda Trips)! Sent UGX 8,000 Stage Bonus to your Mobile Money!")
		hud.toast("🏆 DAILY GOAL COMPLETE: 3 Boda Trips! +UGX 8,000 Bonus on Mobile Money!")
	elif int(day_stats.get("hustles", 0)) >= 2 and int(day_stats.get("goal_hustles", 0)) == 0:
		day_stats["goal_hustles"] = 1
		add_money(7000, "Daily Goal Bonus: 2 Street Hustles")
		day_stats["tips"] += 7000
		sfx.play("bonus")
		add_sms("Kikuubo Traders", "Daily Goal Complete (2 Roadside Shifts)! Sent UGX 7,000 Hustler Bonus!")
		hud.toast("🏆 DAILY GOAL COMPLETE: 2 Street Hustle Shifts! +UGX 7,000 Bonus!")
	elif int(day_stats.get("fares", 0)) >= 25000 and int(day_stats.get("goal_earn", 0)) == 0:
		day_stats["goal_earn"] = 1
		add_money(10000, "Daily Goal Bonus: UGX 25k Earned")
		day_stats["tips"] += 10000
		sfx.play("bonus")
		add_sms("Mobile Money Rewards", "Daily Goal Complete (UGX 25,000 Earned)! You received UGX 10,000 Cashback Bonus!")
		hud.toast("🏆 DAILY GOAL COMPLETE: UGX 25,000 Earned Today! +UGX 10,000 Bonus!")


func time_str() -> String:
	var h := int(time_of_day)
	var m := int((time_of_day - h) * 60.0)
	return "%02d:%02d" % [h, m]


func add_money(amount: int, reason := "Transaction") -> void:
	money += amount
	if amount > 0 and hud and hud.has_method("spawn_money_pop"):
		hud.spawn_money_pop(amount)
	if reason != "":
		var sign_s := "+" if amount >= 0 else "-"
		momo_log.push_front("[%s] %sUGX %s  •  %s" % [time_str(), sign_s, ugx(absi(amount)), reason])
		if momo_log.size() > 14:
			momo_log.resize(14)


func add_sms(sender: String, text: String) -> void:
	sms_list.push_front("[%s] %s: %s" % [time_str(), sender, text])
	if sms_list.size() > 12:
		sms_list.resize(12)


func adjust_rating(delta_r: float) -> void:
	rating = clampf(snappedf(rating + delta_r, 0.01), 1.0, 5.0)
	if rating >= 4.9:
		unlock_achievement("five_star")


func unlock_achievement(aid: String) -> void:
	if unlocked_achievements.has(aid):
		return
	for a in ACHIEVEMENTS:
		if str(a["id"]) == aid:
			unlocked_achievements[aid] = true
			var rwd: int = int(a["reward"])
			add_money(rwd, "Trophy bonus: %s" % str(a["title"]))
			if sfx:
				sfx.play("bonus", -2.5, 1.12)
			if hud:
				hud.toast("🏆 TROPHY UNLOCKED: %s!\n%s  •  +UGX %s MoMo Bonus!" % [str(a["title"]), str(a["desc"]), ugx(rwd)])
			save_game()
			return


func on_trip_completed() -> void:
	total_trips += 1
	unlock_achievement("first_trip")
	if total_trips >= 5:
		unlock_achievement("five_trips")


func district_level(dn: String) -> int:
	return mini(5, 1 + int(district_rep.get(dn, 0)) / 60)


func district_bonus_mult(dn: String) -> float:
	return 1.0 + 0.10 * float(district_level(dn) - 1)


func add_district_rep(dn: String, pts: int) -> void:
	if dn == "":
		return
	var prev_lv := district_level(dn)
	district_rep[dn] = int(district_rep.get(dn, 0)) + pts
	var new_lv := district_level(dn)
	if new_lv > prev_lv:
		add_money(5000, "%s District Lv.%d Bonus" % [dn, new_lv])
		sfx.play("bonus")
		hud.toast("🏅 %s RESPECT LEVEL %d! Fares here now pay +%d%% (+UGX 5,000 bonus)!" % [dn.to_upper(), new_lv, (new_lv - 1) * 10])


func spin_daily_wheel() -> String:
	if daily_spin_day >= day:
		return "Already spun today! Come back tomorrow (Day %d)." % (day + 1)
	daily_spin_day = day
	var roll := randi() % 5
	var msg := ""
	match roll:
		0:
			add_money(10000, "Stage Chairman's Lucky Spin Jackpot")
			msg = "💰 JACKPOT! +UGX 10,000 sent to Mobile Money!"
		1:
			player.fuel = player.max_tank()
			player.fuel_warn_level = 0
			msg = "⛽ FREE FULL TANK! Your boda tank is 100% full!"
		2:
			player.repair_bike()
			msg = "🔧 FREE BODA TUNE-UP! Engine restored to 100%!"
		3:
			vip_ticket = true
			msg = "🎫 VIP GOLDEN TICKET! Your next delivery pays 2x FARE!"
		_:
			adjust_rating(0.15)
			if life:
				life.mood = minf(100.0, life.mood + 20.0)
			msg = "⭐ CROWD FAVOURITE! +0.15 ★ Rating & +20 Mood!"
	sfx.play("bonus")
	hud.toast("🎁 DAILY SPIN: " + msg)
	save_game()
	return msg


func _update_encounter(delta: float) -> void:
	if not active_encounter.is_empty() or tutorial_step < 1:
		return
	_encounter_t -= delta
	if _encounter_t <= 0.0:
		_encounter_t = randf_range(85.0, 130.0)
		const ENCOUNTERS := [
			{
				"title": "🚦 Kikuubo Jam Shortcut!",
				"body": "A fellow rider waves you into a narrow Kikuubo alley to dodge the jam.",
				"a": "Take Shortcut (+UGX 3k)",
				"b": "Stay on Main Road (+Safe)",
			},
			{
				"title": "🔧 Stage Friend Has a Flat Tyre!",
				"body": "Your stage mate is stranded by the roundabout with a punctured rear tyre.",
				"a": "Help Patch (+0.08★ & +Rep)",
				"b": "Keep Hustling (+10 Mood)",
			},
			{
				"title": "🌦️ Sudden Kampala Rain Tip!",
				"body": "Clouds gather over Kololo. A commuter offers extra cash to beat the rain!",
				"a": "Sprint Fast (+UGX 5,000)",
				"b": "Cruise Safely (+0.04★)",
			},
			{
				"title": "📸 Visitor at Nakasero!",
				"body": "A visitor asks you to point out Kampala's landmarks & best rolex spot.",
				"a": "Give City Guide (+UGX 6k)",
				"b": "Friendly Wave (+12 Mood)",
			},
		]
		active_encounter = ENCOUNTERS[randi() % ENCOUNTERS.size()]
		sfx.play("pop", -4.0, 1.15)


func trigger_accident_confrontation(hit_kind: String, repair_cost: int) -> void:
	var speaker := "Angry Driver"
	var line := "Ehh boss! You knocked my %s! Where were you looking?!" % hit_kind
	var title := "💥 ROADSIDE CONFRONTATION (%s)" % hit_kind.capitalize()
	var body := "%s: \"%s\"\nYour boda took -24%% health and you feel shaken (-12 Mood)." % [speaker, line]
	var opt_a := "🙏 Apologize & Pay UGX %s" % ugx(repair_cost)
	var opt_b := "😤 Argue & Blame Traffic"
	if hit_kind == "boda":
		speaker = "Fellow Rider"
		line = "Oba wa! My side mirror is gone, man!"
		body = "%s: \"%s\"\nBoda brotherhood is watching — how do you handle it?" % [speaker, line]
		opt_a = "🤝 Settle Brotherly (UGX %s)" % ugx(mini(repair_cost, 4000))
		opt_b = "💨 Speed Off!"
	elif hit_kind == "pedestrian":
		speaker = "Bystander"
		line = "Eh! Look where you are riding, ssebo!"
		body = "%s: \"%s\"\nA crowd gathers around the street." % [speaker, line]
		opt_a = "🏥 Check on Them (UGX 5,000)"
		opt_b = "😰 Rush Away"
	active_encounter = {
		"kind": "accident",
		"hit": hit_kind,
		"cost": repair_cost,
		"title": title,
		"body": body,
		"a": opt_a,
		"b": opt_b,
	}
	if hud and hud.has_method("show_voice_subtitle"):
		hud.show_voice_subtitle(speaker, line)
	if sfx:
		sfx.play("whistle" if hit_kind == "pedestrian" else "horn_taxi", -4.0, 0.92)


func resolve_encounter(choice: int) -> void:
	if active_encounter.is_empty():
		return
	var ev := active_encounter
	var title: String = str(ev.get("title", ""))
	active_encounter = {}
	if str(ev.get("kind", "")) == "accident":
		var hit_kind: String = str(ev.get("hit", "vehicle"))
		var cost: int = int(ev.get("cost", 5000))
		if hit_kind == "boda":
			cost = mini(cost, 4000)
		elif hit_kind == "pedestrian":
			cost = 5000
		if choice == 0:
			add_money(-cost, "Accident settlement (%s)" % hit_kind)
			day_stats["crashes"] += cost
			if life:
				life.mood = minf(100.0, life.mood + 5.0)
			if hit_kind == "boda":
				adjust_rating(0.02)
			hud.toast("🤝 Settled calmly (-UGX %s). Crowd respects your maturity (+5 Mood)!" % ugx(cost))
		else:
			if hit_kind != "pedestrian" and rating >= 4.5 and randf() < 0.48:
				if life:
					life.mood = maxf(0.0, life.mood - 6.0)
				hud.toast("🗣️ You talked your way out of paying! Still shaken (-6 Mood).")
			else:
				var fine: int = cost + 3000
				add_money(-fine, "Heated confrontation fine")
				day_stats["crashes"] += fine
				adjust_rating(-0.18)
				if life:
					life.mood = maxf(0.0, life.mood - 18.0)
				hud.toast("😡 Heated confrontation! Crowd & police sided against you: -UGX %s, -0.18 ★, -18 Mood!" % ugx(fine))
		save_game()
		return
	if "Kikuubo" in title:
		if choice == 0:
			add_money(3000, "Kikuubo shortcut tip")
			if life: life.energy = maxf(0.0, life.energy - 5.0)
			hud.toast("💨 Zipped through the alley! +UGX 3,000 tip!")
		else:
			adjust_rating(0.02)
			hud.toast("🛡️ Smooth & safe ride on Kampala Road (+0.02 ★)!")
	elif "Flat Tyre" in title:
		if choice == 0:
			adjust_rating(0.08)
			add_district_rep(district_at(player.position), 25)
			hud.toast("🤝 Stage brotherhood! +0.08 ★ Rating & +25 District Respect!")
		else:
			if life: life.mood = minf(100.0, life.mood + 10.0)
			hud.toast("🏍️ Focused on the hustle (+10 Mood)!")
	elif "Rain Tip" in title:
		if choice == 0:
			add_money(5000, "Beat-the-rain speed bonus")
			hud.toast("⚡ Beat the storm! +UGX 5,000 bonus!")
		else:
			adjust_rating(0.04)
			hud.toast("☂️ Careful riding pays off (+0.04 ★ Rating)!")
	else:
		if choice == 0:
			add_money(6000, "Kampala city guide tip")
			hud.toast("🌟 The visitor loved your Kampala tips! +UGX 6,000!")
		else:
			if life: life.mood = minf(100.0, life.mood + 12.0)
			hud.toast("😊 Warm Kampala hospitality (+12 Mood)!")
	sfx.play("chime")
	save_game()


func advance_tutorial() -> void:
	tutorial_step = mini(4, tutorial_step + 1)
	if sfx:
		sfx.play("pop", -5.0, 1.1)
	save_game()


func dismiss_tutorial() -> void:
	tutorial_step = 4
	if sfx:
		sfx.play("pop", -6.0, 0.9)
	save_game()


func tutorial_text() -> String:
	if day > 1 or tutorial_step >= 4:
		return ""
	match tutorial_step:
		0: return "Welcome to Kampala! Tap 'Ride boda' (or press E) to hop on your bike, or explore on foot."
		1: return "Tap the top-left Minimap (or press M) to view Kampala streets, [F] Petrol Stations & [★] Promos."
		2: return "Follow the GPS route to deliver! Press H to hoot traffic aside & Shift / ⚡ Boost to overtake."
		3: return "Open 'Phone (P)' for Daily Challenges, Kampala Business Empire, Boda Paint & Save Slots!"
	return ""


## 12500 -> "12,500"
func ugx(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


# =============================================================== the working day
func _reset_day_stats() -> void:
	day_stats = {
		"fares": 0, "tips": 0, "jobs": 0, "fuel": 0, "crashes": 0,
		"boda_trips": 0, "hustles": 0, "goal_trips": 0, "goal_hustles": 0, "goal_earn": 0,
	}


## 23:00 - the day is over. Pay the boda owner, collect fleet & business remits, and see how you did.
func end_day() -> void:
	paused = true
	var rent_cost := 0 if owns_boda else DAILY_RENT
	var fleet_income := daily_passive_income()
	if rent_cost > 0:
		add_money(-rent_cost, "Daily boda owner rent")
	if fleet_income > 0:
		add_money(fleet_income, "Daily remit from riders & businesses")
	var earned: int = day_stats["fares"] + day_stats["tips"] + fleet_income
	var spent: int = day_stats["fuel"] + day_stats["crashes"] + rent_cost
	var net := earned - spent
	var lines := [
		"DAY %d IS OVER   •   %s (★ %.1f)" % [day, player_rank(), rating],
		"",
		"Jobs & shifts completed:   %d" % day_stats["jobs"],
		"Fares & Hustles:   UGX %s" % ugx(day_stats["fares"]),
		"Tips & Daily Goal Bonuses:   UGX %s" % ugx(day_stats["tips"]),
		"Passive Empire Remit (Riders & Stalls):   + UGX %s" % ugx(fleet_income),
		"Fuel:   - UGX %s" % ugx(day_stats["fuel"]),
		"Crashes & Fines:   - UGX %s" % ugx(day_stats["crashes"]),
		"Boda Owner Rent:   %s" % ("OWNED (UGX 0!)" if owns_boda else ("- UGX " + ugx(rent_cost))),
		"",
		"Today you %s UGX %s" % ["made" if net >= 0 else "lost", ugx(absi(net))],
		"Mobile Money balance:   UGX %s" % ugx(money),
		"Own Boda status:   %s" % ("OWNED!" if owns_boda else ("%d%% saved" % int(clampf(float(money) / GOAL * 100.0, 0.0, 100.0)))),
	]
	if not owns_boda and money >= GOAL:
		lines.append("")
		lines.append("You have UGX 500,000! Open your Phone (P) -> Garage to buy your boda title!")
	elif money < 0:
		lines.append("")
		lines.append("You owe money on Mobile Money. Work hard tomorrow!")
	hud.show_summary("\n".join(lines), "Start day %d" % (day + 1))
	save_game()


func start_next_day() -> void:
	day += 1
	time_of_day = DAY_START
	_reset_day_stats()
	paused = false
	hud.hide_summary()
	if raining:
		toggle_rain()
	if not power_on:
		toggle_power()
	# a new day sometimes starts wet
	if randf() < 0.3:
		toggle_rain()
	hud.toast("Day %d. Good morning, Kampala!" % day)
	save_game()


func _slot_path(slot: int) -> String:
	return SAVE_PATH if slot == 1 else ("user://playkampala_save_%d.json" % slot)


func switch_save_slot(slot: int) -> void:
	save_game()
	save_slot = clampi(slot, 1, 3)
	if FileAccess.file_exists(_slot_path(save_slot)):
		load_game()
	else:
		# Fresh career in this slot
		money = 5000
		day = 1
		time_of_day = DAY_START
		player.fuel = 2.8
		has_helmet = false
		has_vest = false
		has_permit = false
		has_rain_jacket = false
		has_big_tank = false
		bike_level = 0
		owns_boda = false
		hired_riders = 0
		owns_rolex_stand = false
		owns_kibanda_tv = false
		owns_momo_kiosk = false
		owns_matatu = false
		rating = 4.6
		regulars = {}
		momo_log = ["[07:00] +UGX 5,000  •  Starting Mobile Money float"]
		sms_list = ["[07:00] Stage Chairman: Welcome to Slot %d! Work hard and build your fleet." % save_slot]
		tutorial_step = 0
		_reset_day_stats()
		save_game()
		hud.toast("Started fresh career in Save Slot %d!" % save_slot)


func save_game() -> void:
	if "--no-save" in OS.get_cmdline_user_args():
		return
	var f := FileAccess.open(_slot_path(save_slot), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"money": money, "day": day, "fuel": player.fuel, "bike_health": player.bike_health, "time": time_of_day,
		"stats": day_stats, "helmet": has_helmet, "vest": has_vest, "permit": has_permit,
		"jacket": has_rain_jacket, "tank": has_big_tank, "bike_level": bike_level,
		"owns_boda": owns_boda, "hired_riders": hired_riders,
		"owns_rolex_stand": owns_rolex_stand, "owns_kibanda_tv": owns_kibanda_tv,
		"owns_momo_kiosk": owns_momo_kiosk, "owns_matatu": owns_matatu,
		"bike_paint": bike_paint, "rider_name": rider_name, "home_stage": home_stage, "rider_outfit": rider_outfit, "rider_female": rider_female,
		"total_trips": total_trips, "achievements": unlocked_achievements,
		"rating": rating, "district_rep": district_rep, "daily_spin_day": daily_spin_day, "vip_ticket": vip_ticket,
		"regulars": regulars, "momo_log": momo_log, "sms_list": sms_list,
		"tutorial_step": tutorial_step,
	}))


func load_game() -> void:
	if momo_log.is_empty():
		momo_log = ["[07:00] +UGX 5,000  •  Starting Mobile Money float"]
	if sms_list.is_empty():
		sms_list = [
			"[07:05] Stage Chairman: Welcome to Downtown Stage! Buy your Helmet, Vest & Permit to avoid Police fines.",
			"[07:02] Mama Kevina: Pass by the Rolex Stand or Owino Market anytime you want extra foot work!",
		]
	var path := _slot_path(save_slot)
	if "--no-save" in OS.get_cmdline_user_args() or not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return
	money = int(data.get("money", money))
	day = int(data.get("day", day))
	player.fuel = float(data.get("fuel", player.fuel))
	player.bike_health = clampf(float(data.get("bike_health", 100.0)), 0.0, 100.0)
	time_of_day = clampf(float(data.get("time", DAY_START)), DAY_START, DAY_END - 0.5)
	has_helmet = bool(data.get("helmet", false))
	has_vest = bool(data.get("vest", false))
	has_permit = bool(data.get("permit", false))
	has_rain_jacket = bool(data.get("jacket", false))
	has_big_tank = bool(data.get("tank", false))
	bike_level = int(data.get("bike_level", 0))
	owns_boda = bool(data.get("owns_boda", false))
	hired_riders = int(data.get("hired_riders", 0))
	owns_rolex_stand = bool(data.get("owns_rolex_stand", false))
	owns_kibanda_tv = bool(data.get("owns_kibanda_tv", false))
	owns_momo_kiosk = bool(data.get("owns_momo_kiosk", false))
	owns_matatu = bool(data.get("owns_matatu", false))
	bike_paint = int(data.get("bike_paint", 0))
	rider_name = str(data.get("rider_name", "Kato"))
	home_stage = int(data.get("home_stage", 0))
	rider_outfit = int(data.get("rider_outfit", 0))
	rider_female = bool(data.get("rider_female", false))
	total_trips = int(data.get("total_trips", 0))
	if typeof(data.get("achievements", {})) == TYPE_DICTIONARY:
		unlocked_achievements = data.get("achievements", {})
	apply_bike_paint()
	rating = float(data.get("rating", 4.6))
	if typeof(data.get("district_rep", {})) == TYPE_DICTIONARY:
		district_rep = data.get("district_rep", {})
	daily_spin_day = int(data.get("daily_spin_day", 0))
	vip_ticket = bool(data.get("vip_ticket", false))
	tutorial_step = int(data.get("tutorial_step", 0))
	if typeof(data.get("regulars")) == TYPE_DICTIONARY:
		regulars = data["regulars"]
	if typeof(data.get("momo_log")) == TYPE_ARRAY:
		momo_log = data["momo_log"]
	if typeof(data.get("sms_list")) == TYPE_ARRAY:
		sms_list = data["sms_list"]
	var st = data.get("stats", {})
	if typeof(st) == TYPE_DICTIONARY:
		for k in day_stats:
			day_stats[k] = int(st.get(k, 0))
	hud.toast("Slot %d loaded! Day %d • UGX %s • ★ %.1f" % [save_slot, day, ugx(money), rating])



# =============================================================== the city generator
## The city is a grid of N x N blocks. Roads run along every grid line; the
## junctions and roads form the graph that traffic drives on and the map draws.
func _build_road_graph() -> void:
	for j in N + 1:
		for i in N + 1:
			nodes.append(Vector3(-HALF + i * BLOCK, 0, -HALF + j * BLOCK))
			adj.append([])
	for j in N + 1:
		for i in N + 1:
			var n := i + j * (N + 1)
			if i < N:
				_link(n, n + 1)
			if j < N:
				_link(n, n + N + 1)


func _link(p: int, q: int) -> void:
	adj[p].append(q)
	adj[q].append(p)
	edges.append([p, q])


func add_place(name: String, pos: Vector3, district: String) -> void:
	places.append({"name": name, "pos": Vector3(pos.x, 0, pos.z), "district": district})


func shop_name() -> String:
	for attempt in 6:
		var n := "%s %s" % [_pick(NAME_A), _pick(NAME_B)]
		if not _used_names.has(n):
			_used_names[n] = true
			return n
	return "%s %s %d" % [_pick(NAME_A), _pick(NAME_B), _used_names.size()]


## Painted shop name. Only drawn when the camera is close, to save phones.
func sign_text(text: String, bg: Color, xf: Transform3D, width: float) -> void:
	var lab := Label3D.new()
	lab.text = text
	lab.font_size = 36
	lab.outline_size = 0
	lab.pixel_size = clampf(width * 0.9 / maxf(1.0, text.length() * 20.0), 0.0035, 0.0065)
	lab.modulate = Color(0.08, 0.06, 0.05) if bg.get_luminance() > 0.5 else Color(1, 1, 1)
	lab.shaded = false
	lab.double_sided = false
	lab.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	lab.visibility_range_end = 55.0
	lab.transform = xf
	add_child(lab)


func _district_for(bx: int, bz: int) -> String:
	var v := Vector2i(bx, bz)
	if v in [Vector2i(2, 2), Vector2i(3, 2), Vector2i(2, 3), Vector2i(3, 3)]:
		return "downtown"
	if v in [Vector2i(1, 1), Vector2i(1, 2), Vector2i(3, 1)]:
		return "nakasero"
	match v:
		Vector2i(2, 1): return "market"
		Vector2i(2, 4): return "taxi"
		Vector2i(4, 1): return "pitch"
		Vector2i(1, 3), Vector2i(4, 4): return "fuel"
	if v in [Vector2i(0, 4), Vector2i(0, 5), Vector2i(1, 5), Vector2i(5, 0), Vector2i(5, 1)]:
		return "workshops"
	if bx == 0 or bz == 0 or bx == N - 1 or bz == N - 1:
		return "estates"
	return "mixed"


func _build_roads() -> void:
	box(Vector3(0, -0.1, 0), Vector3(1000, 0.2, 1000), MURRAM, Transform3D.IDENTITY, "far")
	# junction squares
	for n in nodes:
		box(n + Vector3(0, 0.02, 0), Vector3(8, 0.04, 8), ASPHALT, Transform3D.IDENTITY, "road")
	# Kampala roundabouts (Clock Tower roundabout at (0,0,64), City Square at (0,0,0), Wandegeya at (-64,0,0))
	var r_positions := [Vector3(0, 0, BLOCK), Vector3(0, 0, 0), Vector3(-BLOCK, 0, 0)]
	for ri in r_positions.size():
		var rp: Vector3 = r_positions[ri]
		roundabouts.append(rp)
		# widened asphalt apron around the roundabout
		_add("road", _cyl(6.2, 6.2, 0.045, 16), Transform3D(Basis.IDENTITY, rp + Vector3(0, 0.022, 0)), ASPHALT)
		# yellow-and-black kerb ring & raised grass island (sized so left-hand lanes at 1.9m clear cleanly)
		_add("solid", _cyl(1.42, 1.55, 0.28, 14), Transform3D(Basis.IDENTITY, rp + Vector3(0, 0.14, 0)), CURB_YELLOW)
		_add("solid", _cyl(1.18, 1.25, 0.34, 14), Transform3D(Basis.IDENTITY, rp + Vector3(0, 0.17, 0)), LEAF)
		collide(Transform3D.IDENTITY, rp + Vector3(0, 1.0, 0), Vector3(2.2, 2.0, 2.2))
		if ri == 0:
			# Iconic Queen's Way Clock Tower landmark
			box(rp + Vector3(0, 1.2, 0), Vector3(1.8, 2.4, 1.8), WALLS[0])
			box(rp + Vector3(0, 5.2, 0), Vector3(1.25, 6.2, 1.25), WALLS[6])
			for cx in [-0.52, 0.52]:
				for cz in [-0.52, 0.52]:
					box(rp + Vector3(cx, 5.2, cz), Vector3(0.22, 6.4, 0.22), WALLS[3])
			box(rp + Vector3(0, 9.1, 0), Vector3(1.55, 1.6, 1.55), WALLS[0])
			# 4 glowing clock faces + hands
			for dir in [Vector3(0, 0, 0.79), Vector3(0, 0, -0.79), Vector3(0.79, 0, 0), Vector3(-0.79, 0, 0)]:
				var csz := Vector3(0.95, 0.95, 0.04) if absf(dir.z) > 0.5 else Vector3(0.04, 0.95, 0.95)
				box(rp + Vector3(0, 9.1, 0) + dir, csz, Color(0.98, 0.95, 0.82), Transform3D.IDENTITY, "lamp")
				var hsz := Vector3(0.08, 0.42, 0.06) if absf(dir.z) > 0.5 else Vector3(0.06, 0.42, 0.08)
				box(rp + Vector3(0, 9.22, 0) + dir * 1.02, hsz, DARK)
			_add("solid", _cyl(0.1, 1.15, 1.6, 4), Transform3D(Basis(Vector3.UP, PI * 0.25), rp + Vector3(0, 10.7, 0)), ROOFS[3])
			add_place("the Clock Tower", rp + Vector3(6.2, 0, 6.2), "Kikuubo & Arcades")
		else:
			# Independence / City monument obelisk + Traffic Police officer directing roundabout traffic
			box(rp + Vector3(0, 1.1, 0), Vector3(0.9, 1.8, 0.9), GREY)
			tree(0, Transform3D(Basis.IDENTITY, rp + Vector3(0, 0.25, 0)))
			var cop := make_person(false, "police", false, rp + Vector3(0, 0.34, 1.2))
			cop.rotation.y = 0.0
	# road between junctions, with faded centre dashes, murram shoulders, open storm drains, and black-and-yellow curbs
	for e in edges:
		var p1: Vector3 = nodes[e[0]]
		var p2: Vector3 = nodes[e[1]]
		var mid := (p1 + p2) * 0.5
		var along_x := absf(p2.x - p1.x) > 1.0
		var rlen := BLOCK - 8.0
		var size := Vector3(rlen, 0.03, 8) if along_x else Vector3(8, 0.03, rlen)
		box(mid + Vector3(0, 0.015, 0), size, ASPHALT, Transform3D.IDENTITY, "road")
		# Crisp cream-white road edge lines + storm drain & warm sandstone-terracotta curbs (matches reference art!)
		for s in [-1.0, 1.0]:
			var edge_line_pos := mid + (Vector3(0, 0.036, s * 3.52) if along_x else Vector3(s * 3.52, 0.036, 0))
			var edge_line_sz := Vector3(rlen, 0.01, 0.14) if along_x else Vector3(0.14, 0.01, rlen)
			box(edge_line_pos, edge_line_sz, PAINT, Transform3D.IDENTITY, "road")
			var drain_pos := mid + (Vector3(0, 0.01, s * 3.85) if along_x else Vector3(s * 3.85, 0.01, 0))
			var drain_sz := Vector3(rlen, 0.02, 0.26) if along_x else Vector3(0.26, 0.02, rlen)
			box(drain_pos, drain_sz, DRAIN_DARK, Transform3D.IDENTITY, "road")
			var seg_len := 2.0
			var num_segs := int(rlen / seg_len)
			var sandstone_curb := PAVEMENT.darkened(0.14)
			for ci in num_segs:
				var coff := -rlen * 0.5 + (ci + 0.5) * seg_len
				var near_junc := absf(coff) > rlen * 0.5 - 4.0
				var ccol := (CURB_YELLOW if ci % 2 == 0 else DARK) if near_junc else sandstone_curb
				var cpos := mid + (Vector3(coff, 0.11, s * 4.02) if along_x else Vector3(s * 4.02, 0.11, coff))
				var csz := Vector3(seg_len, 0.15, 0.18) if along_x else Vector3(0.18, 0.15, seg_len)
				box(cpos, csz, ccol)
		var k := -BLOCK / 2 + 8.0
		while k < BLOCK / 2 - 7.0:
			var c := PAINT.lerp(ASPHALT, rng.randf() * 0.5)
			if along_x:
				box(mid + Vector3(k, 0.035, 0), Vector3(2, 0.01, 0.15), c, Transform3D.IDENTITY, "road")
			else:
				box(mid + Vector3(0, 0.035, k), Vector3(0.15, 0.01, 2), c, Transform3D.IDENTITY, "road")
			k += 4.0
		# potholes, some full of muddy water
		if rng.randf() < 0.6:
			var r := rng.randf_range(0.35, 0.9)
			var off := rng.randf_range(-BLOCK / 2 + 9, BLOCK / 2 - 9)
			var side := rng.randf_range(-3.0, 3.0)
			var pos := mid + (Vector3(off, 0.048, side) if along_x else Vector3(side, 0.048, off))
			var pc := Color(0.17, 0.16, 0.16) if rng.randf() < 0.5 else Color(0.42, 0.30, 0.20)
			_add("road", _cyl(r, r, 0.01, 7), Transform3D(Basis.IDENTITY.scaled(Vector3(1, 1, rng.randf_range(0.6, 1.0))), pos), pc)
	# zebra crossings around the downtown junctions
	for n in nodes:
		if absf(n.x) > BLOCK + 1 or absf(n.z) > BLOCK + 1:
			continue
		for dir in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var at: Vector3 = n + dir * 7.6
			var across := Vector3(dir.z, 0, dir.x)
			for t in range(-3, 4):
				var sz := Vector3(2.2, 0.01, 0.5) if absf(dir.x) > 0.5 else Vector3(0.5, 0.01, 2.2)
				box(at + across * t + Vector3(0, 0.045, 0), sz, PAINT.lerp(ASPHALT, 0.15), Transform3D.IDENTITY, "road")
	# 3D Kampala Council Green & White Street Name Signposts at major intersections
	var sign_green := Color(0.08, 0.44, 0.24)
	for j in range(1, N):
		for i in range(1, N):
			var jpos := Vector3(-HALF + i * BLOCK, 0, -HALF + j * BLOCK)
			var post_base := jpos + Vector3(-4.7, 0.18, -4.7)
			_add("solid", _cyl(0.04, 0.05, 2.55, 6), Transform3D(Basis.IDENTITY, post_base + Vector3(0, 1.28, 0)), GREY)
			# East-West street blade
			box(post_base + Vector3(0.65, 2.38, 0), Vector3(1.35, 0.24, 0.05), sign_green)
			sign_text(EW_STREETS[j], sign_green, Transform3D(Basis.IDENTITY, post_base + Vector3(0.65, 2.38, 0.035)), 1.28)
			# North-South street blade
			box(post_base + Vector3(0, 2.10, 0.65), Vector3(0.05, 0.24, 1.35), sign_green)
			sign_text(NS_STREETS[i], sign_green, Transform3D(Basis(Vector3.UP, PI / 2), post_base + Vector3(0.035, 2.10, 0.65)), 1.28)


func _build_blocks() -> void:
	for bz in N:
		for bx in N:
			var d := _district_for(bx, bz)
			district_of[Vector2i(bx, bz)] = d
			var x0 := -HALF + bx * BLOCK
			var z0 := -HALF + bz * BLOCK
			var c := Vector3(x0 + BLOCK / 2, 0, z0 + BLOCK / 2)
			var dn: String = DISTRICT_NAMES[d]
			# pavements: north/south full width, west/east between them
			for sz in [z0 + 5.25, z0 + BLOCK - 5.25]:
				box(Vector3(c.x, 0.09, sz), Vector3(BLOCK - 8, 0.18, 2.5), PAVEMENT)
			for sx in [x0 + 5.25, x0 + BLOCK - 5.25]:
				box(Vector3(sx, 0.09, c.z), Vector3(2.5, 0.18, BLOCK - 13), PAVEMENT)
			match d:
				"downtown":
					_frontage(bx, bz, [true, true, true, true], 2, 4, 0.85, dn)
					shop_house(Transform3D(Basis.IDENTITY, c + Vector3(0, 0, 9)), 20, 18, rng.randi_range(5, 7), "win", 0.0)
				"market":
					_frontage(bx, bz, [false, true, false, true], 1, 3, 0.5, dn)
					_build_market(c)
					add_place("Owino Market", Vector3(c.x, 0, z0 + 8.0), dn)
				"taxi":
					_frontage(bx, bz, [true, false, false, false], 2, 3, 0.6, dn)
					_build_taxi_park(c + Vector3(0, 0, 4))
					add_place("the Old Taxi Park", Vector3(c.x, 0, z0 + BLOCK - 8.0), dn)
					_build_boda_stage(Vector3(x0 + BLOCK - 5.3, 0.18, z0 + 24), 1.0)
				"pitch":
					_frontage(bx, bz, [false, false, true, true], 1, 2, 0.3, dn)
					_build_pitch(c)
					add_place("Nakivubo Stadium", Vector3(c.x, 0, z0 + 8.0), dn)
				"nakasero":
					_frontage(bx, bz, [true, true, false, false], 3, 5, 0.4, dn)
					_build_nakasero(c, dn)
				"workshops":
					_workshops(bx, bz, c, dn)
				"fuel":
					_frontage(bx, bz, [false, true, false, true], 1, 2, 0.3, dn)
					_build_petrol_station(Vector3(x0 + 20, 0, z0 + 18))
					muzigo(Transform3D(Basis(Vector3.UP, PI), c + Vector3(6, 0, 4)), 3)
					tree(0, Transform3D(Basis.IDENTITY, c + Vector3(-8, 0, 12)))
				"mixed":
					_frontage(bx, bz, [true, true, true, true], 1, 3, 0.45, dn)
					_build_residential(c)
				_:
					_estates(bx, bz, c, dn)
	# rolex stands & Mobile Money kiosks on downtown corners, and the boda stage where you start
	for p in [Vector3(-5.25, 0.18, 9.5), Vector3(5.25, 0.18, -9.5), Vector3(-5.25, 0.18, -9.5),
			Vector3(BLOCK - 5.25, 0.18, 9.5), Vector3(-BLOCK + 5.25, 0.18, -9.5)]:
		_build_rolex_stand(p)
		add_place("the rolex stand", p + Vector3(0, 0, 2.2 * signf(p.z)), "Kikuubo & Arcades")
	for mp in [Vector3(-5.3, 0.18, -22.0), Vector3(5.3, 0.18, -BLOCK + 12.0),
			Vector3(BLOCK - 5.3, 0.18, -12.0), Vector3(-BLOCK + 5.3, 0.18, 12.0)]:
		_build_momo_kiosk(mp)
	# Roadside Muchomo & Roasted Gonja charcoal grills
	for ms in [
		[Vector3(-5.3, 0.18, 17.5), PI / 2],
		[Vector3(18.0, 0.18, 5.3), PI],
		[Vector3(-BLOCK + 5.3, 0.18, 22.0), PI / 2],
		[Vector3(BLOCK - 5.3, 0.18, 22.0), -PI / 2],
		[Vector3(-18.0, 0.18, BLOCK - 5.3), 0.0],
		[Vector3(18.0, 0.18, -BLOCK + 5.3), PI],
	]:
		_build_muchomo_stand(ms[0], ms[1])
	# Sugarcane & Tropical Fruit pushcarts (kigaali)
	for fc in [
		[Vector3(5.3, 0.18, 29.0), -PI / 2],
		[Vector3(-20.0, 0.18, -5.3), 0.0],
		[Vector3(-BLOCK - 5.3, 0.18, -16.0), -PI / 2],
		[Vector3(BLOCK + 5.3, 0.18, 16.0), PI / 2],
		[Vector3(16.0, 0.18, BLOCK + 5.3), PI],
		[Vector3(-16.0, 0.18, -BLOCK - 5.3), 0.0],
	]:
		_build_fruit_cart(fc[0], fc[1])
	# Roadside Boda Mechanics & Tyre Pressure Fundis
	for bf in [
		[Vector3(-5.3, 0.18, 34.0), PI / 2],
		[Vector3(28.0, 0.18, -5.3), 0.0],
		[Vector3(-BLOCK + 22.0, 0.18, 5.3), PI],
		[Vector3(BLOCK - 22.0, 0.18, -5.3), 0.0],
		[Vector3(5.3, 0.18, BLOCK - 22.0), -PI / 2],
	]:
		_build_boda_fundi(bf[0], bf[1])
	# Newspaper (Bukedde / New Vision), Airtime & Cold Soda Umbrella Tables
	for at in [
		[Vector3(5.3, 0.18, -19.0), -PI / 2],
		[Vector3(-14.0, 0.18, 5.3), PI],
		[Vector3(-BLOCK + 5.3, 0.18, -22.0), PI / 2],
		[Vector3(BLOCK - 5.3, 0.18, -22.0), -PI / 2],
		[Vector3(22.0, 0.18, BLOCK - 5.3), 0.0],
	]:
		_build_airtime_table(at[0], at[1])
	# Roadside TVs & Football Match / VJ Movie "Kibanda" Screening Stands
	for tv in [
		[Vector3(-5.3, 0.18, 25.5), PI / 2, "Kikuubo Live Football TV"],
		[Vector3(21.0, 0.18, -5.3), 0.0, "Downtown Sports & VJ TV"],
		[Vector3(-BLOCK + 5.3, 0.18, 31.0), PI / 2, "Wandegeya Kibanda TV"],
		[Vector3(-26.0, 0.18, BLOCK - 5.3), 0.0, "Taxi Park Match Screen"],
		[Vector3(-26.0, 0.18, -BLOCK + 5.3), PI, "Owino Market Live TV"],
		[Vector3(BLOCK - 5.3, 0.18, -31.0), -PI / 2, "Nakivubo Fan Zone TV"],
	]:
		_build_roadside_tv(tv[0], tv[1], tv[2])
	_build_billboards()
	_build_boda_stage(Vector3(5.25, 0.18, 9.0), 1.0)
	# Boda Stage Helmet / Vest / Permit stall sign at player spawn stage
	box(Vector3(6.4, 1.35, 8.2), Vector3(0.12, 2.3, 2.2), Color(0.95, 0.76, 0.08))
	sign_text("STAGE GEAR: Helmet / Vest / Permit", Color(0.95, 0.76, 0.08), Transform3D(Basis(Vector3.UP, -PI / 2), Vector3(6.32, 1.85, 8.2)), 2.0)
	_build_police_checkpoints()


## Rows of shop-houses facing the roads around a block.
## sides = [north, south, west, east]
func _frontage(bx: int, bz: int, sides: Array, fmin: int, fmax: int, arcade_p: float, dn: String) -> void:
	var x0 := -HALF + bx * BLOCK
	var z0 := -HALF + bz * BLOCK
	var x1 := x0 + BLOCK
	var z1 := z0 + BLOCK
	const IN := 6.8
	if sides[0]:
		_row(Vector3(0, 0, z0 + IN), Vector3(1, 0, 0), x0 + 7.0, x1 - 7.0, PI, fmin, fmax, arcade_p, dn)
	if sides[1]:
		_row(Vector3(0, 0, z1 - IN), Vector3(1, 0, 0), x0 + 7.0, x1 - 7.0, 0.0, fmin, fmax, arcade_p, dn)
	if sides[2]:
		_row(Vector3(x0 + IN, 0, 0), Vector3(0, 0, 1), z0 + 19.5, z1 - 19.5, -PI / 2, fmin, fmax, arcade_p, dn)
	if sides[3]:
		_row(Vector3(x1 - IN, 0, 0), Vector3(0, 0, 1), z0 + 19.5, z1 - 19.5, PI / 2, fmin, fmax, arcade_p, dn)


func _row(origin: Vector3, along: Vector3, from: float, to: float, theta: float, fmin: int, fmax: int, arcade_p: float, dn: String) -> void:
	var d := from
	while d < to - 3.0:
		if d > from and rng.randf() < 0.12:
			d += 1.6   # alley
			continue
		var w := minf(rng.randf_range(5.5, 9.5), to - d)
		if w < 3.5:
			break
		var center := origin + along * (d + w / 2.0)
		var depth := rng.randf_range(8.0, 11.5)
		var floors := rng.randi_range(fmin, fmax)
		var lit := "gen" if rng.randf() < 0.04 else "win"
		shop_house(Transform3D(Basis(Vector3.UP, theta), center), w - 0.15, depth, floors, lit, arcade_p, shop_name(), dn)
		d += w


func _workshops(bx: int, bz: int, c: Vector3, dn: String) -> void:
	var x0 := -HALF + bx * BLOCK
	var z0 := -HALF + bz * BLOCK
	for side in [0, 1]:
		var z := z0 + 7.0 if side == 0 else z0 + BLOCK - 7.0
		var theta := PI if side == 0 else 0.0
		var x := x0 + 8.0
		while x < x0 + BLOCK - 14.0:
			var w := rng.randf_range(11.0, 16.0)
			w = minf(w, x0 + BLOCK - 8.0 - x)
			var xf := Transform3D(Basis(Vector3.UP, theta), Vector3(x + w / 2, 0, z))
			warehouse(xf, w - 0.5, rng.randf_range(10.0, 13.0), rng.randf_range(5.0, 7.0), "%s %s" % [_pick(NAME_A), _pick(["Motor Garage", "Welding Works", "Metal Fabricators", "Timber Yard", "Tyre Centre", "Car Wash", "Steel & Cement"])], dn)
			x += w + 1.0
	# scrap yard in the middle: old cars and piles of metal
	for i in 6:
		var p := c + Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-6, 6))
		var cxf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p)
		bake_parts(model_car(Color(0.45, 0.4, 0.35).lerp(_pick(SIGNS), 0.3)), cxf)
		collide(cxf, Vector3(0, 0.8, 0), Vector3(1.8, 1.6, 4.1))
	for i in 10:
		var p2 := c + Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-8, 8))
		var s := rng.randf_range(0.5, 1.3)
		box(p2 + Vector3(0, s / 2, 0), Vector3(s * 1.4, s, s), _pick([GREY, ROOFS[0], DARK, ROOFS[1]]))


func warehouse(xf: Transform3D, w: float, d: float, h: float, name: String, dn: String) -> void:
	box(Vector3(0, h / 2, -d / 2), Vector3(w, h, d), _pick([PAINT, WALLS[0], GREY.lightened(0.3), WALLS[2]]), xf)
	collide(xf, Vector3(0, h / 2, -d / 2), Vector3(w, h, d))
	_add("solid", _prism(Vector3(d + 0.6, 1.6, w + 0.3)), xf * Transform3D(Basis(Vector3.UP, PI / 2), Vector3(0, h + 0.8, -d / 2)), _pick(ROOFS))
	box(Vector3(0, 1.8, 0.03), Vector3(w * 0.55, 3.6, 0.08), SHOP_DARK, xf, "win")
	var sc: Color = _pick(SIGNS)
	box(Vector3(0, 4.1, 0.08), Vector3(w * 0.8, 0.7, 0.1), sc, xf)
	sign_text(name, sc, xf * Transform3D(Basis.IDENTITY, Vector3(0, 4.1, 0.14)), w * 0.8)
	add_place(name, xf * Vector3(0, 0, 2.0), dn)
	for i in rng.randi_range(2, 5):
		box(Vector3(rng.randf_range(-w / 2 + 1, w / 2 - 1), 0.4, rng.randf_range(0.8, 2.0)), Vector3(0.8, 0.8, 0.8), _pick([GREY, DARK, WOOD, ROOFS[0]]), xf)


## Residential edge of town: rental rows facing the roads, kiosks, a church, trees.
func _estates(bx: int, bz: int, c: Vector3, dn: String) -> void:
	var x0 := -HALF + bx * BLOCK
	var z0 := -HALF + bz * BLOCK
	const IN := 10.5
	var rows := [
		[Vector3(0, 0, z0 + IN), Vector3(1, 0, 0), x0 + 9.0, x0 + BLOCK - 9.0, PI],
		[Vector3(0, 0, z0 + BLOCK - IN), Vector3(1, 0, 0), x0 + 9.0, x0 + BLOCK - 9.0, 0.0],
		[Vector3(x0 + IN, 0, 0), Vector3(0, 0, 1), z0 + 20.0, z0 + BLOCK - 20.0, -PI / 2],
		[Vector3(x0 + BLOCK - IN, 0, 0), Vector3(0, 0, 1), z0 + 20.0, z0 + BLOCK - 20.0, PI / 2],
	]
	for r in rows:
		var d: float = r[2]
		var to: float = r[3]
		while d < to - 4.0:
			var roll := rng.randf()
			if roll < 0.18:
				# small kiosk shop on the road
				var kw := 4.5
				var kxf := Transform3D(Basis(Vector3.UP, r[4]), (r[0] as Vector3) + (r[1] as Vector3) * (d + kw / 2) - Basis(Vector3.UP, r[4]) * Vector3(0, 0, -3.5))
				shop_house(kxf, kw, 4.0, 1, "win", 0.0, shop_name(), dn)
				d += kw + 1.5
			elif roll < 0.75:
				var rooms := rng.randi_range(2, 4)
				var mw := rooms * 3.4
				if d + mw > to:
					break
				var mxf := Transform3D(Basis(Vector3.UP, r[4]), (r[0] as Vector3) + (r[1] as Vector3) * (d + mw / 2))
				muzigo(mxf, rooms)
				if rng.randf() < 0.5:
					add_place("%s's home" % _pick(RESIDENTS), mxf * Vector3(0, 0, 4.2), dn)
				d += mw + 1.5
			else:
				tree(rng.randi_range(0, 2), Transform3D(Basis(Vector3.UP, rng.randf() * TAU), (r[0] as Vector3) + (r[1] as Vector3) * (d + 2.0) - Basis(Vector3.UP, r[4]) * Vector3(0, 0, 2.0)))
				d += 4.5
	# the middle of the block: a church on some, gardens on others
	if rng.randf() < 0.35:
		var cxf := Transform3D(Basis(Vector3.UP, rng.randi_range(0, 3) * PI / 2), c)
		box(Vector3(0, 3.5, -6), Vector3(9, 7, 14), PAINT, cxf)
		collide(cxf, Vector3(0, 3.5, -6), Vector3(9, 7, 14))
		_add("solid", _prism(Vector3(10, 3, 14.4)), cxf * Transform3D(Basis.IDENTITY, Vector3(0, 8.5, -6)), ROOFS[3])
		box(Vector3(0, 6, 1.6), Vector3(3, 12, 3), PAINT, cxf)
		collide(cxf, Vector3(0, 6, 1.6), Vector3(3, 12, 3))
		box(Vector3(0, 12.6, 1.6), Vector3(0.2, 1.4, 0.2), DARK, cxf)
		box(Vector3(0, 12.8, 1.6), Vector3(0.8, 0.2, 0.2), DARK, cxf)
		# Stone entrance steps, tall wooden double doors with brass handles, and stained-glass windows
		box(Vector3(0, 0.16, 3.6), Vector3(3.4, 0.32, 1.2), PAVEMENT, cxf)
		box(Vector3(0, 1.45, 3.12), Vector3(1.9, 2.5, 0.12), Color(0.36, 0.20, 0.10), cxf)
		box(Vector3(0, 1.45, 3.18), Vector3(0.06, 2.5, 0.04), DARK, cxf)
		box(Vector3(-0.22, 1.35, 3.20), Vector3(0.08, 0.24, 0.06), Color(0.95, 0.78, 0.22), cxf)
		box(Vector3(0.22, 1.35, 3.20), Vector3(0.08, 0.24, 0.06), Color(0.95, 0.78, 0.22), cxf)
		for wx_s in [-4.54, 4.54]:
			for wz_s in [-9.5, -6.0, -2.5]:
				box(Vector3(wx_s, 3.6, wz_s), Vector3(0.10, 2.6, 1.1), Color(0.35, 0.62, 0.95), cxf, "win")
		# Outdoor church bench & congregation + Pastor greeting at the entrance
		box(Vector3(-2.6, 0.42, 4.4), Vector3(2.2, 0.14, 0.55), WOOD, cxf)
		var pastor := make_person(false, "pastor", false, cxf * Vector3(0.0, 0.32, 3.9))
		pastor.rotation.y = (cxf.basis * Vector3(0, 0, -1)).angle_to(Vector3.FORWARD)
		for ci in 4:
			var ch_pos := cxf * Vector3(-2.4 + ci * 1.4, 0.02, 4.8 + (ci % 2) * 0.8)
			make_person(ci % 2 == 0, "gomesi" if ci % 2 == 0 else "kanzu", false, ch_pos)
		var cn := "%s %s" % [_pick(["St. Peter's", "Gospel", "Miracle Centre", "Redeemed", "Mount Zion", "St. Mary's", "Full Gospel"]), "Church"]
		sign_text(cn, PAINT, cxf * Transform3D(Basis.IDENTITY, Vector3(0, 3.5, 3.15)), 3.0)
		add_place(cn, cxf * Vector3(0, 0, 5.2), dn)
		music_spots.append({"pos": cxf * Vector3(0, 0, 3.5), "kind": "church"})
	else:
		for i in 7:
			tree(rng.randi_range(0, 2), Transform3D(Basis(Vector3.UP, rng.randf() * TAU), c + Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-10, 10))))


func _build_boda_stage(p: Vector3, dir: float) -> void:
	for i in 7:
		var q := p + Vector3(0, 0, i * 1.3 * dir)
		bake_parts(model_boda(i % 3 != 2, false), Transform3D(Basis(Vector3.UP, -PI / 2 - 0.6), q))
	collide(Transform3D.IDENTITY, p + Vector3(0, 0.42, 3.9 * dir), Vector3(1.8, 1.2, 9.2))
	_idle_person(p + Vector3(0.6, 0, 9.6 * dir), 0.5)
	_idle_person(p + Vector3(-0.2, 0, 10.2 * dir), -2.5)
	add_place("the boda stage", p + Vector3(-2.2, -0.18, 4.0 * dir), "Downtown")


func _build_street_lights() -> void:
	for e in edges:
		var p1: Vector3 = nodes[e[0]]
		var p2: Vector3 = nodes[e[1]]
		var mid := (p1 + p2) * 0.5
		var d := (p2 - p1).normalized()
		var perp := Vector3(d.z, 0, -d.x)
		if absf((mid + perp * 10).x) > HALF or absf((mid + perp * 10).z) > HALF:
			perp = -perp   # keep lights on the city side of the edge roads
		var base := mid + perp * 4.3 + Vector3(0, 0.18, 0)
		_add("solid", _cyl(0.07, 0.1, 6.5, 6), Transform3D(Basis.IDENTITY, base + Vector3(0, 3.25, 0)), GREY)
		var arm_size := Vector3(0.1, 0.1, 1.5) if absf(perp.z) > 0.5 else Vector3(1.5, 0.1, 0.1)
		box(base + Vector3(0, 6.45, 0) - perp * 0.7, arm_size, GREY)
		box(base + Vector3(0, 6.35, 0) - perp * 1.35, Vector3(0.45, 0.12, 0.45), Color(0.9, 0.85, 0.7), Transform3D.IDENTITY, "lamp")
		_light_pool(mid + perp * 2.95 + Vector3(0, 0.07, 0), 11.0)
		# Lush boulevard palm trees & tropical banana plants lining sunny Kampala avenues!
		for off_t in [-14.0, 14.0]:
			var tp: Vector3 = mid + d * float(off_t) + perp * 5.25 + Vector3(0, 0.16, 0)
			if absf(tp.x) < HALF - 4.0 and absf(tp.z) < HALF - 4.0:
				var tk := 0 if rng.randf() < 0.72 else 2
				bake_parts(model_tree(tk), Transform3D(Basis(Vector3.UP, rng.randf() * TAU), tp))


func _build_petrol_station(c: Vector3) -> void:
	# a generic fuel station (no real brand)
	box(c + Vector3(0, 0.02, 0), Vector3(14, 0.04, 11), PAVEMENT.darkened(0.1))
	for px in [-4.5, 4.5]:
		for pz in [-2.6, 2.6]:
			box(c + Vector3(px, 2.4, pz - 1.4), Vector3(0.35, 4.8, 0.35), PAINT)
			collide(Transform3D.IDENTITY, c + Vector3(px, 1.5, pz - 1.4), Vector3(0.4, 3.0, 0.4))
	box(c + Vector3(0, 4.9, -1.4), Vector3(11, 0.5, 7), Color(0.1, 0.55, 0.3))
	box(c + Vector3(0, 4.9, -1.4 - 3.52), Vector3(11, 0.5, 0.06), Color(1.0, 0.8, 0.1))
	box(c + Vector3(0, 4.62, -1.4), Vector3(10, 0.05, 6), Color(0.95, 0.95, 0.9), Transform3D.IDENTITY, "lamp")
	for px in [-2.0, 2.0]:
		box(c + Vector3(px, 0.15, -1.4), Vector3(1.2, 0.3, 0.8), PAVEMENT)
		box(c + Vector3(px, 0.95, -1.4), Vector3(0.6, 1.3, 0.45), Color(0.1, 0.55, 0.3))
		box(c + Vector3(px, 1.35, -1.17), Vector3(0.4, 0.3, 0.04), Color(0.2, 0.25, 0.3))
		collide(Transform3D.IDENTITY, c + Vector3(px, 0.7, -1.4), Vector3(1.2, 1.4, 0.8))
	# Two uniformed Petrol Station Attendants ready to serve riders + red safety bucket stand
	var att1 := make_person(false, "attendant", false, c + Vector3(-1.1, 0.04, -1.4))
	att1.rotation.y = -PI * 0.4
	var att2 := make_person(true, "attendant", false, c + Vector3(2.9, 0.04, -1.4))
	att2.rotation.y = PI * 0.4
	box(c + Vector3(-3.6, 0.55, -1.4), Vector3(0.7, 1.1, 0.35), Color(0.86, 0.16, 0.14))
	box(c + Vector3(0, 1.5, 4.0), Vector3(8, 3.0, 3), WALLS[6])
	box(c + Vector3(0, 1.3, 2.47), Vector3(5, 2.0, 0.08), SHOP_DARK, Transform3D.IDENTITY, "win")
	box(c + Vector3(0, 3.2, 2.5), Vector3(8, 0.4, 0.1), Color(0.1, 0.55, 0.3))
	sign_text("FUEL  -  Petrol  Diesel  Oil", Color(0.1, 0.55, 0.3), Transform3D(Basis.IDENTITY, c + Vector3(0, 3.2, 2.56)), 7.0)
	collide(Transform3D.IDENTITY, c + Vector3(0, 1.5, 4.0), Vector3(8, 3.0, 3))
	box(c + Vector3(-6.0, 3.5, -6.5), Vector3(0.3, 7, 0.3), GREY)
	box(c + Vector3(-6.0, 6.6, -6.5), Vector3(2.2, 1.6, 0.25), Color(1.0, 0.8, 0.1))
	_light_pool(c + Vector3(0, 0.08, -1.4), 14.0)
	pumps.append(c + Vector3(0, 0, -1.4))
	add_place("the fuel station", c + Vector3(0, 0, -6.0), "Fuel Station")


func _build_nakasero(c: Vector3, dn: String) -> void:
	# Nakasero Hill: modern multi-storey office towers, manicured gardens & ministries
	box(c + Vector3(0, 0.02, 0), Vector3(28, 0.04, 24), LEAF.lerp(PAVEMENT, 0.35))
	var floors := rng.randi_range(6, 9)
	var h := floors * 3.1
	var w := 15.0
	var d := 12.0
	var wall_col: Color = _pick([WALLS[6], WALLS[11], Color(0.84, 0.86, 0.90)])
	box(c + Vector3(0, h * 0.5, 0), Vector3(w, h, d), wall_col)
	collide(Transform3D.IDENTITY, c + Vector3(0, h * 0.5, 0), Vector3(w, h, d))
	# Glass curtain wall bands on front & back facades
	for f in range(1, floors):
		var fy := f * 3.1 + 1.4
		for sz in [-d * 0.5 - 0.04, d * 0.5 + 0.04]:
			box(c + Vector3(0, fy, sz), Vector3(w - 1.6, 1.55, 0.06), Color(0.22, 0.38, 0.55), Transform3D.IDENTITY, "win")
	# Rooftop penthouse mechanical box & telecom mast
	box(c + Vector3(0, h + 1.1, 0), Vector3(6.5, 2.2, 5.0), GREY)
	_add("solid", _cyl(0.08, 0.14, 5.5, 6), Transform3D(Basis.IDENTITY, c + Vector3(0, h + 4.8, 0)), GREY)
	var tname := "%s %s" % [_pick(["Nakasero", "Pearl", "Rwenzori", "Crested", "Victoria", "Crane", "Kampala"]), _pick(["Towers", "House", "Plaza", "Chambers", "Heights"])]
	var sc := Color(0.12, 0.26, 0.52)
	box(c + Vector3(0, 3.6, d * 0.5 + 0.08), Vector3(w * 0.75, 0.8, 0.12), sc)
	sign_text(tname, sc, Transform3D(Basis.IDENTITY, c + Vector3(0, 3.6, d * 0.5 + 0.16)), w * 0.72)
	add_place(tname, c + Vector3(0, 0, d * 0.5 + 4.0), dn)
	for tx in [-11.0, 11.0]:
		for tz in [-8.0, 8.0]:
			tree(rng.randi_range(0, 1), Transform3D(Basis(Vector3.UP, rng.randf() * TAU), c + Vector3(tx, 0, tz)))


func _build_police_checkpoints() -> void:
	# 3 Traffic Police roadside checkpoints checking for Helmet, Reflector Vest & Riding Permit
	var cp_positions: Array[Vector3] = [
		Vector3(0, 0, -BLOCK * 0.5),
		Vector3(BLOCK, 0, BLOCK * 0.5),
		Vector3(-BLOCK, 0, -BLOCK * 0.5),
	]
	for cp: Vector3 in cp_positions:
		checkpoints.append(cp)
		# Roadside orange-and-white traffic cones
		for ci in 4:
			var cz: float = cp.z - 4.5 + ci * 3.0
			var cpos := Vector3(cp.x - 3.3, 0.02, cz)
			_add("solid", _cyl(0.04, 0.24, 0.62, 6), Transform3D(Basis.IDENTITY, cpos + Vector3(0, 0.31, 0)), Color(0.96, 0.32, 0.06))
			_add("solid", _cyl(0.10, 0.15, 0.16, 6), Transform3D(Basis.IDENTITY, cpos + Vector3(0, 0.35, 0)), PAINT)
		# Police check signboard on shoulder
		var sbase: Vector3 = cp + Vector3(-4.5, 0.18, 0)
		box(sbase + Vector3(0, 0.9, 0), Vector3(0.08, 1.8, 0.08), GREY)
		box(sbase + Vector3(0, 1.55, 0), Vector3(0.12, 0.55, 1.5), Color(0.12, 0.25, 0.68))
		sign_text("TRAFFIC POLICE CHECK", Color(0.12, 0.25, 0.68), Transform3D(Basis(Vector3.UP, PI / 2), sbase + Vector3(0.08, 1.55, 0)), 1.4)
		# Two white-uniformed Uganda Traffic Police officers on duty
		var cop1 := make_person(false, "police", false, cp + Vector3(-3.6, 0.03, -1.2))
		cop1.rotation.y = PI * 0.45
		var cop2 := make_person(true, "police", false, cp + Vector3(-4.2, 0.18, 1.4))
		cop2.rotation.y = PI * 0.55


func _build_outskirts() -> void:
	# Lake Victoria shoreline & Ggaba / Port Bell Pier along the southern edge of Kampala (z > HALF + 14)
	var lake_z := HALF + 82.0
	box(Vector3(0, 0.02, HALF + 22.0), Vector3(680, 0.06, 22.0), Color(0.78, 0.67, 0.45), Transform3D.IDENTITY, "far")
	box(Vector3(0, 0.01, lake_z), Vector3(840, 0.04, 130.0), Color(0.08, 0.44, 0.76), Transform3D.IDENTITY, "water")
	# Wooden Ggaba Pier extending out over the water at x = 0
	var pier_z := HALF + 26.0
	box(Vector3(0, 0.35, pier_z), Vector3(6.5, 0.22, 28.0), WOOD)
	for pz in 7:
		for px in [-2.8, 2.8]:
			box(Vector3(px, 0.0, pier_z - 12.0 + pz * 4.0), Vector3(0.28, 1.1, 0.28), DARK)
	# Colourful wooden Lake Victoria fishing boats moored by the pier
	for bx in [-18.0, -9.5, 9.5, 19.0, 29.0]:
		var bpos := Vector3(bx, 0.05, HALF + 34.0 + rng.randf_range(-4.0, 6.0))
		var bcol: Color = _pick([Color(0.15, 0.48, 0.85), Color(0.88, 0.22, 0.16), Color(0.18, 0.68, 0.34), Color(0.95, 0.75, 0.12)])
		var bxf := Transform3D(Basis(Vector3.UP, rng.randf_range(-0.35, 0.35)), bpos)
		box(Vector3(0, 0.22, 0), Vector3(1.5, 0.45, 4.8), bcol, bxf)
		box(Vector3(0, 0.38, 0), Vector3(1.2, 0.12, 3.8), WOOD, bxf)
	# Lakeside tilapia fish stalls, beach loungers & umbrellas near the sand
	for sx in [-12.0, -5.0, 6.0, 13.0]:
		var sp := Vector3(sx, 0.02, HALF + 15.5)
		bake_parts(model_umbrella(_pick(SIGNS), 2.5, 1.8), Transform3D(Basis.IDENTITY, sp))
		box(sp + Vector3(1.1, 0.20, 0.8), Vector3(0.85, 0.22, 1.75), Color(0.92, 0.90, 0.85))
		_idle_person(sp + Vector3(0, 0, -1.0), PI)
	# Swimmers actively swimming in shallow Lake Victoria off Ggaba Beach
	for swx in [-9.0, 7.5, 16.0]:
		var sw := make_person(swx > 0, "swim", false, Vector3(swx, -0.35, HALF + 36.5 + rng.randf_range(0.0, 6.0)))
		sw.body.rotation.x = -1.08
		lake_swimmers.append(sw)
	sign_text("GGABA BEACH & LAKE VICTORIA PIER", Color(0.09, 0.38, 0.68), Transform3D(Basis(Vector3.UP, PI), Vector3(0, 2.6, HALF + 11.0)), 9.5)
	box(Vector3(0, 2.6, HALF + 11.08), Vector3(10.0, 0.75, 0.12), Color(0.09, 0.38, 0.68))
	for px in [-4.2, 4.2]:
		box(Vector3(px, 1.3, HALF + 11.08), Vector3(0.18, 2.6, 0.18), GREY)
	add_place("Ggaba Beach & Pier", Vector3(0, 0, HALF + 14.5), "Old Taxi Park")

	# Expandable Suburbs, Ugandan Red Murram/Mud Feeder Roads & 4 Inter-District Highways
	_build_suburbs_and_highways()


func _add_highway_gantry(pos: Vector3, rot_y: float, text: String) -> void:
	var xf := Transform3D(Basis(Vector3.UP, rot_y), pos)
	for gx in [-5.8, 5.8]:
		box(Vector3(gx, 3.1, 0), Vector3(0.32, 6.2, 0.32), GREY, xf)
		collide(xf, Vector3(gx, 1.5, 0), Vector3(0.45, 3.0, 0.45))
	box(Vector3(0, 5.85, 0), Vector3(12.0, 0.25, 0.25), GREY, xf)
	box(Vector3(0, 5.85, 0.16), Vector3(10.6, 1.45, 0.14), Color(0.05, 0.42, 0.18), xf)
	sign_text(text, Color.WHITE, xf * Transform3D(Basis.IDENTITY, Vector3(0, 5.85, 0.28)), 10.0)
	sign_text(text, Color.WHITE, xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 5.85, -0.28)), 10.0)


func _add_banana_patch(center: Vector3, count: int) -> void:
	for k in count:
		var bp := center + Vector3(rng.randf_range(-7.0, 7.0), 0.0, rng.randf_range(-7.0, 7.0))
		var h := rng.randf_range(2.6, 3.8)
		_add("city", _cyl(0.10, 0.16, h, 6), Transform3D(Basis.IDENTITY, bp + Vector3(0, h * 0.5, 0)), Color(0.36, 0.48, 0.22))
		for lf in 5:
			var ang := lf * TAU / 5.0 + rng.randf_range(-0.2, 0.2)
			var lxf := Transform3D(Basis(Vector3.UP, ang) * Basis(Vector3.RIGHT, 0.52), bp + Vector3(sin(ang) * 0.9, h - 0.1, cos(ang) * 0.9))
			box(Vector3.ZERO, Vector3(0.55, 0.06, 1.9), Color(0.18, 0.56, 0.16), lxf)


func _add_suburb_bungalow(xf: Transform3D) -> void:
	var wcol: Color = _pick([Color(0.92, 0.86, 0.74), Color(0.88, 0.78, 0.66), Color(0.82, 0.86, 0.88), Color(0.76, 0.42, 0.28)])
	var rcol: Color = _pick([Color(0.52, 0.14, 0.12), Color(0.14, 0.34, 0.22), Color(0.18, 0.26, 0.42), Color(0.56, 0.32, 0.18)])
	# Perimeter wall & gate
	box(Vector3(0, 0.95, -5.8), Vector3(11.0, 1.9, 0.22), Color(0.78, 0.74, 0.68), xf)
	box(Vector3(-5.5, 0.95, 0), Vector3(0.22, 1.9, 11.6), Color(0.78, 0.74, 0.68), xf)
	box(Vector3(5.5, 0.95, 0), Vector3(0.22, 1.9, 11.6), Color(0.78, 0.74, 0.68), xf)
	box(Vector3(0, 0.95, 5.8), Vector3(3.2, 1.9, 0.26), Color(0.16, 0.22, 0.28), xf)
	# House & pitched iron-sheet roof
	box(Vector3(0, 1.75, -0.8), Vector3(7.6, 3.5, 6.2), wcol, xf)
	box(Vector3(0, 3.85, -0.8), Vector3(8.4, 0.55, 7.0), rcol, xf)
	box(Vector3(0, 4.35, -0.8), Vector3(6.2, 0.48, 4.8), rcol.darkened(0.08), xf)
	box(Vector3(0, 1.15, 2.34), Vector3(1.15, 2.2, 0.08), WOOD, xf)
	for wx in [-2.3, 2.3]:
		box(Vector3(wx, 1.95, 2.34), Vector3(1.25, 1.05, 0.08), GLASS, xf)
	collide(xf, Vector3(0, 1.8, -0.8), Vector3(8.0, 3.6, 6.6))


func _add_murram_road(center: Vector3, size_xz: Vector2, rot_y := 0.0) -> void:
	var xf := Transform3D(Basis(Vector3.UP, rot_y), center)
	# Rich red Ugandan laterite murram surface + dark wheel ruts & muddy puddles
	box(Vector3(0, 0.025, 0), Vector3(size_xz.x, 0.05, size_xz.y), MURRAM, xf, "murram")
	box(Vector3(0, 0.032, -size_xz.y * 0.22), Vector3(size_xz.x * 0.96, 0.015, 0.85), MURRAM.darkened(0.22), xf, "murram")
	box(Vector3(0, 0.032, size_xz.y * 0.22), Vector3(size_xz.x * 0.96, 0.015, 0.85), MURRAM.darkened(0.22), xf, "murram")
	for pd in 3:
		var px := rng.randf_range(-size_xz.x * 0.36, size_xz.x * 0.36)
		var pz := rng.randf_range(-size_xz.y * 0.25, size_xz.y * 0.25)
		box(Vector3(px, 0.042, pz), Vector3(rng.randf_range(2.2, 4.2), 0.01, rng.randf_range(1.3, 2.4)), Color(0.32, 0.22, 0.14), xf, "water")
	var rx := size_xz.x if absf(cos(rot_y)) > 0.5 else size_xz.y
	var rz := size_xz.y if absf(cos(rot_y)) > 0.5 else size_xz.x
	mud_zones.append(Rect2(center.x - rx * 0.5, center.z - rz * 0.5, rx, rz))
	var half_dir := Vector3(cos(rot_y), 0, -sin(rot_y)) * (size_xz.x * 0.5)
	highway_routes.append({"a": center - half_dir, "b": center + half_dir, "kind": "murram"})


func _build_suburbs_and_highways() -> void:
	var hw_len := 106.0
	var hw_mid := HALF + hw_len * 0.5
	# 1. EAST: Jinja Highway -> Mukono & Bweyogerere Suburb
	box(Vector3(hw_mid, 0.02, 0.0), Vector3(hw_len, 0.06, 11.2), ASPHALT, Transform3D.IDENTITY, "road")
	for dx in range(int(HALF + 6), int(HALF + hw_len - 4), 10):
		box(Vector3(dx, 0.06, 0.0), Vector3(4.5, 0.01, 0.24), PAINT, Transform3D.IDENTITY, "road")
	highway_routes.append({"a": Vector3(HALF, 0, 0), "b": Vector3(HALF + hw_len, 0, 0), "kind": "highway", "label": "JINJA / MUKONO →"})
	_add_highway_gantry(Vector3(HALF + 16.0, 0, 0.0), PI * 0.5, "JINJA 80 KM  •  MUKONO 21 KM  •  BWEYOGERERE")
	# Murram/Mud feeder road branching north & south into Bweyogerere / Kira Suburb
	_add_murram_road(Vector3(HALF + 54.0, 0.0, -34.0), Vector2(68.0, 7.2), PI * 0.5)
	_add_murram_road(Vector3(HALF + 54.0, 0.0, 34.0), Vector2(68.0, 7.2), PI * 0.5)
	for bz in [-52.0, -24.0, 24.0, 50.0]:
		_add_suburb_bungalow(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(HALF + 70.0, 0, bz)))
		_add_suburb_bungalow(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(HALF + 38.0, 0, bz)))
	_add_banana_patch(Vector3(HALF + 82.0, 0, -18.0), 9)
	_add_banana_patch(Vector3(HALF + 84.0, 0, 28.0), 9)
	add_place("Bweyogerere & Mukono Highway Stage", Vector3(HALF + 54.0, 0, -8.5), "Mukono / Bweyogerere")
	add_place("Kira Suburb Trading Centre", Vector3(HALF + 54.0, 0, -56.0), "Mukono / Bweyogerere")
	_idle_person(Vector3(HALF + 51.0, 0, -8.0), 0.0)
	_idle_person(Vector3(HALF + 57.0, 0, -8.2), 0.5)

	# 2. NORTH: Gulu-Bombo Highway -> Kawempe & Kisaasi Suburb
	box(Vector3(0.0, 0.02, -hw_mid), Vector3(11.2, 0.06, hw_len), ASPHALT, Transform3D.IDENTITY, "road")
	for dz in range(int(HALF + 6), int(HALF + hw_len - 4), 10):
		box(Vector3(0.0, 0.06, -dz), Vector3(0.24, 0.01, 4.5), PAINT, Transform3D.IDENTITY, "road")
	highway_routes.append({"a": Vector3(0, 0, -HALF), "b": Vector3(0, 0, -HALF - hw_len), "kind": "highway", "label": "↑ GULU / KAWEMPE"})
	_add_highway_gantry(Vector3(0.0, 0, -HALF - 16.0), 0.0, "GULU 332 KM  •  BOMBO 32 KM  •  KAWEMPE")
	_add_murram_road(Vector3(-42.0, 0.0, -HALF - 52.0), Vector2(84.0, 7.2), 0.0)
	_add_murram_road(Vector3(42.0, 0.0, -HALF - 52.0), Vector2(84.0, 7.2), 0.0)
	for kx in [-64.0, -32.0, 32.0, 64.0]:
		_add_suburb_bungalow(Transform3D(Basis.IDENTITY, Vector3(kx, 0, -HALF - 68.0)))
		muzigo(Transform3D(Basis(Vector3.UP, PI), Vector3(kx, 0, -HALF - 36.0)), 4)
	_add_banana_patch(Vector3(-48.0, 0, -HALF - 84.0), 10)
	_add_banana_patch(Vector3(48.0, 0, -HALF - 84.0), 10)
	add_place("Kawempe & Bombo Highway Stage", Vector3(8.5, 0, -HALF - 52.0), "Kawempe / Kisaasi")
	add_place("Kisaasi Matooke & Charcoal Market", Vector3(44.0, 0, -HALF - 52.0), "Kawempe / Kisaasi")
	_idle_person(Vector3(8.0, 0, -HALF - 50.0), PI * 0.5)

	# 3. WEST: Masaka-Mbarara Highway -> Nateete & Wakiso Suburb
	box(Vector3(-hw_mid, 0.02, 0.0), Vector3(hw_len, 0.06, 11.2), ASPHALT, Transform3D.IDENTITY, "road")
	for dx2 in range(int(HALF + 6), int(HALF + hw_len - 4), 10):
		box(Vector3(-dx2, 0.06, 0.0), Vector3(4.5, 0.01, 0.24), PAINT, Transform3D.IDENTITY, "road")
	highway_routes.append({"a": Vector3(-HALF, 0, 0), "b": Vector3(-HALF - hw_len, 0, 0), "kind": "highway", "label": "← MASAKA / WAKISO"})
	_add_highway_gantry(Vector3(-HALF - 16.0, 0, 0.0), PI * 0.5, "MASAKA 128 KM  •  MBARARA 268 KM  •  NATEETE")
	_add_murram_road(Vector3(-HALF - 54.0, 0.0, -36.0), Vector2(72.0, 7.2), PI * 0.5)
	_add_murram_road(Vector3(-HALF - 54.0, 0.0, 36.0), Vector2(72.0, 7.2), PI * 0.5)
	# Red-brick clay kilns & timber yards along Wakiso murram road
	for kz in [-46.0, -22.0, 22.0, 46.0]:
		box(Vector3(-HALF - 72.0, 1.1, kz), Vector3(5.4, 2.2, 4.2), Color(0.68, 0.28, 0.16))
		collide(Transform3D.IDENTITY, Vector3(-HALF - 72.0, 1.1, kz), Vector3(5.6, 2.2, 4.4))
		_add_suburb_bungalow(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-HALF - 38.0, 0, kz)))
	_add_banana_patch(Vector3(-HALF - 86.0, 0, 0.0), 10)
	add_place("Nateete & Masaka Highway Stage", Vector3(-HALF - 54.0, 0, 8.5), "Nateete / Wakiso")
	add_place("Wakiso Brick Kilns & Timber Yard", Vector3(-HALF - 64.0, 0, -36.0), "Nateete / Wakiso")
	_idle_person(Vector3(-HALF - 52.0, 0, 8.2), PI)

	# 4. SOUTH-WEST: Entebbe Airport Highway (Kajjansi)
	box(Vector3(-BLOCK, 0.02, HALF + 16.0), Vector3(11.2, 0.06, 32.0), ASPHALT, Transform3D.IDENTITY, "road")
	highway_routes.append({"a": Vector3(-BLOCK, 0, HALF), "b": Vector3(-BLOCK, 0, HALF + 32.0), "kind": "highway", "label": "↓ ENTEBBE / KAJJANSI"})
	_add_highway_gantry(Vector3(-BLOCK, 0, HALF + 10.0), 0.0, "ENTEBBE AIRPORT 35 KM  •  KAJJANSI")
	add_place("Kajjansi Entebbe Highway Stage", Vector3(-BLOCK + 7.5, 0, HALF + 18.0), "Kajjansi / Entebbe Rd")


func _build_roadworks() -> void:
	var sites := [
		{"pos": Vector3(-BLOCK * 0.5, 0.0, 0.0), "dir": 0.0, "label": "Entebbe Rd • KCCA Repairs"},
		{"pos": Vector3(BLOCK * 0.5, 0.0, -BLOCK), "dir": 0.0, "label": "Jinja Rd • Tarmac Patching"},
		{"pos": Vector3(0.0, 0.0, -BLOCK * 0.5), "dir": PI * 0.5, "label": "Bombo Rd • Drainage Works"},
	]
	var orange := Color(0.98, 0.42, 0.06)
	var sign_yellow := Color(0.98, 0.80, 0.12)
	for s in sites:
		var c: Vector3 = s["pos"]
		var rot_y: float = s["dir"]
		var xf := Transform3D(Basis(Vector3.UP, rot_y), c)
		roadwork_zones.append({"pos": c, "radius": 11.5, "label": s["label"]})
		# Fresh gravel/tarmac patch on roadside lane
		box(Vector3(0, 0.03, 2.2), Vector3(11.0, 0.06, 2.6), Color(0.22, 0.20, 0.18), xf)
		# Traffic cones & red/white barriers funneling vehicles
		for kx in [-5.5, -2.8, 0.0, 2.8, 5.5]:
			_add("city", _cyl(0.06, 0.24, 0.55, 8), xf * Transform3D(Basis.IDENTITY, Vector3(kx, 0.28, 0.75)), orange)
			_add("city", _cyl(0.11, 0.15, 0.12, 8), xf * Transform3D(Basis.IDENTITY, Vector3(kx, 0.34, 0.75)), Color.WHITE)
		box(Vector3(-3.6, 0.48, 1.05), Vector3(2.4, 0.24, 0.12), orange, xf)
		box(Vector3(3.6, 0.48, 1.05), Vector3(2.4, 0.24, 0.12), Color.WHITE, xf)
		collide(xf, Vector3(-3.6, 0.5, 1.05), Vector3(2.4, 1.0, 0.5))
		collide(xf, Vector3(3.6, 0.5, 1.05), Vector3(2.4, 1.0, 0.5))
		# Roadside warning signs: "DRIVE SLOWLY • WORK AHEAD"
		for side_x in [-7.6, 7.6]:
			var sxf := xf * Transform3D(Basis(Vector3.UP, PI * 0.5 if side_x < 0 else -PI * 0.5), Vector3(side_x, 0, 3.8))
			box(Vector3(0, 1.0, 0), Vector3(0.08, 2.0, 0.08), GREY, sxf)
			box(Vector3(0, 1.85, 0.03), Vector3(2.4, 0.85, 0.08), sign_yellow, sxf)
			sign_text("DRIVE SLOWLY\nWORK AHEAD", DARK, sxf * Transform3D(Basis.IDENTITY, Vector3(0, 1.85, 0.10)), 2.2)
		# Active KCCA workers & tarmac drums
		_add("city", _cyl(0.32, 0.32, 0.88, 10), xf * Transform3D(Basis.IDENTITY, Vector3(-1.2, 0.44, 2.6)), orange)
		_add("city", _cyl(0.32, 0.32, 0.88, 10), xf * Transform3D(Basis.IDENTITY, Vector3(-0.3, 0.44, 2.8)), DARK)
		_idle_person((xf * Transform3D(Basis.IDENTITY, Vector3(1.6, 0.0, 2.3))).origin, rot_y)
		_idle_person((xf * Transform3D(Basis.IDENTITY, Vector3(-2.4, 0.0, 2.5))).origin, rot_y + 1.2)


func _build_wash_bays() -> void:
	var bays := [
		{"pos": Vector3(-BLOCK + 12.0, 0.0, 6.2), "rot": 0.0, "name": "Old Taxi Park Boda & Car Wash Bay", "dist": "Old Taxi Park"},
		{"pos": Vector3(BLOCK - 12.0, 0.0, -BLOCK + 6.2), "rot": 0.0, "name": "Jinja Rd Express Washing Bay", "dist": "Nakawa & Lugogo"},
		{"pos": Vector3(-6.2, 0.0, -BLOCK - 12.0), "rot": PI * 0.5, "name": "Wandegeya Sparkling Wash Bay", "dist": "Wandegeya & Makerere"},
	]
	var water_blue := Color(0.12, 0.52, 0.88)
	for b in bays:
		var c: Vector3 = b["pos"]
		var rot_y: float = b["rot"]
		var xf := Transform3D(Basis(Vector3.UP, rot_y), c)
		wash_bays.append(c)
		add_place(b["name"], c, b["dist"])
		# Wet concrete wash pad & drainage strip
		box(Vector3(0, 0.03, 0), Vector3(6.8, 0.06, 4.6), Color(0.18, 0.26, 0.34), xf)
		box(Vector3(0, 0.065, 0), Vector3(5.8, 0.01, 3.6), Color(0.24, 0.44, 0.62), xf)
		# Elevated blue water tank on steel legs + soap buckets
		for lx in [-2.6, -1.8]:
			for lz in [-1.6, -0.8]:
				box(Vector3(lx, 0.9, lz), Vector3(0.10, 1.8, 0.10), GREY, xf)
		_add("city", _cyl(0.68, 0.68, 1.35, 12), xf * Transform3D(Basis.IDENTITY, Vector3(-2.2, 2.45, -1.2)), water_blue)
		_add("city", _cyl(0.22, 0.18, 0.36, 10), xf * Transform3D(Basis.IDENTITY, Vector3(1.8, 0.22, 1.2)), CURB_YELLOW)
		_add("city", _cyl(0.22, 0.18, 0.36, 10), xf * Transform3D(Basis.IDENTITY, Vector3(2.3, 0.22, 1.0)), water_blue)
		# Car being washed on the pad + attendant
		bake_parts(model_car(Color(0.86, 0.88, 0.92)), xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.4, 0.04, -0.2)))
		collide(xf, Vector3(0.4, 0.8, -0.2), Vector3(4.1, 1.6, 1.9))
		collide(xf, Vector3(-2.2, 1.0, -1.2), Vector3(1.4, 2.0, 1.4))
		_idle_person((xf * Transform3D(Basis.IDENTITY, Vector3(0.8, 0.0, 1.25))).origin, rot_y + PI)
		_idle_person((xf * Transform3D(Basis.IDENTITY, Vector3(-0.9, 0.0, 1.15))).origin, rot_y + PI * 0.7)
		# Overhead Wash Bay signboard
		for px in [-2.8, 2.8]:
			box(Vector3(px, 1.4, -2.0), Vector3(0.14, 2.8, 0.14), GREY, xf)
		box(Vector3(0, 2.85, -2.0), Vector3(6.2, 0.85, 0.14), water_blue, xf)
		sign_text("BODA & CAR WASH BAY • UGX 2,000", Color.WHITE, xf * Transform3D(Basis.IDENTITY, Vector3(0, 2.85, -1.90)), 5.8)


func _build_hills() -> void:
	# Kampala's famous Seven Hills on the distant golden horizon — follows the horizon so endless roads never collide with hills!
	horizon_hills = Node3D.new()
	add_child(horizon_hills)
	var hb = Baker.new()
	for i in 10:
		var a := i * TAU / 10.0 + rng.randf_range(-0.08, 0.08)
		var dist := rng.randf_range(385.0, 445.0)
		var r := rng.randf_range(68.0, 98.0)
		var sy := rng.randf_range(0.36, 0.50)
		var c := Vector3(sin(a) * dist, -8.0, cos(a) * dist)
		if c.z > HALF + 85.0 and absf(c.x) < 190.0:
			continue   # keep southern Lake Victoria horizon open!
		if absf(c.z) < 95.0 or absf(c.x) < 95.0:
			c += c.normalized() * 55.0   # keep cardinal highway vistas open!
		var hill_col := LEAF2.lerp(MURRAM, 0.28 if i % 2 == 0 else 0.16)
		hb.add(_sphere(r, r * 2.0, 12, 6), Transform3D(Basis.IDENTITY.scaled(Vector3(1, sy, 1)), c), hill_col)
		for k in 50:
			var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.28, 1.0), rng.randf_range(-1, 1)).normalized()
			var hp := c + Vector3(dir.x * r, dir.y * r * sy, dir.z * r)
			hb.add(_box_mesh(Vector3(3.6, 2.6, 3.6)), Transform3D(Basis.IDENTITY, hp), _pick([Color(0.95, 0.90, 0.80), Color(0.92, 0.84, 0.72), Color(0.76, 0.36, 0.24), Color(0.24, 0.48, 0.24)]))
		if i == 5:   # Old Kampala Hill — Golden-domed Gaddafi National Mosque
			var top := c + Vector3(0, r * sy - 1.0, 0)
			hb.add(_box_mesh(Vector3(18, 11, 18)), Transform3D(Basis.IDENTITY, top + Vector3(0, 5.5, 0)), Color(0.96, 0.91, 0.78))
			hb.add(_sphere(7.5, 11.0, 12, 6), Transform3D(Basis.IDENTITY, top + Vector3(0, 12.5, 0)), Color(0.98, 0.80, 0.22))
			for mx in [-11.0, 11.0]:
				hb.add(_cyl(0.85, 1.15, 24.0, 8), Transform3D(Basis.IDENTITY, top + Vector3(mx, 12.0, 0)), Color(0.96, 0.91, 0.78))
				hb.add(_sphere(1.2, 2.0, 8, 4), Transform3D(Basis.IDENTITY, top + Vector3(mx, 24.5, 0)), Color(0.98, 0.80, 0.22))
		if i == 3 or i == 7:   # Namirembe & Rubaga Cathedrals
			var top2 := c + Vector3(0, r * sy - 1.0, 0)
			hb.add(_box_mesh(Vector3(10, 10, 18)), Transform3D(Basis.IDENTITY, top2 + Vector3(0, 5.0, 0)), Color(0.94, 0.89, 0.82))
			hb.add(_sphere(5.5, 8.0, 10, 5), Transform3D(Basis.IDENTITY, top2 + Vector3(0, 11.0, 0)), Color(0.76, 0.32, 0.20))
	var hmi := MeshInstance3D.new()
	hmi.mesh = hb.build()
	hmi.material_override = _mat()
	hmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	horizon_hills.add_child(hmi)


# =============================================================== traffic & people
var _car_beam_mesh: PrismMesh
var _boda_beam_mesh: PrismMesh
var _shadow_mat: StandardMaterial3D

func _attach_contact_shadow(parent: Node3D, w: float, l: float) -> void:
	if _shadow_mat == null:
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, 0.56))
		g.add_point(0.58, Color(0, 0, 0, 0.30))
		g.set_color(2, Color(0, 0, 0, 0.0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 64
		gt.height = 64
		_shadow_mat = StandardMaterial3D.new()
		_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shadow_mat.albedo_texture = gt
		_shadow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, l)
	var sh := MeshInstance3D.new()
	sh.mesh = pm
	sh.material_override = _shadow_mat
	sh.position = Vector3(0, 0.042, 0)
	sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sh.visibility_range_end = 110.0
	parent.add_child(sh)


func _spawn_car(parts: Array, kind: String, spd: float, lane: float, weave: float) -> void:
	var b = Baker.new()
	for p in parts:
		b.add(p[0], p[1], p[2])
	var mi := MeshInstance3D.new()
	mi.mesh = b.build()
	mi.scale = Vector3.ONE * (1.18 if kind == "boda" else 1.08)
	mi.material_override = mat_agent
	mi.visibility_range_end = 170.0
	if _car_beam_mesh == null:
		var cmat := StandardMaterial3D.new()
		cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cmat.albedo_color = Color(1.0, 0.90, 0.62, 0.19)
		cmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_car_beam_mesh = PrismMesh.new()
		_car_beam_mesh.size = Vector3(3.6, 6.8, 0.03)
		_car_beam_mesh.material = cmat
		_boda_beam_mesh = PrismMesh.new()
		_boda_beam_mesh.size = Vector3(2.4, 5.2, 0.03)
		_boda_beam_mesh.material = cmat
	var beam := MeshInstance3D.new()
	beam.mesh = _boda_beam_mesh if kind == "boda" else _car_beam_mesh
	beam.transform = Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0, 0.05, -3.4 if kind == "boda" else -5.4))
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.visibility_range_end = 90.0
	beam.visible = false
	mi.add_child(beam)
	var car: Node3D = Car.new()
	car.add_child(mi)
	car.body = mi
	car.headlight = beam
	car.kind = kind
	car.speed = spd
	car.lane = lane
	car.weave = weave
	car.length = mi.mesh.get_aabb().size.z * mi.scale.z
	var sw := 1.05 if kind == "boda" else (2.75 if kind in ["bus", "trailer"] else 2.15)
	_attach_contact_shadow(car, sw, car.length * 1.08)
	car.set_meta("kind", kind)
	car.add_to_group("agents")
	add_child(car)
	var e: Array = edges[rng.randi() % edges.size()]
	var rev := rng.randf() < 0.5
	var frac := rng.randf_range(0.08, 0.92)
	# Pick a clear non-overlapping spawn slot on the road network
	for attempt in 18:
		var cand: Array = edges[rng.randi() % edges.size()]
		var mid: Vector3 = ((nodes[cand[0]] as Vector3) + (nodes[cand[1]] as Vector3)) * 0.5
		if attempt < 10 and (absf(mid.x) > BLOCK + 1.0 or absf(mid.z) > BLOCK + 1.0):
			continue
		var c_rev := rng.randf() < 0.5
		var c_frac := rng.randf_range(0.10, 0.90)
		var p_a: Vector3 = nodes[cand[1] if c_rev else cand[0]]
		var p_b: Vector3 = nodes[cand[0] if c_rev else cand[1]]
		var test_p := p_a.lerp(p_b, c_frac)
		var clear := true
		for ex_v in vehicles:
			if is_instance_valid(ex_v) and ex_v.position.distance_squared_to(test_p) < 13.5 * 13.5:
				clear = false
				break
		if clear:
			e = cand
			rev = c_rev
			frac = c_frac
			break
	if not rev:
		car.setup(self, e[0], e[1], frac)
	else:
		car.setup(self, e[1], e[0], frac)
	vehicles.append(car)
	obstacles.append(car)


func _spawn_traffic() -> void:
	# Uganda drives on the LEFT: lane offsets are to the left of travel
	for i in 22:
		_spawn_car(model_taxi(), "taxi", rng.randf_range(6.8, 7.8), 1.9, 0.0)
	for i in 18:
		_spawn_car(model_car(_pick([Color(0.85, 0.85, 0.88), Color(0.15, 0.2, 0.35), Color(0.7, 0.1, 0.1), Color(0.1, 0.1, 0.1), Color(0.6, 0.6, 0.55)])), "car", rng.randf_range(7.8, 9.2), 1.9, 0.0)
	for i in 32:
		_spawn_car(model_boda(true, rng.randf() < 0.5), "boda", rng.randf_range(9.5, 12.0), 3.0, 0.25)
	# Kampala regional & city buses (Pioneer, YY, Gateway, Link liveries)
	var bus_liveries := [
		[Color(0.08, 0.28, 0.68), Color(0.96, 0.80, 0.14)],
		[Color(0.10, 0.48, 0.22), Color(0.95, 0.96, 0.98)],
		[Color(0.72, 0.12, 0.14), Color(0.95, 0.78, 0.18)],
		[Color(0.14, 0.18, 0.34), Color(0.95, 0.45, 0.12)],
	]
	for i in 6:
		var liv: Array = bus_liveries[i % bus_liveries.size()]
		_spawn_car(model_bus(liv[0], liv[1]), "bus", rng.randf_range(5.8, 6.8), 1.85, 0.0)
	# Heavy cargo trailers & 40ft container trucks
	var trailer_cols := [
		[Color(0.75, 0.16, 0.14), Color(0.14, 0.34, 0.58)],
		[Color(0.92, 0.92, 0.94), Color(0.68, 0.24, 0.12)],
		[Color(0.14, 0.38, 0.20), Color(0.84, 0.64, 0.14)],
		[Color(0.18, 0.22, 0.28), Color(0.45, 0.48, 0.52)],
	]
	for i in 5:
		var tc: Array = trailer_cols[i % trailer_cols.size()]
		_spawn_car(model_trailer(tc[0], tc[1]), "trailer", rng.randf_range(4.8, 5.8), 1.85, 0.0)


func _spawn_pedestrians() -> void:
	for bz in N:
		for bx in N:
			var x0 := -HALF + bx * BLOCK
			var z0 := -HALF + bz * BLOCK
			var busy := 3 if district_of[Vector2i(bx, bz)] in ["downtown", "market", "taxi"] else 2
			for i in busy:
				var side := rng.randi() % 4
				var pts := PackedVector3Array()
				for k in 3:
					var t := rng.randf_range(8.0, BLOCK - 8.0)
					var off := rng.randf_range(4.6, 6.1)
					match side:
						0: pts.append(Vector3(x0 + t, 0.18, z0 + off))
						1: pts.append(Vector3(x0 + t, 0.18, z0 + BLOCK - off))
						2: pts.append(Vector3(x0 + off, 0.18, z0 + t))
						_: pts.append(Vector3(x0 + BLOCK - off, 0.18, z0 + t))
				_walker(pts)
	# people crossing the road wherever they like (very Kampala)
	for i in 18:
		var e: Array = edges[rng.randi() % edges.size()]
		var p1: Vector3 = nodes[e[0]]
		var p2: Vector3 = nodes[e[1]]
		var mid := p1.lerp(p2, rng.randf_range(0.25, 0.75))
		var d := (p2 - p1).normalized()
		var perp := Vector3(d.z, 0, -d.x)
		if absf((mid + perp * 6).x) > HALF or absf((mid + perp * 6).z) > HALF or absf((mid - perp * 6).x) > HALF or absf((mid - perp * 6).z) > HALF:
			continue
		obstacles.append(_walker(PackedVector3Array([mid + perp * 5.3 + Vector3(0, 0.1, 0), mid - perp * 5.3 + Vector3(0, 0.1, 0)])))
	# Street hawkers walking along busy junction approaches selling drinks/airtime/snacks to queued traffic
	for jpos in [Vector3(0, 0, 0), Vector3(0, 0, BLOCK), Vector3(-BLOCK, 0, 0), Vector3(BLOCK, 0, 0), Vector3(0, 0, -BLOCK)]:
		for s in [-1.0, 1.0]:
			var hpts := PackedVector3Array([
				jpos + Vector3(s * 3.6, 0.05, 7.5),
				jpos + Vector3(s * 3.6, 0.05, 22.0),
			])
			var hawker := make_person(rng.randf() < 0.5, "vendor", true, hpts[0])
			hawker.points = hpts
			hawker.mode = 1
			hawker.speed = rng.randf_range(0.95, 1.25)
			walkers.append(hawker)
			obstacles.append(hawker)


# =============================================================== junctions, pumps, sounds
## Only one vehicle crosses a junction at a time. A vehicle holding it for
## too long (stuck) loses it, so the city never locks up.
func request_junction(n: int, car: Node) -> bool:
	var o = junction_owner.get(n)
	var now := Time.get_ticks_msec()
	var last_t: int = int(junction_time.get(n, 0))
	var gap_ms: int = 1050 if is_rush_hour() else 550
	if o == car:
		return true
	if (o == null or not is_instance_valid(o)) and now - last_t >= gap_ms:
		junction_owner[n] = car
		junction_time[n] = now
		return true
	if o != null and is_instance_valid(o):
		var jpos: Vector3 = nodes[n]
		if Vector2(o.global_position.x - jpos.x, o.global_position.z - jpos.z).length() > 11.5 and now - last_t > 2500:
			junction_owner[n] = car
			junction_time[n] = now
			return true
	return false


func release_junction(n: int, car: Node) -> void:
	if junction_owner.get(n) == car:
		junction_owner.erase(n)
		junction_time[n] = Time.get_ticks_msec()


func near_pump() -> bool:
	for p in pumps:
		if Vector2(player.position.x - p.x, player.position.z - p.z).length() < 4.5:
			return true
	return false


func route_to_pump(p: Vector3, close_map := true) -> void:
	if life == null:
		return
	var dist_m := int(roundf(Vector2(player.position.x - p.x, player.position.z - p.z).length()))
	life.set_destination({
		"name": "the Petrol Station",
		"pos": Vector3(p.x, 0, p.z - 4.0),
		"district": district_at(p),
		"cat": "fuel",
	})
	if close_map and hud and hud.bigmap and hud.bigmap.visible:
		hud.bigmap.visible = false
	if sfx:
		sfx.play("chime", -3.0)
	if hud:
		hud.toast("GPS route set to Petrol Station (%d m)! Follow the blue route line." % dist_m)


func nearest_fundi_info() -> Dictionary:
	if player == null:
		return {}
	var best_pos := Vector3.ZERO
	var best_name := "Boda Fundi Mechanic"
	var best_d := 1e9
	for fp in boda_fundis:
		var d := Vector2(player.position.x - fp.x, player.position.z - fp.z).length()
		if d < best_d:
			best_d = d
			best_pos = fp
			best_name = "%s Boda Fundi" % district_at(fp)
	for pl in places:
		var nl := str(pl.get("name", "")).to_lower()
		if "fundi" in nl or "mechanic" in nl or "garage" in nl or "spare" in nl:
			var p: Vector3 = pl["pos"]
			var d2 := Vector2(player.position.x - p.x, player.position.z - p.z).length()
			if d2 < best_d:
				best_d = d2
				best_pos = p
				best_name = str(pl["name"])
	if best_d >= 1e8:
		return {}
	return {"name": best_name, "pos": best_pos, "dist": int(roundf(best_d)), "district": district_at(best_pos), "cat": "shop"}


func route_to_nearest_fundi(close_map := false) -> void:
	var info := nearest_fundi_info()
	if info.is_empty() or life == null:
		return
	life.set_destination(info)
	if close_map and hud and hud.bigmap:
		hud.bigmap.visible = false
	if sfx:
		sfx.play("chime", -3.0)
	if hud:
		hud.toast("🔧 GPS route set to %s (%d m) for boda repair!" % [info["name"], int(info["dist"])])


func find_places_by_filter(cat: String) -> Array:
	if player == null:
		return []
	var out: Array = []
	var px := player.position.x
	var pz := player.position.z
	if cat == "roads":
		for j in EW_STREETS.size():
			var z_rd: float = -HALF + j * BLOCK
			var rp := Vector3(clampf(px, -HALF, HALF), 0, z_rd)
			out.append({"name": EW_STREETS[j], "pos": rp, "district": district_at(rp), "dist": int(roundf(Vector2(px - rp.x, pz - rp.z).length())), "cat": "road"})
		for i in NS_STREETS.size():
			var x_rd: float = -HALF + i * BLOCK
			var rp2 := Vector3(x_rd, 0, clampf(pz, -HALF, HALF))
			out.append({"name": NS_STREETS[i], "pos": rp2, "district": district_at(rp2), "dist": int(roundf(Vector2(px - rp2.x, pz - rp2.z).length())), "cat": "road"})
	elif cat == "suburbs":
		for pl in places:
			var d_low := str(pl.get("district", "")).to_lower()
			var n_low := str(pl.get("name", "")).to_lower()
			if "mukono" in d_low or "kawempe" in d_low or "nateete" in d_low or "kajjansi" in d_low or "highway" in n_low or "suburb" in n_low or "ggaba" in n_low:
				var ps: Vector3 = pl["pos"]
				out.append({"name": pl["name"], "pos": ps, "district": pl.get("district", ""), "dist": int(roundf(Vector2(px - ps.x, pz - ps.z).length())), "cat": "suburbs"})
	elif cat == "wash":
		for wp in wash_bays:
			out.append({"name": "%s Washing Bay" % district_at(wp), "pos": wp, "district": district_at(wp), "dist": int(roundf(Vector2(px - wp.x, pz - wp.z).length())), "cat": "wash"})
	elif cat == "repair":
		for fp in boda_fundis:
			out.append({"name": "%s Boda Fundi" % district_at(fp), "pos": fp, "district": district_at(fp), "dist": int(roundf(Vector2(px - fp.x, pz - fp.z).length())), "cat": "repair"})
		for pl in places:
			var nl := str(pl.get("name", "")).to_lower()
			if "fundi" in nl or "mechanic" in nl or "garage" in nl or "spare" in nl:
				var p: Vector3 = pl["pos"]
				out.append({"name": pl["name"], "pos": p, "district": pl.get("district", ""), "dist": int(roundf(Vector2(px - p.x, pz - p.z).length())), "cat": "repair"})
	elif cat == "fuel":
		for p in pumps:
			out.append({"name": "%s Petrol Station" % district_at(p), "pos": p, "district": district_at(p), "dist": int(roundf(Vector2(px - p.x, pz - p.z).length())), "cat": "fuel"})
	else:
		for pl in places:
			var nl := str(pl.get("name", "")).to_lower()
			var pcat := str(pl.get("cat", ""))
			var ok := false
			match cat:
				"food":
					ok = (pcat == "food" or "restaurant" in nl or "rolex" in nl or "chapati" in nl or "juice" in nl or "muchomo" in nl or "cafe" in nl)
				"market":
					ok = (pcat == "market" or "supermarket" in nl or "market" in nl or "boutique" in nl or "hardware" in nl or "fashions" in nl)
				"church":
					ok = (pcat == "church" or "church" in nl)
				"health":
					ok = (pcat == "health" or "clinic" in nl or "pharmacy" in nl)
				"landmarks":
					ok = (pcat in ["leisure", "sport", "taxi"] or "school" in nl or "stadium" in nl or "beach" in nl or "clock tower" in nl or "taxi" in nl)
				_:
					ok = true
			if ok:
				var p: Vector3 = pl["pos"]
				out.append({"name": pl["name"], "pos": p, "district": pl.get("district", ""), "dist": int(roundf(Vector2(px - p.x, pz - p.z).length())), "cat": cat})
	out.sort_custom(func(a, b): return int(a["dist"]) < int(b["dist"]))
	return out


func _update_street_voices(delta: float) -> void:
	if paused or player == null or sfx == null:
		return
	_voice_t -= delta
	if _voice_t > 0.0:
		return
	_voice_t = randf_range(10.5, 16.5)
	var px := player.position
	# Lines come from tools/audio/voice_lines.csv (real Ugandan English + Luganda),
	# spoken by recorded ElevenLabs voices when the files exist in audio/voice/.
	var say := func(cat: String, who: String, where: Vector3) -> void:
		var line: String = sfx.say(cat, where)
		if line != "" and hud and hud.has_method("show_voice_subtitle"):
			hud.show_voice_subtitle(who, line)
	# 1. A matatu conductor calling passengers
	for v in vehicles:
		if is_instance_valid(v) and str(v.get("kind")) == "taxi" and v.visible:
			if v.global_position.distance_to(px) < 17.0:
				say.call("conductor", "🚐 Taxi Conductor", v.global_position)
				return
	# 2. Roadside sellers
	for rp in rolex_stands:
		if rp.distance_to(px) < 14.0:
			say.call("rolex", "🍳 Rolex Chef", rp)
			return
	for mp in muchomo_stands:
		if mp.distance_to(px) < 14.0:
			say.call("muchomo", "🍢 Muchomo Grill", mp)
			return
	for fc in fruit_carts:
		if fc.distance_to(px) < 12.0:
			say.call("fruit", "🍍 Juice Seller", fc)
			return
	# 3. The boda fundi (mechanic)
	for fp in boda_fundis:
		if fp.distance_to(px) < 15.0:
			say.call("fundi", "🔧 Boda Fundi", fp)
			return
	# 4. Kibanda TV halls
	for tp in tv_stands:
		if tp.distance_to(px) < 16.0:
			say.call("tv", "📺 Kibanda TV", tp)
			return
	# 5. Market sellers
	for mc in market_centres:
		if mc.distance_to(px) < 24.0:
			say.call("market", "🛒 Market Mama", mc)
			return
	# 6. Boda riders at a stage touting for customers (when you're on foot)
	if not player.on_boda and randf() < 0.35:
		for v2 in vehicles:
			if is_instance_valid(v2) and str(v2.get("kind")) == "boda" and v2.visible and v2.global_position.distance_to(px) < 10.0:
				say.call("boda", "🏍 Boda Rider", v2.global_position)
				return


func route_to_nearest_pump(close_map := false) -> void:
	if pumps.is_empty() or player == null:
		return
	var best_p: Vector3 = pumps[0]
	var best_d := 1e9
	for p in pumps:
		var d := Vector2(player.position.x - p.x, player.position.z - p.z).length()
		if d < best_d:
			best_d = d
			best_p = p
	route_to_pump(best_p, close_map)


func honk_from(pos: Vector3, kind := "car") -> void:
	if player == null or sfx == null:
		return
	var d := pos.distance_to(player.position)
	if d < 42.0:
		var hname := "horn_boda" if kind == "boda" else ("horn_taxi" if kind in ["taxi", "bus", "trailer"] else "horn_car")
		var hpitch := 0.56 if kind == "trailer" else (0.68 if kind == "bus" else randf_range(0.92, 1.08))
		sfx.play(hname, -4.5 - d * 0.35, hpitch)


func route_to_category(cat: String, close_map := true) -> void:
	if life == null or player == null:
		return
	if cat == "fuel":
		route_to_nearest_pump(close_map)
		return
	var list: Array = life.nearest(cat, player.position, 1)
	if not list.is_empty():
		var pl: Dictionary = list[0]
		var dist_m := int(roundf(Vector2(player.position.x - (pl["pos"] as Vector3).x, player.position.z - (pl["pos"] as Vector3).z).length()))
		life.set_destination(pl)
		if close_map and hud and hud.bigmap and hud.bigmap.visible:
			hud.bigmap.visible = false
		if sfx:
			sfx.play("chime", -3.0)
		if hud:
			hud.toast("GPS route set to %s (%d m)! Follow the blue route line." % [pl["name"], dist_m])


func player_horn() -> void:
	sfx.play("horn_boda", 0.0, 1.0)
	# Hooting clears the way! Nearby pedestrians step toward the pavement & bodas ahead speed up
	var fwd := Vector3(-sin(player.heading), 0, -cos(player.heading))
	var right := Vector3(cos(player.heading), 0, -sin(player.heading))
	for w in walkers:
		if not is_instance_valid(w):
			continue
		var dp: Vector3 = w.global_position - player.position
		dp.y = 0.0
		if dp.length() < 9.5 and dp.dot(fwd) > 0.0:
			var side_sign := 1.0 if dp.dot(right) >= 0.0 else -1.0
			w.position += right * side_sign * 0.85
	for v in vehicles:
		if not is_instance_valid(v):
			continue
		var vdp: Vector3 = v.global_position - player.position
		vdp.y = 0.0
		if vdp.length() < 11.0 and vdp.dot(fwd) > 0.0:
			v._stop_timer = 0.0


## Height of the ground under a point: pavements are raised, roads are flat.
func ground_height(p: Vector3) -> float:
	if absf(p.x) > HALF + 6.5 or absf(p.z) > HALF + 6.5:
		return 0.0
	var fx := absf(fposmod(p.x + HALF + BLOCK / 2, BLOCK) - BLOCK / 2)
	var fz := absf(fposmod(p.z + HALF + BLOCK / 2, BLOCK) - BLOCK / 2)
	if fx < 4.0 or fz < 4.0:
		return 0.03
	if fx < 6.5 or fz < 6.5:
		return 0.18
	return 0.0


func in_mud_road(p: Vector3) -> bool:
	var pt := Vector2(p.x, p.z)
	for r in mud_zones:
		if (r as Rect2).has_point(pt):
			return true
	return false


func district_at(p: Vector3) -> String:
	if p.x > HALF + 6.0:
		var dx := p.x - HALF
		if dx < 260.0: return "Bweyogerere & Kira Suburb"
		if dx < 580.0: return "Seeta & Namugongo Estate"
		if dx < 980.0: return "Mukono Town Council"
		return "Lugazi / Jinja Highway Corridor"
	if p.x < -HALF - 6.0:
		var dxw := -p.x - HALF
		if dxw < 260.0: return "Nateete & Lungujja Suburb"
		if dxw < 580.0: return "Buloba & Wakiso Suburb"
		if dxw < 980.0: return "Wakiso Town & Estates"
		return "Mpigi / Masaka Highway Corridor"
	if p.z < -HALF - 6.0:
		var dzn := -p.z - HALF
		if dzn < 260.0: return "Kawempe & Kisaasi Suburb"
		if dzn < 580.0: return "Matugga & Kasangati Suburb"
		if dzn < 980.0: return "Bombo Town"
		return "Wobulenzi / Luweero–Gulu Corridor"
	if p.z > HALF + 6.0:
		if p.x < -BLOCK * 0.45:
			var dzs := p.z - HALF
			return "Kajjansi Trading Centre" if dzs < 320.0 else "Kisubi / Entebbe Highway"
		return "Ggaba Beach & Lake Victoria"
	var bx := int(floor((p.x + HALF) / BLOCK))
	var bz := int(floor((p.z + HALF) / BLOCK))
	var d = district_of.get(Vector2i(bx, bz))
	return DISTRICT_NAMES.get(d, "Kampala Suburbs") if d != null else "Kampala Suburbs"


func street_at(p: Vector3) -> String:
	if in_mud_road(p):
		if p.x > HALF:
			return "Kira–Mukono Red Murram Rd"
		if p.x < -HALF:
			return "Wakiso Village Murram Rd"
		return "Kisaasi–Matugga Murram Rd"
	if p.x > HALF + 6.0:
		return "Jinja–Mukono Highway" if absf(p.z) < 28.0 else "Eastern Suburb Estate Access"
	if p.x < -HALF - 6.0:
		return "Masaka–Wakiso Highway" if absf(p.z) < 28.0 else "Western Suburb Estate Access"
	if p.z < -HALF - 6.0:
		return "Bombo–Gulu Highway" if absf(p.x) < 28.0 else "Northern Suburb Estate Access"
	if p.z > HALF + 6.0:
		return "Entebbe Airport Highway" if p.x < -BLOCK * 0.45 else "Ggaba Lakeshore Rd"
	var ix := clampi(roundi((p.x + HALF) / BLOCK), 0, NS_STREETS.size() - 1)
	var iz := clampi(roundi((p.z + HALF) / BLOCK), 0, EW_STREETS.size() - 1)
	var dx := absf(p.x - (-HALF + ix * BLOCK))
	var dz := absf(p.z - (-HALF + iz * BLOCK))
	if dx < 8.5 and dz < 8.5:
		return "%s × %s" % [EW_STREETS[iz], NS_STREETS[ix]]
	return NS_STREETS[ix] if dx < dz else EW_STREETS[iz]


func _ensure_event_marker() -> void:
	if event_marker != null:
		return
	event_marker = Node3D.new()
	add_child(event_marker)
	var gmat := StandardMaterial3D.new()
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.albedo_color = Color(1.0, 0.84, 0.12, 0.94)
	gmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color = Color(1.0, 0.82, 0.10, 0.28)
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var ring := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 2.6
	rm.bottom_radius = 2.6
	rm.height = 0.12
	rm.radial_segments = 24
	rm.material = gmat
	ring.mesh = rm
	ring.position.y = 0.28
	event_marker.add_child(ring)
	var beam := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.55
	bm.bottom_radius = 1.35
	bm.height = 20.0
	bm.radial_segments = 12
	bm.material = bmat
	beam.mesh = bm
	beam.position.y = 10.0
	event_marker.add_child(beam)
	event_marker.visible = false


func _spawn_street_event() -> void:
	_ensure_event_marker()
	var ix := randi_range(1, N - 1)
	var iz := randi_range(1, N - 1)
	var epos := Vector3(-HALF + ix * BLOCK + 4.8, 0, -HALF + iz * BLOCK - 4.8)
	var events := [
		{"title": "Telecom MoMo Promo Van", "reward": 10000, "fuel": false, "msg": "MoMo Promo Team awarded you +UGX 10,000 Cashback & +20 Mood!"},
		{"title": "Stage Chairman Rally Bonus", "reward": 8000, "fuel": true, "msg": "Stage Rally Bonus: +UGX 8,000 & a FREE Full Tank of Fuel!"},
		{"title": "Found VIP Merchant Briefcase", "reward": 12000, "fuel": false, "msg": "Honest Rider Reward! Kikuubo merchant sent +UGX 12,000 & +0.1 ★ Rating!"},
		{"title": "Kampala Wedding Convoy Tip", "reward": 9000, "fuel": false, "msg": "Wedding convoy cheered your boda & tipped +UGX 9,000 on Mobile Money!"},
	]
	var ev: Dictionary = events[randi() % events.size()]
	var st_name := "%s × %s" % [EW_STREETS[iz], NS_STREETS[ix]]
	street_event = {
		"active": true,
		"pos": epos,
		"title": ev["title"],
		"street": st_name,
		"reward": ev["reward"],
		"fuel": ev["fuel"],
		"msg": ev["msg"],
		"timer": 75.0,
	}
	event_marker.position = epos
	event_marker.visible = true
	if hud:
		hud.toast("★ STREET EVENT: %s at %s!\nTap [★] on the Map or ride there within 75s for +UGX %s!" % [ev["title"], st_name, ugx(int(ev["reward"]))])


func _update_street_event(delta: float) -> void:
	_ensure_event_marker()
	if not bool(street_event.get("active", false)):
		_event_cooldown -= delta
		if _event_cooldown <= 0.0:
			_spawn_street_event()
		return
	var rem := float(street_event.get("timer", 0.0)) - delta
	street_event["timer"] = rem
	event_marker.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.09)
	var epos: Vector3 = street_event["pos"]
	if Vector2(player.position.x - epos.x, player.position.z - epos.z).length() < 4.5:
		var rew: int = int(street_event["reward"])
		add_money(rew, "Street Event: " + str(street_event["title"]))
		day_stats["tips"] += rew
		if bool(street_event.get("fuel", false)):
			player.fuel = player.max_tank()
			player.fuel_warn_level = 0
		if life:
			life.mood = minf(100.0, life.mood + 20.0)
		adjust_rating(0.05)
		sfx.play("bonus")
		hud.toast("★ EVENT CLAIMED! " + str(street_event["msg"]))
		street_event = {"active": false}
		event_marker.visible = false
		_event_cooldown = 45.0
		_check_daily_goals()
		save_game()
	elif rem <= 0.0:
		street_event = {"active": false}
		event_marker.visible = false
		_event_cooldown = 38.0


func route_to_event(close_map := true) -> void:
	if not bool(street_event.get("active", false)) or life == null:
		hud.toast("No active Street Promo right now — keep riding, another pops up soon!")
		return
	var epos: Vector3 = street_event["pos"]
	var dist_m := int(roundf(Vector2(player.position.x - epos.x, player.position.z - epos.z).length()))
	life.set_destination({
		"name": "★ " + str(street_event["title"]),
		"pos": epos,
		"district": str(street_event.get("street", district_at(epos))),
		"cat": "event",
	})
	if close_map and hud and hud.bigmap and hud.bigmap.visible:
		hud.bigmap.visible = false
	sfx.play("chime", -2.0)
	hud.toast("GPS route set to ★ %s (%d m at %s)!" % [street_event["title"], dist_m, street_event.get("street", "")])


# =============================================================== Animated PlayKampala Intro & Setup
class IntroOverlay extends Control:
	var t := 0.0
	var progress := 0.15
	var status_text := "Building Kampala's 7 Hills, Arcades & Markets..."
	var skipped := false

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			skipped = true

	func _input(e: InputEvent) -> void:
		if e is InputEventKey and e.pressed:
			skipped = true

	func _draw() -> void:
		var s := size
		var font := get_theme_default_font()
		# 1. Warm Kampala sunset-to-twilight sky bands
		var sky_cols := [
			Color(0.06, 0.05, 0.12),
			Color(0.14, 0.07, 0.20),
			Color(0.32, 0.11, 0.24),
			Color(0.62, 0.22, 0.20),
			Color(0.92, 0.48, 0.16),
			Color(0.98, 0.72, 0.22),
		]
		var band_h := (s.y * 0.68) / sky_cols.size()
		for i in sky_cols.size():
			draw_rect(Rect2(0, i * band_h, s.x, band_h + 2.0), sky_cols[i])

		# 2. Rising Golden Sun over the Seven Hills
		var sun_pos := Vector2(s.x * 0.72, s.y * (0.42 - minf(t * 0.04, 0.08)))
		draw_circle(sun_pos, 88.0 + sin(t * 3.0) * 4.0, Color(1.0, 0.85, 0.28, 0.22))
		draw_circle(sun_pos, 64.0, Color(1.0, 0.90, 0.38, 0.92))

		# 3. Distant Kampala Hills & Skyline Silhouette
		var road_y := s.y * 0.68
		for hi in 5:
			var hx := s.x * (0.12 + hi * 0.21) - fmod(t * 12.0, s.x * 0.21)
			draw_circle(Vector2(hx, road_y + 45.0), 175.0, Color(0.13, 0.09, 0.17))

		# Scrolling skyline buildings & Queen's Way Clock Tower
		var bldgs := [
			[-420.0, 68.0, 145.0, false], [-330.0, 56.0, 110.0, false], [-250.0, 74.0, 175.0, false],
			[-150.0, 44.0, 225.0, true],  [-85.0, 66.0, 130.0, false],  [0.0, 78.0, 165.0, false],
			[95.0, 58.0, 120.0, false],   [170.0, 72.0, 185.0, false],  [260.0, 64.0, 140.0, false],
			[345.0, 70.0, 155.0, false],
		]
		var scroll := fmod(t * 38.0, 160.0)
		for b in bldgs:
			var bx := s.x * 0.5 + float(b[0]) - scroll * 0.35
			var bw := float(b[1])
			var bh := float(b[2])
			var is_clock := bool(b[3])
			draw_rect(Rect2(bx, road_y - bh, bw, bh), Color(0.09, 0.07, 0.13))
			if is_clock:
				# Clock Tower spire & glowing clock face
				var roof_pts := PackedVector2Array([
					Vector2(bx - 5, road_y - bh),
					Vector2(bx + bw * 0.5, road_y - bh - 34),
					Vector2(bx + bw + 5, road_y - bh),
				])
				draw_colored_polygon(roof_pts, Color(0.84, 0.22, 0.16))
				var cc := Vector2(bx + bw * 0.5, road_y - bh + 28.0)
				draw_circle(cc, 12.0, Color(1.0, 0.92, 0.48))
				draw_line(cc, cc + Vector2(0, -8), Color(0.1, 0.1, 0.12), 2.5)
				draw_line(cc, cc + Vector2(6, 2), Color(0.1, 0.1, 0.12), 2.5)
			else:
				# Lit arcade windows & neon rooftop strip
				draw_rect(Rect2(bx + 2, road_y - bh, bw - 4, 4), Color(0.18, 0.88, 0.98, 0.75) if int(b[0]) % 2 == 0 else Color(1.0, 0.25, 0.65, 0.75))
				var rows := int(bh / 26.0)
				for r in range(1, rows):
					for c in 3:
						if (r + c + int(absf(float(b[0])))) % 2 == 0:
							draw_rect(Rect2(bx + 10 + c * 18, road_y - bh + r * 24, 10, 12), Color(1.0, 0.84, 0.32, 0.85))

		# 4. Asphalt Street, Uganda Flag Accent & Scrolling Black/Yellow Kerbs
		draw_rect(Rect2(0, road_y, s.x, s.y - road_y), Color(0.11, 0.12, 0.15))
		var kerb_w := 36.0
		var k_off := fmod(t * 280.0, kerb_w * 2.0)
		var kx := -k_off
		var ki := 0
		while kx < s.x + kerb_w:
			draw_rect(Rect2(kx, road_y - 6.0, kerb_w, 8.0), Color(0.98, 0.78, 0.12) if ki % 2 == 0 else Color(0.10, 0.10, 0.12))
			kx += kerb_w
			ki += 1
		# Scrolling white road centre dashes
		var dx := -fmod(t * 340.0, 90.0)
		while dx < s.x + 90.0:
			draw_rect(Rect2(dx, road_y + 42.0, 46.0, 5.0), Color(0.92, 0.92, 0.88, 0.75))
			dx += 90.0

		# 5. Animated Boda-Boda Rider Rolling Across the Street
		var bike_x := s.x * 0.5 + sin(t * 2.2) * 18.0
		var bounce := sin(t * 18.0) * 2.2
		var bike_y := road_y + 26.0 + bounce
		# Glowing headlight cone
		var beam_pts := PackedVector2Array([
			Vector2(bike_x + 56, bike_y - 44),
			Vector2(bike_x + 260, bike_y - 76),
			Vector2(bike_x + 260, bike_y + 12),
		])
		draw_colored_polygon(beam_pts, Color(1.0, 0.95, 0.62, 0.26))
		# Exhaust puffs behind bike
		for pi in 3:
			var pt := fmod(t * 3.5 + pi * 0.33, 1.0)
			draw_circle(Vector2(bike_x - 62.0 - pt * 55.0, bike_y - 12.0 - pt * 14.0), 6.0 + pt * 10.0, Color(0.85, 0.85, 0.9, (1.0 - pt) * 0.35))
		# Rear & Front Spinning Wheels
		for wx in [-42.0, 44.0]:
			var wc := Vector2(bike_x + wx, bike_y)
			draw_circle(wc, 22.0, Color(0.08, 0.08, 0.10))
			draw_arc(wc, 20.0, 0, TAU, 24, Color(0.22, 0.24, 0.28), 5.0)
			draw_arc(wc, 13.0, 0, TAU, 20, Color(0.82, 0.85, 0.90), 2.5)
			for sp in 4:
				var ang := t * 14.0 + sp * PI * 0.5
				draw_line(wc + Vector2(cos(ang), sin(ang)) * 13.0, wc - Vector2(cos(ang), sin(ang)) * 13.0, Color(0.75, 0.78, 0.84), 2.0)
		# Frame, Tank, Seat & Forks
		draw_line(Vector2(bike_x - 42, bike_y), Vector2(bike_x - 8, bike_y - 34), Color(0.86, 0.16, 0.16), 7.0)
		draw_line(Vector2(bike_x - 8, bike_y - 34), Vector2(bike_x + 30, bike_y - 36), Color(0.92, 0.18, 0.18), 10.0)
		draw_line(Vector2(bike_x + 26, bike_y - 52), Vector2(bike_x + 44, bike_y), Color(0.82, 0.85, 0.90), 5.5)
		draw_circle(Vector2(bike_x + 42, bike_y - 44), 7.5, Color(1.0, 0.96, 0.72))
		# Rider in Yellow Reflector Vest & Blue Helmet
		draw_line(Vector2(bike_x - 10, bike_y - 34), Vector2(bike_x + 2, bike_y - 72), Color(0.98, 0.82, 0.12), 16.0)
		draw_line(Vector2(bike_x + 4, bike_y - 66), Vector2(bike_x + 28, bike_y - 50), Color(0.98, 0.82, 0.12), 7.0)
		draw_circle(Vector2(bike_x + 6, bike_y - 88), 13.5, Color(0.16, 0.45, 0.88))
		draw_rect(Rect2(bike_x + 10, bike_y - 92, 10, 6), Color(0.68, 0.92, 1.0))

		# 6. Title Card, Subtitle & Animated Progress Bar
		var cx := s.x * 0.5
		draw_string(font, Vector2(cx - 210, s.y * 0.17), "PLAY KAMPALA", HORIZONTAL_ALIGNMENT_CENTER, 420, 50, Color(1.0, 0.86, 0.18))
		draw_string(font, Vector2(cx - 260, s.y * 0.23), "BODA HUSTLE  •  STREET LIFE  •  SEVEN HILLS", HORIZONTAL_ALIGNMENT_CENTER, 520, 17, Color(0.96, 0.94, 0.90))
		# Uganda Flag Colours Divider Bar (Black - Yellow - Red)
		draw_rect(Rect2(cx - 120, s.y * 0.255, 80, 4), Color(0.08, 0.08, 0.10))
		draw_rect(Rect2(cx - 40, s.y * 0.255, 80, 4), Color(0.98, 0.82, 0.12))
		draw_rect(Rect2(cx + 40, s.y * 0.255, 80, 4), Color(0.88, 0.16, 0.16))

		# Bottom Progress Bar & Status
		var bw2 := 380.0
		var bx2 := cx - bw2 * 0.5
		var by2 := s.y * 0.84
		draw_rect(Rect2(bx2, by2, bw2, 12.0), Color(1, 1, 1, 0.16))
		draw_rect(Rect2(bx2, by2, bw2 * clampf(progress, 0.0, 1.0), 12.0), Color(0.98, 0.80, 0.14))
		draw_rect(Rect2(bx2, by2, bw2, 12.0), Color(1.0, 0.88, 0.35, 0.65), false, 1.5)
		draw_string(font, Vector2(cx - 260, by2 + 34.0), status_text, HORIZONTAL_ALIGNMENT_CENTER, 520, 16, Color(0.95, 0.92, 0.82))


func _ready() -> void:
	_loading = CanvasLayer.new()
	_loading.layer = 10
	var intro := IntroOverlay.new()
	intro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading.add_child(intro)
	add_child(_loading)
	await get_tree().process_frame
	await get_tree().process_frame

	var t0 := Time.get_ticks_msec()
	rng.seed = 256
	seed(256)
	_make_materials()
	_make_environment()
	collider_body = StaticBody3D.new()
	add_child(collider_body)

	_build_road_graph()
	_build_roads()
	_build_blocks()
	_build_street_lights()
	_build_outskirts()
	_build_roadworks()
	_build_wash_bays()
	_build_hills()
	var static_meshes := _finish_bakers()
	var t_city := Time.get_ticks_msec() - t0

	_spawn_traffic()
	_spawn_pedestrians()
	_make_rain()
	sfx = Sfx.new()
	add_child(sfx)

	rig = CameraRig.new()
	add_child(rig)
	hud = Hud.new()
	hud.main = self
	add_child(hud)
	sfx.now_playing.connect(func(t: String):
		if hud and is_instance_valid(hud) and sfx.music_enabled:
			hud.toast("📻 106.5 PlayKampala FM  •  ♪ %s" % t)
		if hud and hud.radio_btn:
			hud.radio_btn.text = sfx.radio_short_label())
	if sfx.current_title != "":
		hud.call_deferred("toast", "📻 106.5 PlayKampala FM  •  ♪ %s" % sfx.current_title)
	_spawn_player(SPAWN)
	jobs = Jobs.new()
	jobs.main = self
	add_child(jobs)
	life = Life.new()
	life.main = self
	add_child(life)
	endless_world = EndlessWorld.new()
	endless_world.main = self
	add_child(endless_world)

	obstacles.append(player)
	obstacles.append(player.parked_boda)
	_reset_day_stats()
	load_game()
	_parse_args()
	var uargs := OS.get_cmdline_user_args()
	var skip_title := false
	for ua in uargs:
		if ua.begins_with("--shot=") or ua in ["--ride", "--map", "--settings", "--fuel-menu", "--confrontation", "--no-title"]:
			skip_title = true
	if not skip_title and hud and not hud.title_panel.visible:
		hud.call_deferred("show_title_screen")
	_apply_time()
	built = true
	print("PlayKampala city built in %d ms (geometry %d ms): %d merged meshes, %d places, %d shops signs, %d moving people/vehicles" % [
		Time.get_ticks_msec() - t0, t_city, static_meshes, places.size(), _used_names.size(), get_tree().get_nodes_in_group("agents").size()])

	var shot_intro := "--shot-intro" in OS.get_cmdline_user_args()
	if _shot_path == "" or shot_intro:
		sfx.play("intro", -2.0)
		intro.status_text = "Welcome to Kampala!  •  Tap anywhere or press any key to ride"
		var anim_dur := 1.85
		var elapsed := 0.0
		while elapsed < anim_dur and not intro.skipped:
			await get_tree().process_frame
			var dt := get_process_delta_time()
			elapsed += dt
			intro.progress = lerpf(0.25, 1.0, clampf(elapsed / (anim_dur * 0.75), 0.0, 1.0))
			if shot_intro and elapsed >= 0.7 and _shot_path != "":
				get_viewport().get_texture().get_image().save_png(_shot_path)
				print("saved ", _shot_path)
				get_tree().quit()
				return
		# Smooth fade-out into the live Kampala street
		var fade := 0.0
		while fade < 0.35 and not intro.skipped:
			await get_tree().process_frame
			fade += get_process_delta_time()
			intro.modulate.a = 1.0 - clampf(fade / 0.35, 0.0, 1.0)
	_loading.queue_free()
