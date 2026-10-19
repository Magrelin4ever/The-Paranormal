extends SceneTree

const SCENE_PATH := "res://prototype/house_environment.tscn"
const JSON_PATH := "res://qa/whole_house/material_duplicate_results.json"
const LOG_PATH := "res://qa/whole_house/material_duplicate_results.log"
const EXCLUDED := {"resource_name": true, "resource_path": true, "resource_scene_unique_id": true}

var report := {
    "status": "running",
    "scene": SCENE_PATH,
    "mesh_instance_count": 0,
    "surface_count": 0,
    "material_reference_count": 0,
    "unique_material_instance_count": 0,
    "base_material_instance_count": 0,
    "shader_material_count": 0,
    "material_groups_exact": 0,
    "material_groups_with_duplicates": 0,
    "duplicate_material_instances": 0,
    "estimated_rid_reduction": 0,
    "texture_reference_count": 0,
    "unique_texture_instance_count": 0,
    "texture_groups_exact": 0,
    "texture_groups_with_duplicates": 0,
    "duplicate_texture_instances": 0,
    "resource_local_to_scene_true_count": 0,
    "next_pass_count": 0,
    "metadata_count": 0,
    "unreadable_image_count": 0,
    "warnings": [],
    "recommendation": ""
}
var logs: Array[String] = []
var material_fp_by_id := {}
var texture_fp_by_id := {}
var material_refs := {}
var texture_refs := {}
var material_groups := {}
var texture_groups := {}

func _init() -> void:
    _log("BEGIN material duplicate audit (read-only)")
    var scene := load(SCENE_PATH) as PackedScene
    if scene == null:
        _warn("Could not load native scene: %s" % SCENE_PATH)
        _finish(false)
        return
    var root := scene.instantiate()
    if root == null:
        _warn("Could not instantiate native scene")
        _finish(false)
        return
    _walk(root)
    _walk_node_resources(root)
    report["unique_material_instance_count"] = material_refs.size()
    report["unique_texture_instance_count"] = texture_refs.size()
    report["material_groups_exact"] = material_groups.size()
    report["texture_groups_exact"] = texture_groups.size()
    _summarize_groups(material_groups, "material")
    _summarize_groups(texture_groups, "texture")
    report["estimated_rid_reduction"] = report["duplicate_material_instances"]
    if report["duplicate_material_instances"] > 0:
        report["recommendation"] = "A canonical shared BaseMaterial3D per exact fingerprint could reduce approximately %d material RIDs without visual change, subject to local_to_scene/next_pass/metadata/ShaderMaterial review. No changes implemented." % report["estimated_rid_reduction"]
    else:
        report["recommendation"] = "No exact duplicate material fingerprints were found; do not canonicalize without further evidence. No changes implemented."
    if report["resource_local_to_scene_true_count"] > 0:
        _warn("resource_local_to_scene=true cases require per-instance preservation")
    if report["shader_material_count"] > 0:
        _warn("ShaderMaterial cases were detected; shader state is included in fingerprints but requires review")
    if report["next_pass_count"] > 0:
        _warn("next_pass references were detected")
    if report["unreadable_image_count"] > 0:
        _warn("Some Texture2D images could not be read")
    root.free()
    _finish(true)

func _walk(node: Node) -> void:
    if node is MeshInstance3D:
        report["mesh_instance_count"] += 1
        var mesh := (node as MeshInstance3D).mesh
        if mesh != null:
            for surface in range(mesh.get_surface_count()):
                report["surface_count"] += 1
                var mat := mesh.surface_get_material(surface)
                if mat != null:
                    _record_material(mat)
        for slot in range((node as MeshInstance3D).get_surface_override_material_count()):
            var override_mat := (node as MeshInstance3D).get_surface_override_material(slot)
            if override_mat != null:
                _record_material(override_mat)
    for child in node.get_children():
        _walk(child)

func _walk_node_resources(node: Node) -> void:
    if node.get_meta_list().size() > 0:
        report["metadata_count"] += node.get_meta_list().size()
    for child in node.get_children():
        _walk_node_resources(child)

func _record_material(mat: Material) -> void:
    report["material_reference_count"] += 1
    var id := mat.get_instance_id()
    material_refs[id] = true
    if material_fp_by_id.has(id):
        return
    if mat is BaseMaterial3D:
        report["base_material_instance_count"] += 1
    if mat is ShaderMaterial:
        report["shader_material_count"] += 1
    var fp := _material_fingerprint(mat)
    material_fp_by_id[id] = fp
    if not material_groups.has(fp): material_groups[fp] = []
    if not id in material_groups[fp]: material_groups[fp].append(id)
    _record_material_textures(mat)

func _record_material_textures(mat: Material) -> void:
    for p in mat.get_property_list():
        if (int(p.get("usage", 0)) & PROPERTY_USAGE_STORAGE) == 0: continue
        var n := String(p.get("name", ""))
        if EXCLUDED.has(n): continue
        var v = mat.get(n)
        _scan_value_for_textures(v)

func _scan_value_for_textures(v) -> void:
    if v is Texture2D:
        _record_texture(v)
    elif v is Resource:
        for p in v.get_property_list():
            if (int(p.get("usage", 0)) & PROPERTY_USAGE_STORAGE) != 0 and not EXCLUDED.has(String(p.get("name", ""))):
                _scan_value_for_textures(v.get(String(p.get("name", ""))))
    elif v is Array:
        for x in v: _scan_value_for_textures(x)
    elif v is Dictionary:
        for x in v.values(): _scan_value_for_textures(x)

func _record_texture(tex: Texture2D) -> void:
    report["texture_reference_count"] += 1
    var id := tex.get_instance_id()
    texture_refs[id] = true
    if texture_fp_by_id.has(id):
        return
    var fp := _texture_fingerprint(tex)
    texture_fp_by_id[id] = fp
    if not texture_groups.has(fp): texture_groups[fp] = []
    if not id in texture_groups[fp]: texture_groups[fp].append(id)

func _material_fingerprint(mat: Resource) -> String:
    var parts: Array[String] = [mat.get_class()]
    _resource_properties(mat, parts, {})
    return _sha256_text("|".join(parts))

func _resource_properties(res: Resource, parts: Array[String], seen: Dictionary) -> void:
    var id := res.get_instance_id()
    if seen.has(id):
        parts.append("cycle:%s" % id)
        return
    seen[id] = true
    if res.get_meta_list().size() > 0:
        report["metadata_count"] += res.get_meta_list().size()
    for p in res.get_property_list():
        var usage := int(p.get("usage", 0))
        var name := String(p.get("name", ""))
        if (usage & PROPERTY_USAGE_STORAGE) == 0 or EXCLUDED.has(name): continue
        var val = res.get(name)
        if name == "resource_local_to_scene" and bool(val):
            report["resource_local_to_scene_true_count"] += 1
        if name == "next_pass" and val != null:
            report["next_pass_count"] += 1
        parts.append(name + "=" + _value_fingerprint(val, seen))
    seen.erase(id)

func _value_fingerprint(v, seen: Dictionary) -> String:
    if v is Texture2D: return _texture_fingerprint(v)
    if v is Resource:
        if not (v is BaseMaterial3D) and not (v is ShaderMaterial):
            return "resource_ref{%s|path=%s|id=%s}" % [v.get_class(), v.resource_path, str(v.get_instance_id())]
        var rparts: Array[String] = [v.get_class()]
        _resource_properties(v, rparts, seen)
        return "resource{" + "|".join(rparts) + "}"
    if v is Array:
        var a: Array[String] = []
        for x in v: a.append(_value_fingerprint(x, seen))
        return "[" + ",".join(a) + "]"
    if v is Dictionary:
        var d: Array[String] = []
        for k in v.keys(): d.append(_value_fingerprint(k, seen) + ":" + _value_fingerprint(v[k], seen))
        d.sort()
        return "{" + ",".join(d) + "}"
    return var_to_bytes(v).hex_encode()

func _texture_fingerprint(tex: Texture2D) -> String:
    var image := tex.get_image()
    if image == null or image.is_empty():
        report["unreadable_image_count"] += 1
        return "texture-unreadable|" + tex.get_class() + "|" + tex.resource_path + "|" + str(tex.get_instance_id())
    var data := image.get_data()
    var h := HashingContext.new()
    h.start(HashingContext.HASH_SHA256)
    h.update(data)
    var digest := h.finish().hex_encode()
    return "Texture2D|format=%s|w=%d|h=%d|mipmaps=%s|bytes_sha256=%s" % [str(image.get_format()), image.get_width(), image.get_height(), str(image.has_mipmaps()), digest]

func _summarize_groups(groups: Dictionary, kind: String) -> void:
    var dup_groups := 0
    var dup_instances := 0
    for ids in groups.values():
        if ids.size() > 1:
            dup_groups += 1
            dup_instances += ids.size() - 1
    report[kind + "_groups_with_duplicates"] = dup_groups
    report["duplicate_" + kind + "_instances"] = dup_instances

func _sha256_text(s: String) -> String:
    var h := HashingContext.new()
    h.start(HashingContext.HASH_SHA256)
    h.update(s.to_utf8_buffer())
    return h.finish().hex_encode()

func _log(s: String) -> void:
    logs.append(s)
    print(s)

func _warn(s: String) -> void:
    report["warnings"].append(s)
    _log("WARNING: " + s)

func _finish(ok: bool) -> void:
    report["status"] = "ok" if ok else "error"
    report["warnings"] = report["warnings"]
    var json := JSON.stringify(report, "  ")
    var f := FileAccess.open(JSON_PATH, FileAccess.WRITE)
    if f:
        f.store_string(json + "\n")
        f.close()
    logs.append("END status=%s materials=%d exact_groups=%d duplicates=%d textures=%d" % [report["status"], report["unique_material_instance_count"], report["material_groups_exact"], report["duplicate_material_instances"], report["unique_texture_instance_count"]])
    var lf := FileAccess.open(LOG_PATH, FileAccess.WRITE)
    if lf:
        lf.store_string("\n".join(logs) + "\n")
        lf.close()
    print(logs[-1])
    quit(0 if ok else 1)
