extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var state := root.get_node_or_null("GameState")
	if state == null:
		_fail("autoload GameState ausente")
		_finish()
		return
	var catalog: Array = state.call("_case_catalog")
	var packed := load("res://game/investigation.tscn") as PackedScene
	for case_index in range(catalog.size()):
		state.set("current_case", catalog[case_index].duplicate(true))
		(state.get("evidence_found") as Dictionary).clear()
		state.set("session_active", true)
		var scene := packed.instantiate() as Node3D
		root.add_child(scene)
		await process_frame
		await physics_frame
		await physics_frame
		var manager := scene.get_node_or_null("Manager")
		var player := scene.get_node_or_null("Casa/Player") as CharacterBody3D
		if manager == null or player == null:
			_fail("%s não carregou gerente/jogador" % str(state.get("current_case").get("title", "Caso")))
			scene.free()
			await process_frame
			continue
		player.set_physics_process(false)
		var points: Array = manager.get("points")
		var expected: Array = state.get("current_case").get("clues", [])
		if points.size() != expected.size():
			_fail("%s criou %d pontos para %d definições" % [str(state.get("current_case").get("title", "Caso")), points.size(), expected.size()])
		for point_value in points:
			var point := point_value as Node3D
			var data: Dictionary = point.call("data")
			var position := point.global_position
			player.global_position = Vector3(position.x, position.y - 0.8, position.z + 1.2)
			var head := player.get("head") as Node3D
			head.look_at(position, Vector3.UP)
			await physics_frame
			await physics_frame
			var target := player.call("_porta_mirada") as Node
			if target == point:
				print("EVIDENCE_SIGHT_PASS ", str(state.get("current_case").get("title", "Caso")), " / ", str(data.get("name", "Pista")))
			else:
				_fail("raycast não alcança %s / %s; alvo=%s" % [str(state.get("current_case").get("title", "Caso")), str(data.get("name", "Pista")), str(target.get_path()) if target != null else "vazio"])
		scene.free()
		await process_frame
	_finish()

func _fail(message: String) -> void:
	failures.append(message)
	printerr("EVIDENCE_SIGHT_FAIL ", message)

func _finish() -> void:
	var output := {"test":"evidence_line_of_sight","passed":failures.is_empty(),"failures":failures}
	var file := FileAccess.open("res://qa/gameplay/evidence_line_of_sight_results.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(output, "  ") + "\n")
		file.close()
	if failures.is_empty():
		print("EVIDENCE_LINE_OF_SIGHT_PASS")
	else:
		printerr("EVIDENCE_LINE_OF_SIGHT_FAIL count=", failures.size())
	quit(0 if failures.is_empty() else 1)
