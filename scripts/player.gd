extends CharacterBody3D
## The player: walks, rides their own boda, or rolls/pushes it on foot when out of fuel.
## Movement is relative to the camera, so "up" on the joystick
## always means "away from me on screen".

const WALK_SPEED := 3.6
const PUSH_SPEED := 1.85
const BODA_MAX := 17.5
const BODA_ACCEL := 8.5
const BODA_BRAKE := 16.0
const BODA_TURN := 2.9
const TANK_LITRES := 4.0
const LITRES_PER_METRE := 0.00028   # ~3.6 km per litre (1L / 5k lasts ~4 min; 4L full tank lasts ~15 min)

var main: Node
var walk_body: Node3D
var boda_body: Node3D
var passenger_body: Node3D       # shown behind you when carrying a passenger
var cargo_body: Node3D           # shown on the carrier rack when delivering items
var headlight_beam: MeshInstance3D
var parked_boda: Node3D          # the bike standing in the street when you're on foot (or rolled beside you when out of fuel)

var on_boda := false
var speed := 0.0
var heading := 0.0
var fuel := 2.8                  # litres
var fuel_warn_level := 0         # 0 = normal, 1 = <=25% warned, 2 = <=12% reserve warned, 3 = 0% empty
var bike_health := 100.0         # 0..100% mechanical condition (crashes reduce it; Boda Fundi repairs it)
var boost_energy := 1.0          # 0.0 .. 1.0 rechargeable turbo boost meter
var boost_toggle := false        # toggled by HUD Boost button on mobile/desktop
var boosting := false
var is_swimming := false
var _swim_notified := false
var _t := 0.0
var _crash_cooldown := 0.0
var _bump_cooldown := 0.0
var _stuck_t := 0.0
var _last_pos := Vector3.ZERO
var _pothole_jolt := 0.0
var _mud_warn_cd := 0.0


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	add_child(cs)


func _input_vector() -> Vector2:
	var v: Vector2 = main.hud.joy
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y += 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
	return v.limit_length(1.0)


func max_tank() -> float:
	if main and main.get("has_big_tank"):
		return 6.5
	return TANK_LITRES


func fuel_fraction() -> float:
	return clampf(fuel / max_tank(), 0.0, 1.0)


func is_broken() -> bool:
	return bike_health <= 0.0


func is_pushing_boda() -> bool:
	return on_boda and (fuel <= 0.0 or bike_health <= 0.0)


func repair_bike() -> void:
	bike_health = 100.0
	if on_boda and fuel > 0.0:
		_sync_boda_pose(0.0, 0.0)
		if main and main.sfx:
			main.sfx.play("start", -4.0)


func _physics_process(delta: float) -> void:
	_t += delta
	_crash_cooldown = maxf(0.0, _crash_cooldown - delta)
	_bump_cooldown = maxf(0.0, _bump_cooldown - delta)
	_pothole_jolt = maxf(0.0, _pothole_jolt - delta * 6.0)
	var input: Vector2 = Vector2.ZERO if main.paused else _input_vector()
	var yaw: float = main.rig.yaw
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var dir := right * input.x + fwd * input.y
	var mag := minf(dir.length(), 1.0)

	if on_boda:
		var max_spd: float = (21.0 if main.get("bike_level") and main.bike_level >= 1 else BODA_MAX)
		var accel: float = (11.5 if main.get("bike_level") and main.bike_level >= 1 else BODA_ACCEL)
		var rain_mult: float = (0.95 if main.get("has_rain_jacket") else 0.78) if main.raining else 1.0
		var on_mud: bool = main.has_method("in_mud_road") and main.in_mud_road(position)
		var mud_mult: float = (0.66 if main.raining else 0.86) if on_mud else 1.0
		var life_mult: float = main.life.speed_mult() if main.get("life") and main.life else 1.0
		var top := max_spd * mag * rain_mult * mud_mult * life_mult
		_mud_warn_cd = maxf(0.0, _mud_warn_cd - delta)
		if on_mud and speed > 3.5:
			_pothole_jolt = maxf(_pothole_jolt, 0.45 if main.raining else 0.22)
			if main.raining and _mud_warn_cd <= 0.0:
				_mud_warn_cd = 16.0
				main.hud.toast("🌧️ Slippery Kampala Murram Mud! Ride carefully on the suburb dirt road — visit a Washing Bay after!")
		var want_boost := (Input.is_key_pressed(KEY_SHIFT) or boost_toggle) and fuel > 0.0 and bike_health > 0.0 and mag > 0.15
		if want_boost and boost_energy > 0.04:
			boosting = true
			boost_energy = maxf(0.0, boost_energy - delta * 0.28)
			if boost_energy <= 0.04:
				boost_toggle = false
			top *= 1.34
			accel *= 1.48
		else:
			boosting = false
			var fever_regen: float = 1.5 if (main.jobs and main.jobs.streak >= 3) else 1.0
			boost_energy = minf(1.0, boost_energy + delta * 0.18 * fever_regen)
		if fuel <= 0.0 or bike_health <= 0.0:
			# Out of fuel or broken down: cannot ride! Player walks beside the bike and rolls/pushes it by hand
			top = minf(top, PUSH_SPEED)
		speed = move_toward(speed, top, (accel if top > speed else BODA_BRAKE) * delta)
		if mag > 0.1:
			var turn_rate := BODA_TURN * (0.65 if (fuel <= 0.0 or bike_health <= 0.0) else (0.45 + speed / max_spd))
			heading = lerp_angle(heading, atan2(-dir.x, -dir.z), clampf(turn_rate * delta, 0.0, 1.0))
		velocity = Vector3(-sin(heading), 0, -cos(heading)) * speed
		if fuel > 0.0 and bike_health > 0.0:
			var lean := clampf(angle_difference(heading, atan2(-dir.x, -dir.z)) * 0.52, -0.36, 0.36) if mag > 0.1 else 0.0
			boda_body.rotation.z = lerpf(boda_body.rotation.z, lean, 7.0 * delta)
			boda_body.rotation.x = lerpf(boda_body.rotation.x, 0.13 if boosting else 0.0, 8.0 * delta)
			var vib := sin(_t * (28.0 + speed * 3.0)) * (0.008 if speed < 1.0 else 0.015) + sin(_t * 45.0) * _pothole_jolt * 0.08
			boda_body.position.y = vib
			passenger_body.rotation.z = boda_body.rotation.z
			passenger_body.position.y = vib
			if cargo_body:
				cargo_body.rotation.z = boda_body.rotation.z
				cargo_body.position.y = vib
		if headlight_beam:
			headlight_beam.visible = on_boda and main.night_amount > 0.25 and fuel > 0.0
		# Real speed- & boost-scaled fuel consumption (idling sips tiny fuel; boosting burns more)
		if fuel > 0.0:
			var load_mult := 1.38 if boosting else (0.78 + 0.32 * clampf(speed / maxf(max_spd, 1.0), 0.0, 1.0))
			var idle_burn := delta * 0.00004
			fuel = maxf(0.0, fuel - (speed * delta * LITRES_PER_METRE * load_mult + idle_burn))
			var ff := fuel_fraction()
			if ff <= 0.25 and fuel_warn_level < 1 and fuel > 0.0:
				fuel_warn_level = 1
				if main.sfx:
					main.sfx.play("low_fuel", -2.5, 1.0)
				main.hud.toast("LOW FUEL (25%)! Tap any green [F] on the Map to set a GPS route to a Petrol Station.")
			if ff <= 0.12 and fuel_warn_level < 2 and fuel > 0.0:
				fuel_warn_level = 2
				if main.sfx:
					main.sfx.play("low_fuel", 0.0, 1.15)
				main.hud.toast("RESERVE FUEL (12%)! Engine will cut out soon — tap a green [F] on the Map for fuel!")
			if fuel <= 0.0 and fuel_warn_level < 3:
				fuel_warn_level = 3
				speed = minf(speed, PUSH_SPEED)
				if main.sfx:
					main.sfx.play("sputter", 0.0, 1.0)
				if main.has_method("route_to_nearest_pump"):
					main.route_to_nearest_pump(false)
				main.hud.toast("OUT OF FUEL! Engine cut out — rolling boda by hand. Follow the blue GPS route to the Petrol Station!")
	else:
		if headlight_beam:
			headlight_beam.visible = false
		var on_pier: bool = absf(position.x) <= 3.4 and position.z <= float(main.HALF) + 40.5
		is_swimming = position.z > float(main.HALF) + 34.0 and not on_pier
		var swim_mult := 0.72 if is_swimming else 1.0
		var walk_mag := clampf((mag - 0.12) / 0.88, 0.0, 1.0) if mag > 0.12 else 0.0
		var target_walk: float = WALK_SPEED * walk_mag * swim_mult * (1.30 if (main.raining and not is_swimming) else 1.0) * (float(main.life.speed_mult()) if main.get("life") and main.life else 1.0)
		speed = move_toward(speed, target_walk, (14.0 if target_walk > speed else 18.0) * delta)
		if walk_mag > 0.0:
			var want_h := atan2(-dir.x, -dir.z)
			heading = lerp_angle(heading, want_h, clampf(18.0 * delta, 0.0, 1.0))
			var align := maxf(0.25, cos(angle_difference(heading, want_h)))
			velocity = Vector3(-sin(heading), 0, -cos(heading)) * (speed * align)
		else:
			velocity = Vector3(-sin(heading), 0, -cos(heading)) * speed
		if is_swimming:
			if not _swim_notified:
				_swim_notified = true
				main.hud.toast("🏊 Diving into Lake Victoria! Swimming refreshes your mood.")
			if main.get("life") and main.life:
				main.life.mood = minf(100.0, main.life.mood + delta * 3.5)
			walk_body.rotation.x = lerpf(walk_body.rotation.x, -1.12 if speed > 0.15 else -0.22, clampf(8.0 * delta, 0.0, 1.0))
			if walk_body.has_method("animate_swim"):
				walk_body.animate_swim(delta, speed > 0.15)
		else:
			walk_body.rotation.x = lerpf(walk_body.rotation.x, 0.0, clampf(10.0 * delta, 0.0, 1.0))
			if walk_body.has_method("animate"):
				walk_body.animate(delta, speed if speed > 0.12 else 0.0)

	rotation.y = heading
	move_and_slide()
	if on_boda and get_slide_collision_count() > 0 and _bump_cooldown <= 0.0 and speed > 4.0:
		speed *= 0.5   # one bump, then slide along the wall (never a trap)
		_bump_cooldown = 0.5
		_pothole_jolt = 0.6
		if main.jobs and main.jobs.has_method("on_cargo_bump"):
			main.jobs.on_cargo_bump()

	if on_boda and speed > 6.5 and _crash_cooldown <= 0.0:
		_check_crash()

	_resolve_agent_collisions()
	_unstick(delta, mag)
	# Clamp to the full city + suburbs + inter-district highways boundary (allow swimming into Lake Victoria on foot!)
	var limit: float = main.HALF + 102.0
	var max_z: float = (main.HALF + 52.0) if (not on_boda and absf(position.x) <= 125.0) else (main.HALF + 30.0)
	position.x = clampf(position.x, -limit, limit)
	position.z = clampf(position.z, -limit, max_z)
	if is_swimming:
		position.y = -0.38 + sin(_t * 3.8) * 0.06
	elif not on_boda and absf(position.x) <= 3.3 and position.z > main.HALF + 12.0 and position.z <= main.HALF + 40.2:
		position.y = 0.48   # walking on the wooden Ggaba Pier above the water
	else:
		position.y = main.ground_height(position)
	_sync_boda_pose(delta, mag)


## Switches visuals between seated riding (fuel > 0) and walking beside the bike to roll/push it (fuel <= 0).
func _sync_boda_pose(delta: float, mag: float) -> void:
	if not on_boda:
		walk_body.position = Vector3.ZERO
		return
	if fuel <= 0.0 or bike_health <= 0.0:
		boda_body.visible = false
		passenger_body.visible = false
		walk_body.visible = true
		walk_body.position = Vector3(-0.56, 0, 0.08)
		if walk_body.has_method("animate"):
			walk_body.animate(delta, speed * 1.45 if mag > 0.05 else 0.0)
		parked_boda.visible = true
		var side_offset := Basis(Vector3.UP, heading) * Vector3(0.14, 0, 0)
		parked_boda.position = Vector3(position.x, position.y, position.z) + side_offset
		parked_boda.rotation.y = heading
		parked_boda.rotation.z = 0.04
	else:
		if not boda_body.visible:
			boda_body.visible = true
			walk_body.visible = false
			walk_body.position = Vector3.ZERO
			parked_boda.visible = false
			parked_boda.rotation.z = 0.0
			var has_job: bool = main.jobs != null and main.jobs.state == 1
			show_passenger(has_job and bool(main.jobs.is_passenger()))
			show_cargo(has_job and not bool(main.jobs.is_passenger()))


## Solid personal-space collision so the player can NEVER walk or ride through any person or vehicle.
func _resolve_agent_collisions() -> void:
	var p_sep := 0.92 if on_boda else 0.78
	for person in main.people:
		if not is_instance_valid(person) or not person.visible:
			continue
		var dx: float = position.x - person.global_position.x
		var dz: float = position.z - person.global_position.z
		if absf(dx) > 1.2 or absf(dz) > 1.2:
			continue
		var d := sqrt(dx * dx + dz * dz)
		if d < p_sep:
			if d < 0.001:
				dx = 0.1
				d = 0.1
			var overlap := p_sep - d
			var nx := dx / d
			var nz := dz / d
			position.x += nx * overlap * 0.75
			position.z += nz * overlap * 0.75
			# If it's a walking pedestrian, gently nudge them back too
			if person.get("points") != null and (person.points as PackedVector3Array).size() >= 2:
				person.position.x -= nx * overlap * 0.25
				person.position.z -= nz * overlap * 0.25
			if on_boda and speed > 2.5:
				speed *= 0.75
	if not on_boda and parked_boda and parked_boda.visible:
		var bdx: float = position.x - parked_boda.position.x
		var bdz: float = position.z - parked_boda.position.z
		var bd := sqrt(bdx * bdx + bdz * bdz)
		if bd < 0.82 and bd > 0.001:
			position.x += (bdx / bd) * (0.82 - bd)
			position.z += (bdz / bd) * (0.82 - bd)
	var pr := 0.56 if on_boda else 0.40
	for v in main.vehicles:
		if not is_instance_valid(v):
			continue
		var vpos: Vector3 = v.global_position
		var vdx: float = position.x - vpos.x
		var vdz: float = position.z - vpos.z
		var v_hl: float = float(v.length) * 0.5
		if absf(vdx) > v_hl + 2.2 or absf(vdz) > v_hl + 2.2:
			continue
		var vkind: String = str(v.get_meta("kind", "car"))
		var v_hw: float = 0.52 if vkind == "boda" else (1.22 if vkind in ["bus", "trailer"] else 1.02)
		var vfwd := Vector3(-sin(v.rotation.y), 0, -cos(v.rotation.y))
		var vside := Vector3(-vfwd.z, 0, vfwd.x)
		var sx := vdx * vside.x + vdz * vside.z
		var sz := vdx * vfwd.x + vdz * vfwd.z
		var ox := (v_hw + pr) - absf(sx)
		var oz := (v_hl + pr) - absf(sz)
		if ox > 0.0 and oz > 0.0:
			var push := Vector3.ZERO
			if ox < oz:
				push = vside * (ox if sx >= 0.0 else -ox)
			else:
				push = vfwd * (oz if sz >= 0.0 else -oz)
			position.x += push.x
			position.z += push.z
			if on_boda:
				var into := Vector3(-sin(heading), 0, -cos(heading)).dot(-push.normalized())
				if into > 0.25:
					speed = minf(speed, 1.5)


func _check_crash() -> void:
	var repair_cost: int = 5000 if main.get("has_helmet") else 8000
	var pr := 0.58 if on_boda else 0.40
	for o in main.vehicles:
		if not is_instance_valid(o):
			continue
		var vpos: Vector3 = o.global_position
		var vdx: float = position.x - vpos.x
		var vdz: float = position.z - vpos.z
		var v_hl: float = float(o.length) * 0.5
		if absf(vdx) > v_hl + 2.2 or absf(vdz) > v_hl + 2.2:
			continue
		var okind: String = str(o.get_meta("kind", "vehicle"))
		var v_hw: float = 0.54 if okind == "boda" else (1.24 if okind in ["bus", "trailer"] else 1.04)
		var vfwd := Vector3(-sin(o.rotation.y), 0, -cos(o.rotation.y))
		var vside := Vector3(-vfwd.z, 0, vfwd.x)
		var sx := vdx * vside.x + vdz * vside.z
		var sz := vdx * vfwd.x + vdz * vfwd.z
		if absf(sx) < v_hw + pr + 0.12 and absf(sz) < v_hl + pr + 0.12:
			_crash(okind, repair_cost)
			return
	for w in main.people:
		if not is_instance_valid(w) or not w.visible:
			continue
		var d2 := Vector2(w.global_position.x - position.x, w.global_position.z - position.z).length()
		if d2 < 0.92:
			_crash("pedestrian", 5000)
			return


func _crash(hit_kind: String, cost: int) -> void:
	_crash_cooldown = 3.5
	_pothole_jolt = 1.0
	speed = 0.0
	main.sfx.play("crash")
	if main.life:
		main.life.mood = maxf(0.0, main.life.mood - 12.0)
		main.life.energy = maxf(0.0, main.life.energy - 5.0)
	bike_health = maxf(0.0, bike_health - 24.0)
	if bike_health <= 0.0:
		_sync_boda_pose(0.0, 0.0)
		main.sfx.play("sputter")
		main.hud.toast("🔧 BODA BREAKDOWN! Engine damaged — roll your bike to a Boda Fundi Mechanic (or repair in Phone -> Garage)!")
		if main.jobs and main.jobs.state == 0:
			main.jobs.pause_dispatch("🔧 Bike Broken Down — Boda calls paused until repaired at a Boda Fundi or Garage!")
	elif main.has_method("trigger_accident_confrontation"):
		main.trigger_accident_confrontation(hit_kind, cost)
	else:
		main.add_money(-cost, "Crash repair / compensation")
		main.day_stats["crashes"] += cost
		main.hud.toast("Crash! Repairs cost UGX %s." % main.ugx(cost))
	if main.jobs:
		if main.jobs.has_method("on_cargo_bump"):
			main.jobs.on_cargo_bump()
		if main.jobs.state == 1 and main.jobs.is_passenger():
			main.adjust_rating(-0.15)
			main.jobs.cancel("Your passenger got off and walked away (-0.15 ★ rating). No fare.")


func refuel(cost_per_litre: int, budget_ugx := -1) -> int:
	var need := max_tank() - fuel
	var spend_cap := maxi(main.money, 0) if budget_ugx < 0 else mini(maxi(main.money, 0), budget_ugx)
	var affordable := float(spend_cap) / cost_per_litre
	var litres := minf(need, affordable)
	var cost := int(ceil(litres * cost_per_litre / 100.0) * 100)
	if budget_ugx > 0:
		cost = mini(cost, spend_cap)
	fuel += litres
	var ff := fuel_fraction()
	if ff > 0.25:
		fuel_warn_level = 0
	elif ff > 0.12:
		fuel_warn_level = 1
	elif fuel > 0.0:
		fuel_warn_level = 2
	if on_boda and fuel > 0.0:
		_sync_boda_pose(0.0, 0.0)
		if main.sfx:
			main.sfx.play("start", -4.0)
	return cost


func near_parked_boda() -> bool:
	return not on_boda and parked_boda.visible and \
		Vector2(position.x - parked_boda.position.x, position.z - parked_boda.position.z).length() < 3.0


func show_passenger(on: bool) -> void:
	passenger_body.visible = on and on_boda and fuel > 0.0
	if cargo_body and on:
		cargo_body.visible = false


func show_cargo(on: bool) -> void:
	if cargo_body:
		cargo_body.visible = on and on_boda and not passenger_body.visible


func hop_on() -> void:
	on_boda = true
	position = Vector3(parked_boda.position.x, position.y, parked_boda.position.z)
	heading = parked_boda.rotation.y
	speed = 0.0
	if fuel <= 0.0 or bike_health <= 0.0:
		# Out of fuel or broken down: cannot sit on the bike! Walk beside it and roll/push it
		_sync_boda_pose(0.0, 0.0)
		if main.sfx:
			main.sfx.play("pop", -2.0)
		if fuel <= 0.0:
			if main.has_method("route_to_nearest_pump"):
				main.route_to_nearest_pump(false)
			main.hud.toast("No fuel! Rolling your boda by hand — follow the blue GPS route or tap [F] on the Map for fuel.")
		else:
			main.hud.toast("Bike broken down! Roll your boda to any Boda Fundi Mechanic (or repair in Phone -> Garage).")
		return
	parked_boda.visible = false
	parked_boda.rotation.z = 0.0
	walk_body.visible = false
	walk_body.position = Vector3.ZERO
	boda_body.visible = true
	var has_job: bool = main.jobs != null and main.jobs.state == 1
	show_passenger(has_job and bool(main.jobs.is_passenger()))
	show_cargo(has_job and not bool(main.jobs.is_passenger()))
	if main.sfx:
		main.sfx.play("start", -4.0)


func get_off() -> void:
	on_boda = false
	var limit: float = main.HALF + 18.0
	var bx := clampf(position.x, -limit, limit)
	var bz := clampf(position.z, -limit, limit)
	parked_boda.position = Vector3(bx, main.ground_height(Vector3(bx, 0, bz)), bz)
	parked_boda.rotation.y = heading
	parked_boda.rotation.z = 0.0
	parked_boda.visible = true
	boda_body.visible = false
	passenger_body.visible = false
	if cargo_body:
		cargo_body.visible = false
	if headlight_beam:
		headlight_beam.visible = false
	walk_body.position = Vector3.ZERO
	walk_body.visible = true
	# step off to the left side of the bike
	position += Vector3(-cos(heading), 0, sin(heading)) * 0.9
	position.x = clampf(position.x, -limit, limit)
	position.z = clampf(position.z, -limit, limit)
	speed = 0.0


## Safety net: if you push the stick but haven't moved for 1.5 seconds, squeeze
## the player towards the nearest road. Nobody should ever be trapped.
func _unstick(delta: float, mag: float) -> void:
	var moved := Vector2(position.x - _last_pos.x, position.z - _last_pos.z).length()
	_last_pos = position
	if mag > 0.3 and moved < 0.025:
		_stuck_t += delta
	else:
		_stuck_t = 0.0
	if _stuck_t > 1.5:
		_stuck_t = 0.0
		var b: float = main.BLOCK
		var h: float = main.HALF
		var nx := clampf(roundf((position.x + h) / b) * b - h, -h, h)
		var nz := clampf(roundf((position.z + h) / b) * b - h, -h, h)
		var to := Vector3(nx - position.x, 0, 0) if absf(nx - position.x) < absf(nz - position.z) else Vector3(0, 0, nz - position.z)
		if to.length() > 0.01:
			position += to.normalized() * minf(1.8, to.length())
		speed = 0.0
