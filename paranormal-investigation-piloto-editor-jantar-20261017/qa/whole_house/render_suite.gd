extends SceneTree
# Capturas reais do renderizador Compatibility; não são imagens promocionais.
const OUT := "res://qa/whole_house/previews/"
var house: Node3D
var player: CharacterBody3D
var camera: Camera3D

func _initialize() -> void:
	call_deferred("run")

func wait_render() -> void:
	for i in range(3):
		await process_frame
		await RenderingServer.frame_post_draw

func capture(label: String, eye: Vector3, target: Vector3, flashlight_on: bool = true) -> void:
	player.global_position = eye - Vector3(0, 1.6, 0)
	player.rotation = Vector3.ZERO
	player.head.rotation = Vector3.ZERO
	camera.look_at(target, Vector3.UP)
	player.set_flashlight_active(flashlight_on)
	await wait_render()
	var image := root.get_texture().get_image()
	var result := image.save_png(OUT + label + ".png")
	print("CAPTURE %s result=%s" % [label, result])

func run() -> void:
	root.size = Vector2i(960,540)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	house = load("res://prototype/house_environment.tscn").instantiate() as Node3D
	root.add_child(house)
	await process_frame
	await physics_frame
	house.set_process(false)
	player = house.get_node("Player") as CharacterBody3D
	player.set_process(false)
	player.set_physics_process(false)
	camera = player.camera
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var grain := house.get_node("FiltroCinematografico/VinhetaEGrãoSutil").material as ShaderMaterial
	grain.set_shader_parameter("grain_strength", 0.0)
	var samples := [
		["fachada",Vector3(9.0,3.0,21.0),Vector3(0,3,0)],
		["cozinha_preservada",Vector3(-2.6,1.65,-3.5),Vector3(-6.5,0.9,-6.0)],
		["sala_estar",Vector3(-2.9,1.65,3.8),Vector3(-6.7,0.9,6.5)],
		["jantar",Vector3(-2.6,1.65,1.6),Vector3(-5.8,0.9,-0.4)],
		["biblioteca",Vector3(2.5,1.65,2.0),Vector3(6.4,1.0,-1.0)],
		["quarto_infantil",Vector3(-2.6,4.45,-1.2),Vector3(-5.3,3.5,-3.7)],
		["suite_casal",Vector3(2.7,4.45,-1.2),Vector3(5.0,3.5,-4.5)],
		["closet_casal",Vector3(2.65,4.45,.55),Vector3(6.6,3.9,.6)],
		["closet_infantil",Vector3(-2.65,4.45,.55),Vector3(-6.6,3.9,.6)],
		["banheiro_suite",Vector3(2.75,4.5,5.5),Vector3(6.3,3.6,3.8)],
		["banheiro_familiar",Vector3(-2.75,4.5,5.5),Vector3(-6.3,3.6,3.8)],
		["area_servico",Vector3(2.7,1.65,-3.7),Vector3(6.4,1.0,-6.6)],
		["porao_oficina",Vector3(4.6,-1.20,-3.7),Vector3(2.7,-1.9,-6.7)],
		["porao_lavanderia",Vector3(-3.4,-1.20,-3.8),Vector3(-7,-1.9,-6.2)],
		["sotao_arquivo",Vector3(1.8,7.3,-1.0),Vector3(-4.3,6.4,-4.4)],
		["sotao_deposito",Vector3(2.5,7.3,1.0),Vector3(-5.5,6.5,4.2)],
	]
	var only := OS.get_environment("RENDER_ONLY")
	for sample in samples:
		if only.is_empty() or only == sample[0]: await capture(sample[0],sample[1],sample[2])
	if only.is_empty() or only == "lanterna":
		await capture("lanterna_on",Vector3(2.5,1.65,2.0),Vector3(6.4,1.0,-1.0),true)
		await capture("lanterna_off",Vector3(2.5,1.65,2.0),Vector3(6.4,1.0,-1.0),false)
	house.free()
	quit()
