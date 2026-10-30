extends StaticBody3D

@export var console_id: String = "briefing"
@export var console_label: String = "Abrir terminal"

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

func texto_interacao() -> String:
	return "E  ·  " + console_label

func interagir(_player: Node) -> void:
	var headquarters := get_tree().get_first_node_in_group("headquarters_manager")
	if headquarters != null and headquarters.has_method("open_console"):
		headquarters.call("open_console", console_id)
