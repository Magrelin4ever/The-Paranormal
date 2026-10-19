extends SceneTree
## Mede AABBs visuais em coordenadas locais da raiz Modelo_* alvo.
## Uso: godot --headless --path . --script res://qa/whole_house/measure_target_aabbs.gd
const SCENE := "res://prototype/whole_house/rooms/terreo__Sala_Estar.tscn"
const TARGETS := [
    "Modelo_TelevisaoSala_027",
    "Modelo_LuminariaTripodeSala_043",
    "Modelo_VentiladorSala_044",
]

func _initialize() -> void:
    var packed := ResourceLoader.load(SCENE) as PackedScene
    if packed == null:
        push_error("Falha carregando " + SCENE)
        quit(1)
        return
    var root := packed.instantiate()
    get_root().add_child(root)
    call_deferred("_measure", root)

func _measure(root: Node3D) -> void:
    for target_name in TARGETS:
        var target := root.get_node_or_null(NodePath(target_name)) as Node3D
        if target == null:
            push_error("Alvo ausente: " + target_name)
            continue
        var local_aabb := _visual_aabb_in_target(target)
        print("%s min=%s max=%s size=%s center=%s" % [
            target_name, local_aabb.position, local_aabb.end, local_aabb.size, local_aabb.get_center()
        ])
    root.free()
    quit()

func _visual_aabb_in_target(target: Node3D) -> AABB:
    var result := AABB()
    var initialized := false
    for node in target.find_children("*", "MeshInstance3D", true, false):
        var mesh_node := node as MeshInstance3D
        if mesh_node == null or mesh_node.mesh == null:
            continue
        var aabb_in_target: AABB = target.global_transform.affine_inverse() * (mesh_node.global_transform * mesh_node.get_aabb())
        if not initialized:
            result = aabb_in_target
            initialized = true
        else:
            result = result.merge(aabb_in_target)
    return result
