extends Node3D

@export var point_id: String = ""
@export var point_name: String = "Sinal anômalo"
@export var category: String = "field"
@export var floor_label: String = "Térreo"
@export_multiline var description: String = ""
@export_multiline var discovery_message: String = "Leitura registrada."
@export var required: bool = true

var manager: Node
var marker_mesh: MeshInstance3D
var registered := false

func _ready() -> void:
	var area := Area3D.new()
	area.name = "AlvoInteracao"
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	add_child(area)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.66
	shape.shape = sphere
	area.add_child(shape)
	marker_mesh = MeshInstance3D.new()
	marker_mesh.name = "FragmentoDeSinal"
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.16
	sphere_mesh.height = 0.32
	marker_mesh.mesh = sphere_mesh
	marker_mesh.position.y = 0.08
	var material := StandardMaterial3D.new()
	material.albedo_color = _color_for_category(category)
	material.roughness = 0.72
	marker_mesh.material_override = material
	add_child(marker_mesh)
	var label := Label3D.new()
	label.name = "TipoDeSinal"
	label.text = _label_for_category(category)
	label.position = Vector3(0, 0.42, 0)
	label.font_size = 24
	label.pixel_size = 0.0035
	label.modulate = Color("d8dce2")
	label.outline_size = 4
	label.outline_modulate = Color("10141c")
	add_child(label)

func texto_interacao() -> String:
	if registered:
		return "Sinal já registrado"
	var state := _state()
	var item_name := str(state.call("get_active_equipment_name")) if state != null else "instrumento"
	return "E  ·  Examinar sinal  [%s]" % item_name

func interagir(_player: Node) -> void:
	if manager != null and manager.has_method("examine_point"):
		manager.call("examine_point", self)

func data() -> Dictionary:
	return {"id": point_id, "name": point_name, "category": category, "floor": floor_label, "description": description, "discovery_message": discovery_message, "required": required}

func mark_registered() -> void:
	registered = true
	if marker_mesh != null and marker_mesh.material_override is StandardMaterial3D:
		(marker_mesh.material_override as StandardMaterial3D).albedo_color = Color("758b75")

func _state() -> Node:
	return get_node_or_null("/root/GameState")

func _color_for_category(value: String) -> Color:
	match value:
		"cold": return Color("95bfd0")
		"voice": return Color("c8b398")
		"visual": return Color("aaa7c9")
		_: return Color("b89056")

func _label_for_category(value: String) -> String:
	match value:
		"cold": return "FRIO"
		"voice": return "ÁUDIO"
		"visual": return "IMAGEM"
		_: return "CAMPO"
