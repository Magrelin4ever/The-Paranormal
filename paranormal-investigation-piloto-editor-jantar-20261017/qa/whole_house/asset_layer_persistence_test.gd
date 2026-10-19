extends SceneTree
## Execute com --headless --editor --script qa/whole_house/asset_layer_persistence_test.gd.
## Apenas cenas temporárias em user://; não modifica o layout do jogo.
const ASSETS := ["res://prototype/assets/models/innerscene/television-modern.glb", "res://prototype/whole_house/real_assets/Comoda_Profile_140.tscn"]
var cases: Array = []
var failures: Array = []
func _initialize() -> void: call_deferred("run")
func walk(n: Node) -> Array[Node]:
	var out: Array[Node] = [n]
	for c in n.get_children(): out.append_array(walk(c))
	return out
func execute_case(path: String, editable: bool, index: int) -> Dictionary:
	var scene := Node3D.new()
	scene.name = "Teste_Camadas"
	root.add_child(scene)
	var asset := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	asset.name = "Asset"
	scene.add_child(asset)
	asset.owner = scene
	if editable:
		for n in walk(asset):
			if not n.scene_file_path.is_empty(): scene.set_editable_instance(n,true)
	var count := 0
	for n in walk(asset):
		if n is VisualInstance3D:
			n.layers = 4
			count += 1
	var packed := PackedScene.new()
	var error := packed.pack(scene)
	var saved := "user://qa_asset_layers_%d.tscn" % index
	if error == OK: error = ResourceSaver.save(packed,saved)
	scene.free()
	var reopened := (ResourceLoader.load(saved,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
	var found := 0
	var incorrect: Array = []
	for n in walk(reopened.get_node("Asset")):
		if n is VisualInstance3D:
			found += 1
			if n.layers != 4: incorrect.append({"path":str(reopened.get_path_to(n)),"layer":n.layers})
	reopened.free()
	return {"asset":path,"editable_children":editable,"save_error":error,"before_visuals":count,"after_visuals":found,"incorrect_layers":incorrect,"persisted":error==OK and found==count and incorrect.is_empty()}
func run() -> void:
	if not Engine.is_editor_hint():
		push_error("Este teste precisa de --editor para simular as instâncias reais do viewport.")
		quit(2)
		return
	for path in ASSETS:
		var baseline := execute_case(path,false,cases.size())
		cases.append(baseline)
		var corrected := execute_case(path,true,cases.size())
		cases.append(corrected)
		if not corrected.persisted: failures.append("Camadas não persistem com editable_children: "+path)
	var f := FileAccess.open("res://qa/whole_house/asset_layer_persistence_results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"test":"asset_layer_persistence","engine":Engine.get_version_info().string,"editor_hint":Engine.is_editor_hint(),"cases":cases,"failures":failures,"passed":failures.is_empty()},"\t")+"\n")
	f.close()
	print("ASSET_LAYER_PERSISTENCE ","PASS" if failures.is_empty() else "FAIL", " failures=",failures)
	quit(0 if failures.is_empty() else 1)
