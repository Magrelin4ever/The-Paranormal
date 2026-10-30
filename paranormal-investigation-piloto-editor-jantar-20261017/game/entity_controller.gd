extends Node3D

var player: CharacterBody3D
var manager: Node
var active := false
var speed := 1.25
var floor_height := 0.0
var close_reported := false

func _ready() -> void:
	floor_height = global_position.y

func _process(delta: float) -> void:
	if not active or not is_instance_valid(player):
		return
	if manager != null and bool(manager.get("is_hiding")):
		return
	var to_player := player.global_position - global_position
	if absf(to_player.y) > 1.8:
		return
	to_player.y = 0.0
	var distance := to_player.length()
	if distance > 15.0:
		active = false
		visible = false
		if manager != null and manager.has_method("entity_escaped"):
			manager.call("entity_escaped", self)
		return
	if distance > 0.05:
		global_position += to_player.normalized() * speed * delta
	if distance < 1.35 and not close_reported:
		close_reported = true
		if manager != null and manager.has_method("entity_reached_player"):
			manager.call("entity_reached_player", self)

func activate(target: CharacterBody3D, owner_manager: Node) -> void:
	player = target
	manager = owner_manager
	active = true
	visible = true
	close_reported = false
