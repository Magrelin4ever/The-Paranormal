extends SceneTree

## Percorre fisicamente as 61 saídas usando o player e as células livres da auditoria.
## O player é colocado uma vez no primeiro marcador de cada cômodo; entre as
## saídas daquele cômodo o deslocamento é contínuo, com gravidade e colisões reais.
const HOUSE_SCENE := "res://prototype/house_environment.tscn"
const MARKERS_SCENE := "res://prototype/whole_house/marcadores_rotas.tscn"
const ROUTE_RESULTS := "res://qa/whole_house/physics_rooms_results.json"
const OUTPUT := "res://qa/whole_house/exit_marker_walk_results.json"
const SPACING := 0.18
const DT := 1.0 / 60.0
const ARRIVAL_TOLERANCE := 0.06
const EXIT_REACHED_TOLERANCE := 0.20

var house: Node3D
var player: CharacterBody3D
var marker_results: Array[Dictionary] = []
var failures: Array[String] = []
var walked_markers := 0
var repositionings := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var route_data := JSON.parse_string(FileAccess.get_file_as_string(ROUTE_RESULTS)) as Dictionary
	if route_data == null or not bool(route_data.get("passed", false)):
		_failures_add("A auditoria física precisa passar antes do percurso real.")
		_finish()
		return
	var packed := load(HOUSE_SCENE) as PackedScene
	var markers_packed := load(MARKERS_SCENE) as PackedScene
	if packed == null or markers_packed == null:
		_failures_add("Cena da casa ou dos marcadores não carregou.")
		_finish()
		return
	house = packed.instantiate() as Node3D
	root.add_child(house)
	house.add_child(markers_packed.instantiate())
	await process_frame
	await physics_frame
	await physics_frame
	player = _find_player(house)
	if player == null:
		_failures_add("CharacterBody3D do jogador não foi encontrado.")
		_finish()
		return
	_open_all_doors()
	await physics_frame
	player.set_process(false)
	player.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var total_exits := 0
	for room in route_data.get("rooms", []):
		total_exits += (room.get("exit_world_xz", []) as Array).size()
	if total_exits != 61:
		_failures_add("Esperava 61 marcadores; a auditoria contém %d." % total_exits)
	for room in route_data.get("rooms", []):
		await _walk_room(room)
	_finish()

func _walk_room(room: Dictionary) -> void:
	var room_id := str(room.get("room", "sem_id"))
	var exits: Array = room.get("exit_world_xz", [])
	var grid: Array = room.get("grid_mask", [])
	var origin: Array = room.get("grid_origin", [])
	var floor_y := float(room.get("floor_y", 0.0))
	room_origin_x = float(origin[0]) if origin.size() >= 2 else 0.0
	room_origin_z = float(origin[1]) if origin.size() >= 2 else 0.0
	if exits.is_empty() or grid.is_empty() or origin.size() < 2:
		failures.append("%s: dados de saída/grade ausentes." % room_id)
		return
	var exit_cells: Array[Vector2i] = []
	for exit_position in exits:
		var cell := _nearest_reachable_cell(exit_position, grid)
		exit_cells.append(cell)
		if cell.x < 0:
			failures.append("%s: marcador sem célula acessível %s." % [room_id, str(exit_position)])
			return
	var current_cell: Vector2i = exit_cells[0]
	player.global_position = Vector3(float(origin[0]) + current_cell.x * SPACING, floor_y, float(origin[1]) + current_cell.y * SPACING)
	player.velocity = Vector3.ZERO
	repositionings += 1
	for settle in range(6):
		await physics_frame
		player.call("_physics_process", DT)
	var first_colliders: Dictionary = {}
	var first_target := Vector3(float(exits[0][0]), floor_y, float(exits[0][1]))
	var first_moved := await _walk_to(first_target, floor_y, first_colliders)
	var first_exit_distance := _distance_to_exit(player.global_position, exits[0], floor_y)
	var first_ok := first_moved and first_exit_distance <= EXIT_REACHED_TOLERANCE
	marker_results.append({"room_id": room_id, "exit_index": 0, "exit_world": [exits[0][0], floor_y, exits[0][1]], "player_world": [player.global_position.x, player.global_position.y, player.global_position.z], "distance": first_exit_distance, "passed": first_ok, "start_marker": true, "colliders": first_colliders.keys()})
	if first_ok:
		walked_markers += 1
	else:
		failures.append("%s saída 0: distância inicial %.3fm." % [room_id, first_exit_distance])
	var visited: Dictionary = {0: true}
	while visited.size() < exits.size():
		var best_index := -1
		var best_path: Array[Vector2i] = []
		for index in range(exits.size()):
			if visited.has(index):
				continue
			var candidate := _path_between(grid, current_cell, exit_cells[index])
			if not candidate.is_empty() and (best_path.is_empty() or candidate.size() < best_path.size()):
				best_index = index
				best_path = candidate
		if best_index < 0:
			failures.append("%s: remaining exits have no path in the clearance grid." % room_id)
			break
		var colliders: Dictionary = {}
		var moved := true
		for step_index in range(1, best_path.size()):
			var cell := best_path[step_index]
			var target := Vector3(float(origin[0]) + cell.x * SPACING, floor_y, float(origin[1]) + cell.y * SPACING)
			if not await _walk_to(target, floor_y, colliders):
				moved = false
				break
		var exit_position: Array = exits[best_index]
		if moved:
			var marker_target := Vector3(float(exit_position[0]), floor_y, float(exit_position[1]))
			moved = await _walk_to(marker_target, floor_y, colliders)
		var exit_distance := _distance_to_exit(player.global_position, exit_position, floor_y)
		var passed := moved and exit_distance <= EXIT_REACHED_TOLERANCE
		marker_results.append({"room_id": room_id, "exit_index": best_index, "exit_world": [exit_position[0], floor_y, exit_position[1]], "player_world": [player.global_position.x, player.global_position.y, player.global_position.z], "distance": exit_distance, "passed": passed, "start_marker": false, "path_cells": best_path.size(), "colliders": colliders.keys()})
		if passed:
			walked_markers += 1
			current_cell = exit_cells[best_index]
			visited[best_index] = true
		else:
			failures.append("%s saída %d: jogador não alcançou o marcador (distância %.3fm)." % [room_id, best_index, exit_distance])
			break
	print("EXIT_WALK_ROOM %s markers=%d passed=%s" % [room_id, exits.size(), visited.size() == exits.size()])

func _walk_to(target: Vector3, floor_y: float, colliders: Dictionary) -> bool:
	for frame in range(90):
		var current := player.global_position
		if Vector2(current.x - target.x, current.z - target.z).length() <= ARRIVAL_TOLERANCE and absf(current.y - floor_y) < 0.30:
			return true
		player.look_at(Vector3(target.x, current.y, target.z), Vector3.UP)
		Input.action_press("move_forward")
		await physics_frame
		player.call("_physics_process", DT)
		Input.action_release("move_forward")
		if player.global_position.y < floor_y - 0.65:
			return false
		for index in range(player.get_slide_collision_count()):
			var collider := player.get_slide_collision(index).get_collider() as Node
			if collider != null:
				colliders[str(collider.get_path())] = true
	var last := player.global_position
	return Vector2(last.x - target.x, last.z - target.z).length() <= ARRIVAL_TOLERANCE and absf(last.y - floor_y) < 0.30

func _nearest_reachable_cell(exit_position: Array, grid: Array) -> Vector2i:
	var target := Vector2(float(exit_position[0]), float(exit_position[1]))
	var best := Vector2i(-1, -1)
	var best_distance := 0.26
	for z in range(grid.size()):
		var row: Array = grid[z]
		for x in range(row.size()):
			if int(row[x]) != 2:
				continue
			var cell_position := Vector2(float(room_origin_x) + x * SPACING, float(room_origin_z) + z * SPACING)
			var distance := cell_position.distance_to(target)
			if distance < best_distance:
				best_distance = distance
				best = Vector2i(x, z)
	return best

var room_origin_x := 0.0
var room_origin_z := 0.0

func _path_between(grid: Array, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if start == goal:
		return [start]
	var queue: Array[Vector2i] = [start]
	var parents: Dictionary = {start: Vector2i(-1, -1)}
	var found := false
	while not queue.is_empty() and not found:
		var current: Vector2i = queue.pop_front()
		for delta_value in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var delta: Vector2i = delta_value
			var next: Vector2i = current + delta
			if next.x < 0 or next.y < 0 or next.y >= grid.size() or next.x >= (grid[next.y] as Array).size():
				continue
			if int(grid[next.y][next.x]) != 2 or parents.has(next):
				continue
			parents[next] = current
			if next == goal:
				found = true
				break
			queue.append(next)
	if not parents.has(goal):
		return []
	var path: Array[Vector2i] = []
	var cursor := goal
	while cursor != start:
		path.push_front(cursor)
		cursor = parents[cursor]
	path.push_front(start)
	return path

func _distance_to_exit(position: Vector3, exit_position: Array, floor_y: float) -> float:
	return Vector3(position.x, floor_y, position.z).distance_to(Vector3(float(exit_position[0]), floor_y, float(exit_position[1])))

func _find_player(root_node: Node) -> CharacterBody3D:
	for node in root_node.find_children("*", "CharacterBody3D", true, false):
		return node as CharacterBody3D
	return null

func _open_all_doors() -> void:
	for node in get_nodes_in_group("porta_interativa"):
		if not is_instance_valid(node) or not house.is_ancestor_of(node):
			continue
		node.rotation.y += deg_to_rad(float(node.get("angulo_abertura_graus")))

func _failures_add(message: String) -> void:
	failures.append(message)
	printerr("EXIT_WALK_FAIL ", message)

func _finish() -> void:
	var total := 0
	for result in marker_results:
		if not bool(result.get("start_marker", false)):
			total += 1
	var output := {"test": "real_player_exit_marker_walk", "engine": Engine.get_version_info().string, "movement": "CharacterBody3D; move_and_slide; W; cápsula/gravidade originais; caminho BFS pela grade física", "mode": "contínuo entre marcadores dentro de cada cômodo; uma posição inicial por cômodo", "markers_total": 61, "markers_walked": walked_markers, "room_initial_repositions": repositionings, "marker_results": marker_results, "failures": failures, "passed": failures.is_empty() and walked_markers == 61}
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(output, "\t") + "\n")
		file.close()
	if is_instance_valid(house):
		house.free()
	print("EXIT_MARKER_WALK_%s markers=%d/%d room_repositions=%d" % ["PASS" if output["passed"] else "FAIL", walked_markers, 61, repositionings])
	quit(0 if output["passed"] else 1)
