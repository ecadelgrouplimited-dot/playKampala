extends Node3D
## Moves a boda, taxi or person along a list of points.
## mode 0 = drive through and wrap back to the start (traffic)
## mode 1 = walk back and forth with little pauses (people)
## no points = stand and sway (vendors, customers, conductors)
##
## Vehicles look ahead in their lane and slow down or stop for the player,
## other vehicles and people on the zebra crossing.

var points := PackedVector3Array()
var speed := 2.0
var mode := 0
var bob := 0.0
var weave := 0.0
var speed_mul := 1.0
var body: Node3D
var main: Node
var is_vehicle := false
var length := 2.0          # used by others to judge gaps

var cur_speed := 0.0
var _idx := 1
var _step := 1
var _pause := 0.0
var _t := 0.0
var _phase := 0.0
var _stuck := 0.0
var _ignore := 0.0


func _ready() -> void:
	_phase = randf() * 10.0


func start_at(fraction: float) -> void:
	if points.size() >= 2:
		position = points[0].lerp(points[1], fraction)
		_idx = 1
		var to := points[1] - points[0]
		rotation.y = atan2(-to.x, -to.z)
		cur_speed = speed


func _process(delta: float) -> void:
	_t += delta
	if body == null:
		return
	var animated := body.has_method("animate")
	if points.size() < 2:
		# idle: small sway, like someone chatting or waiting
		body.rotation.y = sin(_t * 0.7 + _phase) * 0.25
		if animated:
			body.animate(delta, 0.0)
		else:
			body.position.y = 0.0
		return

	if _pause > 0.0:
		_pause -= delta
		if animated:
			body.animate(delta, 0.0)
		else:
			body.position.y = 0.0
		return

	var target := points[_idx]
	var to := target - position
	to.y = 0.0
	var d := to.length()

	var want := speed * speed_mul
	var steer := Vector3.ZERO
	if is_vehicle:
		want = _traffic_speed(want, delta)
		cur_speed = move_toward(cur_speed, want, (6.0 if want > cur_speed else 18.0) * delta)
	else:
		if d > 0.001 and main != null:
			var fwd := to / d
			var side := Vector3(-fwd.z, 0, fwd.x)
			# Check player first so pedestrians never walk through you
			if main.player != null:
				var dp_p: Vector3 = main.player.global_position - global_position
				dp_p.y = 0.0
				var dist_p := dp_p.length()
				if dist_p < 1.8:
					var ahead_p := dp_p.dot(fwd)
					var lat_p := dp_p.dot(side)
					if ahead_p > -0.2 and ahead_p < 1.45 and absf(lat_p) < 0.85:
						steer += side * (-1.0 if lat_p >= 0.0 else 1.0) * 1.15
						if dist_p < 0.95:
							want *= 0.25
			# Check nearby pedestrians so people steer around each other instead of passing through
			for other in main.people:
				if other == self or not is_instance_valid(other):
					continue
				var dp_o: Vector3 = other.position - position
				if absf(dp_o.x) > 1.6 or absf(dp_o.z) > 1.6:
					continue
				dp_o.y = 0.0
				var dist_o := dp_o.length()
				if dist_o < 1.45 and dist_o > 0.001:
					var ahead_o := dp_o.dot(fwd)
					var lat_o := dp_o.dot(side)
					if ahead_o > -0.15 and ahead_o < 1.3 and absf(lat_o) < 0.78:
						steer += side * (-1.0 if lat_o >= 0.0 else 1.0) * 0.95
						if dist_o < 0.78:
							want *= 0.35
		cur_speed = want
	var mv := cur_speed * delta

	if d <= mv:
		position = Vector3(target.x, position.y, target.z)
		if mode == 0:
			_idx += 1
			if _idx >= points.size():
				position = points[0]
				_idx = 1
		else:
			_idx += _step
			if _idx >= points.size() or _idx < 0:
				_step = -_step
				_idx += 2 * _step
				_pause = randf_range(0.5, 3.0)
	elif d > 0.001:
		var move_dir := (to / d + steer).normalized()
		position += move_dir * mv
		rotation.y = lerp_angle(rotation.y, atan2(-move_dir.x, -move_dir.z), clampf(delta * 10.0, 0.0, 1.0))
		# Hard personal-space separation so walkers never clip through the player or other people
		if not is_vehicle and main != null:
			if main.player != null:
				var pdx: float = position.x - main.player.position.x
				var pdz: float = position.z - main.player.position.z
				var pdist := sqrt(pdx * pdx + pdz * pdz)
				var psep := 0.92 if main.player.on_boda else 0.78
				if pdist < psep and pdist > 0.001:
					position.x += (pdx / pdist) * (psep - pdist)
					position.z += (pdz / pdist) * (psep - pdist)
			for other in main.people:
				if other == self or not is_instance_valid(other):
					continue
				var odx: float = position.x - other.position.x
				var odz: float = position.z - other.position.z
				if absf(odx) > 0.8 or absf(odz) > 0.8:
					continue
				var odist := sqrt(odx * odx + odz * odz)
				if odist < 0.72 and odist > 0.001:
					position.x += (odx / odist) * (0.72 - odist) * 0.6
					position.z += (odz / odist) * (0.72 - odist) * 0.6

	if animated:
		body.animate(delta, cur_speed)
	elif bob > 0.0 and cur_speed > 0.1:
		body.position.y = absf(sin(_t * cur_speed * 3.2 + _phase)) * bob
	if weave > 0.0:
		body.position.x = sin(_t * 1.3 + _phase) * weave


## Look down the lane: slow for anything close ahead, stop if very close.
func _traffic_speed(want: float, delta: float) -> float:
	if main == null:
		return want
	if _ignore > 0.0:
		_ignore -= delta
		return want
	var fwd := Vector3(-sin(rotation.y), 0, -cos(rotation.y))
	var side := Vector3(-fwd.z, 0, fwd.x)
	var result := want
	for o in main.obstacles:
		if o == self or not is_instance_valid(o) or not o.visible:
			continue
		var dp: Vector3 = o.global_position - global_position
		dp.y = 0.0
		var ahead := dp.dot(fwd)
		if ahead <= 0.0 or ahead > 10.0:
			continue
		var lateral := absf(dp.dot(side))
		if lateral > 1.7:
			continue
		var gap := ahead - length * 0.5 - 1.2
		if gap < 1.5:
			result = 0.0
			break
		result = minf(result, want * clampf(gap / 7.0, 0.2, 1.0))
	# stuck for too long (Kampala junction stand-off): somebody has to go
	if result < 0.1:
		_stuck += delta
		if _stuck > 5.0:
			_stuck = 0.0
			_ignore = 1.5
	else:
		_stuck = 0.0
	return result
