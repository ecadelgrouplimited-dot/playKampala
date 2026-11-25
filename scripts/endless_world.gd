extends Node3D
## ENDLESS GREATER KAMPALA & UGANDA WORLD STREAMER
## Streams 96m x 96m procedural chunks infinitely around the player outside the
## central city core: endless Inter-District Highways (Jinja, Gulu-Bombo, Masaka,
## Entebbe), branching red murram roads, walled suburb estates, houses under
## construction, trading centres, community boreholes, schools, brick kilns & shambas.

const Baker = preload("res://scripts/mesh_baker.gd")
const MeshSculpt = preload("res://scripts/mesh_sculpt.gd")

const CHUNK := 96.0
const VIEW_R := 2          # 5x5 active chunks (480m x 480m around player at all times)

var main: Node
var loaded := {}           # Vector2i(cx, cz) -> Dictionary {node, mud_rects}
var _registered_chunks := {}
var _last_center := Vector2i(99999, 99999)


func _process(_delta: float) -> void:
	if main == null or not main.built or main.player == null:
		return
	force_sync()


func force_sync() -> void:
	if main == null or main.player == null:
		return
	var p: Vector3 = main.player.global_position
	var cc := Vector2i(int(floor((p.x + CHUNK * 0.5) / CHUNK)), int(floor((p.z + CHUNK * 0.5) / CHUNK)))
	if cc == _last_center:
		return
	_last_center = cc
	_sync_chunks(cc)


func _is_core_chunk(c: Vector2i) -> bool:
	var wx := c.x * CHUNK
	var wz := c.y * CHUNK
	var half_f := float(main.HALF)
	# Central Kampala + inner suburbs are already built statically; south is Lake Victoria
	if wz > half_f + 45.0:
		return true
	return absf(wx) <= half_f + 68.0 and absf(wz) <= half_f + 68.0


func _sync_chunks(center: Vector2i) -> void:
	var keep := {}
	for dz in range(-VIEW_R, VIEW_R + 1):
		for dx in range(-VIEW_R, VIEW_R + 1):
			var k := Vector2i(center.x + dx, center.y + dz)
			if _is_core_chunk(k):
				continue
			keep[k] = true
			if not loaded.has(k):
				_spawn_chunk(k)
	var to_drop := []
	for k in loaded.keys():
		if not keep.has(k):
			to_drop.append(k)
	for k in to_drop:
		var info: Dictionary = loaded[k]
		for mr in info["mud_rects"]:
			main.mud_zones.erase(mr)
		if is_instance_valid(info["node"]):
			(info["node"] as Node3D).queue_free()
		loaded.erase(k)


func _spawn_chunk(c: Vector2i) -> void:
	var root := Node3D.new()
	var origin := Vector3(c.x * CHUNK, 0.0, c.y * CHUNK)
	root.position = origin
	add_child(root)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(c.x * 73856093) ^ int(c.y * 19349663) ^ 0x5A17

	var b_solid = Baker.new()
	var b_road = Baker.new()
	var b_murram = Baker.new()
	var body := StaticBody3D.new()
	root.add_child(body)
	var mud_rects := []

	# Lush peri-urban grass & red earth base slab
	var dist_km := origin.length() / 180.0
	var ground_col: Color = main.EARTH.lerp(main.LEAF, clampf(0.32 + dist_km * 0.08, 0.25, 0.68))
	b_murram.add(main._box_mesh(Vector3(CHUNK + 0.4, 0.06, CHUNK + 0.4)), Transform3D(Basis.IDENTITY, Vector3(0, -0.03, 0)), ground_col)

	var half_f := float(main.HALF)
	var on_ew_hwy: bool = (c.y == 0)                                     # East Jinja Hwy / West Masaka Hwy (z = 0)
	var on_ns_hwy: bool = (c.x == 0 and c.y < 0)                         # North Gulu-Bombo Hwy (x = 0)
	var on_entebbe: bool = (c.x == -1 and c.y > 0 and origin.z <= half_f + 45.0)
	var has_ew_murram: bool = (absi(c.y) % 2 == 1)
	var has_ns_murram: bool = (absi(c.x) % 2 == 1)
	var hwy_z: float = 0.0
	var hwy_x: float = 0.0 if c.x == 0 else (float(-main.BLOCK) - origin.x)
	var murram_col: Color = main.MURRAM

	# 1. Endless Asphalt Trunk Highways (aligned at z=0 and x=0 with city exit highways!)
	if on_ew_hwy:
		b_road.add(main._box_mesh(Vector3(CHUNK, 0.05, 11.2)), Transform3D(Basis.IDENTITY, Vector3(0, 0.025, hwy_z)), main.ASPHALT)
		b_murram.add(main._box_mesh(Vector3(CHUNK, 0.03, 15.8)), Transform3D(Basis.IDENTITY, Vector3(0, 0.012, hwy_z)), murram_col)
		for dx in range(-42, 46, 10):
			b_road.add(main._box_mesh(Vector3(4.4, 0.012, 0.24)), Transform3D(Basis.IDENTITY, Vector3(dx, 0.056, hwy_z)), main.PAINT)
		# Roadside palms, eucalyptus utility poles & milestone post along the highway!
		for tx in [-34.0, 12.0, 38.0]:
			for tz_s in [-9.2, 9.2]:
				for p in main.model_tree(0 if absi(int(tx)) != 12 else 1):
					b_solid.add(p[0], Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(tx, 0, tz_s)) * (p[1] as Transform3D), p[2])
		for px_pole in [-22.0, 22.0]:
			b_solid.add(main._cyl(0.08, 0.11, 6.8, 6), Transform3D(Basis.IDENTITY, Vector3(px_pole, 3.4, -7.8)), main.WOOD)
			b_solid.add(main._box_mesh(Vector3(0.12, 0.10, 1.3)), Transform3D(Basis.IDENTITY, Vector3(px_pole, 6.5, -7.8)), main.WOOD)
		b_solid.add(main._box_mesh(Vector3(0.28, 0.95, 0.18)), Transform3D(Basis.IDENTITY, Vector3(0, 0.48, -6.8)), main.PAINT)
		b_solid.add(main._box_mesh(Vector3(0.30, 0.26, 0.20)), Transform3D(Basis.IDENTITY, Vector3(0, 0.84, -6.8)), Color(0.12, 0.44, 0.22))
		if absi(c.x) % 3 == 0:
			b_road.add(main._box_mesh(Vector3(1.4, 0.09, 10.8)), Transform3D(Basis.IDENTITY, Vector3(-18.0, 0.05, hwy_z)), main.CURB_YELLOW)

	if on_ns_hwy or on_entebbe:
		b_road.add(main._box_mesh(Vector3(11.2, 0.05, CHUNK)), Transform3D(Basis.IDENTITY, Vector3(hwy_x, 0.025, 0)), main.ASPHALT)
		b_murram.add(main._box_mesh(Vector3(15.8, 0.03, CHUNK)), Transform3D(Basis.IDENTITY, Vector3(hwy_x, 0.012, 0)), murram_col)
		for dz in range(-42, 46, 10):
			b_road.add(main._box_mesh(Vector3(0.24, 0.012, 4.4)), Transform3D(Basis.IDENTITY, Vector3(hwy_x, 0.056, dz)), main.PAINT)
		for tz in [-34.0, 14.0]:
			for tx_s in [-9.2, 9.2]:
				for p in main.model_tree(0 if tz < 0 else 1):
					b_solid.add(p[0], Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(hwy_x + tx_s, 0, tz)) * (p[1] as Transform3D), p[2])

	# 2. Endless Branching Red Murram / Mud Feeder Roads (with roadside banana & mango trees!)
	if has_ew_murram and not on_ew_hwy:
		b_murram.add(main._box_mesh(Vector3(CHUNK, 0.045, 7.0)), Transform3D(Basis.IDENTITY, Vector3(0, 0.022, 0)), murram_col)
		b_murram.add(main._box_mesh(Vector3(CHUNK, 0.055, 0.9)), Transform3D(Basis.IDENTITY, Vector3(0, 0.028, -1.6)), murram_col.darkened(0.20))
		b_murram.add(main._box_mesh(Vector3(CHUNK, 0.055, 0.9)), Transform3D(Basis.IDENTITY, Vector3(0, 0.028, 1.6)), murram_col.darkened(0.20))
		for mx in [-36.0, 0.0, 36.0]:
			for p in main.model_tree(2 if mx != 0.0 else 0):
				b_solid.add(p[0], Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(mx, 0, -5.8)) * (p[1] as Transform3D), p[2])
		var mr := Rect2(origin.x - CHUNK * 0.5, origin.z - 3.6, CHUNK, 7.2)
		mud_rects.append(mr)
		main.mud_zones.append(mr)

	if has_ns_murram and not on_ns_hwy:
		b_murram.add(main._box_mesh(Vector3(7.0, 0.045, CHUNK)), Transform3D(Basis.IDENTITY, Vector3(0, 0.022, 0)), murram_col)
		b_murram.add(main._box_mesh(Vector3(0.9, 0.055, CHUNK)), Transform3D(Basis.IDENTITY, Vector3(-1.6, 0.028, 0)), murram_col.darkened(0.20))
		b_murram.add(main._box_mesh(Vector3(0.9, 0.055, CHUNK)), Transform3D(Basis.IDENTITY, Vector3(1.6, 0.028, 0)), murram_col.darkened(0.20))
		for mz in [-36.0, 36.0]:
			for p in main.model_tree(2):
				b_solid.add(p[0], Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(5.8, 0, mz)) * (p[1] as Transform3D), p[2])
		var mr2 := Rect2(origin.x - 3.6, origin.z - CHUNK * 0.5, 7.2, CHUNK)
		mud_rects.append(mr2)
		main.mud_zones.append(mr2)

	# 3. Populate the 4 quadrants (±26, 0, ±26) — always 18m+ clear of centre roads (x=0, z=0)!
	var d_name: String = main.district_at(origin)
	var quads: Array[Vector3] = [Vector3(-25, 0, -25), Vector3(25, 0, -25), Vector3(-25, 0, 25), Vector3(25, 0, 25)]
	for qi in 4:
		var qc: Vector3 = quads[qi]
		var roll := rng.randf()
		if (on_ew_hwy or on_ns_hwy) and qi < 2 and absi(c.x + c.y) % 2 == 0:
			# Bustling Roadside Suburb Trading Centre (Hardware, Kinyozi, Pork Joint, MoMo, Stage)
			_chunk_trading_centre(b_solid, body, qc, 0.0 if on_ew_hwy else PI * 0.5, rng, origin, d_name, c, qi)
		elif roll < 0.30:
			# Walled Suburb Bungalow Compound with Gate, Water Tank & Solar Roof
			_chunk_bungalow_estate(b_solid, body, qc, rng)
		elif roll < 0.50:
			# Developing Suburb Plot: Unfinished Brick House + Scaffolding + Sand & Bricks
			_chunk_construction_plot(b_solid, body, qc, rng, origin, d_name, c, qi)
		elif roll < 0.68:
			# Community Borehole + Primary School Compound OR Brick Kiln Yard
			_chunk_community_spot(b_solid, body, qc, rng, origin, d_name, c, qi)
		else:
			# Lush Matooke Banana / Maize Shamba + Homestead Muzigo
			_chunk_shamba_farm(b_solid, body, qc, rng, origin, d_name, c, qi)

	_attach_baked(root, b_solid, main.mat_solid)
	_attach_baked(root, b_road, main.mat_road, false)
	_attach_baked(root, b_murram, main.mat_murram, false)
	loaded[c] = {"node": root, "mud_rects": mud_rects}
	_registered_chunks[c] = true


func _attach_baked(parent: Node3D, baker, mat: Material, shadow := true) -> void:
	if baker.is_empty():
		return
	var mi := MeshInstance3D.new()
	mi.mesh = baker.build()
	mi.material_override = mat
	mi.visibility_range_end = 340.0
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _col(body: StaticBody3D, pos: Vector3, sz: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = sz
	cs.shape = bs
	cs.position = pos
	body.add_child(cs)


func _register_once(c: Vector2i, qi: int, place_name: String, world_pos: Vector3, dist_name: String) -> void:
	if _registered_chunks.has(c):
		return
	main.places.append({"name": place_name, "pos": world_pos, "district": dist_name})
	if main.life:
		main.life.cat_of.append(main.life.categorize(place_name))


func _chunk_bungalow_estate(b, body: StaticBody3D, qc: Vector3, rng: RandomNumberGenerator) -> void:
	var wcol: Color = main.WALLS[rng.randi() % main.WALLS.size()]
	var rcol: Color = main.ROOFS[rng.randi() % main.ROOFS.size()]
	# Perimeter fence & iron gate
	b.add(main._box_mesh(Vector3(16.0, 1.85, 0.24)), Transform3D(Basis.IDENTITY, qc + Vector3(0, 0.92, -8.0)), Color(0.80, 0.76, 0.70))
	b.add(main._box_mesh(Vector3(0.24, 1.85, 16.0)), Transform3D(Basis.IDENTITY, qc + Vector3(-8.0, 0.92, 0)), Color(0.80, 0.76, 0.70))
	b.add(main._box_mesh(Vector3(0.24, 1.85, 16.0)), Transform3D(Basis.IDENTITY, qc + Vector3(8.0, 0.92, 0)), Color(0.80, 0.76, 0.70))
	b.add(main._box_mesh(Vector3(4.2, 1.95, 0.22)), Transform3D(Basis.IDENTITY, qc + Vector3(0, 0.98, 8.0)), Color(0.16, 0.20, 0.26))
	# Bungalow house, veranda pillars, hipped roof & solar panel
	b.add(main._box_mesh(Vector3(9.4, 3.4, 7.6)), Transform3D(Basis.IDENTITY, qc + Vector3(0, 1.7, -0.8)), wcol)
	b.add(main._prism(Vector3(8.6, 1.65, 10.4)), Transform3D(Basis(Vector3.UP, PI * 0.5), qc + Vector3(0, 4.22, -0.8)), rcol)
	b.add(main._box_mesh(Vector3(2.2, 0.06, 1.3)), Transform3D(Basis(Vector3.RIGHT, 0.28), qc + Vector3(1.8, 4.65, 0.8)), Color(0.10, 0.18, 0.34))
	b.add(main._box_mesh(Vector3(1.15, 2.15, 0.08)), Transform3D(Basis.IDENTITY, qc + Vector3(0, 1.1, 3.04)), main.WOOD)
	for wx in [-2.8, 2.8]:
		b.add(main._box_mesh(Vector3(1.4, 1.1, 0.08)), Transform3D(Basis.IDENTITY, qc + Vector3(wx, 1.9, 3.04)), main.GLASS)
	# Elevated black Crest water tank in compound corner + shade tree
	b.add(main._box_mesh(Vector3(1.3, 2.4, 1.3)), Transform3D(Basis.IDENTITY, qc + Vector3(-5.6, 1.2, -5.4)), main.GREY)
	b.add(main._cyl(0.68, 0.68, 1.35, 10), Transform3D(Basis.IDENTITY, qc + Vector3(-5.6, 3.05, -5.4)), main.DARK)
	for p in main.model_tree(1):
		b.add(p[0], Transform3D(Basis.IDENTITY, qc + Vector3(5.2, 0, 4.2)) * (p[1] as Transform3D), p[2])
	_col(body, qc + Vector3(0, 1.8, -0.8), Vector3(10.0, 3.6, 8.2))


func _chunk_construction_plot(b, body: StaticBody3D, qc: Vector3, rng: RandomNumberGenerator, origin: Vector3, d_name: String, c: Vector2i, qi: int) -> void:
	# Authentic Ugandan unfinished red-brick storied house with eucalyptus scaffolding, sand heap & brick stack!
	var brick := Color(0.68, 0.31, 0.19)
	var concrete := Color(0.62, 0.61, 0.59)
	b.add(main._box_mesh(Vector3(9.0, 3.1, 7.4)), Transform3D(Basis.IDENTITY, qc + Vector3(0, 1.55, -1.2)), brick)
	b.add(main._box_mesh(Vector3(9.4, 0.24, 7.8)), Transform3D(Basis.IDENTITY, qc + Vector3(0, 3.22, -1.2)), concrete)
	# Second floor half-built columns & brick walls + eucalyptus scaffolding poles
	for cx_p in [-4.0, 0.0, 4.0]:
		for cz_p in [-4.4, 2.0]:
			b.add(main._box_mesh(Vector3(0.32, 2.6, 0.32)), Transform3D(Basis.IDENTITY, qc + Vector3(cx_p, 4.6, cz_p)), concrete)
	for sx in [-4.8, -1.6, 1.6, 4.8]:
		b.add(main._cyl(0.05, 0.06, 5.6, 6), Transform3D(Basis.IDENTITY, qc + Vector3(sx, 2.8, 3.1)), main.WOOD)
	# Lake sand heap & stacked clay bricks in front yard
	b.add(MeshSculpt.faceted_canopy("sand_heap", 1.85, 0.48, 31), Transform3D(Basis.IDENTITY, qc + Vector3(-3.4, 0.35, 5.2)), Color(0.82, 0.72, 0.48))
	b.add(main._box_mesh(Vector3(2.2, 1.05, 1.4)), Transform3D(Basis.IDENTITY, qc + Vector3(3.2, 0.52, 5.0)), brick.darkened(0.08))
	_col(body, qc + Vector3(0, 2.2, -1.2), Vector3(9.4, 4.4, 7.8))
	_register_once(c, qi, "%s Building Site & Hardware Yard" % d_name.split(" ")[0], origin + qc + Vector3(0, 0, 6.2), d_name)


func _chunk_trading_centre(b, body: StaticBody3D, qc: Vector3, rot_y: float, rng: RandomNumberGenerator, origin: Vector3, d_name: String, c: Vector2i, qi: int) -> void:
	var xf := Transform3D(Basis(Vector3.UP, rot_y), qc)
	var wcol: Color = main.WALLS[rng.randi() % main.WALLS.size()]
	var scol: Color = main.SIGNS[rng.randi() % main.SIGNS.size()]
	# Row of 4 lively suburb shops (Hardware, Kinyozi Salon, Pork Joint, MoMo Kiosk)
	b.add(main._box_mesh(Vector3(14.4, 3.3, 5.4)), xf * Transform3D(Basis.IDENTITY, Vector3(0, 1.65, 0)), wcol)
	b.add(main._prism(Vector3(6.2, 1.2, 15.0)), xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 3.9, 0)), main.ROOFS[0])
	b.add(main._box_mesh(Vector3(14.0, 0.52, 0.12)), xf * Transform3D(Basis.IDENTITY, Vector3(0, 3.02, 2.75)), scol)
	for si in 4:
		var sx := -5.2 + si * 3.45
		b.add(main._box_mesh(Vector3(1.15, 2.15, 0.08)), xf * Transform3D(Basis.IDENTITY, Vector3(sx, 1.08, 2.72)), main.SHOP_DARK)
	# Parked matatu & boda at suburb trading centre!
	for p in main.model_umbrella(scol, 2.4, 1.5):
		b.add(p[0], xf * Transform3D(Basis.IDENTITY, Vector3(-5.5, 0, 4.4)) * (p[1] as Transform3D), p[2])
	for p in main.model_boda(true, false):
		b.add(p[0], xf * Transform3D(Basis(Vector3.UP, 0.4), Vector3(4.8, 0, 4.5)) * (p[1] as Transform3D), p[2])
	if qi == 0:
		for p in main.model_taxi():
			b.add(p[0], xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.0, 0, 6.2)) * (p[1] as Transform3D), p[2])
	_col(body, qc, Vector3(14.6, 3.5, 5.8))
	var titles := ["Trading Centre Pork Joint & Muchomo", "Executive Kinyozi & Salon", "Hardware & Cement Depot", "Suburb Mobile Money & Stage"]
	_register_once(c, qi, "%s %s" % [d_name.split(" ")[0], titles[(absi(c.x) + qi) % titles.size()]], origin + qc + Vector3(0, 0, 4.8), d_name)


func _chunk_community_spot(b, body: StaticBody3D, qc: Vector3, rng: RandomNumberGenerator, origin: Vector3, d_name: String, c: Vector2i, qi: int) -> void:
	if rng.randf() < 0.55:
		# Community Borehole Water Pump with concrete apron & queue of yellow 20L jerrycans!
		b.add(main._cyl(2.4, 2.5, 0.08, 12), Transform3D(Basis.IDENTITY, qc + Vector3(0, 0.04, 0)), main.PAVEMENT)
		b.add(main._cyl(0.10, 0.14, 1.25, 8), Transform3D(Basis.IDENTITY, qc + Vector3(0, 0.65, 0)), main.GREY)
		b.add(main._box_mesh(Vector3(0.08, 0.08, 0.95)), Transform3D(Basis(Vector3.RIGHT, 0.35), qc + Vector3(0, 1.18, 0.35)), main.DARK)
		for ji in 6:
			b.add(main._box_mesh(Vector3(0.26, 0.38, 0.22)), Transform3D(Basis.IDENTITY, qc + Vector3(-1.4 + ji * 0.52, 0.23, 1.1)), Color(0.94, 0.78, 0.12))
		for p in main.model_tree(1):
			b.add(p[0], Transform3D(Basis.IDENTITY, qc + Vector3(-3.8, 0, -2.5)) * (p[1] as Transform3D), p[2])
		_register_once(c, qi, "%s Community Borehole & Water Point" % d_name.split(" ")[0], origin + qc + Vector3(0, 0, 2.2), d_name)
	else:
		# Suburb Primary School block with veranda & flagpole
		b.add(main._box_mesh(Vector3(15.0, 3.2, 5.6)), Transform3D(Basis.IDENTITY, qc + Vector3(0, 1.6, -2.5)), Color(0.90, 0.85, 0.72))
		b.add(main._prism(Vector3(6.4, 1.35, 15.6)), Transform3D(Basis(Vector3.UP, PI * 0.5), qc + Vector3(0, 3.88, -2.5)), Color(0.20, 0.39, 0.27))
		b.add(main._cyl(0.05, 0.07, 5.8, 6), Transform3D(Basis.IDENTITY, qc + Vector3(0, 2.9, 3.8)), main.PAINT)
		b.add(main._box_mesh(Vector3(0.95, 0.58, 0.04)), Transform3D(Basis.IDENTITY, qc + Vector3(0.48, 5.45, 3.8)), Color(0.88, 0.72, 0.14))
		_col(body, qc + Vector3(0, 1.6, -2.5), Vector3(15.2, 3.4, 5.8))
		_register_once(c, qi, "%s Primary School" % d_name.split(" ")[0], origin + qc + Vector3(0, 0, 3.2), d_name)


func _chunk_shamba_farm(b, body: StaticBody3D, qc: Vector3, rng: RandomNumberGenerator, origin: Vector3, d_name: String, c: Vector2i, qi: int) -> void:
	# Lush Ugandan Shamba (matooke banana grove + homestead muzigo + farm stall)
	b.add(main._box_mesh(Vector3(6.8, 2.7, 4.4)), Transform3D(Basis.IDENTITY, qc + Vector3(-3.2, 1.35, -3.5)), main.WALLS[1])
	b.add(main._prism(Vector3(5.0, 1.1, 7.2)), Transform3D(Basis(Vector3.UP, PI * 0.5), qc + Vector3(-3.2, 3.25, -3.5)), main.ROOFS[1])
	_col(body, qc + Vector3(-3.2, 1.4, -3.5), Vector3(7.0, 2.8, 4.6))
	for bi in 7:
		var bp := qc + Vector3(rng.randf_range(-6.5, 7.5), 0, rng.randf_range(-2.0, 7.5))
		for p in main.model_tree(2 if bi < 5 else 0):
			b.add(p[0], Transform3D(Basis(Vector3.UP, rng.randf() * TAU), bp) * (p[1] as Transform3D), p[2])
	if qi == 0:
		_register_once(c, qi, "%s Shamba Farm & Matooke Harvest Stall" % d_name.split(" ")[0], origin + qc + Vector3(0, 0, 5.5), d_name)
