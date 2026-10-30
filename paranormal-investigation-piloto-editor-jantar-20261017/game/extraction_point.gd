extends Node3D

var manager: Node

func _ready() -> void:
	var area := Area3D.new()
	area.name = "AlvoInteracao"
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	add_child(area)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.95
	shape.shape = sphere
	shape.position.y = 0.9
	area.add_child(shape)
	var label := Label3D.new()
	label.name = "IdentificacaoVeiculo"
	label.text = "VAN  ·  RETORNO AO QG"
	label.position.y = 2.0
	label.font_size = 20
	label.pixel_size = 0.0035
	label.modulate = Color("e2c18d")
	label.outline_size = 5
	label.outline_modulate = Color("10141c")
	add_child(label)

func texto_interacao() -> String:
	return "E  ·  Encerrar visita e entregar relatório"

func interagir(_player: Node) -> void:
	if manager != null and manager.has_method("finish_investigation"):
		manager.call("finish_investigation")
