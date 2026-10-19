extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var paths := ["res://prototype/assets/models/real_house_20261019/hush_wingback_bed.glb","res://prototype/assets/models/real_house_20261019/studio_loft_study_bed.glb","res://prototype/assets/models/innerscene/curtain-pair-open-original-interior-furnishing.glb","res://prototype/assets/models/polyhaven/small_wooden_table_01/small_wooden_table_01_1k.gltf","res://prototype/assets/models/polyhaven/potted_plant_02/potted_plant_02_1k.gltf"]
	var result: Array = []
	for path in paths:
		var n := load(path).instantiate() as Node3D
		root.add_child(n)
		var found := false
		var a := AABB()
		var count := 0
		for m in n.find_children("*","MeshInstance3D",true,false):
			if m.mesh == null: continue
			var b: AABB = m.global_transform*m.get_aabb()
			a = a.merge(b) if found else b
			found = true
			count += 1
		print("ASSET_BOUNDS %s %s meshes=%d" % [path,a,count])
		result.append({"path":path,"min":[a.position.x,a.position.y,a.position.z],"size":[a.size.x,a.size.y,a.size.z],"meshes":count})
		n.free()
	var f := FileAccess.open("res://qa/whole_house/polish_asset_bounds.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t")+"\n")
	quit()
