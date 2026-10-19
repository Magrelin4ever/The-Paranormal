extends SceneTree
var house: Node3D
var player: CharacterBody3D
var results: Array = []
var failures: Array[String] = []
const DT := 1.0/60.0
func _initialize() -> void:
	call_deferred("run")
func walk(label: String, start: Vector3, goal: Vector3) -> void:
	print("STAIR_ROUTE_START "+label)
	Input.action_release("move_forward")
	player.global_position = start
	player.velocity = Vector3.ZERO
	for i in range(30):
		await physics_frame
		player.call("_physics_process",DT)
	var trace: Array = []
	var reached := false
	var min_y := player.position.y
	var colliders: Dictionary = {}
	for frame in range(720):
		var p := player.global_position
		var distance := Vector2(p.x,p.z).distance_to(Vector2(goal.x,goal.z))
		if distance < .16 and absf(p.y-goal.y)<.22:
			reached = true
			break
		if p.y < minf(start.y,goal.y)-.8: break
		player.look_at(Vector3(goal.x,p.y,goal.z),Vector3.UP)
		Input.action_press("move_forward")
		await physics_frame
		player.call("_physics_process",DT)
		min_y = minf(min_y,player.position.y)
		if frame%15 == 0: trace.append([player.position.x,player.position.y,player.position.z])
		for i in range(player.get_slide_collision_count()):
			var c := player.get_slide_collision(i).get_collider() as Node
			if c != null: colliders[str(c.get_path())] = true
	Input.action_release("move_forward")
	var end := player.global_position
	results.append({"route":label,"start":[start.x,start.y,start.z],"goal":[goal.x,goal.y,goal.z],"end":[end.x,end.y,end.z],"min_y":min_y,"passed":reached,"trace":trace,"colliders":colliders.keys()})
	if not reached: failures.append(label+" terminou em "+str(end))
	print("STAIR_ROUTE_%s %s end=%s" % ["PASS" if reached else "FAIL",label,end])
func run() -> void:
	house = load("res://prototype/house_environment.tscn").instantiate() as Node3D
	root.add_child(house)
	await process_frame
	await physics_frame
	house.set_process(false)
	player = house.get_node("Player") as CharacterBody3D
	player.set_process(false)
	player.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for n in house.find_children("*","AnimatableBody3D",true,false):
		n.rotation.y += deg_to_rad(float(n.get("angulo_abertura_graus")))
	await physics_frame
	await walk("terreo_para_primeiro",Vector3(0,.06,3.55),Vector3(0,2.85,-1.6))
	await walk("primeiro_para_terreo",Vector3(0,2.91,-1.6),Vector3(0,0,3.55))
	await walk("primeiro_para_sotao",Vector3(0,2.91,5.15),Vector3(0,5.7,.72))
	await walk("sotao_para_primeiro",Vector3(0,5.76,.72),Vector3(0,2.85,5.15))
	await walk("porao_para_terreo",Vector3(7.8,-2.79,-7.45),Vector3(7.8,0,-3.45))
	await walk("terreo_para_porao",Vector3(7.8,.06,-3.45),Vector3(7.8,-2.85,-7.45))
	var f := FileAccess.open("res://qa/whole_house/stair_navigation_results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"test":"real_player_stair_navigation","engine":Engine.get_version_info().string,"movement":"house_player._physics_process; W; capsule original 0.35/1.7; gravidade original; sem teleportar dentro de uma rota","routes":results,"failures":failures,"passed":failures.is_empty()},"\t")+"\n")
	house.free()
	print("STAIR_NAVIGATION_%s routes=%d" % ["PASS" if failures.is_empty() else "FAIL",results.size()])
	quit(0 if failures.is_empty() else 1)
