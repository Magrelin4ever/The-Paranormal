extends SceneTree
# Conversão editorial offline; NÃO é carregado pelo jogo.
const ASSETS := "res://prototype/assets/models/bathroom_20261019/"
const OUT := "res://prototype/whole_house/bathroom_props/"
const ROOMS := "res://prototype/whole_house/rooms/"
var metrics: Dictionary = {}
var serial := 0

func _initialize() -> void:
	call_deferred("run")

func own_all(n: Node, r: Node) -> void:
	if n != r:
		n.owner = r
		n.scene_file_path = ""
	for c in n.get_children(): own_all(c,r)

func save_scene(r: Node3D, path: String) -> void:
	own_all(r,r)
	var p := PackedScene.new()
	assert(p.pack(r) == OK)
	assert(ResourceSaver.save(p,path) == OK)

func material(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	m.emission_enabled = false
	return m

func textured(color: Color, name_id: String) -> StandardMaterial3D:
	var m := material(color)
	var folder := "res://prototype/assets/textures/polyhaven/brown_floor_tiles/"
	if name_id == "marble":
		folder = "res://prototype/assets/textures/ambientcg/Marble002/"
		m.albedo_texture = load(folder+"Marble002_Color_2K.jpg")
		m.normal_texture = load(folder+"Marble002_NormalGL_2K.jpg")
		m.roughness_texture = load(folder+"Marble002_Roughness_2K.jpg")
	else:
		m.albedo_texture = load(folder+"brown_floor_tiles_diff_1k.jpg")
		m.normal_texture = load(folder+"brown_floor_tiles_nor_gl_1k.jpg")
		m.roughness_texture = load(folder+"brown_floor_tiles_rough_1k.jpg")
	m.normal_enabled = true
	m.normal_scale = 0.65
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(1.1,1.1,1.1)
	return m

func aabb_for(n: Node3D) -> AABB:
	var found := false
	var result := AABB()
	for mesh in n.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null: continue
		var local: Transform3D = n.global_transform.affine_inverse() * mesh.global_transform
		var bounds: AABB = local * mesh.get_aabb()
		result = result.merge(bounds) if found else bounds
		found = true
	return result

func sanitize(n: Node3D, label: String) -> void:
	var idx := 0
	for mesh in n.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null: continue
		idx += 1
		for s in range(mesh.mesh.get_surface_count()):
			var src := mesh.get_active_material(s) as BaseMaterial3D
			if src != null:
				var m := src.duplicate() as BaseMaterial3D
				m.emission_enabled = false
				m.emission = Color.BLACK
				mesh.set_surface_override_material(s,m)
		var p := OUT+"resources/%s_mesh_%02d.res" % [label, idx]
		ResourceSaver.save(mesh.mesh,p,ResourceSaver.FLAG_COMPRESS)
		mesh.mesh = ResourceLoader.load(p,"",ResourceLoader.CACHE_MODE_IGNORE)

func create_asset(label: String, file: String, collision: bool = true) -> String:
	var wrapper := Node3D.new()
	wrapper.name = label
	wrapper.set_meta("_edit_group_",true)
	wrapper.set_meta("licenca", "CC0 1.0 — Innerscene; fonte e SHA em assets/models/bathroom_20261019/manifest.json")
	root.add_child(wrapper)
	var model := load(ASSETS+file).instantiate() as Node3D
	model.name = "Modelo"
	wrapper.add_child(model)
	var bounds := aabb_for(wrapper)
	model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	bounds = aabb_for(wrapper)
	if collision:
		var body := StaticBody3D.new()
		body.name = "Colisao_Move_Com_Peca"
		wrapper.add_child(body)
		var col := CollisionShape3D.new()
		col.name = "Forma"
		var shape := BoxShape3D.new()
		shape.size = bounds.size
		col.shape = shape
		col.position = bounds.get_center()
		body.add_child(col)
	sanitize(wrapper,label)
	metrics[label] = {"bounds_min": str(bounds.position), "bounds_size": str(bounds.size), "floor_y": bounds.position.y}
	var path := OUT+label+".tscn"
	save_scene(wrapper,path)
	wrapper.free()
	return path

func add_prop(r: Node3D, path: String, label: String, p: Vector3, angle: float = 0.0) -> Node3D:
	var n := load(path).instantiate() as Node3D
	n.name = label
	n.position = p
	n.rotation.y = deg_to_rad(angle)
	n.set_meta("_edit_group_",true)
	r.add_child(n)
	return n

func box(r: Node3D, label: String, p: Vector3, size: Vector3, m: Material, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	n.position = p
	n.set_meta("_edit_group_", true)
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = m
	r.add_child(n)
	if solid:
		var b := StaticBody3D.new()
		b.name = "Colisao"
		n.add_child(b)
		var c := CollisionShape3D.new()
		c.name = "Forma"
		var shape := BoxShape3D.new()
		shape.size = size
		c.shape = shape
		b.add_child(c)
	return n

func cylinder(r: Node3D, label: String, p: Vector3, radius: float, height: float, m: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	n.position = p
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	n.mesh = mesh
	n.material_override = m
	r.add_child(n)
	return n

func towel_rack(r: Node3D, label: String, p: Vector3, tone: Color, mirror_x: float) -> void:
	var rack := Node3D.new()
	rack.name = label
	rack.position = p
	rack.set_meta("_edit_group_",true)
	r.add_child(rack)
	var metal := material(Color("716654"),0.42,0.75)
	box(rack,"Suporte_Esquerdo",Vector3(0,0,-.32),Vector3(.14,.045,.045),metal)
	box(rack,"Suporte_Direito",Vector3(0,0,.32),Vector3(.14,.045,.045),metal)
	box(rack,"Barra",Vector3(mirror_x*.08,0,0),Vector3(.04,.04,.69),metal)
	var cloth := material(tone,0.98)
	cloth.albedo_texture = load("res://prototype/assets/textures/ambientcg/Carpet012/Carpet012_Color_2K.jpg")
	cloth.uv1_scale = Vector3(2,3,1)
	box(rack,"Toalha_Pendurada",Vector3(mirror_x*.09,-.23,0),Vector3(.035,.46,.50),cloth)

func build_room(family: bool, tub_path: String, toilet_path: String, roll_path: String) -> void:
	var sign_x := -1.0 if family else 1.0
	var r := Node3D.new()
	r.name = "Banheiro_Familiar" if family else "Banheiro_Suite"
	r.set_meta("pavimento","primeiro")
	r.set_meta("edicao","Selecione cada raiz, W mover/E girar, Ctrl+S e F5. Loucas e colisoes acompanham a peca.")
	root.add_child(r)
	var floor_y := 2.85
	var pale := Color("93a498") if family else Color("aaa39a")
	var tile := textured(pale,"tile")
	box(r,"Piso_Azulejo",Vector3(sign_x*4.70,2.864,4.10),Vector3(5.40,.018,3.85),tile)
	var marble := textured(Color("b5bcb5") if family else Color("b6afa5"),"marble")
	box(r,"Revestimento_Parede_Pia",Vector3(sign_x*5.30,3.67,2.145),Vector3(2.15,1.55,.025),marble)
	add_prop(r,tub_path,"Banheira_Familiar" if family else "Banheira_Com_Pes",Vector3(sign_x*6.82,floor_y,4.91))
	if family:
		box(r,"Saia_Azulejada_Banheira",Vector3(-6.39,3.10,4.91),Vector3(.045,.49,1.79),marble,true)
		for z in [4.02,5.80]: box(r,"Acabamento_Banheira_%s" % z,Vector3(-6.82,3.10,z),Vector3(.90,.49,.045),marble,true)
	add_prop(r,toilet_path,"Vaso_Sanitario",Vector3(sign_x*6.85,floor_y,2.85))
	add_prop(r,roll_path,"Suporte_Papel",Vector3(sign_x*7.36,3.52,3.10),-90.0 if family else 90.0)
	var vanity := add_prop(r,"res://prototype/whole_house/real_assets/Pia_Banheiro_Basin90.tscn","Pia_Com_Gabinete",Vector3(sign_x*5.25,floor_y,2.60))
	# Higienização também das superfícies do asset importado; nenhum emissivo ativo.
	for mesh in vanity.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh != null:
			for s in range(mesh.mesh.get_surface_count()):
				var source := mesh.get_active_material(s) as BaseMaterial3D
				if source != null:
					var safe := source.duplicate() as BaseMaterial3D
					safe.emission_enabled = false
					mesh.set_surface_override_material(s,safe)
	var bronze := material(Color("615448"),.48,.72)
	var glass := material(Color("87908b"),.18,.78)
	box(r,"Moldura_Espelho",Vector3(sign_x*5.25,4.50,2.205),Vector3(.83,.89,.055),bronze)
	box(r,"Espelho_Sem_Emissao",Vector3(sign_x*5.25,4.50,2.24),Vector3(.75,.81,.018),glass)
	var cloth_tone := Color("556c64") if family else Color("837b6b")
	towel_rack(r,"Toalheiro",Vector3(sign_x*7.38,4.32,4.07),cloth_tone,-sign_x)
	var rug_mat := material(cloth_tone,.98)
	rug_mat.albedo_texture = load("res://prototype/assets/textures/ambientcg/Carpet012/Carpet012_Color_2K.jpg")
	box(r,"Tapete_Banho",Vector3(sign_x*5.85,2.882,4.93),Vector3(.78,.024,1.19),rug_mat)
	# Armário baixo encostado na parede; não ocupa o acesso vindo do hall.
	add_prop(r,"res://prototype/whole_house/real_assets/Comoda_Profile_140.tscn","Armario_Roupa_Banho",Vector3(sign_x*3.15,floor_y,5.72),180.0)
	var cloth := material(Color("b4b2a7"),.98)
	for i in range(3): box(r,"Toalha_Dobrada_%d" % i,Vector3(sign_x*3.12,3.735+i*.052,5.72),Vector3(.48,.046,.28),cloth)
	var soap := material(Color("c0b6a4"),.62)
	box(r,"Sabonete",Vector3(sign_x*4.98,3.777,2.73),Vector3(.11,.026,.065),soap)
	cylinder(r,"Frasco_Sabonete",Vector3(sign_x*5.55,3.865,2.64),.045,.19,material(Color("5e756f"),.45))
	box(r,"Bico_Sabonete",Vector3(sign_x*5.55,3.975,2.66),Vector3(.04,.025,.075),bronze)
	var folder := "primeiro__Banheiro_Familiar.tscn" if family else "primeiro__Banheiro_Suite.tscn"
	save_scene(r,ROOMS+folder)
	print("BATHROOM_SAVED %s children=%d" % [folder,r.get_child_count()])
	r.free()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"resources"))
	var vintage := create_asset("Banheira_Vintage", "banheira_vintage.glb")
	var family := create_asset("Banheira_Familiar", "banheira_familiar.glb")
	var toilet := create_asset("Vaso_Sanitario", "vaso_sanitario.glb")
	var roll := create_asset("Suporte_Papel", "suporte_papel.glb", false)
	build_room(true,family,toilet,roll)
	build_room(false,vintage,toilet,roll)
	var f := FileAccess.open("res://qa/whole_house/bathroom_bounds.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(metrics,"\t")+"\n")
	print("BATHROOMS_COMPLETE assets=4 rooms=2")
	quit()
