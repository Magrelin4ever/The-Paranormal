extends SceneTree

const SCENE := preload("res://prototype/house_environment.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var house := SCENE.instantiate() as Node3D
	root.add_child(house)
	await process_frame
	await physics_frame
	await physics_frame
	var player := house.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		push_error("C13_KEY_E_FAIL: jogador não encontrado")
		quit(1)
		return
	player.position = Vector3(0.0, 0.08, 9.35)
	player.rotation.y = 0.0
	var head := player.get("head") as Node3D
	if head != null:
		head.rotation = Vector3.ZERO
	await physics_frame
	var door := player.call("_porta_mirada") as Node
	if door == null:
		push_error("C13_KEY_E_FAIL: raycast não encontrou a porta frontal")
		quit(1)
		return
	var key_event := InputEventKey.new()
	key_event.physical_keycode = KEY_E
	key_event.pressed = true
	player.call("_unhandled_input", key_event)
	await create_timer(0.35).timeout
	var opened := bool(door.call("esta_aberta"))
	key_event.pressed = false
	player.call("_unhandled_input", key_event)
	key_event.pressed = true
	player.call("_unhandled_input", key_event)
	await create_timer(0.35).timeout
	var closed := not bool(door.call("esta_aberta"))
	print("C13_KEY_E_RESULT opened=%s closed=%s" % [str(opened), str(closed)])
	if opened and closed:
		print("C13_KEY_E_PASS")
		quit(0)
	else:
		push_error("C13_KEY_E_FAIL: tecla E não abriu/fechou a porta")
		quit(1)
