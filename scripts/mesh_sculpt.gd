class_name MeshSculpt
## Procedural sculpted 3D mesh builders for PlayKampala:
## - Organic revolved anatomy (torso, muscular limbs, heads, open-face helmets)
## - 3D torus tires with 5-spoke cast-alloy wheels
## - Semi-circular masonry veranda arches for Kampala shop-houses
## - Beveled vehicle profiles & V-folded arched tropical palm fronds

static var _cache := {}


## Smoothly revolved 3D lathe mesh around Y axis from [Vector2(radius, y), ...] (bottom to top).
## Produces organic, seamless torsos, muscular arms/legs, heads, and helmets with smooth normals!
static func lathe_profile(key: String, pts_ry: Array, radial_segs := 14, scale_xz := Vector2.ONE, angle_span := TAU, angle_offset := 0.0) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	var m_pts := pts_ry.size()
	var closed := absf(angle_span - TAU) < 0.001
	var cols := radial_segs if closed else (radial_segs + 1)
	var rings := []
	var ring_nrms := []
	for j in m_pts:
		var p_cur: Vector2 = pts_ry[j]
		var p_prev: Vector2 = pts_ry[maxi(0, j - 1)]
		var p_next: Vector2 = pts_ry[mini(m_pts - 1, j + 1)]
		var tang := (p_next - p_prev)
		var nr := tang.y
		var ny := -tang.x
		var nlen := sqrt(nr * nr + ny * ny)
		if nlen > 0.0001:
			nr /= nlen
			ny /= nlen
		else:
			nr = 1.0
			ny = 0.0
		var ring := PackedVector3Array()
		var nring := PackedVector3Array()
		for i in cols:
			var a := angle_offset + (float(i) / float(radial_segs)) * angle_span
			var ca := cos(a)
			var sa := sin(a)
			ring.append(Vector3(ca * p_cur.x * scale_xz.x, p_cur.y, sa * p_cur.x * scale_xz.y))
			var wn := Vector3(ca * nr / maxf(0.2, scale_xz.x), ny, sa * nr / maxf(0.2, scale_xz.y)).normalized()
			nring.append(wn)
		rings.append(ring)
		ring_nrms.append(nring)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(m_pts - 1):
		var r0: PackedVector3Array = rings[j]
		var r1: PackedVector3Array = rings[j + 1]
		var n0: PackedVector3Array = ring_nrms[j]
		var n1: PackedVector3Array = ring_nrms[j + 1]
		for i in radial_segs:
			var i1 := (i + 1) % radial_segs if closed else (i + 1)
			# Outward CW winding in Godot 4: r0[i] -> r0[i1] -> r1[i1] -> r1[i] gives outward normal +r!
			_smooth_quad(st, r0[i], r0[i1], r1[i1], r1[i], n0[i], n0[i1], n1[i1], n1[i])
			if not closed:
				# Inner shell face
				_smooth_quad(st, r0[i], r1[i], r1[i1], r0[i1], -n0[i], -n1[i], -n1[i1], -n0[i1])

	# Cap bottom (-Y normal) & top (+Y normal) if radius > 0.004
	var p_bot: Vector2 = pts_ry[0]
	if closed and p_bot.x > 0.004:
		var c_b := Vector3(0, p_bot.y, 0)
		var r_b: PackedVector3Array = rings[0]
		for i in radial_segs:
			var i1 := (i + 1) % radial_segs
			_tri(st, c_b, r_b[i1], r_b[i])
	var p_top: Vector2 = pts_ry[m_pts - 1]
	if closed and p_top.x > 0.004:
		var c_t := Vector3(0, p_top.y, 0)
		var r_t: PackedVector3Array = rings[m_pts - 1]
		for i in radial_segs:
			var i1 := (i + 1) % radial_segs
			_tri(st, c_t, r_t[i], r_t[i1])

	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


## 3D rounded rubber tire torus + alloy rim ring + open cast-alloy spokes (axis along X, centered at origin).
## Returns Array of [ArrayMesh, is_metal: bool] cached as two meshes: [tire_mesh, rim_spokes_mesh].
static func spoked_wheel_pair(key: String, outer_r: float, tire_thick: float, width: float, spokes := 5) -> Array:
	if _cache.has(key):
		return _cache[key]
	var major_r := outer_r - tire_thick * 0.52
	var minor_r := tire_thick * 0.52
	var u_segs := 18
	var v_segs := 10
	var st_tire := SurfaceTool.new()
	st_tire.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in u_segs:
		var u0 := float(i) / u_segs * TAU
		var u1 := float(i + 1) / u_segs * TAU
		for j in v_segs:
			var v0 := float(j) / v_segs * TAU
			var v1 := float(j + 1) / v_segs * TAU
			var p00 := _torus_pt(u0, v0, major_r, minor_r, width * 0.5)
			var p10 := _torus_pt(u1, v0, major_r, minor_r, width * 0.5)
			var p11 := _torus_pt(u1, v1, major_r, minor_r, width * 0.5)
			var p01 := _torus_pt(u0, v1, major_r, minor_r, width * 0.5)
			var n00 := _torus_nrm(u0, v0)
			var n10 := _torus_nrm(u1, v0)
			var n11 := _torus_nrm(u1, v1)
			var n01 := _torus_nrm(u0, v1)
			_smooth_quad(st_tire, p00, p10, p11, p01, n00, n10, n11, n01)
	var tire_mesh := st_tire.commit()

	# Rim ring + center hub + 5 angled alloy spokes (with real open gaps!)
	var st_rim := SurfaceTool.new()
	st_rim.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim_outer := outer_r - tire_thick * 0.88
	var rim_inner := rim_outer * 0.82
	var rw := width * 0.40
	for i in u_segs:
		var a0 := float(i) / u_segs * TAU
		var a1 := float(i + 1) / u_segs * TAU
		var o0l := Vector3(-rw, sin(a0) * rim_outer, cos(a0) * rim_outer)
		var o1l := Vector3(-rw, sin(a1) * rim_outer, cos(a1) * rim_outer)
		var i0l := Vector3(-rw, sin(a0) * rim_inner, cos(a0) * rim_inner)
		var i1l := Vector3(-rw, sin(a1) * rim_inner, cos(a1) * rim_inner)
		var o0r := Vector3(rw, sin(a0) * rim_outer, cos(a0) * rim_outer)
		var o1r := Vector3(rw, sin(a1) * rim_outer, cos(a1) * rim_outer)
		var i0r := Vector3(rw, sin(a0) * rim_inner, cos(a0) * rim_inner)
		var i1r := Vector3(rw, sin(a1) * rim_inner, cos(a1) * rim_inner)
		_quad(st_rim, i0l, o0l, o1l, i1l)
		_quad(st_rim, o0r, i0r, i1r, o1r)
		_quad(st_rim, i0r, i0l, i1l, i1r)

	var hub_r := outer_r * 0.22
	var hw := width * 0.46
	for i in 10:
		var a0 := float(i) / 10.0 * TAU
		var a1 := float(i + 1) / 10.0 * TAU
		var h0l := Vector3(-hw, sin(a0) * hub_r, cos(a0) * hub_r)
		var h1l := Vector3(-hw, sin(a1) * hub_r, cos(a1) * hub_r)
		var h0r := Vector3(hw, sin(a0) * hub_r, cos(a0) * hub_r)
		var h1r := Vector3(hw, sin(a1) * hub_r, cos(a1) * hub_r)
		_quad(st_rim, h0l, h0r, h1r, h1l)
		_tri(st_rim, Vector3(-hw, 0, 0), h1l, h0l)
		_tri(st_rim, Vector3(hw, 0, 0), h0r, h1r)

	# Spokes
	var sp_len := rim_inner - hub_r * 0.65
	var sp_mid := hub_r * 0.65 + sp_len * 0.5
	var sp_thick := outer_r * 0.085
	var sp_x := width * 0.24
	for s in spokes:
		var sa := float(s) / float(spokes) * TAU + 0.2
		var dir := Vector3(0, sin(sa), cos(sa))
		var tang := Vector3(0, cos(sa), -sin(sa))
		var c_sp := dir * sp_mid
		_add_oriented_box(st_rim, c_sp, Vector3(1, 0, 0), dir, tang, Vector3(sp_x, sp_len * 0.52, sp_thick * 0.5))

	var rim_mesh := st_rim.commit()
	var pair := [tire_mesh, rim_mesh]
	_cache[key] = pair
	return pair


static func _torus_pt(u: float, v: float, R: float, r: float, half_w: float) -> Vector3:
	var rad := R + cos(v) * r
	return Vector3(sin(v) * half_w, sin(u) * rad, cos(u) * rad)


static func _torus_nrm(u: float, v: float) -> Vector3:
	var rad_n := cos(v)
	return Vector3(sin(v), sin(u) * rad_n, cos(u) * rad_n).normalized()


## 3D Semi-circular Masonry Arch Spandrel (spans width along X, height along Y, depth along Z; arch opening from y=0..arch_h).
static func arch_spandrel(key: String, bay_w: float, total_h: float, depth_z: float, pier_w: float) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := bay_w * 0.5
	var iw := maxf(0.25, hw - pier_w)
	var spring_y := maxf(0.4, total_h - iw - 0.34)
	var hz := depth_z * 0.5
	var segs := 10

	# Left & right vertical piers from y=0 to y=spring_y
	_add_oriented_box(st, Vector3(-hw + pier_w * 0.5, spring_y * 0.5, 0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(pier_w * 0.5, spring_y * 0.5, hz))
	_add_oriented_box(st, Vector3(hw - pier_w * 0.5, spring_y * 0.5, 0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(pier_w * 0.5, spring_y * 0.5, hz))

	# Curved spandrel wedges from spring_y up to total_h
	for i in segs:
		var a0 := PI - float(i) / float(segs) * PI        # PI (left) -> 0 (right)
		var a1 := PI - float(i + 1) / float(segs) * PI
		var ix0 := cos(a0) * iw
		var iy0 := spring_y + sin(a0) * iw
		var ix1 := cos(a1) * iw
		var iy1 := spring_y + sin(a1) * iw
		var ox0 := (-hw if i == 0 else (hw if i == segs else clampf(ix0 * (hw / iw), -hw, hw)))
		var ox1 := (hw if i + 1 == segs else clampf(ix1 * (hw / iw), -hw, hw))
		# Front (+hz), Back (-hz), and Curved Intrados (underside of arch!)
		var f_i0 := Vector3(ix0, iy0, hz)
		var f_i1 := Vector3(ix1, iy1, hz)
		var f_t0 := Vector3(ox0, total_h, hz)
		var f_t1 := Vector3(ox1, total_h, hz)
		var b_i0 := Vector3(ix0, iy0, -hz)
		var b_i1 := Vector3(ix1, iy1, -hz)
		var b_t0 := Vector3(ox0, total_h, -hz)
		var b_t1 := Vector3(ox1, total_h, -hz)
		_quad(st, f_i0, f_i1, f_t1, f_t0)     # front face (+Z)
		_quad(st, b_i1, b_i0, b_t0, b_t1)     # back face (-Z)
		_quad(st, b_i0, b_i1, f_i1, f_i0)     # curved arch underside (intrados)
		_quad(st, b_t0, f_t0, f_t1, b_t1)     # top lintel (+Y)
	# Outer left/right upper cheeks
	_quad(st, Vector3(-hw, spring_y, -hz), Vector3(-hw, spring_y, hz), Vector3(-hw, total_h, hz), Vector3(-hw, total_h, -hz))
	_quad(st, Vector3(hw, spring_y, hz), Vector3(hw, spring_y, -hz), Vector3(hw, total_h, -hz), Vector3(hw, total_h, hz))

	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


## Extrudes a 2D side profile (in Y-Z plane) along X with side bevels and exterior CW winding.
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

	var area2 := 0.0
	for i in n:
		var p0: Vector2 = pts_yz[i]
		var p1: Vector2 = pts_yz[(i + 1) % n]
		area2 += (p1.x - p0.x) * (p1.y + p0.y)
	var ordered_pts := pts_yz.duplicate()
	if area2 > 0.0:
		ordered_pts.reverse()

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

	for r in 3:
		var a: PackedVector3Array = rings[r]
		var b: PackedVector3Array = rings[r + 1]
		for i in n:
			var j := (i + 1) % n
			_quad(st, a[i], b[i], b[j], a[j])

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


## Lush arched V-folded tropical palm / banana frond along -Z.
static func curved_frond(key: String, length: float, width: float) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 7
	var hw := width * 0.5
	for i in segs:
		var t0 := float(i) / segs
		var t1 := float(i + 1) / segs
		var w0 := hw * sin(clampf(t0 * 0.88 + 0.10, 0.0, 1.0) * PI)
		var w1 := hw * sin(clampf(t1 * 0.88 + 0.10, 0.0, 1.0) * PI)
		var y0 := sin(t0 * PI * 0.68) * length * 0.28 - t0 * t0 * length * 0.42
		var y1 := sin(t1 * PI * 0.68) * length * 0.28 - t1 * t1 * length * 0.42
		var z0 := -t0 * length
		var z1 := -t1 * length
		var spine0 := Vector3(0, y0 + 0.07, z0)
		var spine1 := Vector3(0, y1 + 0.07, z1)
		var l0 := Vector3(-w0, y0 - 0.06, z0)
		var l1 := Vector3(-w1, y1 - 0.06, z1)
		var r0 := Vector3(w0, y0 - 0.06, z0)
		var r1 := Vector3(w1, y1 - 0.06, z1)
		_quad(st, l0, spine0, spine1, l1)
		_quad(st, spine0, r0, r1, spine1)
		_quad(st, l1, spine1, spine0, l0)
		_quad(st, spine1, r1, r0, spine0)
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
	sp.radial_segments = 10
	sp.rings = 5
	var arr := sp.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ind: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var r := RandomNumberGenerator.new()
	var jittered := PackedVector3Array()
	for v in verts:
		var h := int(roundf(v.x * 13.0)) * 73856093 ^ int(roundf(v.y * 13.0)) * 19349663 ^ int(roundf(v.z * 13.0)) * 83492791
		r.seed = seed_val + h
		var sc := r.randf_range(0.88, 1.12)
		jittered.append(v * sc)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(0, ind.size(), 3):
		_tri(st, jittered[ind[k]], jittered[ind[k + 1]], jittered[ind[k + 2]])
	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


static func _add_oriented_box(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3, az: Vector3, he: Vector3) -> void:
	var x := ax * he.x
	var y := ay * he.y
	var z := az * he.z
	var p000 := c - x - y - z
	var p100 := c + x - y - z
	var p010 := c - x + y - z
	var p110 := c + x + y - z
	var p001 := c - x - y + z
	var p101 := c + x - y + z
	var p011 := c - x + y + z
	var p111 := c + x + y + z
	_quad(st, p001, p101, p111, p011) # +z
	_quad(st, p100, p000, p010, p110) # -z
	_quad(st, p011, p111, p110, p010) # +y
	_quad(st, p000, p100, p101, p001) # -y
	_quad(st, p101, p100, p110, p111) # +x
	_quad(st, p000, p001, p011, p010) # -x


static func _smooth_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3) -> void:
	st.set_normal(na); st.add_vertex(a)
	st.set_normal(nb); st.add_vertex(b)
	st.set_normal(nc); st.add_vertex(c)
	st.set_normal(na); st.add_vertex(a)
	st.set_normal(nc); st.add_vertex(c)
	st.set_normal(nd); st.add_vertex(d)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (c - a).cross(b - a).normalized()
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)
