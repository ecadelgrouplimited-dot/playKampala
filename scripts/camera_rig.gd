extends Node3D
## Townscaper-style camera: angled view that orbits a point on the ground.
## Phone: one finger drag = rotate/tilt, two fingers = pinch zoom (+ pan when free).
## Desktop: left drag = rotate/tilt, right drag = pan, wheel = zoom.
## When following the player on a boda, the camera pulls back as you speed up
## and widens its view a little, so fast riding feels fast and you see further ahead.

const VIEWS := [
	[9.0, -13.5, 50.0],    # Street-level cinematic chase (shows golden sky, hills, palms, arcades & traffic!)
	[14.5, -26.0, 42.0],   # Cruise mid-angle
	[24.0, -48.0, 36.0],   # Overhead city view
]

var cam: Camera3D
var yaw := deg_to_rad(0.0)
var pitch := deg_to_rad(-13.5)
var dist := 9.0
var base_dist := 9.0     # what the player chose (pinch / View button)
var base_pitch := deg_to_rad(-13.5)
var base_fov := 50.0
var target := Vector3(0, 1.4, 0)
var follow: Node3D        # when set, the camera tracks this node (the player)
var view_index := 0
var _manual_cam_t := 0.0

var _touches := {}
var _last_pinch := 0.0


func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = base_fov
	cam.far = 950.0
	cam.near = 0.35
	add_child(cam)
	_update()


func cycle_view() -> int:
	view_index = (view_index + 1) % VIEWS.size()
	var v: Array = VIEWS[view_index]
	base_dist = float(v[0])
	base_pitch = deg_to_rad(float(v[1]))
	pitch = base_pitch
	base_fov = float(v[2])
	return view_index


func _update() -> void:
	base_dist = clampf(base_dist, 6.0, 110.0)
	dist = clampf(dist, 6.0, 130.0)
	pitch = clampf(pitch, deg_to_rad(-72.0), deg_to_rad(-9.0))
	target.x = clampf(target.x, -340.0, 340.0)
	target.z = clampf(target.z, -340.0, 340.0)
	basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	position = target
	cam.position = Vector3(0, 0, dist)


func _process(delta: float) -> void:
	_manual_cam_t = maxf(0.0, _manual_cam_t - delta)
	var extra := 0.0
	var want_base := base_dist
	if follow:
		var p := follow.global_position
		var lead := Vector3.ZERO
		if follow.get("on_boda"):
			if follow.speed > 1.2:
				extra = follow.speed * 0.24
				lead = Vector3(-sin(follow.heading), 0, -cos(follow.heading)) * (1.2 + follow.speed * 0.22)
				# Gently swing camera behind the motorcycle while riding so you look down the Kampala street!
				if _manual_cam_t <= 0.0 and view_index < 2:
					yaw = lerp_angle(yaw, follow.heading, clampf(delta * 2.2, 0.0, 1.0))
		else:
			want_base = minf(base_dist, 9.2)
		var look_y := 2.05 if view_index == 0 else 1.45
		target = target.lerp(Vector3(p.x, p.y + look_y, p.z) + lead, 1.0 - exp(-7.5 * delta))
	dist = lerpf(dist, want_base + extra, 1.0 - exp(-4.0 * delta))
	cam.fov = lerpf(cam.fov, base_fov + extra * 1.1, 1.0 - exp(-3.0 * delta))
	_update()


func _pan(rel: Vector2) -> void:
	if follow:
		return
	var k := dist * 0.0018
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	target -= right * rel.x * k + fwd * rel.y * k


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
		else:
			_touches.erase(e.index)
		_last_pinch = 0.0
	elif e is InputEventScreenDrag:
		_touches[e.index] = e.position
		if _touches.size() == 1:
			yaw -= e.relative.x * 0.006
			pitch -= e.relative.y * 0.004
			_manual_cam_t = 3.5
		elif _touches.size() >= 2:
			var pts: Array = _touches.values()
			var d: float = (pts[0] as Vector2).distance_to(pts[1])
			if _last_pinch > 0.0 and d > 1.0:
				base_dist *= _last_pinch / d
			_last_pinch = d
			_pan(e.relative * 0.5)
	elif e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			base_dist *= 0.9
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			base_dist *= 1.1
	elif e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION:
		if e.button_mask & MOUSE_BUTTON_MASK_LEFT:
			yaw -= e.relative.x * 0.006
			pitch -= e.relative.y * 0.004
			_manual_cam_t = 3.5
		elif e.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_pan(e.relative)
	elif e is InputEventMagnifyGesture:
		base_dist /= e.factor
	elif e is InputEventPanGesture:
		_pan(e.delta * 10.0)
	_update()
