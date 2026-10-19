extends SceneTree
# Separa geometria aglutinada por material em móveis reais, somente offline.
const ROOMS := "res://prototype/whole_house/rooms/"
const OUT := "res://prototype/whole_house/editable_parts/geometry/"
var report: Array = []
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func owned(n: Node, r: Node) -> void:
	if n != r:
		n.owner = r
		n.scene_file_path = ""
	for c in n.get_children(): owned(c,r)

func save(r: Node3D, file: String) -> void:
	owned(r,r)
	var p := PackedScene.new()
	assert(p.pack(r) == OK)
	assert(ResourceSaver.save(p,ROOMS+file) == OK)

func clear_group_metadata(n: Node) -> void:
	if n.has_meta("_edit_group_"): n.remove_meta("_edit_group_")
	for c in n.get_children(): clear_group_metadata(c)

func body_bounds(body: Node3D) -> AABB:
	var c := body.find_child("Forma",true,false) as CollisionShape3D
	if c == null:
		for child in body.get_children():
			if child is CollisionShape3D: c = child
	assert(c != null and c.shape is BoxShape3D)
	var size: Vector3 = c.shape.size
	return c.global_transform * AABB(-size*0.5,size)

func choose_part(p: Vector3, zones: Array) -> int:
	var best := 0
	var score := INF
	for i in range(zones.size()):
		var a: AABB = zones[i]["bounds"]
		var nearest := Vector3(clampf(p.x,a.position.x,a.end.x),clampf(p.y,a.position.y,a.end.y),clampf(p.z,a.position.z,a.end.z))
		var distance := p.distance_squared_to(nearest)
		# Um objeto exatamente sobre um tampo acompanha esse móvel, não a sala.
		if distance < score:
			score = distance
			best = i
	return best

func emit_vertex(st: SurfaceTool, arrays: Array, index: int, world: Transform3D) -> void:
	var normal: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	if normal.size() > index:
		st.set_normal((world.basis.inverse().transposed()*normal[index]).normalized())
	var tangent: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT] if arrays[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
	if tangent.size() >= index*4+4:
		var t := (world.basis*Vector3(tangent[index*4],tangent[index*4+1],tangent[index*4+2])).normalized()
		st.set_tangent(Plane(t,tangent[index*4+3]))
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	if uv.size() > index: st.set_uv(uv[index])
	var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2] if arrays[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
	if uv2.size() > index: st.set_uv2(uv2[index])
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	if colors.size() > index: st.set_color(colors[index])
	st.add_vertex(world*arrays[Mesh.ARRAY_VERTEX][index])

func partition(file: String, model_pattern: String, prefix: String, definitions: Array) -> void:
	var r := load(ROOMS+file).instantiate() as Node3D
	root.add_child(r)
	var model := r.find_child(model_pattern,true,false) as Node3D
	assert(model != null)
	clear_group_metadata(model)
	var zones: Array = []
	var assembly := Node3D.new()
	assembly.name = prefix+"_Pecas_Independentes"
	r.add_child(assembly)
	for definition in definitions:
		var body := r.find_child(definition[1],true,false) as StaticBody3D
		assert(body != null)
		var bounds := body_bounds(body)
		var group := Node3D.new()
		group.name = definition[0]
		group.position = Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
		group.set_meta("_edit_group_",true)
		group.set_meta("edicao","Mova/gire esta raiz: geometria, detalhes e colisao acompanham.")
		assembly.add_child(group)
		body.reparent(group,true)
		zones.append({"group":group,"bounds":bounds,"mesh":ArrayMesh.new(),"triangles":0})
	var originals: Array[MeshInstance3D] = []
	for m in model.find_children("*", "MeshInstance3D", true, false):
		if String(m.name).begins_with(prefix+"_Runtime"): originals.append(m)
	assert(not originals.is_empty())
	var triangles_before := 0
	var before_bounds := AABB()
	var found := false
	for source in originals:
		var source_bounds: AABB = source.global_transform*source.get_aabb()
		before_bounds = before_bounds.merge(source_bounds) if found else source_bounds
		found = true
		for surface in range(source.mesh.get_surface_count()):
			var arrays := source.mesh.surface_get_arrays(surface)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				indices.resize(verts.size())
				for i in range(verts.size()): indices[i] = i
			var tools: Dictionary = {}
			for tri in range(0,indices.size(),3):
				var midpoint: Vector3 = (verts[indices[tri]]+verts[indices[tri+1]]+verts[indices[tri+2]])/3.0
				var selected := choose_part(source.global_transform*midpoint,zones)
				if not tools.has(selected):
					var st := SurfaceTool.new()
					st.begin(Mesh.PRIMITIVE_TRIANGLES)
					st.set_material(source.get_active_material(surface))
					tools[selected] = st
				for j in range(3): emit_vertex(tools[selected],arrays,indices[tri+j],source.global_transform)
				zones[selected]["triangles"] += 1
				triangles_before += 1
			for selected in tools:
				var st: SurfaceTool = tools[selected]
				st.index()
				st.commit(zones[selected]["mesh"])
	var after_bounds := AABB()
	found = false
	var parts: Array = []
	var total := 0
	for zone in zones:
		var group: Node3D = zone["group"]
		var mesh: ArrayMesh = zone["mesh"]
		var tris: int = zone["triangles"]
		total += tris
		if mesh.get_surface_count() > 0:
			var path := OUT+prefix+"_"+String(group.name)+".res"
			ResourceSaver.save(mesh,path,ResourceSaver.FLAG_COMPRESS)
			var rendered := MeshInstance3D.new()
			rendered.name = "Modelo_Separado_Com_UVs"
			rendered.mesh = ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE)
			rendered.position = -group.position
			group.add_child(rendered)
			var bounds: AABB = rendered.global_transform*rendered.get_aabb()
			after_bounds = after_bounds.merge(bounds) if found else bounds
			found = true
		parts.append({"name":String(group.name),"triangles":tris,"colliders":group.find_children("*","CollisionShape3D",true,false).size()})
	for source in originals: source.free()
	# O conjunto antigo agora só contém as pastas vazias; os props externos são preservados.
	if model.find_children("*","MeshInstance3D",true,false).is_empty() and model.find_children("*","CollisionShape3D",true,false).is_empty(): model.free()
	var bounds_ok := before_bounds.position.is_equal_approx(after_bounds.position) and before_bounds.size.is_equal_approx(after_bounds.size)
	if total != triangles_before: errors.append(prefix+" perdeu triangulos")
	if not bounds_ok: errors.append(prefix+" alterou AABB")
	save(r,file)
	report.append({"scene":file,"triangles_before":triangles_before,"triangles_after":total,"aabb_preserved":bounds_ok,"before_bounds":str(before_bounds),"after_bounds":str(after_bounds),"parts":parts})
	print("PARTITION %s triangles=%d parts=%d bounds_ok=%s" % [prefix,total,zones.size(),bounds_ok])
	r.free()

func office() -> void:
	var file := "terreo__Escritorio.tscn"
	var r := load(ROOMS+file).instantiate() as Node3D
	root.add_child(r)
	var model := r.find_child("Modelo_MesaEscritorioC15_*",true,false) as Node3D
	assert(model != null)
	clear_group_metadata(model)
	for pair in [["Mesa_Escritorio","C15_Desk","Hitbox_Mesa_Escritorio_C15"],["Cadeira_Escritorio","C15_Chair","Hitbox_Cadeira_Escritorio_C15"]]:
		var body := model.find_child(pair[2],true,false) as StaticBody3D
		var bounds := body_bounds(body)
		var group := Node3D.new()
		group.name = pair[0]
		group.set_meta("_edit_group_",true)
		group.position = Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
		r.add_child(group)
		for mesh in model.find_children(pair[1]+"*","MeshInstance3D",true,false): mesh.reparent(group,true)
		body.reparent(group,true)
	if model.find_children("*","MeshInstance3D",true,false).is_empty(): model.free()
	save(r,file)
	r.free()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	partition("terreo__Hall_Entrada.tscn","Modelo_ConjuntoHallC19_*","C19",[["Console_Entrada","C19_Console_Perimetro"],["Banco_Sapateira","C19_Banco_Perimetro"]])
	partition("terreo__Area_Servico.tscn","Modelo_ConjuntoServicoC18_*","C18",[["Bancada_Principal","BancadaServicoC18"],["Bancada_Retorno","RetornoServicoC18"],["Armario_Aereo_Esquerdo","AereoEsquerdoC18"],["Armario_Sobrejanela","SobrejanelaC18"],["Armario_Aereo_Direito","AereoDireitoC18"],["Aspirador","AspiradorC18"],["Balde","BaldeC18"]])
	office()
	var f := FileAccess.open("res://qa/whole_house/real_partition_results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"parts":report,"failures":errors,"passed":errors.is_empty()},"\t")+"\n")
	quit(0 if errors.is_empty() else 1)
