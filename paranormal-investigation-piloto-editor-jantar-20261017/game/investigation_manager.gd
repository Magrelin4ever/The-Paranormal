extends Node

const UI := preload("res://game/ui_style.gd")
const POINT_SCRIPT := preload("res://game/investigation_point.gd")
const HIDE_SCRIPT := preload("res://game/hide_spot.gd")
const EXTRACTION_SCRIPT := preload("res://game/extraction_point.gd")
const ENTITY_SCRIPT := preload("res://game/entity_controller.gd")

var house: Node3D
var player: CharacterBody3D
var points: Array[Node3D] = []
var hide_spots: Array[Node3D] = []
var extraction_node: Node3D
var entity: Node3D
var is_hiding := false
var player_movement_locked := false
var pause_open := false
var manifestation_active := false
var manifestations_used := 0
var max_manifestations := 3
var threat_timer := 48.0
var threat_rng := RandomNumberGenerator.new()
var hide_elapsed := 0.0
var stun_timer := 0.0
var hud_tick := 0.0
var status_label: Label
var objective_label: Label
var message_label: Label
var modal_layer: Control
var modal_content: VBoxContainer
var current_message := ""
var message_time := 0.0

func _ready() -> void:
	add_to_group("investigation_manager")
	threat_rng.randomize()
	if GameState.current_case.is_empty():
		GameState.start_new_case()
	house = get_node_or_null("../Casa") as Node3D
	if house == null:
		house = get_tree().current_scene.get_node_or_null("Casa") as Node3D
	if house != null:
		player = house.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		push_error("InvestigationManager: jogador não encontrado na cena da casa.")
		return
	_setup_leave_hide_action()
	_create_points()
	_create_hide_spots()
	_create_entity()
	_create_van_and_extraction()
	_create_hud()
	GameState.changed.connect(_refresh_hud)
	_refresh_hud()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_show_message("Caso iniciado. Registre quatro tipos de evidência e volte à van.", 6.0)

func _process(delta: float) -> void:
	if not GameState.session_active:
		return
	GameState.elapsed_seconds += delta
	if stun_timer > 0.0:
		stun_timer -= delta
		if stun_timer <= 0.0 and not pause_open and not is_hiding:
			player_movement_locked = false
	if is_hiding:
		hide_elapsed += delta
		if hide_elapsed > 18.0:
			_leave_hide("O ruído passou. Mude de lugar antes que ela volte.")
	if not manifestation_active and manifestations_used < max_manifestations:
		threat_timer -= delta
		if threat_timer <= 0.0:
			_start_entity_event()
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0 and is_instance_valid(message_label):
			message_label.visible = false
	hud_tick -= delta
	if hud_tick <= 0.0:
		hud_tick = 0.5
		_refresh_hud()

func _setup_leave_hide_action() -> void:
	if not InputMap.has_action("leave_hide"):
		InputMap.add_action("leave_hide")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_H
	if InputMap.action_get_events("leave_hide").is_empty():
		InputMap.action_add_event("leave_hide", event)

func _unhandled_input(event: InputEvent) -> void:
	if is_hiding and event.is_action_pressed("leave_hide"):
		_leave_hide("Você saiu do esconderijo.")

func _create_points() -> void:
	points.clear()
	for clue_value in GameState.current_case.get("clues", []):
		var clue: Dictionary = clue_value
		var point := POINT_SCRIPT.new() as Node3D
		point.name = "Evidencia_" + str(clue.get("id", "sinal"))
		point.set("point_id", str(clue.get("id", "")))
		point.set("point_name", str(clue.get("name", "Sinal anômalo")))
		point.set("category", str(clue.get("category", "field")))
		point.set("floor_label", str(clue.get("floor", "Térreo")))
		point.set("description", str(clue.get("description", "")))
		point.set("discovery_message", str(clue.get("discovery_message", "Leitura registrada.")))
		point.set("required", bool(clue.get("required", true)))
		point.set("manager", self)
		var floor_position: Vector3 = clue.get("position", Vector3.ZERO)
		point.position = floor_position + Vector3(0,0.8,0)
		add_child(point)
		points.append(point)

func _create_hide_spots() -> void:
	var locations := [
		{"name":"Abrigo_Oficina", "position":Vector3(4.8,-2.85,-6.4)},
		{"name":"Abrigo_Closet", "position":Vector3(-6.5,2.85,0.55)},
		{"name":"Abrigo_Sotao", "position":Vector3(5.2,5.7,3.1)}
	]
	for item in locations:
		var spot := HIDE_SCRIPT.new() as Node3D
		spot.name = str(item["name"])
		spot.position = item["position"]
		spot.set("manager", self)
		add_child(spot)
		hide_spots.append(spot)

func _create_entity() -> void:
	entity = ENTITY_SCRIPT.new() as Node3D
	entity.name = "Entidade"
	entity.visible = false
	var body := MeshInstance3D.new()
	body.name = "Silhueta"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.28
	capsule.height = 1.55
	body.mesh = capsule
	body.position.y = 0.95
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("171a22")
	material.roughness = 1.0
	body.material_override = material
	entity.add_child(body)
	var head_mesh := MeshInstance3D.new()
	head_mesh.name = "Cabeca"
	var head_shape := SphereMesh.new()
	head_shape.radius = 0.23
	head_shape.height = 0.46
	head_mesh.mesh = head_shape
	head_mesh.position = Vector3(0,1.86,0)
	head_mesh.material_override = material
	entity.add_child(head_mesh)
	var shoulder := MeshInstance3D.new()
	var shoulder_mesh := BoxMesh.new()
	shoulder_mesh.size = Vector3(0.78,0.22,0.26)
	shoulder.mesh = shoulder_mesh
	shoulder.position.y = 1.38
	shoulder.material_override = material
	entity.add_child(shoulder)
	add_child(entity)

func _start_entity_event() -> void:
	if entity == null or not is_instance_valid(player):
		return
	manifestation_active = true
	manifestations_used += 1
	var offset := player.global_transform.basis.z.normalized() * 7.0
	if player.global_position.z > 10.0:
		offset = Vector3(0,0,-6.0)
	entity.global_position = player.global_position + offset
	var progress := GameState.required_evidence_count()
	entity.set("speed", threat_rng.randf_range(0.9, 1.35) + minf(float(progress) * 0.08, 0.28))
	entity.call("activate", player, self)
	GameState.record_entity_event()
	_show_message("O medidor dispara. Manifestação %d/%d: algo se move no escuro — encontre abrigo ou continue avançando." % [manifestations_used, max_manifestations], 7.0)

func examine_point(point: Node3D) -> void:
	if not is_instance_valid(point) or bool(point.get("registered")):
		return
	var result: Dictionary = GameState.find_evidence(point.call("data"))
	_show_message(str(result.get("message", "")), 5.0)
	if not bool(result.get("ok", false)):
		return
	point.call("mark_registered")
	if GameState.required_evidence_count() >= 1 and manifestations_used == 0:
		threat_timer = minf(threat_timer, 22.0)
	if GameState.required_evidence_count() >= GameState.required_evidence_total():
		_show_message("Quatro categorias completas. Volte à van para entregar o relatório.", 8.0)

func cycle_equipment() -> void:
	var active := GameState.cycle_equipment()
	_show_message("Instrumento ativo: %s" % GameState.get_active_equipment_name(), 2.2)

func use_equipment(user: CharacterBody3D) -> void:
	if user == null:
		return
	var target := user.call("_porta_mirada") as Node
	if target != null and target.has_method("interagir"):
		target.call("interagir", user)
	else:
		_show_message("Aponte para um sinal ou objeto de interação.", 2.0)

func enter_hide_spot(_spot: Node3D, _user: CharacterBody3D) -> void:
	if is_hiding:
		_leave_hide("Você saiu do esconderijo.")
		return
	is_hiding = true
	hide_elapsed = 0.0
	player_movement_locked = true
	_show_message("Você se escondeu. Pressione H para sair; não fique parado por muito tempo.", 5.0)

func _leave_hide(message: String) -> void:
	is_hiding = false
	hide_elapsed = 0.0
	if not pause_open and stun_timer <= 0.0:
		player_movement_locked = false
	_show_message(message, 3.0)

func entity_reached_player(_source: Node3D) -> void:
	if is_hiding:
		return
	GameState.record_catch()
	stun_timer = 1.6
	player_movement_locked = true
	manifestation_active = false
	if entity != null:
		entity.set("active", false)
		entity.visible = false
	_show_message("A presença alcançou você. A luz voltou; afaste-se e mude de andar.", 5.0)
	_schedule_next_manifestation()

func entity_escaped(_source: Node3D) -> void:
	if not manifestation_active:
		return
	manifestation_active = false
	_show_message("A presença se perdeu entre os cômodos. O silêncio não dura.", 3.5)
	_schedule_next_manifestation()

func _schedule_next_manifestation() -> void:
	if manifestations_used >= max_manifestations:
		return
	var evidence_count := GameState.required_evidence_count()
	var low := 24.0 if evidence_count < GameState.required_evidence_total() else 16.0
	var high := 42.0 if evidence_count < GameState.required_evidence_total() else 28.0
	threat_timer = threat_rng.randf_range(low, high)

func finish_investigation() -> void:
	if is_hiding:
		_leave_hide("Você saiu do esconderijo.")
	var report := GameState.finish_case()
	if report.is_empty():
		return
	get_tree().change_scene_to_file("res://game/results.tscn")

func toggle_pause() -> void:
	if is_hiding:
		_leave_hide("Você saiu do esconderijo.")
		return
	if pause_open:
		_close_pause()
		return
	pause_open = true
	player_movement_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	modal_layer.visible = true
	for child in modal_content.get_children():
		child.queue_free()
	modal_content.add_child(_label("PAUSADO", 28, Color("f3eee4")))
	modal_content.add_child(_label("O equipamento e as descobertas deste caso ficam no perfil.", 15, Color("c0c8d3")))
	var resume := _button("RETOMAR", true)
	resume.pressed.connect(_close_pause)
	modal_content.add_child(resume)
	var end := _button("ENCERRAR VISITA  ·  RELATÓRIO PARCIAL", false)
	end.pressed.connect(finish_investigation)
	modal_content.add_child(end)

func _close_pause() -> void:
	pause_open = false
	player_movement_locked = false
	modal_layer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _create_van_and_extraction() -> void:
	var van := Node3D.new()
	van.name = "VanDeCampo"
	van.position = Vector3(-3.0,0,20.0)
	add_child(van)
	var body := _van_box(Vector3(0,1.05,0), Vector3(2.2,1.45,4.6), Color("33404a"))
	van.add_child(body)
	var cabin := _van_box(Vector3(0,1.45,-1.35), Vector3(1.92,1.18,1.65), Color("45525b"))
	van.add_child(cabin)
	var windshield := _van_box(Vector3(0,1.58,-2.19), Vector3(1.55,0.68,0.035), Color("18242d"))
	van.add_child(windshield)
	for side in [-1.0, 1.0]:
		for wheel_z in [-1.5, 1.35]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.34
			wheel_mesh.bottom_radius = 0.34
			wheel_mesh.height = 0.18
			wheel.mesh = wheel_mesh
			wheel.position = Vector3(side * 1.08,0.36,wheel_z)
			wheel.rotation.z = deg_to_rad(90.0)
			var wheel_material := StandardMaterial3D.new()
			wheel_material.albedo_color = Color("13171c")
			wheel_material.roughness = 1.0
			wheel.material_override = wheel_material
			van.add_child(wheel)
	var van_label := Label3D.new()
	van_label.text = "UNIDADE DE CAMPO"
	van_label.position = Vector3(0,2.25,0.0)
	van_label.font_size = 24
	van_label.pixel_size = 0.004
	van_label.modulate = Color("d6bd93")
	van_label.outline_size = 5
	van_label.outline_modulate = Color("11151b")
	van.add_child(van_label)
	extraction_node = EXTRACTION_SCRIPT.new() as Node3D
	extraction_node.name = "PontoDeRetorno"
	extraction_node.position = Vector3(-3.0,0,17.4)
	extraction_node.set("manager", self)
	add_child(extraction_node)

func _van_box(box_position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = box_position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.83
	mesh_instance.material_override = material
	return mesh_instance

func _create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUDInvestigacao"
	add_child(layer)
	var root_ui := Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root_ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(18,58)
	panel.custom_minimum_size = Vector2(390,104)
	UI.apply_panel(panel, Color("0b1119d9"), Color("6e7786"))
	root_ui.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	panel.add_child(stack)
	status_label = _label("CASO", 17, Color("f0e9dd"))
	stack.add_child(status_label)
	objective_label = _label("Evidências", 13, Color("c3ccd7"))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(objective_label)
	var gear := _label("Q instrumento  ·  F lanterna  ·  E examinar  ·  Shift correr  ·  Esc pausar", 12, Color("c4cbd5"))
	gear.position = Vector2(18,16)
	root_ui.add_child(gear)
	message_label = _label("", 16, Color("f0e8da"))
	message_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	message_label.offset_left = -370
	message_label.offset_top = -115
	message_label.offset_right = 370
	message_label.offset_bottom = -68
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.visible = false
	root_ui.add_child(message_label)
	modal_layer = CenterContainer.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.visible = false
	root_ui.add_child(modal_layer)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(540,310)
	UI.apply_panel(card, Color("101722f5"), Color("a18a67"))
	modal_layer.add_child(card)
	modal_content = VBoxContainer.new()
	modal_content.add_theme_constant_override("separation", 14)
	card.add_child(modal_content)

func _refresh_hud() -> void:
	if not is_instance_valid(status_label) or not is_instance_valid(objective_label):
		return
	var elapsed_minutes := int(GameState.elapsed_seconds / 60.0)
	var elapsed_remainder := int(GameState.elapsed_seconds) % 60
	status_label.text = "%s  ·  %02d:%02d  ·  $%d" % [str(GameState.current_case.get("title", "CASO")), elapsed_minutes, elapsed_remainder, GameState.credits]
	var required := GameState.required_evidence_total()
	var found := GameState.required_evidence_count()
	var next_line := "Retorne à van para entregar o relatório." if found >= required else _next_clue_hint()
	objective_label.text = "Evidências %d/%d  ·  %s\nFerramenta: %s  ·  Incidentes: %d" % [found, required, next_line, GameState.get_active_equipment_name(), GameState.catches]

func _next_clue_hint() -> String:
	var best: Node3D
	var best_distance := INF
	for point in points:
		if not is_instance_valid(point) or bool(point.get("registered")):
			continue
		var data: Dictionary = point.call("data")
		if not bool(data.get("required", true)):
			continue
		var distance := player.global_position.distance_to(point.global_position)
		if distance < best_distance:
			best_distance = distance
			best = point
	if best == null:
		return "Todos os sinais registrados"
	var category := str(best.get("category"))
	var name := str(best.get("point_name"))
	var floor_label := str(best.get("floor_label"))
	return "Próximo: %s · %s" % [floor_label, name]

func _show_message(text: String, duration: float = 3.5) -> void:
	current_message = text
	message_time = duration
	if is_instance_valid(message_label):
		message_label.text = text
		message_label.visible = true

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("06080b"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _button(text: String, accent: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0,44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.apply_button(button, accent)
	return button
