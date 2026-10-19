extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func bounds_for(n: Node3D) -> AABB:
	var found := false
	var result := AABB()
	var list: Array = [n]
	list.append_array(n.find_children("*","MeshInstance3D",true,false))
	for m in list:
		if not m is MeshInstance3D or m.mesh == null: continue
		var a: AABB = m.global_transform*m.get_aabb()
		result = result.merge(a) if found else a
		found = true
	return result
func run() -> void:
	var h := load("res://prototype/house_environment.tscn").instantiate() as Node3D
	root.add_child(h)
	await process_frame
	await physics_frame
	var data: Dictionary = {}
	for floor in h.get_node("Casa_Editavel").get_children():
		for room in floor.get_children():
			var props: Array = []
			for prop in room.get_children():
				if not prop is Node3D: continue
				var a := bounds_for(prop)
				var colls: Array = []
				for c in prop.find_children("*","CollisionShape3D",true,false):
					if c.shape == null: continue
					var b: AABB = c.global_transform*c.shape.get_debug_mesh().get_aabb()
					colls.append({"path":str(prop.get_path_to(c)),"min":[b.position.x,b.position.y,b.position.z],"size":[b.size.x,b.size.y,b.size.z]})
				props.append({"name":str(prop.name),"position":[prop.global_position.x,prop.global_position.y,prop.global_position.z],"rotation_y":prop.rotation.y,"mesh_min":[a.position.x,a.position.y,a.position.z],"mesh_size":[a.size.x,a.size.y,a.size.z],"collisions":colls})
			data[str(floor.name)+"/"+str(room.name)] = props
	var f := FileAccess.open("res://qa/whole_house/layout_bounds.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"\t")+"\n")
	h.free()
	quit()
