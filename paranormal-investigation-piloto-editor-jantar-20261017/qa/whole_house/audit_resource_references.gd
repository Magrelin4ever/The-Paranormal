extends SceneTree
var visited: Dictionary = {}
var queue: Array[String] = []
func _initialize() -> void: call_deferred("run")
func files(path: String, extension: String) -> Array[String]:
	var result: Array[String] = []
	for f in DirAccess.get_files_at(path):
		if f.ends_with(extension): result.append(path.path_join(f))
	for dir in DirAccess.get_directories_at(path): result.append_array(files(path.path_join(dir),extension))
	return result
func run() -> void:
	queue.append_array(files("res://prototype/whole_house",".tscn"))
	queue.append("res://prototype/house_environment.tscn")
	var cursor := 0
	while cursor < queue.size():
		var path: String = queue[cursor]
		cursor += 1
		if visited.has(path): continue
		visited[path] = true
		for entry in ResourceLoader.get_dependencies(path):
			for part in entry.split("::"):
				if part.begins_with("res://") and FileAccess.file_exists(part) and not visited.has(part):
					queue.append(part)
	var unused: Array = []
	var bytes := 0
	for directory in ["res://prototype/whole_house/resources","res://prototype/whole_house/editor_resources"]:
		for path in files(directory,".res"):
			if visited.has(path): continue
			var f := FileAccess.open(path,FileAccess.READ)
			var size := f.get_length()
			f.close()
			unused.append({"path":path,"bytes":size})
			bytes += size
			if OS.get_environment("REMOVE_UNUSED_BAKE_RESOURCES") == "1": assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path))==OK)
	var f := FileAccess.open("res://qa/whole_house/resource_reference_results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"roots":"Todas as cenas de whole_house e main scene; dependencias transitivas nativas do ResourceLoader","visited":visited.size(),"unused_resources":unused,"unused_bytes":bytes,"removed":OS.get_environment("REMOVE_UNUSED_BAKE_RESOURCES")=="1"},"\t")+"\n")
	print("RESOURCE_REFERENCE_AUDIT visited=%d unused=%d bytes=%d removed=%s" % [visited.size(),unused.size(),bytes,OS.get_environment("REMOVE_UNUSED_BAKE_RESOURCES")=="1"])
	quit()
