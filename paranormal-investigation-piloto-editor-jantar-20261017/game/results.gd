extends Control

const UI := preload("res://game/ui_style.gd")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("090d13")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(700, 610)
	UI.apply_panel(card, Color("111923f2"), Color("718096"))
	center.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	card.add_child(column)
	var report: Dictionary = GameState.last_report
	var resolved := bool(report.get("resolved", false))
	column.add_child(_label("RELATÓRIO DE CAMPO", 14, Color("c4a06c")))
	column.add_child(_label("CASO RESOLVIDO" if resolved else "VISITA ENCERRADA", 32, Color("e5ca97") if resolved else Color("c7a57e")))
	column.add_child(_label(str(report.get("case_title", "Caso sem identificação")), 20, Color("f3eee4")))
	var family := _label("%s  ·  %s" % [str(report.get("family", "Família")), "Concluído" if resolved else "Parcial"], 14, Color("c0c8d3"))
	column.add_child(family)
	var divider := HSeparator.new()
	column.add_child(divider)
	column.add_child(_label("EVIDÊNCIAS: %d / %d obrigatórias  ·  %d pistas complementares" % [int(report.get("evidence_count", 0)), int(report.get("evidence_total", 0)), int(report.get("optional_count", 0))], 15, Color("d9dfe6")))
	var evidence_lines := PackedStringArray()
	for item_value in report.get("evidence", []):
		var item: Dictionary = item_value
		evidence_lines.append("• %s  —  %s" % [str(item.get("name", "Sinal")), str(item.get("floor", ""))])
	if evidence_lines.is_empty():
		evidence_lines.append("Nenhuma evidência foi anexada ao relatório.")
	var evidence := _label("\n".join(evidence_lines), 13, Color("c0c8d3"))
	evidence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(evidence)
	column.add_child(_label("EVENTOS DA ENTIDADE: %d  ·  INCIDENTES: %d  ·  TEMPO: %s" % [int(report.get("entity_events", 0)), int(report.get("catches", 0)), _format_time(float(report.get("elapsed_seconds", 0.0)))], 13, Color("aeb9c7")))
	var closing := _label(str(report.get("closing", "")), 14, Color("d6d7d8"))
	closing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(closing)
	column.add_child(_label("Pagamento do caso: +$%d    ·    Saldo do perfil: $%d" % [int(report.get("reward", 0)), int(report.get("credits", 0))], 17, Color("e1c08b")))
	var next := _button("ACEITAR PRÓXIMO CASO  ·  VOLTAR AO QG", true)
	next.pressed.connect(_new_case)
	column.add_child(next)
	var menu := _button("MENU PRINCIPAL", false)
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://game/main_menu.tscn"))
	column.add_child(menu)

func _new_case() -> void:
	GameState.start_another_case()
	get_tree().change_scene_to_file("res://game/headquarters.tscn")

func _format_time(seconds: float) -> String:
	var minutes := int(seconds / 60.0)
	var remainder := int(seconds) % 60
	return "%02d:%02d" % [minutes, remainder]

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
