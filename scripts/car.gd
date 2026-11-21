extends Node3D
## A vehicle that drives the city's road graph, junction to junction.
## - keeps to the LEFT lane (Uganda)
## - at each junction picks a new road (straight is most likely)
## - only one vehicle crosses a junction at a time (simple give-way)
## - brakes for anything close ahead in its lane, and hoots when stuck

var main: Node
var body: Node3D
var headlight: MeshInstance3D
var speed := 8.0
var cur_speed := 0.0
var length := 2.0
var lane := 2.0
var weave := 0.0
var kind := "car"

var a := 0           # current road: from node a ...
var b := 1           # ... to node b
var _next := -1
var _target := Vector3.ZERO
var _crossing := false
var _stuck := 0.0
var _accident_timer := 0.0
var _t := 0.0
var _phase := 0.0
var _honk_cool := 0.0
var _blocked_by_player := 0.0
var _stop_timer := 0.0
var _stop_cool := 6.0


func setup(m: Node, from_node: int, to_node: int, frac: float) -> void:
	main = m
	a = from_node
	b = to_node
	_phase = randf() * 10.0
	_stop_cool = randf_range(4.0, 16.0)
	var seg := _lane(a, b)
	position = seg[0].lerp(seg[1], frac)
	_target = seg[1]
	_face(_target - position)
	cur_speed = speed * 0.5


func _lane(n1: int, n2: int) -> Array:
	var p1: Vector3 = main.nodes[n1]
	var p2: Vector3 = main.nodes[n2]
	var d := (p2 - p1).normalized()
	var left := Vector3(d.z, 0, -d.x)
	var r: float = main.JUNCTION_R
	var y := Vector3(0, 0.04, 0)
	return [p1 + d * r + left * lane + y, p2 - d * r + left * lane + y]


func _face(dir: Vector3) -> void:
	if dir.length() > 0.01:
		rotation.y = atan2(-dir.x, -dir.z)


func _pick_next() -> int:
	var options: Array = main.adj[b].duplicate()
	if options.size() > 1:
		options.erase(a)
	var here: Vector3 = main.nodes[b]
	var dir_in: Vector3 = (here - main.nodes[a]).normalized()
	# Bias traffic toward bustling central Kampala (Kikuubo, Old Taxi Park, Clock Tower, Wandegeya, Owino)
	var central_opts := []
	for o in options:
		var np: Vector3 = main.nodes[o]
		if absf(np.x) <= main.BLOCK + 1.0 and absf(np.z) <= main.BLOCK + 1.0:
			central_opts.append(o)
	if not central_opts.is_empty() and randf() < 0.72:
		options = central_opts
	# prefer going straight on
	for o in options:
		var d: Vector3 = (main.nodes[o] - here).normalized()
		if d.dot(dir_in) > 0.9 and randf() < 0.55:
			return o
	return options[randi() % options.size()]


func _process(delta: float) -> void:
	_t += delta
	if headlight:
		headlight.visible = main.night_amount > 0.25 or main.raining
	_honk_cool = maxf(0.0, _honk_cool - delta)
	_stop_cool = maxf(0.0, _stop_cool - delta)
	var to := _target - position
	to.y = 0.0
	var dist := to.length()

	# Active AI-to-AI roadside accident pause: both vehicles stay halted as real obstacles!
	if _accident_timer > 0.0:
		_accident_timer -= delta
		cur_speed = 0.0
		if body:
			body.rotation.z = lerpf(body.rotation.z, 0.09 if _accident_timer > 1.0 else 0.0, clampf(delta * 6.0, 0.0, 1.0))
		return
	elif body and weave <= 0.0 and absf(body.rotation.z) > 0.002:
		body.rotation.z = lerpf(body.rotation.z, 0.0, clampf(delta * 5.0, 0.0, 1.0))

	# Matatu taxis periodically pause along busy streets to pick up / offload passengers, creating real Kampala traffic jams
	if _stop_timer > 0.0:
		_stop_timer -= delta
		cur_speed = move_toward(cur_speed, 0.0, 18.0 * delta)
		return
	elif kind == "taxi" and not _crossing and _stop_cool <= 0.0 and dist > 14.0 and dist < 42.0:
		if absf(position.x) <= main.BLOCK + 8.0 and absf(position.z) <= main.BLOCK + 8.0 and randf() < 0.35:
			_stop_timer = randf_range(2.6, 4.5)
			_stop_cool = randf_range(12.0, 22.0)
			if _honk_cool <= 0.0 and randf() < 0.55:
				_honk_cool = 7.0
				main.honk_from(global_position, kind)
			return

	var base_spd: float = speed * (0.72 if main.is_rush_hour() else 1.0)
	if main.has_method("in_roadwork") and main.in_roadwork(global_position):
		base_spd *= 0.42
	var want := _traffic_speed(base_spd, delta)
	cur_speed = move_toward(cur_speed, want, (6.0 if want > cur_speed else 22.0) * delta)
	var mv := cur_speed * delta

	if dist <= mv + 0.05:
		var cand_pos := Vector3(_target.x, position.y, _target.z)
		if not _would_overlap_vehicle(cand_pos):
			position = cand_pos
			if not _crossing:
				# at the stop line: choose a road and wait for the junction to be clear
				if _next == -1:
					_next = _pick_next()
				if main.request_junction(b, self):
					_crossing = true
					_target = _lane(b, _next)[0]
				else:
					cur_speed = 0.0
			else:
				# across the junction: release it and drive the new road
				main.release_junction(b, self)
				_crossing = false
				a = b
				b = _next
				_next = -1
				_target = _lane(a, b)[1]
		else:
			cur_speed = 0.0
	elif dist > 0.001 and mv > 0.0001:
		var next_pos := position + to / dist * mv
		var hit_v := _find_overlap_vehicle(next_pos)
		if hit_v == null:
			position = next_pos
			var turn := atan2(-to.x, -to.z)
			rotation.y = lerp_angle(rotation.y, turn, clampf(delta * 9.0, 0.0, 1.0))
		else:
			if cur_speed > 3.6 and hit_v.has_method("on_ai_accident") and _accident_timer <= 0.0:
				on_ai_accident(hit_v)
				hit_v.on_ai_accident(self)
			cur_speed = 0.0

	if weave > 0.0:
		body.position.x = sin(_t * 1.4 + _phase) * weave
		body.rotation.z = -cos(_t * 1.4 + _phase) * weave * 0.4


static func _v_half_width(k: String) -> float:
	return 0.52 if k == "boda" else (1.22 if k in ["bus", "trailer"] else 1.02)


func _find_overlap_vehicle(test_pos: Vector3) -> Node3D:
	var my_hw := _v_half_width(kind)
	var my_hl := length * 0.5
	var my_fwd := Vector3(-sin(rotation.y), 0, -cos(rotation.y))
	var my_side := Vector3(-my_fwd.z, 0, my_fwd.x)
	for o in main.vehicles:
		if o == self or not is_instance_valid(o) or not o.visible:
			continue
		var dp: Vector3 = o.global_position - test_pos
		dp.y = 0.0
		var o_hl: float = float(o.length) * 0.5
		if absf(dp.x) > my_hl + o_hl + 2.5 or absf(dp.z) > my_hl + o_hl + 2.5:
			continue
		var o_hw := _v_half_width(str(o.get("kind")))
		var o_fwd := Vector3(-sin(o.rotation.y), 0, -cos(o.rotation.y))
		var o_side := Vector3(-o_fwd.z, 0, o_fwd.x)
		# Separating-axis check along both vehicles' local axes (exact OBB overlap!)
		var a_l := absf(dp.dot(my_fwd))
		var a_w := absf(dp.dot(my_side))
		var proj_l := o_hl * absf(o_fwd.dot(my_fwd)) + o_hw * absf(o_side.dot(my_fwd))
		var proj_w := o_hl * absf(o_fwd.dot(my_side)) + o_hw * absf(o_side.dot(my_side))
		if a_l < my_hl + proj_l + 0.25 and a_w < my_hw + proj_w + 0.15:
			var b_l := absf(dp.dot(o_fwd))
			var b_w := absf(dp.dot(o_side))
			var proj_bl := my_hl * absf(my_fwd.dot(o_fwd)) + my_hw * absf(my_side.dot(o_fwd))
			var proj_bw := my_hl * absf(my_fwd.dot(o_side)) + my_hw * absf(my_side.dot(o_side))
			if b_l < o_hl + proj_bl + 0.25 and b_w < o_hw + proj_bw + 0.15:
				return o
	return null


func _would_overlap_vehicle(test_pos: Vector3) -> bool:
	return _find_overlap_vehicle(test_pos) != null


func on_ai_accident(other: Node3D) -> void:
	if _accident_timer > 0.0:
		return
	_accident_timer = randf_range(7.0, 11.0)
	cur_speed = 0.0
	if main and main.player and global_position.distance_to(main.player.position) < 44.0:
		if main.sfx:
			main.sfx.play("crash", -6.0, randf_range(0.9, 1.08))
		main.honk_from(global_position, kind)
		if main.hud and main.hud.has_method("show_voice_subtitle"):
			var okind := str(other.get("kind")) if other else "vehicle"
			main.hud.show_voice_subtitle("💥 Road Accident (%s & %s)" % [kind.capitalize(), okind.capitalize()], "Ehh! Look at my bumper! Why did you stop like that?!")


## Look down the lane: slow for anything close ahead, stop if very close. NEVER ghost through obstacles!
func _traffic_speed(want: float, delta: float) -> float:
	var fwd := Vector3(-sin(rotation.y), 0, -cos(rotation.y))
	var side := Vector3(-fwd.z, 0, fwd.x)
	var my_hw := _v_half_width(kind)
	var result := want
	var blocker: Node3D = null
	for o in main.obstacles:
		if o == self or not is_instance_valid(o) or not o.visible:
			continue
		var dp: Vector3 = o.global_position - global_position
		dp.y = 0.0
		if absf(dp.x) > 19.0 or absf(dp.z) > 19.0:
			continue
		var ahead := dp.dot(fwd)
		if ahead <= 0.0 or ahead > 18.0:
			continue
		var o_kind := str(o.get("kind")) if o.get("kind") != null else "car"
		var o_hw := _v_half_width(o_kind) if o != main.player else (0.58 if main.player.on_boda else 0.45)
		if absf(dp.dot(side)) > my_hw + o_hw + 0.30:
			continue
		var o_len: float = float(o.get("length")) if o.get("length") != null else (2.0 if (o == main.player and main.player.on_boda) else 1.2)
		var gap := ahead - length * 0.5 - o_len * 0.5 - 0.55
		if gap < 1.35:
			result = 0.0
			blocker = o
			break
		result = minf(result, want * clampf(gap / 7.5, 0.16, 1.0))
	if result < 0.1:
		_stuck += delta
		# hoot when stuck in a Kampala jam or blocked by the player
		if blocker == main.player:
			_blocked_by_player += delta
			if _blocked_by_player > 1.2 and _honk_cool <= 0.0:
				_honk_cool = randf_range(3.5, 6.0)
				main.honk_from(global_position, kind)
		elif _stuck > 2.4 and _honk_cool <= 0.0 and randf() < 0.03:
			_honk_cool = randf_range(6.0, 12.0)
			main.honk_from(global_position, kind)
	else:
		_stuck = 0.0
		_blocked_by_player = 0.0
	return result

