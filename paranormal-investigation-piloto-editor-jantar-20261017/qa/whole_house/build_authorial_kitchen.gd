extends SceneTree

const OUTPUT_PATH := "res://prototype/whole_house/rooms/terreo__Cozinha_Richard.tscn"
const RESULT_PATH := "res://qa/whole_house/kitchen_rebuild_results.json"

var root_scene: Node3D
var materials: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	_create_materials()
	root_scene = Node3D.new()
	root_scene.name = "Cozinha_Richard"
	root_scene.set_meta("pavimento", "terreo")
	root_scene.set_meta("edicao", "Cozinha autoral modular; geometry original; materiais PBR CC0 Wood026 e Marble002.")
	root.add_child(root_scene)
	_build_back_cabinets()
	_build_tall_oven_tower()
	_build_fridge()
	_build_island()
	_build_stool("Banqueta_A", Vector3(-6.83, 0.0, -3.16))
	_build_stool("Banqueta_B", Vector3(-5.75, 0.0, -3.16))
	_build_open_shelf()
	_build_counter_props()
	await process_frame
	_set_edit_owners(root_scene, root_scene)
	var packed := PackedScene.new()
	var pack_error := packed.pack(root_scene)
	if pack_error != OK:
		push_error("Falha ao empacotar a cozinha autoral: %s" % pack_error)
		quit(1)
		return
	var save_error := ResourceSaver.save(packed, OUTPUT_PATH)
	if save_error != OK:
		push_error("Falha ao gravar a cena da cozinha: %s" % save_error)
		quit(1)
		return
	var verify := (load(OUTPUT_PATH) as PackedScene).instantiate() as Node3D
	root.add_child(verify)
	await process_frame
	var bounds := AABB()
	var first := true
	var meshes := verify.find_children("*", "MeshInstance3D", true, false)
	var colliders := verify.find_children("*", "CollisionShape3D", true, false)
	var forbidden := 0
	for node in meshes:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		var mesh_bounds := mesh_node.global_transform * mesh_node.get_aabb()
		bounds = mesh_bounds if first else bounds.merge(mesh_bounds)
		first = false
		if mesh_node.layers != 4:
			forbidden += 1
	var result := {
		"scene": OUTPUT_PATH,
		"source": "Autoral, Godot primitive meshes e materiais com licença verificada; nenhuma malha Kitchen004/Tripo.",
		"modules": ["Armarios_fundo", "Torre_forno", "Geladeira", "Ilha", "Banquetas", "Prateleiras", "Aderecos"],
		"mesh_count": meshes.size(),
		"collision_shape_count": colliders.size(),
		"bounds": {"position": bounds.position, "size": bounds.size},
		"all_meshes_on_ground_floor_layer": forbidden == 0,
		"external_unknown_assets": [],
		"passed": meshes.size() >= 20 and colliders.size() >= 4 and forbidden == 0
	}
	var file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	print("KITCHEN_AUTHORIAL_BUILD %s meshes=%d colliders=%d bounds=%s" % ["PASS" if result["passed"] else "FAIL", meshes.size(), colliders.size(), bounds])
	verify.free()
	root_scene.free()
	quit(0 if result["passed"] else 1)

func _create_materials() -> void:
	var wood := _material(Color("796048"), 0.82)
	wood.albedo_texture = load("res://prototype/assets/textures/ambientcg/Wood026/Wood026_Color_2K.jpg") as Texture2D
	wood.normal_texture = load("res://prototype/assets/textures/ambientcg/Wood026/Wood026_NormalGL_2K.jpg") as Texture2D
	wood.normal_enabled = wood.normal_texture != null
	wood.normal_scale = 0.55
	wood.roughness_texture = load("res://prototype/assets/textures/ambientcg/Wood026/Wood026_Roughness_2K.jpg") as Texture2D
	wood.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	wood.albedo_color = Color(0.82, 0.76, 0.66)
	materials["wood"] = wood
	var stone := _material(Color("b8b7b0"), 0.74)
	stone.albedo_texture = load("res://prototype/assets/textures/ambientcg/Marble002/Marble002_Color_2K.jpg") as Texture2D
	stone.normal_texture = load("res://prototype/assets/textures/ambientcg/Marble002/Marble002_NormalGL_2K.jpg") as Texture2D
	stone.normal_enabled = stone.normal_texture != null
	stone.normal_scale = 0.28
	stone.roughness_texture = load("res://prototype/assets/textures/ambientcg/Marble002/Marble002_Roughness_2K.jpg") as Texture2D
	stone.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	stone.albedo_color = Color(0.89, 0.88, 0.84)
	materials["stone"] = stone
	materials["cabinet"] = _material(Color("475147"), 0.84)
	materials["panel"] = _material(Color("5e695d"), 0.88)
	materials["metal"] = _material(Color("747a7b"), 0.48, 0.54)
	materials["dark_metal"] = _material(Color("24292c"), 0.58, 0.18)
	materials["glass"] = _material(Color("111518"), 0.3, 0.12)
	materials["ceramic"] = _material(Color("ded8cb"), 0.62)
	materials["linen"] = _material(Color("817b6d"), 0.94)
	materials["leaf"] = _material(Color("435448"), 0.95)

func _material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	material.emission_enabled = false
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material

func _module(name: String, position: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = name
	node.position = position
	node.set_meta("_edit_group_", true)
	root_scene.add_child(node)
	return node

func _box(parent: Node3D, name: String, position: Vector3, size: Vector3, material_key: String, layer: int = 4) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.position = position
	instance.layers = layer
	instance.material_override = materials[material_key]
	parent.add_child(instance)
	return instance

func _cylinder(parent: Node3D, name: String, position: Vector3, radius: float, height: float, material_key: String, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	var instance := MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.layers = 4
	instance.material_override = materials[material_key]
	parent.add_child(instance)
	return instance

func _sphere(parent: Node3D, name: String, position: Vector3, radius: float, material_key: String) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var instance := MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.position = position
	instance.layers = 4
	instance.material_override = materials[material_key]
	parent.add_child(instance)
	return instance

func _body(parent: Node3D, name: String, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "Colisao_" + name
	body.collision_layer = 1
	body.collision_mask = 1
	parent.add_child(body)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position = position
	body.add_child(shape)

func _build_back_cabinets() -> void:
	var module := _module("Armarios_e_bancada_fundo", Vector3(-6.30, 0.0, -7.62))
	_body(module, "Armarios_base", Vector3(0.0, 0.36, 0.0), Vector3(5.35, 0.72, 0.62))
	_box(module, "Corpo_base", Vector3(0.0, 0.36, 0.0), Vector3(5.35, 0.72, 0.62), "cabinet")
	_box(module, "Rodape", Vector3(0.0, 0.07, 0.325), Vector3(5.20, 0.12, 0.035), "wood")
	for index in range(6):
		var x := -2.13 + float(index) * 0.852
		_box(module, "Porta_inferior_%02d" % index, Vector3(x, 0.39, 0.331), Vector3(0.79, 0.59, 0.045), "panel")
		_box(module, "Frente_gaveta_%02d" % index, Vector3(x, 0.70, 0.334), Vector3(0.79, 0.10, 0.05), "wood")
		_box(module, "Puxador_%02d" % index, Vector3(x, 0.71, 0.366), Vector3(0.18, 0.022, 0.018), "metal")
	_box(module, "Tampo_pedra", Vector3(0.0, 0.77, 0.0), Vector3(5.55, 0.08, 0.76), "stone")
	_box(module, "Rodabanca", Vector3(0.0, 1.04, -0.282), Vector3(5.45, 0.46, 0.045), "stone")
	_box(module, "Cuba_pia", Vector3(-1.25, 0.718, 0.04), Vector3(0.82, 0.018, 0.44), "dark_metal")
	_box(module, "Fundo_cuba", Vector3(-1.25, 0.704, 0.04), Vector3(0.66, 0.012, 0.30), "metal")
	_cylinder(module, "Torneira_vertical", Vector3(-1.25, 0.94, -0.19), 0.024, 0.28, "metal")
	_cylinder(module, "Torneira_bica", Vector3(-1.25, 1.075, -0.08), 0.016, 0.18, "metal", Vector3(0.0, 0.0, PI / 2.0))
	_box(module, "Armario_superior", Vector3(0.0, 1.89, -0.12), Vector3(4.85, 0.82, 0.42), "wood")
	for index in range(5):
		var x := -1.94 + float(index) * 0.97
		_box(module, "Porta_aerea_%02d" % index, Vector3(x, 1.89, 0.105), Vector3(0.90, 0.73, 0.045), "panel")
		_box(module, "Puxador_aereo_%02d" % index, Vector3(x + (0.27 if index % 2 == 0 else -0.27), 1.89, 0.14), Vector3(0.025, 0.12, 0.02), "metal")
	_box(module, "Cooktop_desligado", Vector3(1.30, 0.817, 0.00), Vector3(0.68, 0.018, 0.51), "glass")
	for x in [1.12, 1.45]:
		for z in [-0.12, 0.12]:
			_cylinder(module, "Disco_cooktop_sem_emissao", Vector3(x, 0.829, z), 0.067, 0.004, "dark_metal")

func _build_tall_oven_tower() -> void:
	var module := _module("Torre_de_forno", Vector3(-2.11, 0.0, -6.55))
	_body(module, "Torre", Vector3.ZERO, Vector3(0.48, 2.40, 0.94))
	_box(module, "Carcaca_torre", Vector3(0.0, 1.20, 0.0), Vector3(0.48, 2.40, 0.94), "wood")
	_box(module, "Painel_torre_frontal", Vector3(-0.257, 1.22, 0.0), Vector3(0.025, 2.28, 0.86), "panel")
	_box(module, "Nicho_forno", Vector3(-0.275, 1.12, 0.0), Vector3(0.032, 0.64, 0.70), "glass")
	_box(module, "Moldura_forno", Vector3(-0.295, 1.12, 0.0), Vector3(0.018, 0.72, 0.78), "metal")
	_box(module, "Vidro_forno", Vector3(-0.308, 1.12, 0.0), Vector3(0.014, 0.55, 0.61), "glass")
	_box(module, "Puxador_forno", Vector3(-0.337, 1.45, 0.0), Vector3(0.035, 0.035, 0.43), "metal")
	_box(module, "Nicho_microondas_desligado", Vector3(-0.276, 1.91, 0.0), Vector3(0.03, 0.36, 0.72), "dark_metal")
	_box(module, "Frente_microondas", Vector3(-0.298, 1.91, 0.0), Vector3(0.018, 0.30, 0.62), "glass")
	_box(module, "Prateleira_separadora", Vector3(-0.24, 1.64, 0.0), Vector3(0.06, 0.045, 0.80), "stone")
	for side in [-1.0, 1.0]:
		_box(module, "Puxador_torre_%s" % str(side), Vector3(-0.33, 2.23, side * 0.22), Vector3(0.035, 0.16, 0.025), "metal")
		_cylinder(module, "Botao_forno_%s" % str(side), Vector3(-0.33, 1.55, side * 0.22), 0.035, 0.025, "metal", Vector3(0.0, 0.0, PI / 2.0))

func _build_fridge() -> void:
	var module := _module("Geladeira_duas_portas", Vector3(-8.86, 0.0, -5.62))
	_body(module, "Geladeira", Vector3(0.0, 0.91, 0.0), Vector3(0.86, 1.82, 0.75))
	_box(module, "Gabinete", Vector3(0.0, 0.91, 0.0), Vector3(0.86, 1.82, 0.75), "metal")
	_box(module, "Porta_superior", Vector3(0.447, 1.29, 0.0), Vector3(0.025, 1.02, 0.70), "metal")
	_box(module, "Porta_inferior", Vector3(0.447, 0.55, 0.0), Vector3(0.025, 0.42, 0.70), "metal")
	_box(module, "Junta_horizontal", Vector3(0.465, 0.76, 0.0), Vector3(0.012, 0.018, 0.69), "dark_metal")
	for z in [-0.26, 0.26]:
		_box(module, "Puxador_vertical_%s" % str(z), Vector3(0.475, 1.23, z), Vector3(0.035, 0.30, 0.025), "dark_metal")
	_box(module, "Pezes", Vector3(0.0, 0.055, 0.0), Vector3(0.72, 0.08, 0.64), "dark_metal")

func _build_island() -> void:
	var module := _module("Ilha_de_preparo", Vector3(-6.26, 0.0, -5.18))
	_body(module, "Ilha", Vector3(0.0, 0.39, -0.02), Vector3(1.90, 0.78, 0.82))
	_box(module, "Carcaca_ilha", Vector3(0.0, 0.39, -0.02), Vector3(1.90, 0.78, 0.82), "cabinet")
	for index in range(3):
		var x := -0.62 + float(index) * 0.62
		_box(module, "Porta_ilha_%02d" % index, Vector3(x, 0.38, -0.45), Vector3(0.56, 0.68, 0.035), "panel")
		_box(module, "Puxador_ilha_%02d" % index, Vector3(x + 0.18, 0.40, -0.478), Vector3(0.022, 0.14, 0.018), "metal")
	_box(module, "Linha_sombra_ilha", Vector3(0.0, 0.79, -0.02), Vector3(1.96, 0.03, 0.87), "panel")
	_box(module, "Tampo_ilha", Vector3(0.0, 0.86, 0.07), Vector3(2.15, 0.08, 1.12), "stone")
	_box(module, "Tábua_de_madeira", Vector3(-0.45, 0.914, 0.16), Vector3(0.58, 0.018, 0.34), "wood")
	_cylinder(module, "Tigela_ceramica", Vector3(0.50, 0.98, 0.18), 0.16, 0.10, "ceramic")
	for offset in [Vector3(0.46, 1.07, 0.14), Vector3(0.55, 1.06, 0.22), Vector3(0.49, 1.04, 0.28)]:
		_sphere(module, "Maca", offset, 0.065, "leaf")

func _build_stool(name: String, world_position: Vector3) -> void:
	var module := _module(name, world_position)
	_body(module, "Banqueta", Vector3(0.0, 0.34, 0.0), Vector3(0.38, 0.68, 0.38))
	_cylinder(module, "Assento_de_madeira", Vector3(0.0, 0.68, 0.0), 0.20, 0.08, "wood")
	for x in [-0.13, 0.13]:
		for z in [-0.13, 0.13]:
			_cylinder(module, "Perna", Vector3(x, 0.33, z), 0.018, 0.62, "metal", Vector3(z * 0.30, 0.0, -x * 0.30))
	_box(module, "Apoio_pes_horizontal", Vector3(0.0, 0.28, 0.0), Vector3(0.30, 0.025, 0.30), "metal")

func _build_open_shelf() -> void:
	var module := _module("Prateleiras_de_parede", Vector3(-2.24, 0.0, -5.30))
	_box(module, "Painel_fundo", Vector3(0.15, 1.80, 0.0), Vector3(0.035, 1.40, 1.56), "wood")
	for y in [1.36, 1.80, 2.22]:
		_box(module, "Prateleira_%02d" % int(y * 100.0), Vector3(0.0, y, 0.0), Vector3(0.32, 0.05, 1.58), "wood")
	for z in [-0.68, 0.68]:
		_box(module, "Montante", Vector3(0.11, 1.80, z), Vector3(0.035, 1.33, 0.035), "metal")
	_cylinder(module, "Pote_de_cha", Vector3(-0.02, 1.50, -0.40), 0.085, 0.22, "ceramic")
	_cylinder(module, "Jarra", Vector3(-0.03, 1.98, 0.40), 0.11, 0.27, "metal")

func _build_counter_props() -> void:
	var module := _module("Aderecos_da_cozinha", Vector3(-6.30, 0.0, -7.62))
	for index in range(3):
		_cylinder(module, "Pote_de_tempero_%02d" % index, Vector3(-0.18 + float(index) * 0.13, 1.12, 0.10), 0.04, 0.15, "ceramic")
	var mug := _cylinder(module, "Caneca_de_ceramica", Vector3(-0.52, 0.91, 0.12), 0.055, 0.11, "ceramic")
	mug.scale = Vector3(1.0, 0.9, 1.0)
	_box(module, "Cafeteira_apagada", Vector3(0.68, 0.98, 0.02), Vector3(0.28, 0.34, 0.24), "dark_metal")
	_box(module, "Vidro_cafeteira", Vector3(0.68, 0.88, 0.145), Vector3(0.15, 0.10, 0.012), "glass")

func _set_edit_owners(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_edit_owners(child, scene_owner)
