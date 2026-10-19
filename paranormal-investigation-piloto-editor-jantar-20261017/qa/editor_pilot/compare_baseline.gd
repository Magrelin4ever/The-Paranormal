extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _signature(house: Node) -> Dictionary:
	var meshes: Array[String] = []
	var boxes: Array[String] = []
	for n in house.find_children("*", "MeshInstance3D", true, false):
		var m := n as MeshInstance3D
		if m.name == "MalhasEstaticasAgrupadas" or m.mesh == null:
			continue
		var mats: Array[String] = []
		for i in range(m.mesh.get_surface_count()):
			var mat := m.get_active_material(i) as StandardMaterial3D
			if mat != null:
				mats.append("%s|%.4f|%.4f|%s|%s" % [str(mat.albedo_color), mat.roughness, mat.metallic, str(mat.emission_enabled), mat.albedo_texture.resource_path if mat.albedo_texture else "none"])
		meshes.append("%s|%s|%s|%s" % [str(m.global_transform), str(m.mesh.get_aabb()), str(m.visible), str(mats)])
	for n in house.find_children("*", "CollisionShape3D", true, false):
		var c := n as CollisionShape3D
		if c.shape is BoxShape3D:
			boxes.append("%s|%s|%s" % [str(c.global_transform), str((c.shape as BoxShape3D).size), str(c.disabled)])
	meshes.sort()
	boxes.sort()
	return {"meshes": meshes, "boxes": boxes}

func _run() -> void:
	var baseline := (load("res://qa/editor_pilot/baseline_environment.gd") as Script).new() as Node3D
	root.add_child(baseline)
	await process_frame
	await physics_frame
	var before := _signature(baseline)
	root.remove_child(baseline)
	baseline.free()
	await process_frame
	var candidate := (load("res://prototype/house_environment.tscn") as PackedScene).instantiate()
	root.add_child(candidate)
	await process_frame
	await process_frame
	await physics_frame
	var after := _signature(candidate)
	var good := true
	for key in ["meshes", "boxes"]:
		var same: bool = before[key] == after[key]
		print("BASELINE_COMPARE %s equal=%s baseline=%d candidate=%d" % [key, str(same), before[key].size(), after[key].size()])
		if not same:
			good = false
			var absent: Array = []
			var added: Array = []
			for value in before[key]:
				if not after[key].has(value): absent.append(value)
			for value in after[key]:
				if not before[key].has(value): added.append(value)
			print("DIFF missing=", absent.slice(0, 8), " added=", added.slice(0, 8))
	print("BASELINE_COMPARE_SCOPE excludes_aggregated_mesh=true compares_world_transforms_materials_boxes=true")
	print("BASELINE_COMPARE_RESULT ", "PASS" if good else "FAIL")
	candidate.queue_free()
	await process_frame
	quit(0 if good else 1)
