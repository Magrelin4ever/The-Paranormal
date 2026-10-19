extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var scene := (load("res://prototype/house_environment.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	var chair := scene.get_node("SalaJantar_Editavel/Cadeira_02") as Node3D
	var col := chair.get_node("Colisao_Acompanha_Movel") as StaticBody3D
	var good := chair.global_position.distance_to(Vector3(-4.807675, 0.0, 1.18)) < 0.0001 and absf(chair.rotation_degrees.y) > 1.0
	good = good and col.global_transform.is_equal_approx(chair.global_transform)
	print("MOUSE_SAVED_RUNTIME position=", chair.global_position, " rotation_y=", chair.rotation_degrees.y, " collider_follows=", col.global_transform.is_equal_approx(chair.global_transform))
	print("MOUSE_SAVED_RUNTIME_RESULT ", "PASS" if good else "FAIL")
	scene.queue_free()
	await process_frame
	quit(0 if good else 1)
