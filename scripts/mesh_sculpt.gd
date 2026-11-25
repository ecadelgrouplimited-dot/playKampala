class_name MeshSculpt
## Procedural sculpted low-poly 3D mesh builders (beveled profiles, curved fronds,
## sloped vehicles, teardrop tanks, arches & faceted foliage) for PlayKampala.

static var _cache := {}


## Extrudes a 2D side profile (in Y-Z plane, CCW or CW) along X with optional
## side bevel so vehicles, tanks, and roofs look sculpted rather than boxy.
static func extrude_profile(key: String, pts_yz: Array, width_x: float, bevel_x := 0.08, bevel_inset := 0.05) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	var n := pts_yz.size()
	var hw := width_x * 0.5
	var iw := maxf(0.01, hw - bevel_x)
	var cy := 0.0
	var cz := 0.0
	for p in pts_yz:
		cy += (p as Vector2).x
		cz += (p as Vector2).y
	cy /= float(n)
	cz /= float(n)

	# Ensure clockwise profile orientation in (Y, Z) so outward normals face exterior (+Y on roof, -Z on front)
	var area2 := 0.0
	for i in n:
		var p0: Vector2 = pts_yz[i]
		var p1: Vector2 = pts_yz[(i + 1) % n]
		area2 += (p1.x - p0.x) * (p1.y + p0.y)
	var ordered_pts := pts_yz.duplicate()
	if area2 > 0.0:
		ordered_pts.reverse()

	# 4 rings along X: -hw (inset), -iw (full), +iw (full), +hw (inset)
	var rings := []
	for spec in [[-hw, bevel_inset], [-iw, 0.0], [iw, 0.0], [hw, bevel_inset]]:
		var rx: float = spec[0]
		var ins: float = spec[1]
		var ring := PackedVector3Array()
		for p in ordered_pts:
			var py: float = (p as Vector2).x
			var pz: float = (p as Vector2).y
			if ins > 0.0:
				var d := Vector2(py - cy, pz - cz)
				if d.length() > 0.001:
					var f := maxf(0.2, 1.0 - ins / d.length())
					py = cy + d.x * f
					pz = cz + d.y * f
			ring.append(Vector3(rx, py, pz))
		rings.append(ring)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Connect adjacent rings with outward-facing Godot CW winding
	for r in 3:
		var a: PackedVector3Array = rings[r]
		var b: PackedVector3Array = rings[r + 1]
		for i in n:
			var j := (i + 1) % n
			_quad(st, a[i], b[i], b[j], a[j])

	# Cap left (-hw, normal -X) and right (+hw, normal +X) sides
	var left_ring: PackedVector3Array = rings[0]
	var right_ring: PackedVector3Array = rings[3]
	var c_left := Vector3(-hw, cy, cz)
	var c_right := Vector3(hw, cy, cz)
	for i in n:
		var j := (i + 1) % n
		_tri(st, c_left, left_ring[i], left_ring[j])
		_tri(st, c_right, right_ring[j], right_ring[i])

	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


## Curved tropical banana / palm frond along -Z (root at origin, drooping tip).
static func curved_frond(key: String, length: float, width: float) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 5
	var hw := width * 0.5
	for i in segs:
		var t0 := float(i) / segs
		var t1 := float(i + 1) / segs
		var w0 := hw * sin(clampf(t0 * 0.85 + 0.12, 0.0, 1.0) * PI)
		var w1 := hw * sin(clampf(t1 * 0.85 + 0.12, 0.0, 1.0) * PI)
		var y0 := sin(t0 * PI * 0.72) * length * 0.24 - t0 * t0 * length * 0.34
		var y1 := sin(t1 * PI * 0.72) * length * 0.24 - t1 * t1 * length * 0.34
		var z0 := -t0 * length
		var z1 := -t1 * length
		var spine0 := Vector3(0, y0 + 0.04, z0)
		var spine1 := Vector3(0, y1 + 0.04, z1)
		var l0 := Vector3(-w0, y0 - 0.04, z0)
		var l1 := Vector3(-w1, y1 - 0.04, z1)
		var r0 := Vector3(w0, y0 - 0.04, z0)
		var r1 := Vector3(w1, y1 - 0.04, z1)
		# Double-sided leaf facets (top & underside)
		_quad(st, l0, spine0, spine1, l1)
		_quad(st, spine0, r0, r1, spine1)
		_quad(st, l1, spine1, spine0, l0)
		_quad(st, spine1, r1, r0, spine0)
	st.generate_normals()
	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


## Crisp low-poly faceted bush/canopy sphere with gentle organic variation.
static func faceted_canopy(key: String, radius: float, squash_y := 0.75, seed_val := 7) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	var sp := SphereMesh.new()
	sp.radius = radius
	sp.height = radius * 2.0 * squash_y
	sp.radial_segments = 8
	sp.rings = 4
	var arr := sp.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ind: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var r := RandomNumberGenerator.new()
	r.seed = seed_val
	var jittered := PackedVector3Array()
	for v in verts:
		var h := int(roundf(v.x * 13.0)) * 73856093 ^ int(roundf(v.y * 13.0)) * 19349663 ^ int(roundf(v.z * 13.0)) * 83492791
		r.seed = seed_val + h
		var sc := r.randf_range(0.84, 1.16)
		jittered.append(v * sc)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(0, ind.size(), 3):
		_tri(st, jittered[ind[k]], jittered[ind[k + 1]], jittered[ind[k + 2]])
	st.generate_normals()
	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (c - a).cross(b - a).normalized()
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)
