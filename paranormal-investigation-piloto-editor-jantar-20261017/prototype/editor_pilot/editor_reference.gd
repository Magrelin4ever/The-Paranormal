@tool
extends Node3D
# Referência estrutural somente no editor. A estrutura jogável original é mantida.
func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		visible = false
		queue_free()
