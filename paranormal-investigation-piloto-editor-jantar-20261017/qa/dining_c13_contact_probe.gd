extends SceneTree

const SCENE := preload("res://prototype/house_environment.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var house := SCENE.instantiate() as Node3D
	if house == null:
		printerr("C13_AABB_SUPPORT_FAIL: casa indisponível")
		quit(1)
		return
	root.add_child(house)
	await process_frame
	await physics_frame
	await physics_frame
	var table_mesh := _find_mesh(house, "dining_table")
	var table_model := _find_asset(house, "dining_table", Vector3(-6.075, 0.0, -0.05))
	var tea_set := _find_asset(house, "tea_set_01", Vector3(-5.99, 0.788, 0.015))
	var cabinet := _find_asset(house, "modern_wooden_cabinet", Vector3(-8.05, 0.0, -2.52))
	var vase := _find_asset(house, "ceramic_vase_02", Vector3(-8.35, 0.7005, -2.52))
	var lamp := _find_asset(house, "vintage_oil_lamp", Vector3(-7.65, 0.7005, -2.52))
	var cup_body := _find_mesh(house, "CopoInfantilJantar_Corpo")
	var napkin_base := _find_mesh(house, "GuardanapoJantar_Tecido")
	var napkin_fold := _find_mesh(house, "GuardanapoJantar_Dobra")
	if table_mesh == null or table_model == null or tea_set == null or cabinet == null or vase == null or lamp == null or cup_body == null or napkin_base == null or napkin_fold == null:
		printerr("C13_AABB_SUPPORT_FAIL: falta um modelo/prop da composição")
		quit(1)
		return
	var table_bounds: AABB = table_mesh.global_transform * table_mesh.get_aabb()
	var table_top := table_bounds.position.y + table_bounds.size.y
	var plate_count := 0
	var plate_gaps: Array[float] = []
	for node in house.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.name.begins_with("PratoJantar_"):
			plate_count += 1
			var bounds: AABB = mesh_node.global_transform * mesh_node.get_aabb()
			plate_gaps.append(bounds.position.y - table_top)
	var tea_bounds := _aggregate_bounds(tea_set)
	var cabinet_bounds := _aggregate_bounds(cabinet)
	var vase_bounds := _aggregate_bounds(vase)
	var lamp_bounds := _aggregate_bounds(lamp)
	var cup_bounds: AABB = cup_body.global_transform * cup_body.get_aabb()
	var napkin_base_bounds: AABB = napkin_base.global_transform * napkin_base.get_aabb()
	var napkin_fold_bounds: AABB = napkin_fold.global_transform * napkin_fold.get_aabb()
	var cabinet_top := cabinet_bounds.position.y + cabinet_bounds.size.y
	var tea_gap := tea_bounds.position.y - table_top
	var vase_gap := vase_bounds.position.y - cabinet_top
	var lamp_gap := lamp_bounds.position.y - cabinet_top
	var cup_gap := cup_bounds.position.y - table_top
	var napkin_gap := napkin_base_bounds.position.y - table_top
	var fold_gap := napkin_fold_bounds.position.y - (napkin_base_bounds.position.y + napkin_base_bounds.size.y)
	var min_plate_gap := INF
	var max_plate_gap := -INF
	for gap in plate_gaps:
		min_plate_gap = minf(min_plate_gap, gap)
		max_plate_gap = maxf(max_plate_gap, gap)
	var cloth_visible := false
	var cloth := _find_mesh(house, "dining_table_cloth")
	if cloth != null:
		cloth_visible = cloth.visible
	var plates_pass := plate_count == 4 and min_plate_gap >= -0.005 and max_plate_gap <= 0.02
	var tea_pass := tea_gap >= -0.005 and tea_gap <= 0.02
	var sideboard_pass := absf(vase_gap) <= 0.015 and absf(lamp_gap) <= 0.015
	var small_props_pass := cup_gap >= -0.005 and cup_gap <= 0.02 and napkin_gap >= -0.005 and napkin_gap <= 0.02 and absf(fold_gap) <= 0.005
	var pass_all := plates_pass and tea_pass and sideboard_pass and small_props_pass and not cloth_visible
	print("C13_AABB_SUPPORT_RESULT method=world_AABB_gaps table_top=%.4f plate_count=%d plate_gap_min=%.4f plate_gap_max=%.4f tea_gap=%.4f cabinet_top=%.4f vase_gap=%.4f lamp_gap=%.4f cup_gap=%.4f napkin_gap=%.4f fold_to_base_gap=%.4f cloth_visible=%s" % [table_top, plate_count, min_plate_gap, max_plate_gap, tea_gap, cabinet_top, vase_gap, lamp_gap, cup_gap, napkin_gap, fold_gap, str(cloth_visible)])
	print("C13_AABB_SUPPORT_SCOPE geometry_bounds_only=true physical_contact_not_proven=true prop_colliders_not_checked=true")
	if pass_all:
		print("C13_AABB_SUPPORT_PASS")
		quit(0)
	else:
		printerr("C13_AABB_SUPPORT_FAIL: gaps ou contagens fora da tolerância")
		quit(1)

func _find_asset(house: Node, suffix: String, expected_position: Vector3) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for node in house.find_children("*", "Node3D", true, false):
		var node_3d := node as Node3D
		var node_name := String(node_3d.name)
		if node_name.begins_with("Asset_") and node_name.ends_with("_" + suffix):
			var distance := node_3d.global_position.distance_to(expected_position)
			if distance < best_distance:
				best = node_3d
				best_distance = distance
	return best

func _find_mesh(house: Node, mesh_name: String) -> MeshInstance3D:
	for node in house.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.name == mesh_name:
			return mesh_node
	return null

func _aggregate_bounds(model: Node) -> AABB:
	var bounds := AABB()
	var found := false
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh == null:
				continue
			var mesh_bounds: AABB = mesh_node.global_transform * mesh_node.get_aabb()
			bounds = bounds.merge(mesh_bounds) if found else mesh_bounds
			found = true
	return bounds
