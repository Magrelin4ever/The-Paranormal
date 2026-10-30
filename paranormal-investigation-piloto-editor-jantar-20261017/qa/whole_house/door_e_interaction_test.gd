extends SceneTree

var failures: Array[String] = []
var opened_count := 0
var closed_count := 0
var door_total := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://prototype/house_environment.tscn") as PackedScene
	if packed == null:
		_fail("house_environment.tscn não carregou")
		_finish()
		return
	var house := packed.instantiate() as Node3D
	root.add_child(house)
	await process_frame
	await physics_frame
	await physics_frame
	var player := house.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		_fail("CharacterBody3D do jogador ausente")
		_finish()
		return
	player.set_physics_process(false)
	var head := player.get("head") as Node3D
	var doors := get_nodes_in_group("porta_interativa")
	door_total = doors.size()
	print("DOOR_E_TEST_START doors=", doors.size())
	for door_value in doors:
		var door := door_value as Node3D
		if door == null or not is_instance_valid(door):
			_fail("porta inválida no grupo")
			continue
		var target := door.get_node_or_null("AlvoInteracao") as Area3D
		if target == null:
			target = door.find_child("AlvoInteracao", true, false) as Area3D
		if target == null:
			_fail("%s sem AlvoInteracao" % door.get_path())
			continue
		var normal := door.global_transform.basis.z
		normal.y = 0.0
		if normal.length() < 0.1:
			normal = Vector3.FORWARD
		normal = normal.normalized()
		var acquired := false
		for side in [-1.0, 1.0]:
			player.global_position = Vector3(target.global_position.x + normal.x * side * 1.25, door.global_position.y + 0.08, target.global_position.z + normal.z * side * 1.25)
			head.look_at(target.global_position, Vector3.UP)
			await physics_frame
			await physics_frame
			var looked := player.call("_porta_mirada") as Node
			if looked == door:
				acquired = true
				break
		if not acquired:
			_fail("E não encontra %s pelo raycast nos dois lados" % door.get_path())
			continue
		if bool(door.call("esta_aberta")):
			_fail("%s inicia aberta" % door.get_path())
			continue
		_press_e(player)
		await create_timer(0.30).timeout
		if bool(door.call("esta_aberta")):
			opened_count += 1
		else:
			_fail("E não abriu %s" % door.get_path())
		_press_e(player)
		await create_timer(0.30).timeout
		if not bool(door.call("esta_aberta")):
			closed_count += 1
		else:
			_fail("E não fechou %s" % door.get_path())
	print("DOOR_E_TEST_RESULT doors=%d opened=%d closed=%d" % [doors.size(), opened_count, closed_count])
	house.free()
	_finish()

func _press_e(player: Node) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.physical_keycode = KEY_E
	event.pressed = true
	player.call("_unhandled_input", event)

func _fail(message: String) -> void:
	failures.append(message)
	printerr("DOOR_E_TEST_FAIL ", message)

func _finish() -> void:
	var output := {"test":"door_e_interaction","doors":door_total,"opened_via_e":opened_count,"closed_via_e":closed_count,"failures":failures,"passed":failures.is_empty()}
	var file := FileAccess.open("res://qa/whole_house/door_e_interaction_results.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(output, "  ") + "\n")
		file.close()
	if failures.is_empty():
		print("DOOR_E_TEST_PASS")
	else:
		printerr("DOOR_E_TEST_FAIL count=", failures.size())
	quit(0 if failures.is_empty() else 1)
