extends SceneTree
const BASE := "res://prototype/whole_house/rooms/"
var scenes: Dictionary = {}
func _initialize() -> void:
	call_deferred("run")
func room(file: String) -> Node3D:
	if scenes.has(file): return scenes[file]
	var n := load(BASE+file).instantiate() as Node3D
	root.add_child(n)
	scenes[file] = n
	return n
func move(r: Node3D, name_pattern: String, p: Vector3, angle: float = INF) -> void:
	var n := r.find_child(name_pattern,true,false) as Node3D
	assert(n != null,"Missing piece "+name_pattern)
	n.global_position = p
	if angle != INF: n.rotation.y = deg_to_rad(angle)
func mat(color: Color, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = .8
	m.metallic = metal
	if metal == 0.0:
		m.albedo_texture = load("res://prototype/assets/textures/ambientcg/Wood026/Wood026_Color_2K.jpg")
		m.normal_texture = load("res://prototype/assets/textures/ambientcg/Wood026/Wood026_NormalGL_2K.jpg")
		m.normal_enabled = true
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(1.4,1.4,1.4)
	return m
func box(r: Node3D, label: String, p: Vector3, size: Vector3, material: Material) -> void:
	var m := MeshInstance3D.new()
	m.name = label
	m.position = p
	m.layers = 8
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.material_override = material
	r.add_child(m)
func wardrobe(r: Node3D, p: Vector3, angle: float, light: bool) -> void:
	if r.has_node("Armario_Roupeiro_Editavel"): r.get_node("Armario_Roupeiro_Editavel").free()
	var g := Node3D.new()
	g.name = "Armario_Roupeiro_Editavel"
	g.position = p
	g.rotation.y = deg_to_rad(angle)
	g.set_meta("_edit_group_",true)
	g.set_meta("edicao","Raiz do armário; mover e girar leva portas, puxadores e colisão.")
	r.add_child(g)
	var wood := mat(Color("bdb6a4") if light else Color("8d765c"))
	var trim := mat(Color("615041"))
	var metal := mat(Color("796f5e"),.75)
	box(g,"Caixa",Vector3(0,1.08,0),Vector3(1.5,2.16,.57),wood)
	box(g,"Soco",Vector3(0,.08,.02),Vector3(1.53,.16,.62),trim)
	box(g,"Cornija",Vector3(0,2.15,.01),Vector3(1.57,.09,.64),trim)
	for side in [-1.0,1.0]:
		box(g,"Porta_Esquerda" if side < 0 else "Porta_Direita",Vector3(side*.375,1.12,.302),Vector3(.735,1.96,.045),wood)
		box(g,"Puxador_%s" % side,Vector3(side*.10,1.12,.342),Vector3(.025,.25,.035),metal)
	var body := StaticBody3D.new()
	body.name = "Colisao_Acompanha_Armario"
	g.add_child(body)
	var col := CollisionShape3D.new()
	col.name = "Forma"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.57,2.20,.65)
	col.shape = shape
	col.position = Vector3(0,1.10,0)
	body.add_child(col)
func own_all(n: Node, r: Node) -> void:
	if n != r:
		n.owner = r
		n.scene_file_path = ""
	for c in n.get_children(): own_all(c,r)
func save_all() -> void:
	for file in scenes:
		var r: Node3D = scenes[file]
		own_all(r,r)
		var p := PackedScene.new()
		assert(p.pack(r)==OK)
		assert(ResourceSaver.save(p,BASE+file)==OK)
		print("CIRCULATION_REFINED "+file)
		r.free()
func run() -> void:
	var library := room("terreo__Biblioteca.tscn")
	move(library,"Modelo_ArmChair_01_073",Vector3(4.0,0,1.20),25)
	move(library,"Modelo_ArmChair_01_074",Vector3(7.50,0,1.20),-25)
	move(library,"Modelo_coffee_table_round_01_075",Vector3(6.30,0,-.20))
	move(library,"Modelo_book_encyclopedia_set_01_076",Vector3(6.30,.43,-.20))
	move(library,"Modelo_small_wooden_table_01_077",Vector3(3.10,0,1.75))
	move(library,"Modelo_vintage_oil_lamp_078",Vector3(3.10,.40,1.75))
	var suite := room("primeiro__Suite_Casal.tscn")
	move(suite,"Cama_Casal_Linho",Vector3(5.0,2.85,-4.85))
	move(suite,"Banco_Pe_Cama",Vector3(4.75,3.075,-2.75))
	move(suite,"Comoda_Suite",Vector3(7.0,2.85,-2.1),-90)
	move(suite,"Planta_Canto",Vector3(2.45,2.85,-5.55))
	var child := room("primeiro__Quarto_Infantil.tscn")
	move(child,"Cama_Irmao_Azul",Vector3(-5.90,2.85,-4.85))
	move(child,"Cama_Irma_Salvia",Vector3(-3.65,2.85,-4.85))
	move(child,"Comoda_Infantil",Vector3(-7.05,2.85,-1.90),90)
	move(child,"Prateleira_Azul",Vector3(-7.35,4.40,-1.9),90)
	move(child,"Prateleira_Salvia",Vector3(-7.35,5.0,-1.9),90)
	var couple := room("primeiro__Closet_Casal.tscn")
	move(couple,"Comoda_Vestir",Vector3(2.65,2.85,1.65))
	move(couple,"Comoda_Acessorios",Vector3(6.25,2.85,-.41))
	move(couple,"Estante_Madeira",Vector3(6.2,4.95,-.55))
	wardrobe(couple,Vector3(7.15,2.85,.65),-90,false)
	var kids := room("primeiro__Closet_Infantil.tscn")
	move(kids,"Comoda_Roupa_Cama",Vector3(-2.65,2.85,1.65))
	move(kids,"Estante_Baixa_Salvia",Vector3(-6.2,4.95,-.55))
	wardrobe(kids,Vector3(-7.15,2.85,.65),90,true)
	var doors := room("primeiro__Portas.tscn")
	for door in doors.get_children():
		if door is AnimatableBody3D:
			for c in door.get_children():
				if c is CollisionShape3D and c.shape is BoxShape3D:
					if c.shape.size.z > c.shape.size.x:
						door.set("angulo_abertura_graus",-95.0 if door.position.x < 0.0 else 95.0)
					break
	save_all()
	quit()
