extends SceneTree

const SCENE := preload("res://prototype/house_environment.tscn")
const BODY_Y := 0.05
const SAMPLE_SPACING := 0.18

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var house := SCENE.instantiate() as Node3D
	if house == null:
		printerr("C13_ACCESS_PHYSICS_FAIL: cena indisponível")
		quit(1)
		return
	root.add_child(house)
	await process_frame
	await physics_frame
	await physics_frame
	var player := house.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		printerr("C13_ACCESS_PHYSICS_FAIL: jogador não encontrado")
		quit(1)
		return
	var shape_candidates := player.find_children("*", "CollisionShape3D", true, false)
	if shape_candidates.is_empty():
		printerr("C13_ACCESS_PHYSICS_FAIL: cápsula do jogador não encontrada")
		quit(1)
		return
	var shape_node := shape_candidates[0] as CollisionShape3D
	if shape_node == null or shape_node.shape == null:
		printerr("C13_ACCESS_PHYSICS_FAIL: cápsula do jogador não encontrada")
		quit(1)
		return
	var open_doors := 0
	var closed_doors := 0
	var door_nodes := get_nodes_in_group("porta_interativa")
	for door in door_nodes:
		if bool(door.call("esta_aberta")):
			open_doors += 1
		else:
			closed_doors += 1
	var space := player.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape_node.shape
	query.collision_mask = player.collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]
	var segments: Array[Dictionary] = [
		{"name": "faixa_acesso_lado_leste", "a": Vector2(-3.8, 1.85), "b": Vector2(-6.85, 1.85)},
		{"name": "contorno_leste", "a": Vector2(-3.8, 1.85), "b": Vector2(-3.8, -1.95)},
		{"name": "faixa_acesso_lado_cozinha", "a": Vector2(-3.8, -1.95), "b": Vector2(-6.85, -1.95)}
	]
	var checks := 0
	var collisions: Array[String] = []
	var clearance_points: Array[Dictionary] = [
		{"name": "acesso_cadeira_norte_esquerda", "p": Vector2(-6.85, 1.85)},
		{"name": "acesso_cadeira_norte_direita", "p": Vector2(-5.30, 1.85)},
		{"name": "acesso_cadeira_sul_esquerda", "p": Vector2(-6.85, -1.95)},
		{"name": "acesso_cadeira_sul_direita", "p": Vector2(-5.30, -1.95)},
		{"name": "corredor_leste_norte", "p": Vector2(-3.80, 1.85)},
		{"name": "corredor_leste_sul", "p": Vector2(-3.80, -1.95)}
	]
	for point in clearance_points:
		var access_position: Vector2 = point["p"]
		var result := _test_clear(space, query, shape_node, access_position, player)
		checks += 1
		if not result["clear"]:
			collisions.append("%s:%s" % [String(point["name"]), String(result["hits"])])
	for segment in segments:
		var start: Vector2 = segment["a"]
		var finish: Vector2 = segment["b"]
		var distance := start.distance_to(finish)
		var steps := maxi(1, int(ceil(distance / SAMPLE_SPACING)))
		for index in range(steps + 1):
			var t := float(index) / float(steps)
			var sample := start.lerp(finish, t)
			var result := _test_clear(space, query, shape_node, sample, player)
			checks += 1
			if not result["clear"]:
				var label := "%s@%.2f,%.2f" % [String(segment["name"]), sample.x, sample.y]
				collisions.append("%s:%s" % [label, String(result["hits"])])
	var all_doors_closed := door_nodes.size() > 0 and open_doors == 0 and closed_doors == door_nodes.size()
	print("C13_ACCESS_PHYSICS_RESULT method=player_capsule_intersect_shape samples=%d spacing_max=%.2f doors=%d closed=%d open=%d doors_toggled=false collision_points=%d" % [checks, SAMPLE_SPACING, door_nodes.size(), closed_doors, open_doors, collisions.size()])
	print("C13_ACCESS_PHYSICS_SCOPE actual_player_capsule=true physics_space_query=true sampled_path_not_continuous_motion=true doors_left_in_spawn_state=true")
	if collisions.is_empty() and all_doors_closed:
		print("C13_ACCESS_PHYSICS_PASS areas=seat_approach_and_east_perimeter")
		quit(0)
	else:
		printerr("C13_ACCESS_PHYSICS_FAIL doors_closed=%s collisions=%s" % [str(all_doors_closed), str(collisions)])
		quit(1)

func _test_clear(space: PhysicsDirectSpaceState3D, query: PhysicsShapeQueryParameters3D, shape_node: CollisionShape3D, point: Vector2, player: CharacterBody3D) -> Dictionary:
	var body_origin := Vector3(point.x, BODY_Y, point.y)
	query.transform = Transform3D(Basis.IDENTITY, body_origin) * shape_node.transform
	var hits := space.intersect_shape(query, 8)
	var names: Array[String] = []
	for hit in hits:
		var collider := hit.get("collider") as Node
		names.append(collider.name if collider != null else "collider_sem_no")
	return {"clear": hits.is_empty(), "hits": names}
