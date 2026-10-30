extends Control

const UI := preload("res://game/ui_style.gd")
var modal_layer: Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("090d13")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var wash := ColorRect.new()
	wash.color = Color("111a27")
	wash.anchor_left = 0.0
	wash.anchor_top = 0.0
	wash.anchor_right = 1.0
	wash.anchor_bottom = 1.0
	wash.offset_left = 0.0
	wash.offset_top = 0.0
	wash.offset_right = 0.0
	wash.offset_bottom = 0.0
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 520)
	UI.apply_panel(panel, Color("111923f2"), Color("718096"))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var eyebrow := _label("SINGLE-PLAYER · INVESTIGAÇÃO SOBRENATURAL", 13, Color("c4a06c"))
	column.add_child(eyebrow)
	var title := _label("THE PARANORMAL", 38, Color("f3eee4"))
	column.add_child(title)
	var subtitle := _label("A casa está sem energia. A família ainda está lá.", 17, Color("c0c8d3"))
	column.add_child(subtitle)
	var divider := HSeparator.new()
	column.add_child(divider)
	var description := _label("Prepare o equipamento, converse com quem mora na residência e siga os sinais por quatro pavimentos. Reúna evidências, administre o risco e volte para entregar o relatório.", 16, Color("d8dce3"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)
	column.add_child(_spacer(6))
	var start := _button("INICIAR INVESTIGAÇÃO", true)
	start.pressed.connect(_start_campaign)
	column.add_child(start)
	var options := _button("OPÇÕES", false)
	options.pressed.connect(_open_options)
	column.add_child(options)
	var controls := _button("CONTROLES", false)
	controls.pressed.connect(_open_controls)
	column.add_child(controls)
	var exit_button := _button("SAIR", false)
	exit_button.pressed.connect(_exit_game)
	column.add_child(exit_button)
	var profile := _label("Casos concluídos: %d   ·   Evidências: %d   ·   Créditos: $%d" % [GameState.cases_completed, GameState.total_evidence, GameState.credits], 13, Color("8994a3"))
	column.add_child(profile)
	var footer := _label("Projeto single-player · Godot 4 · progresso salvo neste computador", 11, Color("6d7887"))
	column.add_child(footer)

func _start_campaign() -> void:
	GameState.start_new_case()
	get_tree().change_scene_to_file("res://game/headquarters.tscn")

func _exit_game() -> void:
	get_tree().quit()

func _open_controls() -> void:
	var body := "W A S D  ·  mover\nMouse  ·  olhar\nShift  ·  correr\nF  ·  lanterna\nE  ·  interagir / examinar\nQ  ·  trocar ferramenta\nBotão esquerdo  ·  usar instrumento\nEsc  ·  pausar / liberar o cursor\nH  ·  sair de um esconderijo"
	var panel := _make_modal("CONTROLES", body)
	var close := _button("VOLTAR", false)
	close.pressed.connect(_close_modal)
	panel.add_child(close)

func _open_options() -> void:
	var panel := _make_modal("OPÇÕES", "As preferências ficam salvas no perfil local.")
	panel.add_child(_label("Sensibilidade do mouse", 15, Color("d8dce3")))
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.7
	sensitivity.max_value = 4.5
	sensitivity.step = 0.1
	sensitivity.value = GameState.mouse_sensitivity * 1000.0
	sensitivity.value_changed.connect(func(value: float): GameState.set_sensitivity(value / 1000.0))
	panel.add_child(sensitivity)
	panel.add_child(_label("Volume principal", 15, Color("d8dce3")))
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.01
	volume.value = GameState.master_volume
	volume.value_changed.connect(GameState.set_master_volume)
	panel.add_child(volume)
	var close := _button("VOLTAR", false)
	close.pressed.connect(_close_modal)
	panel.add_child(close)

func _make_modal(title_text: String, body_text: String) -> VBoxContainer:
	_close_modal()
	modal_layer = CenterContainer.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal_layer)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(470, 360)
	UI.apply_panel(card, Color("121a25f8"), Color("9c815b"))
	modal_layer.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	card.add_child(column)
	column.add_child(_label(title_text, 26, Color("f3eee4")))
	var body := _label(body_text, 16, Color("d0d6df"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body)
	return column

func _close_modal() -> void:
	if is_instance_valid(modal_layer):
		modal_layer.queue_free()
	modal_layer = null

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("080a0d"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _button(text: String, accent: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.apply_button(button, accent)
	return button

func _spacer(height: float) -> Control:
	var space := Control.new()
	space.custom_minimum_size.y = height
	return space
