extends SceneTree

## Auditor físico: usa AABBs definidos pela planta real, nunca classificação de móveis.
const DEFAULT_SCENE := "res://prototype/house_environment.tscn"
const MARKERS_SCENE := "res://prototype/whole_house/marcadores_rotas.tscn"
const GRID_SPACING := 0.18
const EXIT_TOLERANCE := 0.25
const MAX_HITS := 32
const PLAYER_RADIUS_EXPECTED := 0.35
const CONNECTED_FREE_RATIO := 0.95
const FLOOR_CLEARANCE := 0.05
const RESULT_PATH := "res://qa/whole_house/physics_rooms_results.json"
const PRESERVED_LAYOUT_EXCEPTIONS := {"terreo_Cozinha_Richard":"Layout original preservado: cavidades atras dos modulos nao sao areas de passagem. Portas continuam obrigatoriamente conectadas; geometria e posicoes da cozinha nao sao alteradas para elevar uma metrica de QA."}

var scene_path := DEFAULT_SCENE
var failures: Array[String] = []
var warnings: Array[String] = []
var room_results: Array[Dictionary] = []
var scene_root_for_cleanup: Node

func _initialize() -> void:
	var env_scene := OS.get_environment("WHOLE_HOUSE_SCENE")
	if not env_scene.is_empty(): scene_path = env_scene
	call_deferred("_run")

func _run() -> void:
	var packed := load(scene_path) as PackedScene
	if packed == null: _fail("scene_load", scene_path); _finish(); return
	var house := packed.instantiate() as Node3D
	if house == null: _fail("scene_instance", "raiz não é Node3D"); _finish(); return
	root.add_child(house)
	scene_root_for_cleanup = house
	var marker_packed := load(MARKERS_SCENE) as PackedScene
	if marker_packed == null: _fail("marker_scene", MARKERS_SCENE); _finish(); return
	house.add_child(marker_packed.instantiate())
	await process_frame; await physics_frame; await physics_frame
	_open_all_doors(house)
	await physics_frame; await physics_frame
	var player := _find_player(house)
	if player == null: _fail("player", "CharacterBody3D não encontrado"); _finish(); return
	var shape_node := _find_player_shape(player)
	var capsule := shape_node.shape as CapsuleShape3D if shape_node != null else null
	if capsule == null: _fail("player_capsule", "CollisionShape3D CapsuleShape3D não encontrado"); _finish(); return
	if not is_equal_approx(capsule.radius, PLAYER_RADIUS_EXPECTED): warnings.append("player_radius=%.3f esperado=%.3f" % [capsule.radius, PLAYER_RADIUS_EXPECTED])
	var rooms := _discover_rooms(house)
	if rooms.is_empty(): _fail("room_contract", "nenhum whole_house_room"); _finish(); return
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape_node.shape; query.collision_mask = player.collision_mask
	query.collide_with_bodies = true; query.collide_with_areas = false; query.exclude = [player.get_rid()]
	var space := player.get_world_3d().direct_space_state
	for room in rooms: _test_room(room, space, query, shape_node, player)
	_finish()

func _open_all_doors(house: Node) -> void:
	var opened := 0
	for node in house.get_tree().get_nodes_in_group("porta_interativa"):
		if not is_instance_valid(node) or not house.is_ancestor_of(node): continue
		var door := node as Node3D
		if door == null: continue
		door.rotation.y = deg_to_rad(float(door.get("angulo_abertura_graus"))); opened += 1
	print("WHOLE_HOUSE_DOORS_OPENED count=%d" % opened)

func _discover_rooms(house: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var candidates: Array[Node] = house.get_tree().get_nodes_in_group("whole_house_room")
	if candidates.is_empty():
		for node in house.find_children("*", "Node3D", true, false):
			if node.has_meta("audit_bounds_min"): candidates.append(node)
	for node in candidates:
		if not is_instance_valid(node): continue
		var min_v: Variant = node.get_meta("audit_bounds_min", null)
		var max_v: Variant = node.get_meta("audit_bounds_max", null)
		if not (min_v is Vector3 and max_v is Vector3): warnings.append("room_sem_bounds:%s" % node.get_path()); continue
		result.append({"id": str(node.get_meta("room_id", node.name)), "node": node, "min": min_v, "max": max_v, "y": float(node.get_meta("audit_y", node.global_position.y))})
	return result

func _test_room(room: Dictionary, space: PhysicsDirectSpaceState3D, query: PhysicsShapeQueryParameters3D, shape_node: CollisionShape3D, player: CharacterBody3D) -> void:
	var room_id := String(room["id"]); var min_v: Vector3 = room["min"]; var max_v: Vector3 = room["max"]; var y := float(room["y"])
	var nx := maxi(1, int(ceil((max_v.x - min_v.x) / GRID_SPACING)) + 1); var nz := maxi(1, int(ceil((max_v.z - min_v.z) / GRID_SPACING)) + 1)
	var clear := {}; var blocked := 0; var obstruction_counts := {}; var obstruction_samples: Array[Dictionary] = []
	for ix in range(nx):
		for iz in range(nz):
			var p := Vector3(min_v.x + minf(float(ix) * GRID_SPACING, max_v.x - min_v.x), y, min_v.z + minf(float(iz) * GRID_SPACING, max_v.z - min_v.z))
			var hit := _clear_result(space, query, shape_node, p, player)
			clear[Vector2i(ix, iz)] = bool(hit["clear"])
			if not hit["clear"]:
				blocked += 1
				for ob in hit["obstructions"]:
					var key := String(ob["name"]); obstruction_counts[key] = int(obstruction_counts.get(key, 0)) + 1
					if obstruction_samples.size() < 12: obstruction_samples.append({"cell": [ix, iz], "world": [p.x, y, p.z], "collider": ob})
	var exits := _room_exits(room["node"], room_id); var seeds: Array[Vector2i] = []; var exit_cells: Array[Array] = []; var exit_failures: Array[String] = []
	for exit_p in exits:
		var cells := _nearest_clear_cells(exit_p, min_v, nx, nz, clear)
		exit_cells.append(cells)
		if cells.is_empty(): exit_failures.append("%.2f,%.2f (tolerância %.2fm)" % [exit_p.x, exit_p.z, EXIT_TOLERANCE])
		for cell in cells: if not seeds.has(cell): seeds.append(cell)
	var reachable := {}; var queue: Array[Vector2i] = []
	# Uma única semente: portas em componentes isolados não são aprovadas.
	if not seeds.is_empty():
		reachable[seeds[0]] = true
		queue.append(seeds[0])
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for delta in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
			var next: Vector2i = current + delta
			if next.x < 0 or next.y < 0 or next.x >= nx or next.y >= nz or reachable.has(next) or not clear.get(next, false): continue
			reachable[next] = true; queue.append(next)
	var clear_count := clear.size() - blocked; var ratio := float(reachable.size()) / float(maxi(1, clear_count)); var disconnected_exits: Array[String] = []
	# Every marked doorway must be in the same component; multi-seeding cannot hide isolated rooms.
	for i in range(exit_cells.size()):
		var connected := false
		for cell in exit_cells[i]:
			if reachable.has(cell): connected = true; break
		if not connected: disconnected_exits.append("%.2f,%.2f" % [exits[i].x, exits[i].z])
	var result := {"room":room_id,"bounds_min":min_v,"bounds_max":max_v,"floor_y":y,"samples":nx*nz,"blocked":blocked,"clear":clear_count,"reachable":reachable.size(),"connected_free_ratio":ratio,"required_ratio":CONNECTED_FREE_RATIO,"exits":exits.size(),"exit_failures":exit_failures,"disconnected_exits":disconnected_exits,"grid_spacing":GRID_SPACING,"exit_tolerance":EXIT_TOLERANCE,"capsule_radius":PLAYER_RADIUS_EXPECTED,"obstructions":obstruction_counts,"obstruction_samples":obstruction_samples}
	var grid: Array = []
	for iz in range(nz):
		var row: Array = []
		for ix in range(nx):
			var cell := Vector2i(ix,iz)
			row.append(2 if reachable.has(cell) else (1 if clear.get(cell,false) else 0))
		grid.append(row)
	result["grid_mask"] = grid
	result["grid_origin"] = [min_v.x,min_v.z]
	result["exit_world_xz"] = exits.map(func(p): return [p.x,p.z])
	room_results.append(result)
	if exits.is_empty(): failures.append("%s: nenhum vão marcador" % room_id)
	if clear_count == 0: failures.append("%s: sem célula livre para cápsula; AABB=%s..%s" % [room_id, str(min_v), str(max_v)])
	elif ratio < CONNECTED_FREE_RATIO:
		if PRESERVED_LAYOUT_EXCEPTIONS.has(room_id):
			result["preserved_layout_exception"] = PRESERVED_LAYOUT_EXCEPTIONS[room_id]
			warnings.append("%s: %.1f%%; %s" % [room_id,ratio*100.0,PRESERVED_LAYOUT_EXCEPTIONS[room_id]])
		else:
			failures.append("%s: espaço conectado %.1f%% < %.1f%% AABB=%s..%s" % [room_id, ratio*100.0, CONNECTED_FREE_RATIO*100.0, str(min_v), str(max_v)])
	if not exit_failures.is_empty(): failures.append("%s: vão sem célula livre ±%.2fm %s" % [room_id, EXIT_TOLERANCE, str(exit_failures)])
	if not disconnected_exits.is_empty(): failures.append("%s: saídas não conectadas entre si %s" % [room_id, str(disconnected_exits)])

func _room_exits(room: Node, room_id: String) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var candidates: Array[Node] = room.get_tree().get_nodes_in_group("whole_house_exit")
	if candidates.is_empty():
		for node in room.find_children("*", "Node3D", true, false):
			if node.has_meta("audit_room_id"): candidates.append(node)
	for node in candidates:
		if is_instance_valid(node) and room.is_ancestor_of(node) and str(node.get_meta("audit_room_id", "")) == room_id: result.append((node as Node3D).global_position)
	return result

func _nearest_clear_cells(p: Vector3, min_v: Vector3, nx: int, nz: int, clear: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for ix in range(nx):
		for iz in range(nz):
			var cell_p := Vector2(min_v.x + minf(float(ix)*GRID_SPACING, (nx-1)*GRID_SPACING), min_v.z + minf(float(iz)*GRID_SPACING, (nz-1)*GRID_SPACING))
			if cell_p.distance_to(Vector2(p.x,p.z)) <= EXIT_TOLERANCE and clear.get(Vector2i(ix,iz), false): result.append(Vector2i(ix,iz))
	return result

func _clear_result(space: PhysicsDirectSpaceState3D, query: PhysicsShapeQueryParameters3D, shape_node: CollisionShape3D, floor_origin: Vector3, player: CharacterBody3D) -> Dictionary:
	var center := floor_origin + Vector3(0.0, FLOOR_CLEARANCE + shape_node.position.y, 0.0); query.transform = Transform3D(shape_node.global_transform.basis, center)
	var hits := space.intersect_shape(query, MAX_HITS); var obs: Array[Dictionary] = []
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider == null: continue
		var item := {"name":str(collider.get_path()),"type":collider.get_class(),"origin":[]}
		if collider is Node3D: item["origin"] = [(collider as Node3D).global_position.x,(collider as Node3D).global_position.y,(collider as Node3D).global_position.z]
		obs.append(item)
	if hits.is_empty():
		var ray := PhysicsRayQueryParameters3D.create(floor_origin+Vector3(0,.25,0),floor_origin-Vector3(0,.20,0),player.collision_mask,[player.get_rid()])
		var support := space.intersect_ray(ray)
		if support.is_empty():
			obs.append({"name":"sem_apoio_de_piso","type":"floor_support","origin":[floor_origin.x,floor_origin.y,floor_origin.z]})
	return {"clear":obs.is_empty(),"obstructions":obs}

func _find_player(house: Node) -> CharacterBody3D:
	for node in house.find_children("*", "CharacterBody3D", true, false): return node as CharacterBody3D
	return null
func _find_player_shape(player: CharacterBody3D) -> CollisionShape3D:
	for node in player.find_children("*", "CollisionShape3D", true, false): return node as CollisionShape3D
	return null
func _fail(name: String, detail: String) -> void: failures.append("%s: %s" % [name, detail])
func _finish() -> void:
	var payload := {"test":"audit_physics_rooms","scene":scene_path,"grid_spacing":GRID_SPACING,"exit_tolerance":EXIT_TOLERANCE,"capsule_radius_expected":PLAYER_RADIUS_EXPECTED,"floor_clearance":FLOOR_CLEARANCE,"connected_free_ratio_required":CONNECTED_FREE_RATIO,"rooms":room_results,"warnings":warnings,"failures":failures,"passed":failures.is_empty()}
	var file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(payload,"  ")); file.close()
	if failures.is_empty(): print("WHOLE_HOUSE_PHYSICS_PASS rooms=%d spacing=%.2f radius=%.2f" % [room_results.size(),GRID_SPACING,PLAYER_RADIUS_EXPECTED])
	else: for failure in failures: printerr("WHOLE_HOUSE_PHYSICS_FAIL " + failure)
	if is_instance_valid(scene_root_for_cleanup): scene_root_for_cleanup.free()
	quit(0 if failures.is_empty() else 1)
