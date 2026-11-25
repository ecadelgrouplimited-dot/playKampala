extends Node3D
## A low-poly person with a real (tiny) skeleton, so they actually walk:
## legs swing, knees bend, arms swing opposite, hips bob.
## The whole body is ONE skinned mesh = one draw call, which keeps phones happy.
## Shapes are rounded (capsules, spheres, tapered cylinders), not boxes.

enum { HIPS, SPINE, HEAD, THIGH_L, SHIN_L, THIGH_R, SHIN_R, ARM_L, FORE_L, ARM_R, FORE_R }

# bone name, parent, offset from parent (metres, before scaling)
const RIG := [
	["hips", -1, Vector3(0, 0.95, 0)],
	["spine", HIPS, Vector3(0, 0.10, 0)],
	["head", SPINE, Vector3(0, 0.46, 0)],
	["thigh_l", HIPS, Vector3(-0.10, -0.03, 0)],
	["shin_l", THIGH_L, Vector3(0, -0.44, 0)],
	["thigh_r", HIPS, Vector3(0.10, -0.03, 0)],
	["shin_r", THIGH_R, Vector3(0, -0.44, 0)],
	["arm_l", SPINE, Vector3(-0.21, 0.36, 0)],
	["fore_l", ARM_L, Vector3(-0.02, -0.29, 0)],
	["arm_r", SPINE, Vector3(0.21, 0.36, 0)],
	["fore_r", ARM_R, Vector3(0.02, -0.29, 0)],
]

## Where the camera is looking: people far from it skip animation (saves CPU).
static var focus := Vector3.ZERO

var skel: Skeleton3D
var mesh_inst: MeshInstance3D
var phase := 0.0
var _hips_rest := Vector3.ZERO
var _was_moving := true


## parts: [mesh: PrimitiveMesh, xform: Transform3D (standing pose), colour, bone]
func build(parts: Array, mat: Material) -> void:
	if skel == null or not is_instance_valid(skel):
		for ch in get_children():
			ch.queue_free()
		skel = Skeleton3D.new()
		for b in RIG:
			var i := skel.add_bone(b[0])
			skel.set_bone_parent(i, b[1])
			skel.set_bone_rest(i, Transform3D(Basis.IDENTITY, b[2]))
		skel.reset_bone_poses()
		_hips_rest = RIG[0][2]
		add_child(skel)
		mesh_inst = MeshInstance3D.new()
		mesh_inst.visibility_range_end = 120.0
		skel.add_child(mesh_inst)   # default skeleton path ".." points at skel
	mesh_inst.mesh = _skinned_mesh(parts)
	mesh_inst.material_override = mat
	skel.reset_bone_poses()


static func _skinned_mesh(parts: Array) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var idx := PackedInt32Array()
	for p in parts:
		var m_src: Mesh = p[0]
		var arr: Array = (m_src as ArrayMesh).surface_get_arrays(0) if m_src is ArrayMesh else (m_src as PrimitiveMesh).get_mesh_arrays()
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var ind: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var xf: Transform3D = p[1]
		var nb := xf.basis.inverse().transposed()
		var c: Color = p[2]
		var bone: int = p[3]
		var base := verts.size()
		for k in v.size():
			verts.append(xf * v[k])
			norms.append((nb * n[k]).normalized())
			cols.append(c)
			bones.append_array([bone, 0, 0, 0])
			weights.append_array([1.0, 0.0, 0.0, 0.0])
		if ind.size() > 0:
			for k in ind:
				idx.append(base + k)
		else:
			for k in v.size():
				idx.append(base + k)
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = verts
	a[Mesh.ARRAY_NORMAL] = norms
	a[Mesh.ARRAY_COLOR] = cols
	a[Mesh.ARRAY_BONES] = bones
	a[Mesh.ARRAY_WEIGHTS] = weights
	a[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	return m


func _rot(bone: int, angle: float) -> void:
	skel.set_bone_pose_rotation(bone, Quaternion(Vector3.RIGHT, angle))


## speed in metres per second (0 = standing)
func animate(delta: float, speed: float) -> void:
	if skel == null:
		return
	if global_position.distance_squared_to(focus) > 70.0 * 70.0:
		return
	if speed > 0.05:
		_was_moving = true
		phase += delta * clampf(speed, 0.8, 4.2) * 2.65
		var amt := clampf(speed / 2.6, 0.32, 1.05)
		var s := sin(phase)
		var c := cos(phase)
		_rot(THIGH_L, s * 0.44 * amt)
		_rot(THIGH_R, -s * 0.44 * amt)
		_rot(SHIN_L, -maxf(0.0, c) * 0.68 * amt)
		_rot(SHIN_R, -maxf(0.0, -c) * 0.68 * amt)
		skel.set_bone_pose_rotation(ARM_L, Quaternion(Vector3.FORWARD, 0.09) * Quaternion(Vector3.RIGHT, -s * 0.36 * amt))
		skel.set_bone_pose_rotation(ARM_R, Quaternion(Vector3.FORWARD, -0.09) * Quaternion(Vector3.RIGHT, s * 0.36 * amt))
		_rot(FORE_L, 0.28 + maxf(0.0, -s) * 0.24 * amt)
		_rot(FORE_R, 0.28 + maxf(0.0, s) * 0.24 * amt)
		skel.set_bone_pose_rotation(SPINE, Quaternion(Vector3.UP, s * 0.055) * Quaternion(Vector3.RIGHT, -0.04 * amt))
		skel.set_bone_pose_position(HIPS, _hips_rest + Vector3(0, absf(c) * 0.026 * amt, 0))
	else:
		phase += delta * 1.6   # gentle breathing / weight shift
		if _was_moving:
			_was_moving = false
			for b in [THIGH_L, THIGH_R, SHIN_L, SHIN_R]:
				_rot(b, 0.0)
		var br := sin(phase) * 0.03
		skel.set_bone_pose_rotation(ARM_L, Quaternion(Vector3.FORWARD, 0.10) * Quaternion(Vector3.RIGHT, br))
		skel.set_bone_pose_rotation(ARM_R, Quaternion(Vector3.FORWARD, -0.10) * Quaternion(Vector3.RIGHT, -br))
		_rot(FORE_L, 0.22)
		_rot(FORE_R, 0.22)
		skel.set_bone_pose_rotation(SPINE, Quaternion(Vector3.RIGHT, br * 0.5))
		skel.set_bone_pose_position(HIPS, _hips_rest)


## Front-crawl / treading water animation for Lake Victoria swimming
func animate_swim(delta: float, moving: bool) -> void:
	if skel == null:
		return
	_was_moving = true
	phase += delta * (7.5 if moving else 3.2)
	var s := sin(phase)
	var c := cos(phase)
	if moving:
		_rot(ARM_L, -1.6 + s * 1.15)
		_rot(ARM_R, -1.6 - s * 1.15)
		_rot(FORE_L, 0.45 + maxf(0.0, c) * 0.5)
		_rot(FORE_R, 0.45 + maxf(0.0, -c) * 0.5)
		_rot(THIGH_L, s * 0.45)
		_rot(THIGH_R, -s * 0.45)
		_rot(SHIN_L, -0.25 + c * 0.35)
		_rot(SHIN_R, -0.25 - c * 0.35)
		skel.set_bone_pose_rotation(SPINE, Quaternion(Vector3.UP, s * 0.14))
	else:
		_rot(ARM_L, -0.5 + s * 0.4)
		_rot(ARM_R, -0.5 - s * 0.4)
		_rot(FORE_L, 0.65)
		_rot(FORE_R, 0.65)
		_rot(THIGH_L, s * 0.25)
		_rot(THIGH_R, -s * 0.25)
		_rot(SHIN_L, -0.2)
		_rot(SHIN_R, -0.2)
		skel.set_bone_pose_rotation(SPINE, Quaternion.IDENTITY)
	skel.set_bone_pose_position(HIPS, _hips_rest)
