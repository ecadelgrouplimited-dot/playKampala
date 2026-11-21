extends RefCounted
## Merges many small low-poly parts into ONE mesh with vertex colours.
## One merged mesh = one draw call, which is what keeps cheap phones smooth.

var verts := PackedVector3Array()
var norms := PackedVector3Array()
var colors := PackedColorArray()
var idx := PackedInt32Array()

static var _arrays_cache := {}


func add(mesh: Mesh, xf: Transform3D, col: Color) -> void:
	var key := mesh.get_instance_id()
	var arr: Array
	if _arrays_cache.has(key):
		arr = _arrays_cache[key]
	else:
		arr = (mesh as PrimitiveMesh).get_mesh_arrays() if mesh is PrimitiveMesh else mesh.surface_get_arrays(0)
		_arrays_cache[key] = arr
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ind: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var nb := xf.basis.inverse().transposed()
	var base := verts.size()
	for k in v.size():
		verts.append(xf * v[k])
		norms.append((nb * n[k]).normalized())
		colors.append(col)
	if ind.is_empty():
		for k in v.size():
			idx.append(base + k)
	else:
		for k in ind:
			idx.append(base + k)


func is_empty() -> bool:
	return verts.is_empty()


## Middle of everything added so far (used to centre a chunk on its node,
## so visibility ranges and culling measure from the right place).
func centre() -> Vector3:
	var lo := verts[0]
	var hi := verts[0]
	for v in verts:
		lo = lo.min(v)
		hi = hi.max(v)
	return (lo + hi) * 0.5


func build(offset := Vector3.ZERO) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var v := verts
	if offset != Vector3.ZERO:
		v = PackedVector3Array()
		v.resize(verts.size())
		for i in verts.size():
			v[i] = verts[i] - offset
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m
