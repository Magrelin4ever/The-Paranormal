extends SceneTree
const BASE := "res://prototype/whole_house/rooms/"
var rooms: Dictionary = {}
var records: Array = []
func _initialize() -> void: call_deferred("run")
func room(file: String) -> Node3D:
	if rooms.has(file): return rooms[file]
	var r := load(BASE+file).instantiate() as Node3D
	root.add_child(r)
	rooms[file] = r
	return r
func bounds(n: Node3D) -> AABB:
	var found := false
	var a := AABB()
	for m in n.find_children("*","MeshInstance3D",true,false):
		if m.mesh == null: continue
		var b: AABB = m.global_transform*m.get_aabb()
		a = a.merge(b) if found else b
		found = true
	return a
func copy(r: Node3D, source: Node3D, label: String, p: Vector3, angle: float, factor: float = 1.0) -> Node3D:
	if r.has_node(label): r.get_node(label).free()
	var n := source.duplicate() as Node3D
	n.name = label
	r.add_child(n)
	n.position = p
	n.rotation.y = deg_to_rad(angle)
	n.scale = source.scale*factor
	n.set_meta("_edit_group_",true)
	for m in n.find_children("*","VisualInstance3D",true,false): m.layers = 16
	return n
func own(n: Node, r: Node) -> void:
	if n != r:
		n.owner = r
		n.scene_file_path = ""
	for c in n.get_children(): own(c,r)
func beam(r: Node3D, label: String, p: Vector3, size: Vector3, mat: Material) -> void:
	if r.has_node(label): r.get_node(label).free()
	var g := Node3D.new()
	g.name = label
	g.position = p
	g.set_meta("_edit_group_",true)
	g.set_meta("edicao","Viga aparente; camada do teto do sótão. Mover a raiz leva a colisão.")
	r.add_child(g)
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.material_override = mat
	m.layers = 256
	g.add_child(m)
	var body := StaticBody3D.new()
	g.add_child(body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
func run() -> void:
	var storage := room("sotao__Deposito_Sotao.tscn")
	var base := storage.get_node("SeasonalCrateA") as Node3D
	var upper := storage.get_node("SeasonalCrateB") as Node3D
	upper.position.y += bounds(base).end.y-bounds(upper).position.y
	var a := copy(storage,base,"Caixa_Memorias_Base",Vector3(-5.75,5.7,4.85),-8,1.6)
	var b := copy(storage,base,"Caixa_Memorias_Topo",Vector3(-5.75,5.7,4.85),4,1.6)
	b.position.y += bounds(a).end.y-bounds(b).position.y
	copy(storage,base,"Caixa_Tecidos_Estacao",Vector3(-4.6,5.7,4.75),12,1.6)
	copy(storage,base,"Caixa_Documentos_Antigos",Vector3(-5.8,5.7,5.5),-3,1.45)
	var library := room("terreo__Biblioteca.tscn")
	copy(storage,library.get_node("Modelo_ArmChair_01_073"),"Poltrona_Guardada",Vector3(4.8,5.7,1.0),-35)
	var table := copy(storage,library.get_node("Modelo_small_wooden_table_01_077"),"Mesa_Guardada",Vector3(5.85,5.7,1.35),0)
	copy(storage,library.get_node("Modelo_vintage_oil_lamp_078"),"Lamparina_Sotao_Apagada",Vector3(5.85,bounds(table).end.y,1.35),12)
	var depot := room("porao__Deposito.tscn")
	var lower_crate := depot.get_node("Modelo_wooden_crate_01_011") as Node3D
	var plastic := depot.get_node("Modelo_plastic_crate_01_013") as Node3D
	plastic.position.y += bounds(lower_crate).end.y-bounds(plastic).position.y
	var structure := room("sotao__Estrutura.tscn")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("786852")
	material.albedo_texture = load("res://prototype/assets/textures/ambientcg/Wood026/Wood026_Color_2K.jpg")
	material.normal_texture = load("res://prototype/assets/textures/ambientcg/Wood026/Wood026_NormalGL_2K.jpg")
	material.normal_enabled = true
	material.roughness = .92
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(1.2,1.2,1.2)
	for i in range(4): beam(structure,"Viga_Aparente_%02d" % i,Vector3(0,8.10,-4.8+i*3.1),Vector3(14.85,.18,.20),material)
	# A biblioteca só forneceu modelos; não deve ser regravada.
	for file in rooms:
		var r: Node3D = rooms[file]
		if file != "terreo__Biblioteca.tscn":
			own(r,r)
			var p := PackedScene.new()
			assert(p.pack(r)==OK)
			assert(ResourceSaver.save(p,BASE+file)==OK)
			records.append(file)
		r.free()
	var f := FileAccess.open("res://qa/whole_house/attic_storage_results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"rooms_updated":records,"new_lights":0,"source_assets":"Reutilizacao de assets CC0 existentes e vigas nativas PBR editaveis","stacked_crates_aligned":true},"\t")+"\n")
	print("ATTIC_STORAGE_FINISH_DONE")
	quit()
