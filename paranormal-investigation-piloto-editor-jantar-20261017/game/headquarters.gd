extends Node3D

const UI := preload("res://game/ui_style.gd")
const CONSOLE_SCRIPT := preload("res://game/hq_console.gd")

var player: CharacterBody3D
var player_movement_locked := false
var current_console := ""
var hud_status: Label
var hud_objective: Label
var modal_layer: Control
var modal_content: VBoxContainer
var notice_text := ""

func _ready() -> void:
	add_to_group("investigation_manager")
	add_to_group("headquarters_manager")
	if GameState.current_case.is_empty():
		GameState.start_new_case()
	_build_room()
	_build_consoles()
	_spawn_player()
	_build_hud()
	GameState.changed.connect(_refresh_hud)
	_refresh_hud()

func _build_room() -> void:
	var environment_node := WorldEnvironment.new()
	environment_node.name = "AmbienteQG"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("0b1018")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a7b4c4")
	environment.ambient_light_energy = 0.62
	environment_node.environment = environment
	add_child(environment_node)
	_add_box("Piso", Vector3(0,-0.12,0), Vector3(20,0.24,18), Color("34383b"))
	_add_box("ParedeOeste", Vector3(-10,3,0), Vector3(0.3,6,18), Color("333844"))
	_add_box("ParedeLeste", Vector3(10,3,0), Vector3(0.3,6,18), Color("333844"))
	_add_box("ParedeFundos", Vector3(0,3,-9), Vector3(20,6,0.3), Color("303642"))
	_add_box("ParedeFrenteEsquerda", Vector3(-5.8,3,9), Vector3(8.4,6,0.3), Color("303642"))
	_add_box("ParedeFrenteDireita", Vector3(5.8,3,9), Vector3(8.4,6,0.3), Color("303642"))
	_add_box("Teto", Vector3(0,6.15,0), Vector3(20,0.3,18), Color("222a34"))
	_add_box("MesaDeBriefing", Vector3(0,0.9,0.3), Vector3(4.3,1.8,1.4), Color("483a2c"))
	_add_box("BancadaDeContatos", Vector3(-5.2,0.62,-3.9), Vector3(2.6,1.24,1.1), Color("4a4032"))
	_add_box("BancadaDeEquipamento", Vector3(0,0.62,-4.1), Vector3(2.8,1.24,1.1), Color("353e47"))
	_add_box("BancadaDeBriefing", Vector3(5.2,0.62,-3.9), Vector3(2.6,1.24,1.1), Color("403a32"))
	_add_box("ArmarioDeCampo", Vector3(-8.2,1.45,1.0), Vector3(1.6,2.9,2.0), Color("3f464b"))
	_add_box("QuadroDeOcorrencias", Vector3(0,3.3,-8.78), Vector3(5.7,2.6,0.12), Color("4b4436"))
	_add_point_light("LuzCentral", Vector3(0,5.45,0), Color("d8d3c5"), 1.05, 18.0)
	_add_point_light("LuzArquivo", Vector3(-6,4.2,-4), Color("c2d0dc"), 0.7, 12.0)
	_add_point_light("LuzBriefing", Vector3(6,4.2,-4), Color("e4c28d"), 0.78, 12.0)
	_add_label_3d("PONTO DE CONTATO", Vector3(-5.2,2.0,-3.25), Color("d5c5a9"))
	_add_label_3d("EQUIPAMENTO", Vector3(0,2.0,-3.40), Color("bfcbd4"))
	_add_label_3d("COMPUTADOR DE CASOS", Vector3(5.2,2.0,-3.25), Color("e2c18d"))
	_add_label_3d("QG  ·  UNIDADE DE INVESTIGAÇÃO", Vector3(0,5.0,-8.68), Color("e1c08b"), 30)

func _build_consoles() -> void:
	_add_console("family", "Atender contato da família", Vector3(-5.2,1.58,-3.15), Color("69604b"))
	_add_console("equipment", "Comprar / equipar instrumentos", Vector3(0,1.58,-3.35), Color("566673"))
	_add_console("briefing", "Rever o caso e iniciar visita", Vector3(5.2,1.58,-3.15), Color("776548"))

func _spawn_player() -> void:
	var player_script := load("res://prototype/house_player.gd") as Script
	player = player_script.new() as CharacterBody3D
	player.name = "Player"
	player.position = Vector3(0,0,5.8)
	add_child(player)
	var player_camera := player.get("camera") as Camera3D
	if player_camera != null:
		player_camera.make_current()

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD_QG"
	add_child(layer)
	var root_ui := Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root_ui)
	var status_panel := PanelContainer.new()
	status_panel.position = Vector2(18,54)
	status_panel.custom_minimum_size = Vector2(350,110)
	UI.apply_panel(status_panel, Color("0c1119dc"), Color("657386"))
	root_ui.add_child(status_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	status_panel.add_child(stack)
	hud_status = Label.new()
	hud_status.add_theme_font_size_override("font_size", 17)
	hud_status.add_theme_color_override("font_color", Color("f0e9dd"))
	stack.add_child(hud_status)
	hud_objective = Label.new()
	hud_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_objective.add_theme_font_size_override("font_size", 13)
	hud_objective.add_theme_color_override("font_color", Color("c0c9d3"))
	stack.add_child(hud_objective)
	var help := Label.new()
	help.text = "WASD mover  ·  mouse olhar  ·  E usar console  ·  Esc pausar"
	help.position = Vector2(20,18)
	help.add_theme_font_size_override("font_size", 13)
	help.add_theme_color_override("font_color", Color("c4cbd5"))
	root_ui.add_child(help)
	var prompt := Label.new()
	prompt.text = "Aproxime-se de um console."
	prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -300
	prompt.offset_top = -76
	prompt.offset_right = 300
	prompt.offset_bottom = -38
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 15)
	prompt.add_theme_color_override("font_color", Color("f0e8da"))
	root_ui.add_child(prompt)
	modal_layer = CenterContainer.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.visible = false
	root_ui.add_child(modal_layer)
	var modal_card := PanelContainer.new()
	modal_card.custom_minimum_size = Vector2(720, 560)
	UI.apply_panel(modal_card, Color("101722f5"), Color("a18a67"))
	modal_layer.add_child(modal_card)
	modal_content = VBoxContainer.new()
	modal_content.add_theme_constant_override("separation", 11)
	modal_card.add_child(modal_content)

func _refresh_hud() -> void:
	if not is_instance_valid(hud_status):
		return
	var current_title := str(GameState.current_case.get("title", "Sem caso aberto"))
	hud_status.text = "CENTRAL DE CAMPO  ·  $%d" % GameState.credits
	hud_objective.text = "%s\n%s" % [current_title, GameState.get_launch_blocker()]
	if not current_console.is_empty() and modal_layer.visible:
		_render_console(current_console)

func open_console(console_id: String) -> void:
	current_console = console_id
	player_movement_locked = true
	modal_layer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_render_console(console_id)

func close_console() -> void:
	if modal_layer != null:
		modal_layer.visible = false
	current_console = ""
	player_movement_locked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_pause() -> void:
	if modal_layer == null:
		return
	if modal_layer.visible:
		close_console()
		return
	current_console = "pause"
	player_movement_locked = true
	modal_layer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_render_console("pause")

func _render_console(console_id: String) -> void:
	for child in modal_content.get_children():
		child.queue_free()
	match console_id:
		"family": _render_family()
		"equipment": _render_equipment()
		"briefing": _render_briefing()
		_: _render_pause()

func _render_family() -> void:
	modal_content.add_child(_label("CONTATO DA FAMÍLIA", 25, Color("f3eee4")))
	modal_content.add_child(_label(str(GameState.current_case.get("family", "Família")) + "  ·  " + str(GameState.current_case.get("area", "Residência")), 14, Color("c8b48f")))
	var body := _label(str(GameState.current_case.get("brief", "Há relatos de atividade incomum.")), 16, Color("d5dae2"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_content.add_child(body)
	modal_content.add_child(_label("Uma chamada libera o relato de primeira mão e um adiantamento de $125 para completar o equipamento.", 14, Color("aeb9c7")))
	if GameState.family_contacted:
		var response := _label("“%s”" % str(GameState.current_case.get("family_message", "Obrigado por ajudar.")), 15, Color("e5d5ba"))
		response.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		modal_content.add_child(response)
		modal_content.add_child(_label("Adiantamento recebido. As três ferramentas restantes custam $315 no total.", 13, Color("9fb69f")))
	else:
		var call_button := _button("LIGAR PARA A FAMÍLIA  ·  RECEBER $125", true)
		call_button.pressed.connect(_contact_family)
		modal_content.add_child(call_button)
	modal_content.add_child(_spacer())
	_add_close_button()

func _contact_family() -> void:
	var result: Dictionary = GameState.contact_family()
	if not bool(result.get("ok", false)):
		notice_text = str(result.get("message", ""))
	_render_console("family")

func _render_equipment() -> void:
	modal_content.add_child(_label("EQUIPAMENTO DE CAMPO", 25, Color("f3eee4")))
	modal_content.add_child(_label("Créditos disponíveis: $%d  ·  Carga: %d/%d" % [GameState.credits, GameState.equipped_equipment.size(), GameState.EQUIPMENT_CAPACITY], 14, Color("c8b48f")))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 365)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for item_id in ["meter", "thermometer", "recorder", "camera", "battery", "filter"]:
		var item: Dictionary = GameState.TOOL_CATALOG[item_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		list.add_child(row)
		var details := _label("%s\n%s" % [item["name"], item["description"]], 13, Color("d3d8df"))
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(details)
		var action := _button(_equipment_action_text(item_id), false)
		action.custom_minimum_size = Vector2(175, 44)
		action.pressed.connect(_change_equipment.bind(item_id))
		row.add_child(action)
	modal_content.add_child(_label("A carga tem cinco espaços: lanterna e quatro instrumentos. Equipar os quatro instrumentos é necessário para fechar um caso.", 12, Color("9ca8b6")))
	_add_close_button()

func _equipment_action_text(item_id: String) -> String:
	if not GameState.owned_equipment.has(item_id):
		return "COMPRAR  $%d" % int(GameState.TOOL_CATALOG[item_id]["price"])
	if str(GameState.TOOL_CATALOG[item_id].get("category", "")) == "upgrade":
		return "MELHORIA INSTALADA"
	if GameState.equipped_equipment.has(item_id):
		return "EQUIPADO  ·  RETIRAR"
	return "EQUIPAR"

func _change_equipment(item_id: String) -> void:
	var result: Dictionary
	var passive_upgrade := str(GameState.TOOL_CATALOG[item_id].get("category", "")) == "upgrade"
	if GameState.owned_equipment.has(item_id):
		result = GameState.equip_equipment(item_id)
	else:
		result = GameState.buy_equipment(item_id)
		if bool(result.get("ok", false)) and not passive_upgrade:
			GameState.equip_equipment(item_id)
	notice_text = str(result.get("message", ""))
	_render_console("equipment")

func _render_briefing() -> void:
	modal_content.add_child(_label("BRIEFING DA OCORRÊNCIA", 25, Color("f3eee4")))
	modal_content.add_child(_label("%s  ·  %s" % [str(GameState.current_case.get("title", "Caso")), str(GameState.current_case.get("family", "Família"))], 16, Color("e0c58f")))
	modal_content.add_child(_label("NOTÍCIA LOCAL  ·  COMPUTADOR DO QG", 12, Color("c8b48f")))
	var news := _label(str(GameState.current_case.get("news", "Sem notícia adicional.")), 14, Color("c0c8d3"))
	news.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_content.add_child(news)
	var body := _label(str(GameState.current_case.get("brief", "")), 16, Color("d5dae2"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_content.add_child(body)
	modal_content.add_child(_label("OBJETIVO\n1. Percorrer os quatro pavimentos e registrar campo, frio, áudio e imagem.\n2. Use Q para trocar de instrumento e E para examinar um sinal.\n3. Evite a entidade, use os esconderijos e volte à van para entregar o relatório.", 14, Color("c5ccd6")))
	modal_content.add_child(_label("Pontos de retorno antecipado são permitidos; o relatório parcial fica salvo.", 13, Color("9ca8b6")))
	var blocker := GameState.get_launch_blocker()
	var start := _button("SAIR PARA A RESIDÊNCIA", true)
	start.disabled = not GameState.can_launch_case()
	start.pressed.connect(_launch_case)
	modal_content.add_child(start)
	if not GameState.can_launch_case():
		modal_content.add_child(_label(blocker, 13, Color("d5b27d")))
	_add_close_button()

func _launch_case() -> void:
	if not GameState.launch_case():
		return
	get_tree().change_scene_to_file("res://game/investigation.tscn")

func _render_pause() -> void:
	modal_content.add_child(_label("PAUSADO", 28, Color("f3eee4")))
	modal_content.add_child(_label("O progresso do perfil e o equipamento já estão salvos.", 15, Color("c0c8d3")))
	var resume := _button("RETOMAR", true)
	resume.pressed.connect(close_console)
	modal_content.add_child(resume)
	var menu := _button("MENU PRINCIPAL", false)
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://game/main_menu.tscn"))
	modal_content.add_child(menu)

func _add_close_button() -> void:
	var close := _button("FECHAR  ·  ESC", false)
	close.pressed.connect(close_console)
	modal_content.add_child(close)

func _add_console(console_id: String, label: String, position_3d: Vector3, color: Color) -> void:
	var console := CONSOLE_SCRIPT.new() as StaticBody3D
	console.name = "Console_" + console_id
	console.set("console_id", console_id)
	console.set("console_label", label)
	console.position = position_3d
	console.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1.20, 0.95, 0.62)
	shape.shape = box_shape
	console.add_child(shape)
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_shape.size
	mesh_instance.mesh = box_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	mesh_instance.material_override = material
	console.add_child(mesh_instance)
	var screen := MeshInstance3D.new()
	var screen_mesh := BoxMesh.new()
	screen_mesh.size = Vector3(0.72, 0.38, 0.025)
	screen.mesh = screen_mesh
	screen.position = Vector3(0,0.50,-0.325)
	var screen_material := StandardMaterial3D.new()
	screen_material.albedo_color = Color("253744")
	screen_material.roughness = 0.9
	screen.material_override = screen_material
	console.add_child(screen)
	add_child(console)

func _add_box(node_name: String, box_position: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = box_position
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	add_child(body)
	return body

func _add_point_light(node_name: String, position_3d: Vector3, tint: Color, energy: float, distance: float) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = position_3d
	light.light_color = tint
	light.light_energy = energy
	light.omni_range = distance
	light.shadow_enabled = false
	add_child(light)

func _add_label_3d(text: String, position_3d: Vector3, color: Color, size: int = 22) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = position_3d
	label.font_size = size
	label.pixel_size = 0.0035
	label.modulate = color
	label.outline_size = 5
	label.outline_modulate = Color("10141c")
	add_child(label)

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
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.apply_button(button, accent)
	return button

func _spacer() -> Control:
	var item := Control.new()
	item.custom_minimum_size.y = 4
	return item
