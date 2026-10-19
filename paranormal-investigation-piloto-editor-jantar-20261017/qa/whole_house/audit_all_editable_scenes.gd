extends SceneTree

## Auditoria independente, somente leitura, das cenas nativas editáveis da casa.
## Uso: godot --headless --path . --script res://qa/whole_house/audit_all_editable_scenes.gd
## Não chama builders, bake, finalize, polish ou refine; apenas carrega e inspeciona.
const ROOMS := "res://prototype/whole_house/rooms"
const MASTER := "res://prototype/whole_house/casa_editavel.tscn"
const ACTIVE := "res://prototype/house_environment.tscn"
const OUT := "res://qa/whole_house/all_editable_scenes_results.json"
var scenes: Array[String] = []
var result: Dictionary = {}

func _initialize() -> void:
    call_deferred("run_audit")

func _files(path: String) -> Array[String]:
    var out: Array[String] = []
    for f in DirAccess.get_files_at(path):
        if f.ends_with(".tscn"):
            out.append(path.path_join(f))
    for d in DirAccess.get_directories_at(path):
        out.append_array(_files(path.path_join(d)))
    out.sort()
    return out

func _rel(path: String) -> String:
    return path.trim_prefix("res://")

func _dep_paths(path: String) -> Array[String]:
    var out: Array[String] = []
    for raw in ResourceLoader.get_dependencies(path):
        for bit in raw.split("::"):
            if bit.begins_with("res://") and not out.has(bit):
                out.append(bit)
    return out

func _run_scene(path: String) -> Dictionary:
    var d := {"path": _rel(path), "load_ok": false, "instantiate_ok": false,
        "dependencies": 0, "missing_dependencies": [], "nodes": 0, "meshes": 0,
        "collision_bodies": 0, "collision_shapes": 0, "meshless_mesh_nodes": 0,
        "model_groups": 0, "groups_without_collision": [], "collision_exemptions": [],
        "collision_requirements": [], "edit_groups": 0,
        "nodes_without_owner": [], "meshes_owned_by_scene": 0,
        "errors": []}
    var missing: Array = []
    for dep in _dep_paths(path):
        d["dependencies"] += 1
        if not FileAccess.file_exists(dep):
            missing.append(_rel(dep))
    d["missing_dependencies"] = missing
    var packed := ResourceLoader.load(path) as PackedScene
    if packed == null:
        d["errors"].append("ResourceLoader.load retornou null")
        return d
    d["load_ok"] = true
    var root := packed.instantiate()
    if root == null:
        d["errors"].append("PackedScene.instantiate retornou null")
        return d
    d["instantiate_ok"] = true
    var model_collision: Dictionary = {}
    _walk(root, root, d, model_collision)
    # Modelo_ pode ser apenas uma submalha: a colisão pode ser sua irmã
    # dentro da raiz móvel (Console_Entrada/Banco_Sapateira, por exemplo).
    var movement_roots: Dictionary = {}
    for model in root.find_children("*", "Node3D", true, false):
        if not model.name.begins_with("Modelo_"): continue
        var movement: Node = model
        var ancestor := model.get_parent()
        while ancestor != null and ancestor != root:
            if ancestor.get_meta("_edit_group_", false):
                movement = ancestor
                break
            ancestor = ancestor.get_parent()
        movement_roots[movement.get_instance_id()] = movement
    for movement in movement_roots.values():
        var meshes: int = movement.find_children("*", "MeshInstance3D", true, false).size() + (1 if movement is MeshInstance3D else 0)
        var collisions: int = movement.find_children("*", "CollisionShape3D", true, false).size()
        if meshes > 0:
            d["model_groups"] += 1
            if collisions == 0:
                var label := _node_label(movement)
                var classification := _decoration_exemption(label)
                if classification.is_empty():
                    d["groups_without_collision"].append(label)
                    d["collision_requirements"].append({"path": label,
                        "classification": "collision_required",
                        "reason": "Modelo visual não é um pequeno adereço decorativo; exige StaticBody3D/CollisionShape3D filha individual."})
                else:
                    classification["path"] = label
                    d["collision_exemptions"].append(classification)
    root.free()
    return d

func _decoration_exemption(name: String) -> Dictionary:
    var n := name.to_lower()
    # Exceções são deliberadamente explícitas e individuais no JSON. Não incluir
    # móveis nem objetos grandes/operáveis aqui: a ausência de colisão deles
    # continua sendo um aviso real (TV, ventilador e luminária tripé incluídos).
    if n.contains("televis") or n.contains("tv") or n.contains("ventilador") or n.contains("fan") or n.contains("tripode") or n.contains("tripod"):
        return {}
    if n.contains("cortina") or n.contains("curtain"):
        return {"classification": "decorative_textile", "reason": "Cortina/tecido arquitetônico decorativo; pequeno detalhe visual sem interação prevista."}
    if n.contains("almofad") or n.contains("pillow") or n.contains("cushion") or n.contains("manta") or n.contains("blanket") or n.contains("throw"):
        return {"classification": "decorative_textile", "reason": "Almofada/manta decorativa sobre tecido; prop pequeno, sem bloqueio de passagem ou interação prevista."}
    if n.contains("quadro") or n.contains("picture") or n.contains("frame") or n.contains("book") or n.contains("livro") or n.contains("binder") or n.contains("notebook"):
        return {"classification": "decorative_small_prop", "reason": "Quadro/livro/pasta decorativo de pequena escala; detalhe visual apoiado ou afixado, sem interação prevista."}
    if n.contains("planta") or n.contains("plant") or n.contains("vase") or n.contains("vaso") or n.contains("decor"):
        return {"classification": "decorative_small_prop", "reason": "Planta/vaso/decoração pequena; adereço visual sem bloqueio de passagem ou interação prevista."}
    if n.contains("lamp") or n.contains("lumin") or n.contains("lustre"):
        return {"classification": "decorative_small_prop", "reason": "Lâmpada/luminária pequena de mesa; adereço visual sem interação prevista (luminária tripé é excluída desta isenção)."}
    if n.contains("food") or n.contains("apple") or n.contains("onion") or n.contains("alimento") or n.contains("comida") or n.contains("cutting") or n.contains("board") or n.contains("bowl") or n.contains("tigela"):
        return {"classification": "decorative_tabletop_prop", "reason": "Alimento/tábua/recipiente pequeno sobre bancada ou mesa; adereço de composição, sem interação prevista."}
    if n.contains("laptop") or n.contains("notebook"):
        return {"classification": "decorative_tabletop_prop", "reason": "Dispositivo pequeno apoiado sobre mesa; tratado como detalhe visual desta auditoria, sem interação prevista."}
    return {}

func _walk(node: Node, root: Node, d: Dictionary, model_collision: Dictionary) -> void:
    d["nodes"] += 1
    if node != root and node.owner == null:
        d["nodes_without_owner"].append(_node_label(node))
        d["errors"].append("Nó sem owner salvo: " + _node_label(node))
    if node is MeshInstance3D:
        d["meshes"] += 1
        if node.owner == root: d["meshes_owned_by_scene"] += 1
        if (node as MeshInstance3D).mesh == null:
            d["meshless_mesh_nodes"] += 1
            d["errors"].append("MeshInstance3D sem mesh: " + _node_label(node))
    if node is StaticBody3D or node is AnimatableBody3D:
        d["collision_bodies"] += 1
    if node is CollisionShape3D:
        d["collision_shapes"] += 1
    if node.get_meta("_edit_group_", false):
        d["edit_groups"] += 1
    var model := _nearest_model(node)
    if model != "":
        if not model_collision.has(model):
            model_collision[model] = {"meshes": 0, "collisions": 0}
        if node is MeshInstance3D:
            model_collision[model].meshes += 1
        if node is StaticBody3D or node is AnimatableBody3D or node is CollisionShape3D:
            model_collision[model].collisions += 1
    for child in node.get_children():
        _walk(child, root, d, model_collision)

func _nearest_model(node: Node) -> String:
    var cur: Node = node
    while cur != null:
        # Modelo_* são os agrupamentos de móveis/props. Peca_* inclui acabamento
        # arquitetônico (telhado, piso, trim etc.) e não exige colisão própria.
        if cur.name.begins_with("Modelo_"):
            return _node_label(cur)
        cur = cur.get_parent()
    return ""

func _node_label(node: Node) -> String:
    var names: Array[String] = []
    var cur: Node = node
    while cur != null:
        names.push_front(str(cur.name))
        cur = cur.get_parent()
    return "/".join(names)

func _master_checks() -> Dictionary:
    var m := {"load_ok": false, "instantiate_ok": false, "instance_count": 0,
        "editable_paths": 0, "invalid_editable_paths": [], "kitchen_present": false,
        "floor_scene_count": 0, "floor_layers": [], "errors": []}
    var text := FileAccess.get_file_as_string(MASTER)
    if text.is_empty():
        m.errors.append("master cena vazia/ausente")
        return m
    var instance_root: Node = null
    var packed := ResourceLoader.load(MASTER) as PackedScene
    if packed == null:
        m.errors.append("master ResourceLoader.load retornou null")
    else:
        m.load_ok = true
        var root := packed.instantiate()
        instance_root = root
        if root == null:
            m.errors.append("master instantiate retornou null")
        else:
            m.instantiate_ok = true
            m.instance_count = root.get_child_count()
            m.kitchen_present = root.get_node_or_null("Terreo/Cozinha_Richard") != null
    for line in text.split("\n"):
        var s := line.strip_edges()
        if s.begins_with("[editable path="):
            m.editable_paths += 1
            var p := s.trim_prefix("[editable path=\"").trim_suffix("\"]")
            if instance_root == null or p.is_empty() or not instance_root.has_node(NodePath(p)):
                m.invalid_editable_paths.append(p)
    for f in scenes:
        if f.get_file().contains("Pisos_E_Acabamentos"):
            m.floor_scene_count += 1
            m.floor_layers.append(f.get_file().get_basename().split("__")[0])
    m.floor_layers.sort()
    if instance_root != null: instance_root.free()
    m["active_scene_references_master"] = FileAccess.get_file_as_string(ACTIVE).contains("whole_house/casa_editavel.tscn")
    return m

func run_audit() -> void:
    scenes = _files(ROOMS)
    var rows: Array = []
    var load_failures := 0
    var missing_deps := 0
    var geometry_failures := 0
    var collision_group_failures := 0
    var total_meshes := 0
    var total_shapes := 0
    var total_bodies := 0
    var total_edit_groups := 0
    var ownerless_nodes := 0
    var native_owned_meshes := 0
    var decorative_exemptions := 0
    for path in scenes:
        var row := _run_scene(path)
        rows.append(row)
        if not row.load_ok or not row.instantiate_ok: load_failures += 1
        if row.missing_dependencies.size() > 0: missing_deps += 1
        if row.meshless_mesh_nodes > 0: geometry_failures += 1
        if row.groups_without_collision.size() > 0: collision_group_failures += 1
        total_meshes += row.meshes
        total_shapes += row.collision_shapes
        total_bodies += row.collision_bodies
        total_edit_groups += row.edit_groups
        ownerless_nodes += row.nodes_without_owner.size()
        native_owned_meshes += row.meshes_owned_by_scene
        decorative_exemptions += row.collision_exemptions.size()
    var master := _master_checks()
    var status := "PASS"
    if load_failures > 0 or missing_deps > 0 or geometry_failures > 0 or ownerless_nodes > 0 or not master.load_ok or not master.instantiate_ok or not master.kitchen_present or master.invalid_editable_paths.size() > 0 or not master.get("active_scene_references_master",false):
        status = "FAIL"
    elif collision_group_failures > 0:
        status = "WARN"
    result = {"status": status, "read_only": true, "time_limit_seconds": 30,
        "scope": {"active_scene": _rel(ACTIVE), "master_scene": _rel(MASTER), "rooms_root": _rel(ROOMS),
        "room_scene_count": scenes.size(), "all_room_scenes_audited": true},
        "counts": {"meshes": total_meshes, "collision_bodies": total_bodies, "collision_shapes": total_shapes, "edit_groups": total_edit_groups, "nodes_without_owner":ownerless_nodes,"meshes_owned_by_scene":native_owned_meshes, "decorative_collision_exemptions": decorative_exemptions},
        "master": master, "scenes": rows,
        "summary": {"load_failures": load_failures, "missing_dependency_scenes": missing_deps,
        "geometry_failures": geometry_failures, "model_groups_without_collision": collision_group_failures,
        "note": "Cada isenção decorativa é registrada individualmente por caminho, classificação e justificativa; móveis e objetos grandes/operáveis continuam exigindo colisão. Nenhum asset/cena/script de produção foi alterado."}}
    var out := FileAccess.open(OUT, FileAccess.WRITE)
    out.store_string(JSON.stringify(result, "\t") + "\n")
    out.close()
    print("WHOLE_HOUSE_EDITABLE_AUDIT status=%s scenes=%d meshes=%d bodies=%d shapes=%d load_failures=%d missing_deps=%d geometry_failures=%d collision_group_warnings=%d" % [status, scenes.size(), total_meshes, total_bodies, total_shapes, load_failures, missing_deps, geometry_failures, collision_group_failures])
    quit(0 if status != "FAIL" else 1)
