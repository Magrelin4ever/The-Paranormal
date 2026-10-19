extends SceneTree
const ROOMS := "res://prototype/whole_house/rooms/"
const LIBRARY := "res://prototype/whole_house/real_assets/"
const RESOURCES := "res://prototype/whole_house/polish_resources/"
const REAL := "res://prototype/assets/models/real_house_20261019/"
const POLY := "res://prototype/assets/models/polyhaven/"
var serial := 0
var mesh_cache: Dictionary = {}
var rooms: Dictionary = {}
var report: Array = []
func _initialize() -> void: call_deferred("run")
func all_meshes(n: Node3D) -> Array:
	var nodes: Array = n.find_children("*","MeshInstance3D",true,false)
	if n is MeshInstance3D: nodes.push_front(n)
	return nodes
func bounds(n: Node3D) -> AABB:
	var found := false
	var a := AABB()
	for m in all_meshes(n):
		if m.mesh == null: continue
		var b: AABB = m.global_transform*m.get_aabb()
		a = a.merge(b) if found else b
		found = true
	return a
func own(n: Node, target: Node) -> void:
	if n != target:
		n.owner = target
		n.scene_file_path = ""
	if n is MeshInstance3D and n.mesh != null and not n.mesh.resource_path.ends_with(".res"):
		var id: int = n.mesh.get_instance_id()
		if not mesh_cache.has(id):
			serial += 1
			var path := RESOURCES+"polish_mesh_%04d.res" % serial
			assert(ResourceSaver.save(n.mesh,path,ResourceSaver.FLAG_COMPRESS)==OK)
			mesh_cache[id] = ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE)
		n.mesh = mesh_cache[id]
	for c in n.get_children(): own(c,target)
func save(n: Node3D, path: String) -> void:
	own(n,n)
	var p := PackedScene.new()
	assert(p.pack(n)==OK)
	assert(ResourceSaver.save(p,path)==OK)
func instance_asset(label: String, path: String, width: float = 0.0, collider: bool = true) -> Node3D:
	var g := Node3D.new()
	g.name = label
	g.set_meta("_edit_group_",true)
	root.add_child(g)
	var model := load(path).instantiate() as Node3D
	model.name = "Modelo"
	g.add_child(model)
	var a := bounds(model)
	var scale_value := width/a.size.x if width > 0 else 1.0
	model.scale *= scale_value
	a = bounds(model)
	model.position -= Vector3(a.get_center().x,a.position.y,a.get_center().z)
	var corrected := bounds(model)
	for m in all_meshes(g):
		for s in range(m.mesh.get_surface_count()):
			var material := m.get_active_material(s) as BaseMaterial3D
			if material != null and (material.emission_enabled or material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED):
				var safe := material.duplicate() as BaseMaterial3D
				safe.emission_enabled = false
				safe.emission = Color.BLACK
				safe.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
				m.set_surface_override_material(s,safe)
	if collider:
		var body := StaticBody3D.new()
		body.name = "Colisao_Acompanha_Peca"
		g.add_child(body)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = corrected.size
		shape.position = corrected.get_center()
		shape.shape = box
		body.add_child(shape)
	report.append({"asset":label,"source":path,"size":[corrected.size.x,corrected.size.y,corrected.size.z],"collider":collider})
	return g
func library_asset(label: String, source: String, width: float = 0.0, collider: bool = true) -> String:
	var g := instance_asset(label,source,width,collider)
	for m in all_meshes(g): m.layers = 1
	var path := LIBRARY+label+".tscn"
	save(g,path)
	g.free()
	return path
func get_room(file: String) -> Node3D:
	if rooms.has(file): return rooms[file]
	var n := load(ROOMS+file).instantiate() as Node3D
	root.add_child(n)
	rooms[file] = n
	return n
func place(r: Node3D, label: String, asset: String, p: Vector3, angle: float = 0.0) -> Node3D:
	if r.has_node(label): r.get_node(label).free()
	var n := load(asset).instantiate() as Node3D
	n.name = label
	r.add_child(n)
	n.position = p
	n.rotation.y = deg_to_rad(angle)
	var layer: int = 8 if str(r.get_meta("pavimento","")).contains("primeiro") else (16 if r.get_meta("pavimento","")=="sotao" else (2 if r.get_meta("pavimento","")=="porao" else 4))
	for m in all_meshes(n): m.layers = layer
	return n
func rug(r: Node3D, label: String, p: Vector3, size: Vector2, color: Color) -> void:
	if r.has_node(label): r.get_node(label).free()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x,.012,size.y)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.albedo_texture = load("res://prototype/assets/textures/ambientcg/Carpet012/Carpet012_Color_2K.jpg")
	material.normal_texture = load("res://prototype/assets/textures/ambientcg/Carpet012/Carpet012_NormalGL_2K.jpg")
	material.normal_enabled = true
	material.roughness = .98
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(2,2,2)
	var n := MeshInstance3D.new()
	n.name = label
	n.position = p
	n.mesh = mesh
	n.material_override = material
	n.layers = 8
	n.set_meta("_edit_group_",true)
	r.add_child(n)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RESOURCES))
	var bed := library_asset("Cama_Casal_Hush",REAL+"hush_wingback_bed.glb")
	var loft := library_asset("Cama_Infantil_Loft_Studio",REAL+"studio_loft_study_bed.glb")
	var curtain := library_asset("Cortina_Linho_Aberta","res://prototype/assets/models/innerscene/curtain-pair-open-original-interior-furnishing.glb",2.12,false)
	var side_table := library_asset("Mesa_Lateral_Madeira",POLY+"small_wooden_table_01/small_wooden_table_01_1k.gltf",.58)
	var plant := library_asset("Planta_Vaso_Desgastado",POLY+"potted_plant_02/potted_plant_02_1k.gltf",.48,false)
	var lamp := library_asset("Luminaria_Mesa_Desligada",POLY+"desk_lamp_arm_01/desk_lamp_arm_01_1k.gltf",.33,false)
	var book := library_asset("Livro_Anotacoes",POLY+"binder_notebook/binder_notebook_1k.gltf",.24,false)
	var basket := library_asset("Cesto_Vime",POLY+"wicker_basket_01/wicker_basket_01_1k.gltf",.43)
	var suite := get_room("primeiro__Suite_Casal.tscn")
	place(suite,"Cama_Casal_Linho",bed,Vector3(5.15,2.85,-4.78))
	var bench := suite.get_node("Banco_Pe_Cama") as Node3D
	bench.position = Vector3(4.75,3.075,-2.45)
	place(suite,"Mesa_Cabeceira_Esquerda",side_table,Vector3(3.65,2.85,-5.25))
	place(suite,"Luminaria_Cabeceira_Off",lamp,Vector3(3.65,3.1875,-5.25),-15)
	place(suite,"Livro_Cabeceira",book,Vector3(3.77,3.1875,-5.15),12)
	place(suite,"Planta_Canto",plant,Vector3(2.45,2.85,-5.45))
	place(suite,"Cortina_Janela_Fundos",curtain,Vector3(4.4,3.05,-6.03))
	place(suite,"Cortina_Janela_Lateral",curtain,Vector3(7.47,3.05,-3.0),-90)
	rug(suite,"Tapete_Linho_Suite",Vector3(4.95,2.866,-4.3),Vector2(3.8,3.4),Color("80796d"))
	var child := get_room("primeiro__Quarto_Infantil.tscn")
	place(child,"Cama_Irmao_Azul",loft,Vector3(-5.9,2.85,-4.8))
	place(child,"Cama_Irma_Salvia",loft,Vector3(-3.65,2.85,-4.8))
	place(child,"Cortina_Infantil_Fundos",curtain,Vector3(-4.4,3.05,-6.03))
	place(child,"Cortina_Infantil_Lateral",curtain,Vector3(-7.47,3.05,-3.0),90)
	place(child,"Cesto_Brinquedos",basket,Vector3(-2.55,2.85,-1.65))
	rug(child,"Tapete_Infantil_Trama",Vector3(-4.6,2.866,-2.9),Vector2(3.2,1.65),Color("637d79"))
	var attic := get_room("sotao__Arquivo_Sotao.tscn")
	place(attic,"Cesto_Tecidos_Arquivo",basket,Vector3(-5.65,5.7,-4.75))
	var library := get_room("terreo__Biblioteca.tscn")
	place(library,"Planta_Leitura_Natural",plant,Vector3(8.5,0,1.95))
	for file in rooms:
		var n: Node3D = rooms[file]
		save(n,ROOMS+file)
		n.free()
	var f := FileAccess.open("res://qa/whole_house/polish_results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"assets":report,"rooms":rooms.keys(),"lights_added":0,"all_props_native_editable":true},"\t")+"\n")
	print("INTERIOR_POLISH_DONE rooms=%d assets=%d" % [rooms.size(),report.size()])
	quit()
