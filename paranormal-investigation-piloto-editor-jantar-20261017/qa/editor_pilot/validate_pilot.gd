extends SceneTree

const HOUSE_SCENE: PackedScene = preload("res://prototype/house_environment.tscn")
const PILOT_SCENE_PATH: String = "res://prototype/editor_pilot/sala_jantar_editavel.tscn"
const GLB_SCENE_PATH: String = "res://prototype/assets/models/custom/kitchen004/kitchen004_fitted.glb"
const GLB_TEST_PATH: String = "user://editor_pilot_glb_persistence.tscn"
var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _find(root_node: Node, node_name: String) -> Node:
	return root_node.find_child(node_name, true, false)

func _run() -> void:
	var main_bytes_before: PackedByteArray = FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(PILOT_SCENE_PATH))
	var house: Node3D = HOUSE_SCENE.instantiate() as Node3D
	_check(house != null, "house_environment.tscn não instanciou")
	if house == null:
		_finish()
		return
	root.add_child(house)
	await process_frame
	await physics_frame
	await physics_frame

	var pilots: Array[Node] = house.find_children("SalaJantar_Editavel", "Node3D", true, false)
	_check(pilots.size() == 1, "runtime piloto duplicado ou ausente: %d" % pilots.size())
	var pilot: Node3D = pilots[0] as Node3D if pilots.size() == 1 else null
	_check(_find(house, "Referencia_EDITOR_so") == null, "Referencia_EDITOR_so sobreviveu ao runtime")
	_check(_find(house, "Mesa") != null, "Mesa ausente")
	if pilot == null:
		_finish()
		return

	var movable_names: Array[String] = ["Mesa", "Cadeira_01", "Cadeira_02", "Cadeira_03", "Cadeira_04", "Cadeira_05_Cabeceira", "Cadeira_06_Cabeceira", "Aparador", "Tapete", "Lustre_Apagado", "Quadro_Com_Arte", "Planta"]
	for movable_name in movable_names:
		var movable: Node = pilot.get_node_or_null(NodePath(movable_name))
		_check(movable != null, "movel ausente: %s" % movable_name)
		if movable != null:
			var saved_child: Node = movable.find_child("*", true, false)
			_check(saved_child == null or saved_child.owner != null, "owner ausente nos filhos salvos: %s" % movable_name)
			for child in movable.find_children("*", "Node", true, false):
				if child.name.begins_with("Asset_"):
					_check(child.name.length() > 9 and child.name.substr(6, 2).is_valid_int() and child.name.substr(8, 1) == "_", "visual Asset malformado: %s" % child.name)

	var chairs: Array[Node] = []
	for child in pilot.get_children():
		if child.name.begins_with("Cadeira_"):
			chairs.append(child)
	_check(chairs.size() == 6, "esperadas seis cadeiras, encontradas %d" % chairs.size())
	_check(_count_nodes_named(house, "dining_table") == 1, "esperada uma instância dining_table")
	_check(_count_nodes_named(house, "dining_chair_02") == 6, "esperadas seis instâncias dining_chair_02")

	var mesa: Node3D = pilot.get_node_or_null("Mesa") as Node3D
	var mesa_col: Node3D = _find(mesa, "Colisao_Acompanha_Movel") as Node3D if mesa != null else null
	var cha: Node3D = _find(mesa, "Conjunto_Cha") as Node3D if mesa != null else null
	_check(mesa_col != null and _has_collision_shape(mesa_col), "Mesa sem StaticBody3D/CollisionShape3D")
	_check(cha != null, "Conjunto_Cha ausente")
	if mesa != null and mesa_col != null:
		var old_pos: Vector3 = mesa.global_position
		var old_rot: Vector3 = mesa.global_rotation
		var old_col: Transform3D = mesa_col.global_transform
		var old_cha: Transform3D = cha.global_transform if cha != null else Transform3D.IDENTITY
		mesa.position += Vector3(0.37, 0.0, -0.29)
		mesa.rotation.y += 0.31
		await physics_frame
		_check(mesa_col.global_transform.origin.distance_to(old_col.origin) > 0.05, "colisor da Mesa não acompanhou transform")
		if cha != null:
			_check(cha.global_transform.origin.distance_to(old_cha.origin) > 0.05, "props da Mesa não acompanharam transform")
		mesa.global_position = old_pos
		mesa.global_rotation = old_rot
		await physics_frame

	var cadeira: Node3D = pilot.get_node_or_null("Cadeira_02") as Node3D
	var cadeira_col: Node3D = _find(cadeira, "Colisao_Acompanha_Movel") as Node3D if cadeira != null else null
	_check(cadeira_col != null and _has_collision_shape(cadeira_col), "Cadeira_02 sem StaticBody3D/CollisionShape3D")
	if cadeira != null and cadeira_col != null:
		var chair_origin: Vector3 = cadeira_col.global_position
		var chair_pos: Vector3 = cadeira.global_position
		var chair_rot: Vector3 = cadeira.global_rotation
		cadeira.position += Vector3(-0.22, 0.0, 0.41)
		cadeira.rotation.y -= 0.27
		await physics_frame
		_check(cadeira_col.global_position.distance_to(chair_origin) > 0.05, "colisor da Cadeira_02 não acompanhou transform")
		cadeira.global_position = chair_pos
		cadeira.global_rotation = chair_rot
		await physics_frame

	var player: Node = house.get_node_or_null("Player")
	var player_lights: Array[Node] = player.find_children("*", "Light3D", true, false) if player != null else []
	_check(player != null and player_lights.size() == 3, "player não expôs as três camadas da lanterna")
	if player != null:
		player.call("set_flashlight_active", false)
		await process_frame
		for light_node in player_lights:
			_check(not (light_node as Light3D).visible, "camada da lanterna não desligou")
		player.call("set_flashlight_active", true)
		await process_frame
		for light_node in player_lights:
			_check((light_node as Light3D).visible, "camada da lanterna não ligou")
	for light_node in house.find_children("*", "Light3D", true, false):
		var light: Light3D = light_node as Light3D
		if not player_lights.has(light_node) and not (light is DirectionalLight3D):
			_check(not light.visible, "luz interna ligada: %s" % light.get_path())

	var glb: PackedScene = load(GLB_SCENE_PATH) as PackedScene
	_check(glb != null, "GLB de teste ausente")
	if glb != null:
		var temp: Node3D = Node3D.new()
		temp.name = "TempGLBRoot"
		var glb_instance: Node = glb.instantiate()
		temp.add_child(glb_instance)
		glb_instance.owner = temp
		var packed: PackedScene = PackedScene.new()
		_check(packed.pack(temp) == OK, "falha ao empacotar instância GLB temporária")
		_check(ResourceSaver.save(packed, GLB_TEST_PATH) == OK, "falha ao salvar GLB temporário em user://")
		var reloaded: PackedScene = ResourceLoader.load(GLB_TEST_PATH) as PackedScene
		_check(reloaded != null, "falha ao recarregar GLB temporário")
		if reloaded != null:
			var reload_instance: Node = reloaded.instantiate()
			_check(reload_instance != null, "falha ao instanciar GLB recarregado")
			reload_instance.free()
		temp.free()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GLB_TEST_PATH))

	var main_bytes_after: PackedByteArray = FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(PILOT_SCENE_PATH))
	_check(main_bytes_before == main_bytes_after, "cena principal foi alterada durante o teste")
	print("PILOT_VALIDATE PASS" if _failures.is_empty() else "PILOT_VALIDATE FAIL")
	house.queue_free()
	await process_frame
	_finish()

func _count_nodes_named(root_node: Node, wanted: String) -> int:
	var count: int = 0
	for node in root_node.find_children("*", "Node", true, false):
		if String(node.name).begins_with("Asset_") and String(node.name).ends_with("_" + wanted):
			count += 1
	return count

func _has_collision_shape(body: Node) -> bool:
	return not body.find_children("*", "CollisionShape3D", true, false).is_empty()

func _finish() -> void:
	for failure in _failures:
		printerr("PILOT_VALIDATE: ", failure)
	quit(0 if _failures.is_empty() else 1)
