@tool
extends EditorPlugin
## Filtro apenas da prévia do editor; não altera propriedades salvas das cenas.
var dock: VBoxContainer
var toolbar: HBoxContainer
var floors: OptionButton
var ceilings: CheckBox
var status: Label
var preview_nodes: Dictionary = {}
var preview_included := 0
var preview_excluded := 0
const MASKS := [1048575,2,4,8,16,1]
const CEILINGS := [992,32,64,128,256,512]

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "Casa — edição 3D"
	var title := Label.new()
	title.text = "CASA INTEIRA · VIEWPORT 3D"
	dock.add_child(title)
	var hint := Label.new()
	hint.text = "O filtro não muda o que aparece no jogo."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(hint)
	toolbar = HBoxContainer.new()
	var floor_label := Label.new()
	floor_label.text = "Piso:"
	toolbar.add_child(floor_label)
	floors = OptionButton.new()
	for label in ["Casa completa", "Porão", "Térreo", "Primeiro andar", "Sótão / segundo andar", "Exterior"]:
		floors.add_item(label)
	floors.item_selected.connect(_floor_changed)
	toolbar.add_child(floors)
	ceilings = CheckBox.new()
	ceilings.text = "Tetos"
	ceilings.tooltip_text = "Mostrar tetos e cobertura no editor; não muda o jogo."
	ceilings.button_pressed = true
	ceilings.toggled.connect(func(_value): _apply_filter())
	toolbar.add_child(ceilings)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU,toolbar)
	var restore := Button.new()
	restore.text = "Restaurar visão completa"
	restore.pressed.connect(_restore_view)
	dock.add_child(restore)
	var assets := Button.new()
	assets.text = "Abrir assets prontos"
	assets.pressed.connect(func(): EditorInterface.get_file_system_dock().navigate_to_path("res://prototype/whole_house/real_assets/"))
	dock.add_child(assets)
	var toolbar_assets := Button.new()
	toolbar_assets.text = "Assets"
	toolbar_assets.pressed.connect(func(): assets.pressed.emit())
	toolbar.add_child(toolbar_assets)
	var assign := Button.new()
	assign.text = "Aplicar piso à seleção"
	assign.tooltip_text = "Depois de arrastar um GLB ou uma cena, selecione sua raiz e aplique a camada do piso escolhido. Ctrl+Z desfaz. Não move a posição do asset."
	assign.pressed.connect(_assign_selected_floor)
	dock.add_child(assign)
	var toolbar_assign := Button.new()
	toolbar_assign.text = "Aplicar piso"
	toolbar_assign.tooltip_text = assign.tooltip_text
	toolbar_assign.pressed.connect(_assign_selected_floor)
	toolbar.add_child(toolbar_assign)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(status)
	var instruction := Label.new()
	instruction.text = "Abra casa_editavel.tscn. Escolha um piso e desmarque os tetos. Selecione a raiz do móvel: W move, E gira, Ctrl+S salva; F5 testa. Para adicionar: arraste uma cena de asset para a árvore ou viewport."
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(instruction)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL,dock)
	scene_changed.connect(_scene_changed)
	call_deferred("_apply_filter")
	if OS.get_environment("HOUSE_EDITOR_QA") == "1": call_deferred("_qa_filter_test")

func _exit_tree() -> void:
	_restore_masks()
	if is_instance_valid(toolbar):
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU,toolbar)
		toolbar.queue_free()
	if is_instance_valid(dock):
		remove_control_from_docks(dock)
		dock.queue_free()

func _apply_changes() -> void:
	# O editor chama este hook antes de salvar ou executar o jogo.
	_restore_visuals()
	call_deferred("_apply_filter")

func _save_external_data() -> void:
	call_deferred("_apply_filter")

func _floor_changed(_index: int) -> void:
	_apply_filter()

func _scene_changed(scene_root: Node) -> void:
	if scene_root == null: return
	var path := scene_root.scene_file_path
	if "whole_house/rooms/" in path:
		var key := path.get_file().split("__")[0]
		var index: int = {"porao":1,"terreo":2,"primeiro":3,"sotao":4,"exterior":5}.get(key,0)
		floors.select(index)
	elif "house_environment.tscn" not in path and "casa_editavel.tscn" not in path:
		_restore_masks()
		return
	call_deferred("_apply_filter")

func _apply_filter() -> void:
	if not is_instance_valid(floors): return
	var index := floors.selected
	var mask: int = MASKS[index]
	if index == 0:
		mask = 1048575 if ceilings.button_pressed else (1|2|4|8|16)
	elif ceilings.button_pressed:
		mask |= CEILINGS[index]
	_restore_visuals()
	preview_included = 0
	preview_excluded = 0
	var edited := EditorInterface.get_edited_scene_root()
	if edited != null:
		var pending: Array[Node] = [edited]
		while not pending.is_empty():
			var n: Node = pending.pop_back()
			pending.append_array(n.get_children())
			if n is VisualInstance3D:
				preview_nodes[n.get_instance_id()] = n.visible
				var included: bool = (n.layers & mask) != 0
				# A propriedade nativa também atualiza a representação do editor.
				# _apply_changes restaura os valores originais ANTES de salvar.
				n.visible = included and n.visible
				if included: preview_included += 1
				else: preview_excluded += 1

func _restore_visuals() -> void:
	for id in preview_nodes:
		var visual := instance_from_id(id) as VisualInstance3D
		if visual != null: visual.visible = preview_nodes[id]
	preview_nodes.clear()

func _restore_masks() -> void:
	_restore_visuals()

func _restore_view() -> void:
	floors.select(0)
	ceilings.button_pressed = true
	_apply_filter()

func _assign_selected_floor() -> void:
	var index := floors.selected
	if index == 0:
		status.text = "Escolha primeiro um piso na barra 3D."
		return
	var edited := EditorInterface.get_edited_scene_root()
	var selected := EditorInterface.get_selection().get_selected_nodes()
	var pending: Array[Node] = []
	for n in selected:
		if n == edited or str(n.name) in ["Terreo","Primeiro_Andar","Porao","Sotao","Sotao_Segundo_Andar","Exterior"]:
			status.text = "Selecione a raiz de um asset, não a casa ou um pavimento inteiro."
			return
		pending.append(n)
	var seen: Dictionary = {}
	var visuals: Array[VisualInstance3D] = []
	while not pending.is_empty():
		var n: Node = pending.pop_back()
		if seen.has(n.get_instance_id()): continue
		seen[n.get_instance_id()] = true
		if n is VisualInstance3D: visuals.append(n)
		pending.append_array(n.get_children())
	if visuals.is_empty():
		status.text = "Selecione um asset na árvore da cena."
		return
	var undo := get_undo_redo()
	undo.create_action("Aplicar piso à seleção")
	# Overrides em filhos de GLB só persistem com a instância editável.
	# Habilite também instâncias aninhadas, sem desvincular o asset original.
	var instances: Dictionary = {}
	for id in seen:
		var candidate := instance_from_id(id) as Node
		if candidate != null and candidate != edited and not candidate.scene_file_path.is_empty():
			instances[id] = candidate
	for n in selected:
		var ancestor := n.get_parent()
		while ancestor != null and ancestor != edited:
			if not ancestor.scene_file_path.is_empty(): instances[ancestor.get_instance_id()] = ancestor
			ancestor = ancestor.get_parent()
	for instance in instances.values():
		undo.add_do_method(edited,"set_editable_instance",instance,true)
		undo.add_undo_method(edited,"set_editable_instance",instance,edited.is_editable_instance(instance))
	for n in selected:
		undo.add_do_method(n,"set_meta","_edit_group_",true)
		if n.has_meta("_edit_group_"):
			undo.add_undo_method(n,"set_meta","_edit_group_",n.get_meta("_edit_group_"))
		else:
			undo.add_undo_method(n,"remove_meta","_edit_group_")
	for mesh in visuals:
		undo.add_do_property(mesh,"layers",MASKS[index])
		undo.add_undo_property(mesh,"layers",mesh.layers)
	undo.commit_action()
	_apply_filter()
	status.text = "%d malhas no piso %s. Ctrl+S salva; Ctrl+Z desfaz." % [visuals.size(),floors.get_item_text(index)]

func _qa_filter_test() -> void:
	var edited: Node
	for attempt in range(30):
		await get_tree().create_timer(1.0).timeout
		edited = EditorInterface.get_edited_scene_root()
		if edited != null and "casa_editavel.tscn" in edited.scene_file_path: break
	if edited == null or "casa_editavel.tscn" not in edited.scene_file_path:
		push_error("QA do plugin não encontrou a composição da casa aberta.")
		return
	var before := FileAccess.get_sha256(edited.scene_file_path)
	floors.select(2)
	ceilings.button_pressed = false
	_apply_filter()
	var tested := 0
	var ok := true
	for i in range(4):
		var viewport := EditorInterface.get_editor_viewport_3d(i)
		var camera := viewport.get_camera_3d() if viewport != null else null
		if camera == null: continue
		tested += 1
		ok = ok and (camera.cull_mask & 1048575) == 1048575
	ok = ok and preview_included > 0 and preview_excluded > 0
	var selection := EditorInterface.get_selection()
	selection.clear()
	var temporary := (load("res://prototype/assets/models/innerscene/television-modern.glb") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	temporary.name = "QA_Asset_Temporario"
	edited.add_child(temporary)
	temporary.owner = edited
	var test_mesh := temporary.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
	var original_layer := test_mesh.layers
	selection.add_node(temporary)
	_assign_selected_floor()
	var assigned := test_mesh.layers == 4 and edited.is_editable_instance(temporary)
	_restore_visuals()
	var packed := PackedScene.new()
	var save_error := packed.pack(edited)
	if save_error == OK: save_error = ResourceSaver.save(packed,"user://qa_editor_asset_assignment.tscn")
	var persisted := false
	if save_error == OK:
		var reopened := (ResourceLoader.load("user://qa_editor_asset_assignment.tscn","PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
		var loaded_asset := reopened.get_node_or_null("QA_Asset_Temporario")
		if loaded_asset != null:
			persisted = true
			for mesh in loaded_asset.find_children("*","MeshInstance3D",true,false): persisted = persisted and mesh.layers == 4
		reopened.free()
	var manager := get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(test_mesh))
	history.undo()
	var undone := test_mesh.layers == original_layer and not edited.is_editable_instance(temporary)
	history.clear_history(false)
	selection.clear()
	temporary.free()
	_apply_filter()
	status.text = ""
	var floor_mesh := edited.get_node_or_null("Terreo/Pisos_E_Acabamentos/Peca_wood_floor_0002")
	if floor_mesh != null: selection.add_node(floor_mesh)
	var after := FileAccess.get_sha256(edited.scene_file_path)
	var file := FileAccess.open("res://qa/whole_house/editor_plugin_results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"plugin_enabled":true,"preview_strategy":"native editor visibility restored before save via _apply_changes","preview_included":preview_included,"preview_excluded":preview_excluded,"editor_viewports_tested":tested,"floor_preview_filter_correct":ok,"new_asset_floor_assignment":assigned,"asset_assignment_survives_save_reload":persisted,"undo_restores_original_layer":undone,"scene_file_unchanged":before==after,"passed":tested>0 and ok and before==after and assigned and undone and persisted},"\t")+"\n")
	file.close()
	print("HOUSE_EDITOR_FILTER_QA passed=%s cameras=%d scene_unchanged=%s" % [tested>0 and ok,tested,before==after])
	await get_tree().create_timer(5.0).timeout
	var cameras: Array = []
	for i in range(4):
		var view := EditorInterface.get_editor_viewport_3d(i)
		var camera := view.get_camera_3d()
		cameras.append({"index":i,"position":camera.global_position,"rotation":camera.global_rotation,"near":camera.near,"far":camera.far,"size":camera.size,"fov":camera.fov,"projection":camera.projection,"mask_after_frames":camera.cull_mask,"current":camera.current,"scenario":str(camera.get_world_3d().scenario)})
	var layers: Dictionary = {}
	for m in edited.find_children("*","MeshInstance3D",true,false):
		var key := str(m.layers)
		if not layers.has(key): layers[key] = {"count":0,"visible":0,"first_mesh":str(m.get_path()),"first_position":m.global_position,"scenario":str(m.get_world_3d().scenario)}
		layers[key]["count"] += 1
		if m.is_visible_in_tree(): layers[key]["visible"] += 1
	var diagnostic := FileAccess.open("res://qa/whole_house/editor_camera_diagnostic.json",FileAccess.WRITE)
	diagnostic.store_string(JSON.stringify({"cameras":cameras,"mesh_layers":layers},"\t")+"\n")
	diagnostic.close()
	for sample in range(60):
		await get_tree().create_timer(3.0).timeout
		var view := EditorInterface.get_editor_viewport_3d(0)
		var cam := view.get_camera_3d()
		var live := FileAccess.open("res://qa/whole_house/editor_live_camera.json",FileAccess.WRITE)
		live.store_string(JSON.stringify({"position":cam.global_position,"rotation":cam.global_rotation,"mask":cam.cull_mask,"near":cam.near,"far":cam.far,"debug_draw":view.debug_draw,"size":cam.size,"fov":cam.fov,"projection":cam.projection},"\t")+"\n")
		live.close()
