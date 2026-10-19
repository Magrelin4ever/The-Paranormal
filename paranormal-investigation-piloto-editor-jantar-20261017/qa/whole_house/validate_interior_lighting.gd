extends SceneTree
const SCENE_PATH := "res://prototype/house_environment.tscn"
const RESULT_PATH := "res://qa/whole_house/interior_lighting_results.json"
var runtime_root: Node
var failures: Array[String] = []
var warnings: Array[String] = []
var light_checks: Array = []
var materials: Dictionary = {}
var shader_materials: Dictionary = {}
var meshes_checked := 0
var surfaces_checked := 0
func _initialize() -> void: call_deferred("run")
func exterior(n: Node) -> bool: return str(n.get_path()).to_lower().contains("/exterior")
func inspect() -> void:
	var house := runtime_root.get_node_or_null("Casa_Editavel")
	if house == null:
		failures.append("Casa_Editavel ausente no runtime")
		return
	for node in house.find_children("*","Light3D",true,false):
		var light := node as Light3D
		if exterior(light): continue
		var ok := not light.visible or is_zero_approx(light.light_energy)
		light_checks.append({"path":str(light.get_path()),"visible":light.visible,"energy":light.light_energy,"compliant":ok})
		if not ok: failures.append("Luz interior ativa: "+str(light.get_path()))
	for node in house.find_children("*","MeshInstance3D",true,false):
		var mesh := node as MeshInstance3D
		if exterior(mesh) or mesh.mesh == null: continue
		meshes_checked += 1
		for s in range(mesh.mesh.get_surface_count()):
			surfaces_checked += 1
			# Inclui material_override, surface_override e material da malha.
			var material := mesh.get_active_material(s)
			if material is BaseMaterial3D:
				var id := material.get_instance_id()
				if materials.has(id):
					materials[id]["uses"] += 1
					continue
				var base := material as BaseMaterial3D
				var unshaded := base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
				materials[id] = {"resource":base.resource_path,"first_mesh":str(mesh.get_path()),"uses":1,"emission_enabled":base.emission_enabled,"unshaded":unshaded}
				if base.emission_enabled: failures.append("Emissão interna ativa: "+str(mesh.get_path()))
				if unshaded: warnings.append("Material interno UNSHADED: "+str(mesh.get_path()))
			elif material is ShaderMaterial:
				var sm := material as ShaderMaterial
				if shader_materials.has(sm.get_instance_id()): continue
				var code := sm.shader.code if sm.shader != null else ""
				shader_materials[sm.get_instance_id()] = {"resource":sm.resource_path,"first_mesh":str(mesh.get_path()),"references_emission":code.contains("EMISSION")}
				if code.contains("EMISSION"): warnings.append("Revisar shader interno com EMISSION: "+str(mesh.get_path()))
func run() -> void:
	runtime_root = load(SCENE_PATH).instantiate()
	runtime_root.name = "QA_RuntimeRoot"
	root.add_child(runtime_root)
	await process_frame
	inspect()
	var status := "FAIL" if not failures.is_empty() else ("PASS_WITH_WARNINGS" if not warnings.is_empty() else "PASS")
	var result := {"status":status,"passed":failures.is_empty() and warnings.is_empty(),"scene":SCENE_PATH,"engine":Engine.get_version_info().string,"lights":{"checked":light_checks.size(),"items":light_checks},"interior_materials":{"meshes_checked":meshes_checked,"surfaces_checked":surfaces_checked,"unique_base_materials":materials.size(),"items":materials.values(),"shader_materials":shader_materials.values()},"warnings":warnings,"failures":failures,"note":"Todos os cômodos e móveis internos, não apenas pisos. As três luzes da lanterna do jogador fora de Casa_Editavel são ignoradas. Exterior/Lua são excluídos."}
	var file := FileAccess.open(RESULT_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")+"\n")
	runtime_root.free()
	print("INTERIOR_LIGHTING_%s meshes=%d surfaces=%d unique_materials=%d lights=%d failures=%s warnings=%s" % [status,meshes_checked,surfaces_checked,materials.size(),light_checks.size(),failures,warnings])
	quit(0 if failures.is_empty() and warnings.is_empty() else 1)
