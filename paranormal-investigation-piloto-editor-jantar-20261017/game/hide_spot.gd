extends Node3D

var manager: Node
var marker_label: Label3D

func _ready() -> void:
	var area := Area3D.new()
	area.name = "AlvoInteracao"
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	add_child(area)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.78
	shape.shape = sphere
	shape.position.y = 0.85
	area.add_child(shape)
	marker_label = Label3D.new()
	marker_label.name = "IndicadorAbrigo"
	marker_label.text = "ABRIGO"
	marker_label.position.y = 1.85
	marker_label.font_size = 18
	marker_label.pixel_size = 0.003
	marker_label.modulate = Color("c8c4b8")
	marker_label.outline_size = 4
	marker_label.outline_modulate = Color("10141c")
	add_child(marker_label)

func texto_interacao() -> String:
	return "E  ·  Esconder-se"

func interagir(player: Node) -> void:
	if manager != null and manager.has_method("enter_hide_spot"):
		manager.call("enter_hide_spot", self, player)
