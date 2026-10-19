extends SceneTree
# Consolidação offline após o bake inicial. Não executar sobre novas edições do usuário.
const ROOMS := "res://prototype/whole_house/rooms/"
const RESOURCES := "res://prototype/whole_house/editor_resources/"
var loaded: Dictionary = {}
var meshes: Dictionary = {}
var serial := 0
var normalization: Array = []
const LAYERS := {"exterior":1,"porao":2,"terreo":4,"primeiro":8,"sotao":16}
const CEILINGS := {"porao":32,"terreo":64,"primeiro":128,"sotao":256}

func _initialize() -> void:
	call_deferred("run")

func own_all(n: Node, r: Node) -> void:
	if n != r:
		n.owner = r
		n.scene_file_path = ""
	for c in n.get_children(): own_all(c,r)

func get_scene(file: String) -> Node3D:
	if loaded.has(file): return loaded[file]
	var r := load(ROOMS+file).instantiate() as Node3D
	assert(r != null)
	root.add_child(r)
	loaded[file] = r
	return r

func bounds_for(prop: Node3D) -> AABB:
	var found := false
	var result := AABB()
	for mesh in prop.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh == null: continue
		var t: Transform3D = prop.global_transform.affine_inverse()*mesh.global_transform
		var a: AABB = t*mesh.get_aabb()
		result = result.merge(a) if found else a
		found = true
	return result

func normalize_prop(prop: Node3D, world_position: Vector3, angle: float = 0.0) -> void:
	var model := prop.get_node_or_null("Model") as Node3D
	if model == null: return
	var a := bounds_for(prop)
	model.position -= Vector3(a.get_center().x,a.position.y,a.get_center().z)
	prop.global_position = world_position
	prop.global_rotation.y = deg_to_rad(angle)
	a = bounds_for(prop)
	for body in prop.find_children("*","StaticBody3D",true,false): body.free()
	var b := StaticBody3D.new()
	b.name = "Colisao_Acompanha_Peca"
	prop.add_child(b)
	var c := CollisionShape3D.new()
	c.name = "Forma"
	var shape := BoxShape3D.new()
	shape.size = a.size
	c.shape = shape
	c.position = a.get_center()
	b.add_child(c)
	prop.set_meta("_edit_group_",true)
	normalization.append({"piece":String(prop.name),"position":str(prop.global_position),"local_bounds":str(a),"base_y":a.position.y})

func refine_decor(file: String, placements: Dictionary, discard: Array, remove_old_boxes: bool = false) -> void:
	var room := get_scene(file)
	var decor := room.find_child("DecorAmbiental_*",true,false) as Node3D
	if decor == null: return
	if decor.has_meta("_edit_group_"): decor.remove_meta("_edit_group_")
	for n in decor.get_children():
		if String(n.name) in discard or not placements.has(String(n.name)):
			n.free()
			continue
		if placements.has(String(n.name)):
			var data: Array = placements[String(n.name)]
			normalize_prop(n,data[0],data[1])
			n.reparent(room,true)
	if decor.get_child_count() == 0: decor.free()
	if remove_old_boxes:
		for n in room.get_children():
			if String(n.name).begins_with("Peca_"): n.free()

func prepare_meshes(n: Node, layer: int, celestial: bool = false) -> void:
	if n is VisualInstance3D: n.layers = layer
	if n is Light3D:
		n.visible = false
		n.light_energy = 0.0
	if n is MeshInstance3D and n.mesh != null:
		if not celestial and n.name != "Lua":
			for s in range(n.mesh.get_surface_count()):
				var m := n.get_active_material(s) as BaseMaterial3D
				if m != null and m.emission_enabled:
					var safe := m.duplicate() as BaseMaterial3D
					safe.emission_enabled = false
					safe.emission = Color.BLACK
					n.set_surface_override_material(s,safe)
		var p: String = n.mesh.resource_path
		if not p.begins_with("res://prototype/whole_house/") or not p.ends_with(".res"):
			var id: int = n.mesh.get_instance_id()
			if not meshes.has(id):
				serial += 1
				var path := RESOURCES+"mesh_%04d.res" % serial
				ResourceSaver.save(n.mesh,path,ResourceSaver.FLAG_COMPRESS)
				meshes[id] = ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE)
			n.mesh = meshes[id]
	for c in n.get_children(): prepare_meshes(c,layer,celestial)

func save(file: String, r: Node3D) -> void:
	own_all(r,r)
	var p := PackedScene.new()
	assert(p.pack(r) == OK)
	assert(ResourceSaver.save(p,ROOMS+file) == OK)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RESOURCES))
	# Os objetos celestes pertencem ao exterior e não contam como emissão interna.
	var outside := get_scene("exterior__Exterior.tscn")
	var attic := get_scene("sotao__Arquivo_Sotao.tscn")
	var hall := get_scene("terreo__Hall_Entrada.tscn")
	for pair in [[attic,"Lua"],[hall,"Estrelas"]]:
		var celestial: Node = pair[0].get_node_or_null(pair[1])
		if celestial != null: celestial.reparent(outside,true)
	# Mantém as máquinas/bancadas realistas originais; acrescenta apenas o que falta.
	refine_decor("porao__Lavanderia_Porao.tscn",{
		"LaundryTub":[Vector3(-4.55,-2.85,-6.75),0.0],
		"LaundryShelf":[Vector3(-8.70,-2.85,-4.6),90.0]},
		["WasherDryer","Dryer","LaundryBasket"])
	refine_decor("porao__Deposito.tscn",{
		"SeasonalCabinet":[Vector3(-8.55,-2.85,-1.2),90.0]},
		["StorageRack","StorageCrateA","StorageCrateB"])
	refine_decor("porao__Oficina.tscn",{
		"PartsShelf":[Vector3(4.52,-2.85,-3.85),-90.0],
		"WorkshopCrate":[Vector3(3.8,-2.85,-7.15),0.0]},
		["Workbench","ToolCart"])
	refine_decor("porao__Circulacao_Porao.tscn",{},["SmallCrate","UtilityBin","HallBasket"])
	refine_decor("sotao__Arquivo_Sotao.tscn",{
		"MemoryBookcase":[Vector3(-6.75,5.70,-4.2),90.0],
		"MemoryDesk":[Vector3(-3.8,5.70,-4.75),0.0],
		"ArchiveCabinet":[Vector3(5.95,5.70,-4.8),0.0],
		"ArchiveBooks":[Vector3(-6.70,7.05,-4.2),90.0],
		"ArchiveBinder":[Vector3(-3.8,6.44,-4.65),0.0]},[],true)
	refine_decor("sotao__Deposito_Sotao.tscn",{
		"SeasonalRack":[Vector3(-6.7,5.70,3.8),90.0],
		"SeasonalCrateA":[Vector3(-5.9,5.70,1.45),0.0],
		"SeasonalCrateB":[Vector3(-5.9,6.05,1.45),0.0],
		"SeasonalCabinet":[Vector3(6.1,5.70,4.7),-90.0]},[],true)
	var files := DirAccess.get_files_at(ROOMS)
	for file in files:
		if not file.ends_with(".tscn"): continue
		var room := get_scene(file)
		var floor_id: String = file.split("__")[0]
		var layer: int = LAYERS[floor_id]
		if "Tetos" in file: layer = CEILINGS.get(floor_id,1)
		if "Telhado_E_Fachada" in file: layer = 512
		prepare_meshes(room,layer,floor_id == "exterior")
		if room.has_meta("_edit_group_"): room.remove_meta("_edit_group_")
		for door in room.find_children("*","AnimatableBody3D",true,false):
			var angle: float = door.get("angulo_abertura_graus")
			if absf(angle) < 90.0: door.set("angulo_abertura_graus",95.0 if angle >= 0.0 else -95.0)
		save(file,room)
		print("EDITOR_SCENE %s layer=%d" % [file,layer])
	var f := FileAccess.open("res://qa/whole_house/editor_finalization_results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"rooms":files.size(),"new_external_meshes":serial,"normalized_props":normalization,"editor_layer_filter":"Viewport camera only; never saves hidden floors"},"\t")+"\n")
	for r in loaded.values(): r.free()
	quit()
