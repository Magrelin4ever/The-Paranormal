extends SceneTree

const SCENE_PATH := "res://prototype/house_environment.tscn"
const OUTPUT_DIR := "res://qa/editor_pilot/previews"
const VIEW_SIZE := Vector2i(1280, 720)

func _initialize() -> void:
	call_deferred("_capture_views")

func _capture_views() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("C13_CAPTURE_FAIL: cena da casa indisponível")
		quit(1)
		return
	var house := packed.instantiate() as Node3D
	root.add_child(house)
	root.size = VIEW_SIZE
	for _frame in range(20):
		await process_frame
	var help_layer := house.get_node_or_null("AjudaPrototipo") as CanvasLayer
	if help_layer != null:
		help_layer.visible = false
	var interaction_hud := house.get_node_or_null("Player/HUDInteracao") as CanvasLayer
	if interaction_hud != null:
		interaction_hud.visible = false
	var player := house.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		push_error("C13_CAPTURE_FAIL: jogador não encontrado")
		quit(1)
		return
	var head := player.get("head") as Node3D
	var camera := player.get("camera") as Camera3D
	if camera == null or head == null:
		push_error("C13_CAPTURE_FAIL: câmera ou cabeça do jogador ausente")
		quit(1)
		return
	var head_default_position := head.position
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	camera.current = true
	var portas := house.get_tree().get_nodes_in_group("porta_interativa")
	var portas_abertas := 0
	for porta in portas:
		if not bool(porta.call("esta_aberta")):
			porta.call("alternar")
			portas_abertas += 1
	await create_timer(0.45).timeout
	print("C13_DOORS_OPEN_FOR_CAPTURE count=%d" % portas_abertas)
	var flashlight_nodes := player.find_children("*", "SpotLight3D", true, false)
	if flashlight_nodes.size() < 3:
		push_error("C13_CAPTURE_FAIL: esperadas três camadas da lanterna; encontradas %d" % flashlight_nodes.size())
		quit(1)
		return
	print("C13_FLASHLIGHT_LAYERS_PASS count=%d" % flashlight_nodes.size())
	print("C13_LIGHT_AUDIT_SCOPE loaded_tree_only=true player_excluded=true directional_light_excluded=true energy_threshold=0.001")

	var interior_lights_on: Array[String] = []
	for node in house.find_children("*", "Light3D", true, false):
		var light := node as Light3D
		if light == null or player.is_ancestor_of(light) or light is DirectionalLight3D:
			continue
		if light.visible and light.light_energy > 0.001:
			interior_lights_on.append("%s energy=%.3f" % [light.get_path(), light.light_energy])
	if interior_lights_on.is_empty():
		print("C13_INTERIOR_LIGHTS_OFF_PASS count=0")
	else:
		push_error("C13_CAPTURE_FAIL: fontes de luz internas acesas: %s" % str(interior_lights_on))
		quit(1)
		return

	print("C13_EMISSIVE_AUDIT_SCOPE loaded_mesh_surfaces_only=true player_excluded=true lua_mesh_excluded=true emission_energy_threshold=0.001 source_import_flags_not_audited=true")
	var emissive_surfaces: Array[String] = []
	for node in house.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node == null or mesh_node.mesh == null:
			continue
		if mesh_node.name == "Lua" or player.is_ancestor_of(mesh_node):
			continue
		for surface in range(mesh_node.mesh.get_surface_count()):
			var material := mesh_node.get_active_material(surface) as BaseMaterial3D
			if material != null and material.emission_enabled and material.emission_energy_multiplier > 0.001:
				emissive_surfaces.append("%s surface=%d" % [mesh_node.get_path(), surface])
	if emissive_surfaces.is_empty():
		print("C13_EMISSIVE_MATERIALS_OFF_PASS count=0")
	else:
		push_error("C13_CAPTURE_FAIL: materiais emissivos ativos: %s" % str(emissive_surfaces))
		quit(1)
		return

	var dining_asset_counts := {"dining_table": 0, "dining_chair_02": 0, "Chandelier_03": 0}
	var plates := 0
	var cloth_visible := false
	var extra_end_chairs := 0
	var child_cups := 0
	var napkins := 0
	for node in house.find_children("*", "Node3D", true, false):
		var node_3d := node as Node3D
		var node_name := String(node_3d.name)
		if node_name == "CopoInfantilJantar":
			child_cups += 1
		if node_name == "GuardanapoJantar":
			napkins += 1
		if not node_name.begins_with("Asset_"):
			continue
		for asset_id in dining_asset_counts.keys():
			if node_name.ends_with("_" + String(asset_id)):
				dining_asset_counts[asset_id] += 1
		if node_name.ends_with("_dining_chair_02"):
			var chair_pos := node_3d.global_position
			if chair_pos.distance_to(Vector3(-7.72, 0.0, 0.03)) < 0.08 or chair_pos.distance_to(Vector3(-4.5, 0.0, -0.05)) < 0.08:
				extra_end_chairs += 1
	for node in house.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.name.begins_with("PratoJantar"):
			plates += 1
		if mesh_node.name == "dining_table_cloth":
			cloth_visible = mesh_node.visible
	if dining_asset_counts["dining_table"] == 1 and dining_asset_counts["dining_chair_02"] == 6 and dining_asset_counts["Chandelier_03"] == 1 and plates == 4 and child_cups == 1 and napkins == 1 and extra_end_chairs == 2 and not cloth_visible:
		print("C13_COMPOSITION_PASS table=1 chairs=6 chandelier=1 used_settings=4 extra_end_chairs=2 plates=4 child_cup=1 napkin=1 tablecloth_hidden=true")
	else:
		push_error("C13_CAPTURE_FAIL: composição inesperada: assets=%s plates=%d child_cups=%d napkins=%d extra_end_chairs=%d cloth_visible=%s" % [str(dining_asset_counts), plates, child_cups, napkins, extra_end_chairs, str(cloth_visible)])
		quit(1)
		return

	var views := [
		{"id": "overview_dark", "player": Vector3(-4.00, 0.05, -1.80), "target": Vector3(-6.15, 1.05, -0.05), "flashlight": false, "fov": 82.0},
		{"id": "overview_flashlight", "player": Vector3(-4.00, 0.05, -1.80), "target": Vector3(-6.15, 1.05, -0.05), "flashlight": true, "fov": 82.0},
		{"id": "tabletop", "player": Vector3(-8.20, 0.05, 0.15), "target": Vector3(-6.10, 0.92, -0.05), "flashlight": true, "fov": 64.0},
		{"id": "chair_detail", "player": Vector3(-4.25, 0.05, 2.05), "target": Vector3(-5.30, 0.95, 1.18), "flashlight": true, "fov": 62.0},
		{"id": "entry_perimeter", "player": Vector3(-4.00, 0.05, -1.85), "target": Vector3(-7.25, 1.18, -0.05), "flashlight": true, "fov": 86.0},
		{"id": "sideboard", "player": Vector3(-6.80, 0.05, -0.85), "target": Vector3(-8.05, 1.20, -2.52), "flashlight": true, "fov": 72.0},
		{"id": "wall_art", "player": Vector3(-7.10, 0.05, -1.30), "target": Vector3(-8.25, 1.78, -2.66), "flashlight": true, "fov": 64.0},
		{"id": "chandelier", "player": Vector3(-5.45, 0.05, 1.35), "target": Vector3(-6.08, 2.50, -0.05), "flashlight": true, "fov": 70.0},
		{"id": "transition_living", "player": Vector3(-5.55, 0.05, 2.05), "target": Vector3(-5.55, 1.00, 4.20), "flashlight": true, "fov": 82.0},
		{"id": "transition_kitchen", "player": Vector3(-5.55, 0.05, -1.72), "target": Vector3(-5.55, 1.00, -4.50), "flashlight": true, "fov": 82.0}
	]
	for view in views:
		var player_position: Vector3 = view["player"]
		var target: Vector3 = view["target"]
		var flashlight_on: bool = view["flashlight"]
		player.global_position = player_position
		player.rotation = Vector3.ZERO
		head.position = head_default_position + Vector3(0.0, float(view.get("eye_offset", 0.0)), 0.0)
		head.rotation = Vector3.ZERO
		head.look_at(target, Vector3.UP)
		camera.rotation = Vector3.ZERO
		camera.fov = float(view.get("fov", 75.0))
		camera.current = true
		for node in flashlight_nodes:
			(node as SpotLight3D).visible = flashlight_on
		await process_frame
		for _settle in range(6):
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			push_error("C13_CAPTURE_FAIL: viewport vazio para " + String(view["id"]))
			continue
		var filename := "piloto_runtime_%s.png" % String(view["id"])
		var output_path := ProjectSettings.globalize_path(OUTPUT_DIR + "/" + filename)
		var error := image.save_png(output_path)
		if error == OK:
			print("C13_CAPTURE_PASS view=%s path=%s size=%s flashlight=%s" % [String(view["id"]), output_path, str(image.get_size()), str(flashlight_on)])
		else:
			push_error("C13_CAPTURE_FAIL: falha ao gravar " + output_path + " error=" + str(error))
	quit(0)
