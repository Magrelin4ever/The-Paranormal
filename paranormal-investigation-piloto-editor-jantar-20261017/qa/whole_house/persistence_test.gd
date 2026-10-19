extends SceneTree
const MAIN := "res://prototype/house_environment.tscn"
const MASTER := "res://prototype/whole_house/casa_editavel.tscn"
const OUT := "res://qa/whole_house/persistence_results.json"
var checks: Array = []
var failures: Array[String] = []
var artifacts: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(label: String, passed: bool, detail: String = "") -> void:
	checks.append({"name":label,"pass":passed,"detail":detail})
	if not passed: failures.append(label+": "+detail)

func nodes(n: Node) -> Array[Node]:
	var result: Array[Node] = [n]
	for c in n.get_children(): result.append_array(nodes(c))
	return result

func collision(n: Node) -> CollisionShape3D:
	for c in nodes(n):
		if c is CollisionShape3D: return c
	return null

func own_all(n: Node, r: Node) -> void:
	if n != r:
		n.owner = r
		n.scene_file_path = ""
	for c in n.get_children(): own_all(c,r)

func write_text(path: String, text: String) -> void:
	var f := FileAccess.open(path,FileAccess.WRITE)
	assert(f != null)
	f.store_string(text)
	f.close()

func persist_floor(key: String, room_file: String, path_in_master: String, target_name: String) -> void:
	print("PERSISTENCE_FLOOR_START "+key)
	var original_path := "res://prototype/whole_house/rooms/"+room_file
	var room := load(original_path).instantiate() as Node3D
	root.add_child(room)
	await process_frame
	var target := room.find_child(target_name,true,false) as Node3D
	check(key+"_movel_selecionavel",target != null)
	if target == null:
		room.free()
		return
	var col := collision(target)
	check(key+"_colisao_filha",col != null)
	var before := col.global_transform if col != null else Transform3D()
	target.position += Vector3(.37,.11,-.23)
	target.rotation.y += .31
	target.force_update_transform()
	if col != null: col.force_update_transform()
	check(key+"_colisao_acompanha_movimento",col != null and not col.global_transform.is_equal_approx(before))
	var changed_position := target.position
	var changed_rotation := target.rotation
	var relative_path := room.get_path_to(target)
	# Arrastar uma cena pronta para a árvore é representado por esta instância.
	var added := load("res://prototype/whole_house/real_assets/Comoda_Profile_140.tscn").instantiate() as Node3D
	added.name = "Asset_Adicionado_No_Viewport_QA"
	added.position = Vector3(16.0,1.2,16.0)
	added.rotation.y = .45
	room.add_child(added)
	own_all(room,room)
	var p := PackedScene.new()
	var err := p.pack(room)
	var saved_room := "user://qa_whole_house_"+key+"_room.tscn"
	if err == OK: err = ResourceSaver.save(p,saved_room)
	check(key+"_salvar_cena",err == OK,str(err))
	artifacts.append(saved_room)
	room.free()
	var reopened := ResourceLoader.load(saved_room,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	check(key+"_reabrir_cena",reopened != null)
	if reopened == null: return
	var reopened_room := reopened.instantiate() as Node3D
	var changed := reopened_room.get_node_or_null(relative_path) as Node3D
	check(key+"_transform_persiste",changed != null and changed.position.is_equal_approx(changed_position) and changed.rotation.is_equal_approx(changed_rotation))
	check(key+"_asset_adicional_persiste",reopened_room.has_node("Asset_Adicionado_No_Viewport_QA"))
	reopened_room.free()
	# Composição real do jogo usando a cópia modificada. Nenhum arquivo oficial é alterado.
	var saved_master := "user://qa_whole_house_"+key+"_master.tscn"
	var saved_main := "user://qa_whole_house_"+key+"_main.tscn"
	write_text(saved_master,FileAccess.get_file_as_string(MASTER).replace(original_path,saved_room))
	write_text(saved_main,FileAccess.get_file_as_string(MAIN).replace(MASTER,saved_master))
	# As cenas têm nomes exclusivos. Reutilizar texturas/malhas não reutiliza transforms.
	var packed_main := ResourceLoader.load(saved_main,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	check(key+"_composicao_jogo_carrega",packed_main != null)
	if packed_main == null: return
	var game := packed_main.instantiate() as Node3D
	root.add_child(game)
	await process_frame
	await physics_frame
	var game_room := game.get_node_or_null("Casa_Editavel/"+path_in_master)
	var game_target := game_room.get_node_or_null(relative_path) as Node3D if game_room != null else null
	check(key+"_jogo_usa_transform_salvo",game_target != null and game_target.position.is_equal_approx(changed_position) and game_target.rotation.is_equal_approx(changed_rotation))
	check(key+"_jogo_usa_asset_adicionado",game_room != null and game_room.has_node("Asset_Adicionado_No_Viewport_QA"))
	check(key+"_jogo_usa_colisao_movida",game_target != null and collision(game_target) != null)
	game.free()
	await process_frame
	print("PERSISTENCE_FLOOR_DONE "+key)

func door_contract() -> void:
	var room := load("res://prototype/whole_house/rooms/primeiro__Portas.tscn").instantiate() as Node3D
	var door: AnimatableBody3D = null
	for n in nodes(room):
		if n is AnimatableBody3D: door = n; break
	if door == null:
		check("porta_existe",false)
		room.free()
		return
	door.position += Vector3(.4,.0,.2)
	door.rotation.y = .28
	root.add_child(room)
	await process_frame
	var closed := door.rotation.y
	door.call("alternar")
	await create_timer(.35).timeout
	check("porta_preserva_rotacao_editada_aberta",is_equal_approx(door.rotation.y,closed+deg_to_rad(float(door.get("angulo_abertura_graus")))))
	door.call("alternar")
	await create_timer(.35).timeout
	check("porta_retorna_a_rotacao_editada",is_equal_approx(door.rotation.y,closed))
	var target := door.get_node_or_null("AlvoInteracao") as Node3D
	var shape := collision(door)
	check("alvo_interacao_acompanha_edicao",target != null and shape != null and target.global_position.distance_to(shape.global_position)<.001)
	room.free()

func run() -> void:
	var master_text := FileAccess.get_file_as_string(MASTER)
	var overrides := 0
	for line in master_text.split("\n"):
		if line.begins_with("transform =") or line.begins_with("position =") or line.begins_with("rotation =") or line.begins_with("scale ="): overrides += 1
	check("master_sem_overrides_de_mobiliario",overrides == 0,str(overrides))
	check("master_tem_40_cenas_nativas",master_text.count(" instance=ExtResource")==40,str(master_text.count(" instance=ExtResource")))
	var main := load(MAIN) as PackedScene
	check("main_carrega",main != null)
	var house := main.instantiate() as Node3D
	root.add_child(house)
	await process_frame
	await physics_frame
	var total_meshes := 0
	var doors := 0
	var interior_lights := 0
	var interior_emissions := 0
	var inventory: Dictionary = {}
	for floor_name in ["Porao","Terreo","Primeiro_Andar","Sotao_Segundo_Andar"]:
		var floor_node := house.get_node("Casa_Editavel/"+floor_name)
		var floor_meshes := 0
		for n in nodes(floor_node):
			if n is AnimatableBody3D: doors += 1
			if n is Light3D and n.is_visible_in_tree() and n.light_energy>0: interior_lights += 1
			if n is MeshInstance3D and n.mesh != null:
				floor_meshes += 1
				for s in range(n.mesh.get_surface_count()):
					var m := n.get_active_material(s) as BaseMaterial3D
					if m != null and m.emission_enabled: interior_emissions += 1
		inventory[floor_name] = floor_meshes
		total_meshes += floor_meshes
		check("pavimento_nativo_"+floor_name,floor_meshes>0,str(floor_meshes))
	check("28_portas_interativas",doors==28,str(doors))
	check("zero_luzes_internas_ativas",interior_lights==0,str(interior_lights))
	check("zero_materiais_emissivos_internos_ativos",interior_emissions==0,str(interior_emissions))
	await process_frame
	var after_count := 0
	for floor_name in inventory:
		for n in nodes(house.get_node("Casa_Editavel/"+floor_name)):
			if n is MeshInstance3D and n.mesh != null: after_count += 1
	check("runtime_nao_recria_geometria",after_count==total_meshes,"antes=%d depois=%d" % [total_meshes,after_count])
	house.free()
	await process_frame
	await persist_floor("porao","porao__Oficina.tscn","Porao/Oficina","Modelo_BancadaOficina_*")
	await persist_floor("terreo","terreo__Hall_Entrada.tscn","Terreo/Hall_Entrada","Console_Entrada")
	await persist_floor("primeiro","primeiro__Suite_Casal.tscn","Primeiro_Andar/Suite_Casal","Cama_Casal_Linho")
	await persist_floor("sotao","sotao__Arquivo_Sotao.tscn","Sotao_Segundo_Andar/Arquivo_Sotao","MemoryDesk")
	await door_contract()
	write_text(OUT,JSON.stringify({"test":"whole_house_persistence_test","engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"inventory_meshes":inventory,"artifacts":artifacts,"passed":failures.is_empty()},"\t")+"\n")
	print("PERSISTENCE_TEST %s checks=%d failures=%s" % ["PASS" if failures.is_empty() else "FAIL",checks.size(),failures])
	quit(0 if failures.is_empty() else 1)
