extends SceneTree

var failures: Array[String] = []
var profile_existed := false
var profile_backup := ""
const PROFILE := "user://paranormal_profile.cfg"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	profile_existed = FileAccess.file_exists(PROFILE)
	if profile_existed:
		profile_backup = FileAccess.get_file_as_string(PROFILE)
	var state := root.get_node_or_null("GameState")
	_check(state != null, "autoload GameState disponível")
	if state == null:
		_finish()
		return

	var menu := (load("res://game/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	_check(menu.find_children("*", "Button", true, false).size() >= 3, "menu inicial oferece iniciar, opções e controles")
	menu.free()
	await process_frame

	state.set("credits", 260)
	(state.get("owned_equipment") as Array).clear()
	(state.get("owned_equipment") as Array).append_array(["lantern", "meter"])
	(state.get("equipped_equipment") as Array).clear()
	(state.get("equipped_equipment") as Array).append_array(["lantern", "meter"])
	state.set("active_equipment", "meter")
	state.call("start_new_case")
	var hq := (load("res://game/headquarters.tscn") as PackedScene).instantiate()
	root.add_child(hq)
	await process_frame
	await physics_frame
	var hq_player := hq.get_node_or_null("Player") as CharacterBody3D
	var family_console := hq.get_node_or_null("Console_family") as StaticBody3D
	_check(hq_player != null and family_console != null, "QG cria jogador FPS e console físico de contato")
	if hq_player != null and family_console != null:
		hq_player.set_physics_process(false)
		var head := hq_player.get("head") as Node3D
		hq_player.global_position = Vector3(-5.2, 0.0, -0.70)
		head.look_at(family_console.global_position + Vector3(0,0.52,0), Vector3.UP)
		await physics_frame
		var looked := hq_player.call("_porta_mirada") as Node
		_check(looked == family_console, "raycast mira o console de contato a partir da posição de jogo")
		_press_key(hq_player, KEY_E)
		await process_frame
		_check(bool(hq.get("player_movement_locked")) and bool(hq.get("modal_layer").get("visible")), "tecla E abre o console e pausa o movimento")
		if bool(hq.get("modal_layer").get("visible")):
			hq.call("close_console")

	var contact: Dictionary = state.call("contact_family")
	_check(bool(contact.get("ok", false)), "chamada familiar concede relato e adiantamento")
	for item_id in ["thermometer", "recorder", "camera"]:
		var purchase: Dictionary = state.call("buy_equipment", item_id)
		var equip: Dictionary = state.call("equip_equipment", item_id)
		_check(bool(purchase.get("ok", false)) and bool(equip.get("ok", false)), "compra/equipe de %s" % item_id)
	_check(bool(state.call("can_launch_case")), "carga completa habilita o briefing")
	_check(bool(state.call("launch_case")), "briefing inicia uma sessão de campo")
	hq.free()
	await process_frame

	var investigation := (load("res://game/investigation.tscn") as PackedScene).instantiate()
	root.add_child(investigation)
	await process_frame
	await physics_frame
	await physics_frame
	var manager := investigation.get_node_or_null("Manager")
	var field_player := investigation.get_node_or_null("Casa/Player") as CharacterBody3D
	_check(manager != null and field_player != null, "cena de investigação carrega casa e jogador")
	if manager == null or field_player == null:
		investigation.free()
		_finish()
		return
	field_player.set_physics_process(false)
	var evidence_points: Array = manager.get("points")
	_check(evidence_points.size() >= 4, "caso cria ao menos quatro pontos de evidência")
	var category_to_tool := {"field":"meter", "cold":"thermometer", "voice":"recorder", "visual":"camera"}
	for index in range(mini(4, evidence_points.size())):
		var point := evidence_points[index] as Node3D
		var data: Dictionary = point.call("data")
		state.set("active_equipment", category_to_tool[str(data["category"])])
		var point_position := point.global_position
		field_player.global_position = Vector3(point_position.x, point_position.y - 0.8, point_position.z + 1.2)
		var head := field_player.get("head") as Node3D
		head.look_at(point_position, Vector3.UP)
		await physics_frame
		await physics_frame
		var target := field_player.call("_porta_mirada") as Node
		_check(target == point, "raycast localiza a pista %s" % str(data["name"]))
		if index == 0:
			_press_key(field_player, KEY_E)
		elif index == 1:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			field_player.call("_unhandled_input", click)
		await process_frame
		if index < 2:
			_check((state.get("evidence_found") as Dictionary).has(str(data["id"])), "%s registra evidência via %s" % [str(data["name"]), "E" if index == 0 else "clique esquerdo"])

	var active_before: String = str(state.get("active_equipment"))
	_press_key(field_player, KEY_Q)
	_check(str(state.get("active_equipment")) != active_before, "Q alterna o instrumento ativo")
	var flashlight_before := bool(field_player.get("flashlight_active"))
	_press_key(field_player, KEY_F)
	_check(bool(field_player.get("flashlight_active")) != flashlight_before, "F alterna a lanterna")

	var hide_spots: Array = manager.get("hide_spots")
	if not hide_spots.is_empty():
		manager.call("enter_hide_spot", hide_spots[0], field_player)
		_check(bool(manager.get("is_hiding")) and bool(manager.get("player_movement_locked")), "abrigo bloqueia movimento enquanto o jogador se esconde")
		var leave := InputEventKey.new()
		leave.keycode = KEY_H
		leave.physical_keycode = KEY_H
		leave.pressed = true
		manager.call("_unhandled_input", leave)
		_check(not bool(manager.get("is_hiding")), "H permite sair do abrigo")
		manager.call("_start_entity_event")
		var entity_node := manager.get("entity") as Node3D
		var first_speed := float(entity_node.get("speed"))
		_check(bool(manager.get("manifestation_active")) and int(manager.get("manifestations_used")) == 1 and first_speed >= 0.9, "primeira manifestação ativa e velocidade variável")
		manager.call("entity_escaped", entity_node)
		var next_delay := float(manager.get("threat_timer"))
		_check(not bool(manager.get("manifestation_active")) and next_delay >= 24.0 and next_delay <= 42.0, "fuga agenda outra manifestação com intervalo variável")
		manager.call("_start_entity_event")
		var entity_position := entity_node.global_position
		manager.call("enter_hide_spot", hide_spots[0], field_player)
		await physics_frame
		await physics_frame
		_check(entity_node.global_position.distance_to(entity_position) < 0.01, "entidade interrompe a perseguição enquanto o jogador está escondido")
		manager.call("_leave_hide", "Teste de abrigo concluído.")
		manager.call("entity_reached_player", entity_node)
		_check(int(state.get("catches")) == 1 and not bool(manager.get("manifestation_active")), "ser alcançado registra incidente e termina aquela manifestação")
		manager.call("_start_entity_event")
		_check(int(manager.get("manifestations_used")) == 3, "terceira manifestação pode retornar após a captura")

		investigation.free()
	await process_frame
	var report: Dictionary = state.call("finish_case")
	_check(int(report.get("evidence_count", 0)) == 2 and not bool(report.get("resolved", true)), "saída parcial preserva as descobertas e fecha o caso corretamente")
	var results := (load("res://game/results.tscn") as PackedScene).instantiate()
	root.add_child(results)
	await process_frame
	_check(results.find_children("*", "Button", true, false).size() >= 2, "tela final oferece próximo caso e menu")
	results.free()
	await process_frame
	var catalog: Array = state.call("_case_catalog")
	var tool_for_category := {"field":"meter", "cold":"thermometer", "voice":"recorder", "visual":"camera"}
	_check(catalog.size() == 3, "campanha oferece três ocorrências distintas")
	for case_index in range(catalog.size()):
		var case_data: Dictionary = catalog[case_index].duplicate(true)
		state.set("current_case", case_data)
		(state.get("evidence_found") as Dictionary).clear()
		var categories := {}
		for clue_value in case_data.get("clues", []):
			var clue: Dictionary = clue_value
			if not bool(clue.get("required", true)):
				continue
			var category := str(clue.get("category", ""))
			categories[category] = true
			state.set("active_equipment", tool_for_category.get(category, "meter"))
			var scan: Dictionary = state.call("find_evidence", clue)
			_check(bool(scan.get("ok", false)), "%s aceita a ferramenta %s" % [str(case_data.get("title", "Caso")), category])
		_check(categories.size() == 4, "%s exige as quatro categorias" % str(case_data.get("title", "Caso")))
		var complete_report: Dictionary = state.call("finish_case")
		_check(bool(complete_report.get("resolved", false)) and int(complete_report.get("evidence_count", 0)) == 4, "%s fecha com relatório completo" % str(case_data.get("title", "Caso")))
	_finish()

func _press_key(player: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	player.call("_unhandled_input", event)

func _check(condition: bool, description: String) -> void:
	if condition:
		print("GAMEPLAY_TEST_PASS ", description)
	else:
		failures.append(description)
		printerr("GAMEPLAY_TEST_FAIL ", description)

func _finish() -> void:
	if profile_existed:
		var file := FileAccess.open(PROFILE, FileAccess.WRITE)
		if file != null:
			file.store_string(profile_backup)
			file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	var output := {"test":"gameplay_flow","passed":failures.is_empty(),"checks_failed":failures}
	var file_out := FileAccess.open("res://qa/gameplay/gameplay_flow_results.json", FileAccess.WRITE)
	if file_out != null:
		file_out.store_string(JSON.stringify(output, "  ") + "\n")
		file_out.close()
	if failures.is_empty():
		print("GAMEPLAY_FLOW_PASS")
	else:
		printerr("GAMEPLAY_FLOW_FAIL ", failures)
	quit(0 if failures.is_empty() else 1)
