extends SceneTree
# Ferramenta offline. NUNCA executar novamente sobre edições manuais sem backup.
const OUT := "res://prototype/whole_house/"
var failures: Array[String] = []
var mesh_paths: Dictionary = {}
var material_paths: Dictionary = {}
var buckets: Dictionary = {}
var mesh_count := 0
var node_count := 0
var recovery := OS.get_environment("RECOVER_AUTHOR_SETS") == "1"

func _initialize() -> void:
	call_deferred("run")

func floor_for(p: Vector3, hint: String = "") -> String:
	if hint in ["porao", "terreo", "primeiro", "sotao", "exterior"]:
		return hint
	if p.y < -0.3: return "porao"
	if p.y >= 5.45: return "sotao"
	if p.y >= 2.6: return "primeiro"
	return "terreo"

func room_for(p: Vector3, floor_id: String) -> String:
	if floor_id == "exterior": return "Exterior"
	if floor_id == "porao":
		if p.x < -1.85: return "Deposito" if p.z < -3.0 else "Lavanderia_Porao"
		return "Oficina" if p.z < -3.0 and p.x < 6.7 else "Circulacao_Porao"
	if floor_id == "terreo":
		if absf(p.x) < 1.85: return "Hall_Entrada"
		if p.x < 0.0:
			if p.z < -2.8: return "Cozinha_Richard"
			return "Sala_Estar" if p.z > 2.5 else "Sala_Jantar"
		if p.z < -2.8: return "Area_Servico"
		return "Escritorio" if p.z > 2.5 else "Biblioteca"
	if floor_id == "primeiro":
		if absf(p.x) < 1.85: return "Hall_Superior"
		if p.z < -1.1: return "Quarto_Infantil" if p.x < 0 else "Suite_Casal"
		if p.z > 2.1: return "Banheiro_Familiar" if p.x < 0 else "Banheiro_Suite"
		return "Closet_Infantil" if p.x < 0 else "Closet_Casal"
	return "Arquivo_Sotao" if p.z < -0.15 else "Deposito_Sotao"

func set_owners(n: Node, scene_root: Node) -> void:
	# Expande recursos importados para edição por nó, sem scripts geradores.
	if n != scene_root:
		n.owner = scene_root
		n.scene_file_path = ""
	for c in n.get_children(): set_owners(c, scene_root)

func external_material(material: Material) -> Material:
	if material == null: return null
	var key := material.get_instance_id()
	if material_paths.has(key): return material_paths[key]
	var prefix := "recovery_" if recovery else ""
	var path := OUT + "resources/" + prefix + "material_%04d.res" % (material_paths.size() + 1)
	var result := ResourceSaver.save(material, path, ResourceSaver.FLAG_COMPRESS)
	if result != OK: failures.append("Material %s: %s" % [path, result])
	var external := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Material
	material_paths[key] = external
	return external

func externalize_meshes(n: Node) -> void:
	node_count += 1
	if n is MeshInstance3D and n.mesh != null:
		n.material_override = external_material(n.material_override)
		for surface in range(n.mesh.get_surface_count()):
			var local: Material = n.get_surface_override_material(surface)
			if local != null: n.set_surface_override_material(surface, external_material(local))
		var key: int = n.mesh.get_instance_id()
		if not mesh_paths.has(key):
			mesh_count += 1
			var prefix := "recovery_" if recovery else ""
			var path := OUT + "resources/" + prefix + "mesh_%04d.res" % mesh_count
			var result := ResourceSaver.save(n.mesh, path, ResourceSaver.FLAG_COMPRESS | ResourceSaver.FLAG_CHANGE_PATH)
			if result != OK: failures.append("Malha %s: %s" % [path, result])
			mesh_paths[key] = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		n.mesh = mesh_paths[key]
	for c in n.get_children(): externalize_meshes(c)

func bucket_for(floor_id: String, room: String) -> Node3D:
	var key := floor_id + "/" + room
	if buckets.has(key): return buckets[key]
	var node := Node3D.new()
	node.name = room
	node.set_meta("pavimento", floor_id)
	node.set_meta("edicao", "Edite esta cena, salve e execute F5. Nao ha reconstrucao procedural no jogo.")
	root.add_child(node)
	buckets[key] = node
	return node

func count_recursive(n: Node) -> int:
	var total := 1
	for c in n.get_children(): total += count_recursive(c)
	return total

func repair_special_colliders(n: Node) -> void:
	# Os conjuntos autorais têm colisões explícitas que antes ficavam no pavimento.
	var mappings := {
		"Hitbox_Mesa_Escritorio_C15": "Modelo_MesaEscritorioC15_*",
		"Hitbox_Cadeira_Escritorio_C15": "Modelo_MesaEscritorioC15_*",
		"BancadaServicoC18": "Modelo_ConjuntoServicoC18_*",
		"RetornoServicoC18": "Modelo_ConjuntoServicoC18_*",
		"AereoEsquerdoC18": "Modelo_ConjuntoServicoC18_*",
		"SobrejanelaC18": "Modelo_ConjuntoServicoC18_*",
		"AereoDireitoC18": "Modelo_ConjuntoServicoC18_*",
		"AspiradorC18": "Modelo_ConjuntoServicoC18_*",
		"BaldeC18": "Modelo_ConjuntoServicoC18_*",
		"C19_Console_Perimetro": "Modelo_ConjuntoHallC19_*",
		"C19_Banco_Perimetro": "Modelo_ConjuntoHallC19_*",
	}
	for label in mappings:
		var body := n.find_child(label, true, false) as Node3D
		var model := n.find_child(mappings[label], true, false) as Node3D
		if body != null and model != null:
			body.reparent(model, true)
	# A cozinha é preservada geometricamente. Cada colisor passa ao mesh homônimo.
	var kitchen := n.find_child("Kitchen004C16", true, false)
	if kitchen != null:
		for body in n.find_children("C16_*", "StaticBody3D", true, false):
			var target := kitchen.find_child(String(body.name).trim_prefix("C16_"), true, false) as Node3D
			if target != null: body.reparent(target, true)

func save_bucket(key: String, bucket: Node3D) -> String:
	if bucket.get_parent() != null: bucket.get_parent().remove_child(bucket)
	bucket.name = key.split("/")[1]
	set_owners(bucket, bucket)
	externalize_meshes(bucket)
	var path := OUT + "rooms/" + key.replace("/", "__") + ".tscn"
	var packed := PackedScene.new()
	var err := packed.pack(bucket)
	if err == OK: err = ResourceSaver.save(packed, path)
	if err != OK: failures.append("Cena %s: %s" % [key, err])
	return path

func run() -> void:
	var script := load("res://qa/whole_house/bake_source.gd") as GDScript
	if script == null:
		push_error("Execute create_bake_source.py primeiro")
		quit(1)
		return
	var builder := script.new() as Node3D
	root.add_child(builder)
	await process_frame
	await physics_frame
	var content := builder.get_node("ConteudoConvertido") as Node3D
	repair_special_colliders(content)
	var doors := 0
	for item in content.get_children():
		if not item is Node3D: continue
		var phase := String(item.get_meta("fase_conversao", ""))
		var p: Vector3 = item.global_position
		var floor_id := floor_for(p, String(item.get_meta("pavimento", "")))
		var room := room_for(p, floor_id)
		if phase == "_montar_vizinhanca":
			floor_id = "exterior"
			room = "Exterior"
		elif phase in ["_montar_pisos_e_estrutura", "_montar_paredes_internas"] or item is AnimatableBody3D:
			if item is AnimatableBody3D:
				room = "Portas"
				doors += 1
			else:
				room = "Estrutura"
				var mat := String(item.get_meta("material_original", ""))
				if "ceiling" in mat: room = "Tetos"
				elif item is MeshInstance3D and item.mesh != null and item.get_aabb().size.y < 0.25: room = "Pisos_E_Acabamentos"
		elif phase == "_montar_escadas":
			room = "Escadas"
		elif phase == "_montar_telhado_exterior":
			floor_id = "exterior"
			room = "Telhado_E_Fachada"
		item.reparent(bucket_for(floor_id,room), true)
	# Colisões originais remanescentes (rampas, se houver) mantêm o pavimento.
	for floor_id in builder._corpos_colisao:
		var body: Node = builder._corpos_colisao[floor_id]
		if body.get_child_count() > 0: body.reparent(bucket_for(String(floor_id), "Escadas"), true)
	# Jantar original continua como fonte única; a referência de paredes do piloto sai do jogo.
	var dining := load("res://prototype/editor_pilot/sala_jantar_editavel.tscn").instantiate() as Node3D
	root.add_child(dining)
	await process_frame
	if dining.has_node("Referencia_EDITOR_so"): dining.get_node("Referencia_EDITOR_so").free()
	for child in dining.get_children(): child.reparent(bucket_for("terreo", "Sala_Jantar"), true)
	dining.free()
	var header := "[gd_scene format=3]\n\n"
	var body_text := "[node name=\"Casa_Editavel\" type=\"Node3D\"]\n\n"
	var editable_text := ""
	var floors: Array[String] = []
	var scene_index := 0
	var manifest: Dictionary = {"fonte_git": "584b69a", "gerador": "offline; nao executar sobre edicoes", "rooms": [], "doors": doors, "failures": failures}
	for key in buckets:
		if recovery and key not in ["terreo/Escritorio", "terreo/Area_Servico", "terreo/Hall_Entrada"]: continue
		var path := save_bucket(key, buckets[key])
		var floor_id := String(key).split("/")[0]
		var floor_name: String = {"porao":"Porao", "terreo":"Terreo", "primeiro":"Primeiro_Andar", "sotao":"Sotao_Segundo_Andar", "exterior":"Exterior"}[floor_id]
		var room_name := String(key).split("/")[1]
		if not floors.has(floor_name):
			body_text += "[node name=\"%s\" type=\"Node3D\" parent=\".\"]\n\n" % floor_name
			floors.append(floor_name)
		scene_index += 1
		header += "[ext_resource type=\"PackedScene\" path=\"%s\" id=\"%d_room\"]\n" % [path, scene_index]
		body_text += "[node name=\"%s\" parent=\"%s\" instance=ExtResource(\"%d_room\")]\n\n" % [room_name, floor_name, scene_index]
		editable_text += "[editable path=\"%s/%s\"]\n" % [floor_name, room_name]
		manifest["rooms"].append({"scene": path, "nodes": count_recursive(buckets[key])})
	if not recovery:
		var master_file := FileAccess.open(OUT+"casa_editavel.tscn", FileAccess.WRITE)
		master_file.store_string(header + "\n" + body_text + editable_text)
		master_file.close()
	manifest["meshes"] = mesh_count
	manifest["nodes"] = node_count
	manifest["boxes"] = builder.bake_box_count
	manifest["triangles"] = builder.bake_triangle_count
	var manifest_name := "recovery_manifest" if recovery else "conversion_manifest"
	var f := FileAccess.open("res://qa/whole_house/"+manifest_name+".json", FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest,"\t")+"\n")
	print("BAKE_HOUSE rooms=%d meshes=%d nodes=%d boxes=%d doors=%d failures=%s" % [buckets.size(),mesh_count,node_count,builder.bake_box_count,doors,failures])
	for bucket in buckets.values(): bucket.free()
	builder.free()
	quit(0 if failures.is_empty() else 1)
