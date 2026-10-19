extends CharacterBody3D

const VELOCIDADE := 3.5
const VELOCIDADE_CORRIDA := 5.8
const SENSIBILIDADE_MOUSE := 0.002
const GRAVIDADE := 9.8

var head: Node3D
var camera: Camera3D
var flashlight: SpotLight3D
var flashlight_mid: SpotLight3D
var flashlight_core: SpotLight3D
var flashlight_active := true
var _dica_porta: Label

func _ready() -> void:
	_configurar_entradas()
	_montar_corpo()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_flashlight_active(flashlight_active)

func _adicionar_tecla(acao: String, tecla: Key) -> void:
	if not InputMap.has_action(acao):
		InputMap.add_action(acao)
	for evento_existente in InputMap.action_get_events(acao):
		if evento_existente is InputEventKey and evento_existente.physical_keycode == tecla:
			return
	var evento := InputEventKey.new()
	evento.physical_keycode = tecla
	InputMap.action_add_event(acao, evento)

func _configurar_entradas() -> void:
	_adicionar_tecla("move_forward", KEY_W)
	_adicionar_tecla("move_back", KEY_S)
	_adicionar_tecla("move_left", KEY_A)
	_adicionar_tecla("move_right", KEY_D)
	_adicionar_tecla("sprint", KEY_SHIFT)
	_adicionar_tecla("toggle_flashlight", KEY_F)
	_adicionar_tecla("interagir", KEY_E)

func _montar_corpo() -> void:
	var colisor := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.35
	capsula.height = 1.7
	colisor.shape = capsula
	colisor.position.y = 0.85
	add_child(colisor)

	head = Node3D.new()
	head.position.y = 1.6
	add_child(head)

	camera = Camera3D.new()
	camera.fov = 75.0
	head.add_child(camera)

	flashlight = SpotLight3D.new()
	flashlight.name = "LanternaFeixeAmplo"
	flashlight.position = Vector3(0.2, -0.15, 0.0)
	flashlight.spot_range = 18.0
	flashlight.spot_angle = 38.0
	flashlight.spot_angle_attenuation = 0.8
	flashlight.spot_attenuation = 1.2
	flashlight.light_color = Color(0.82, 0.89, 1.0)
	flashlight.light_energy = 1.0
	flashlight.light_specular = 1.0
	flashlight.shadow_enabled = false
	camera.add_child(flashlight)
	flashlight_mid = SpotLight3D.new()
	flashlight_mid.name = "LanternaFaixaMedia"
	flashlight_mid.position = Vector3(0.2, -0.15, 0.0)
	flashlight_mid.spot_range = 17.0
	flashlight_mid.spot_angle = 23.0
	flashlight_mid.spot_angle_attenuation = 0.85
	flashlight_mid.spot_attenuation = 1.05
	flashlight_mid.light_color = Color(0.82, 0.89, 1.0)
	flashlight_mid.light_energy = 0.55
	flashlight_mid.light_specular = 1.0
	flashlight_mid.shadow_enabled = false
	camera.add_child(flashlight_mid)
	flashlight_core = SpotLight3D.new()
	flashlight_core.name = "LanternaNucleo"
	flashlight_core.position = Vector3(0.2, -0.15, 0.0)
	flashlight_core.spot_range = 16.0
	flashlight_core.spot_angle = 10.0
	flashlight_core.spot_angle_attenuation = 0.8
	flashlight_core.spot_attenuation = 1.0
	flashlight_core.light_color = Color(0.82, 0.89, 1.0)
	flashlight_core.light_energy = 0.65
	flashlight_core.light_specular = 1.0
	flashlight_core.shadow_enabled = true
	camera.add_child(flashlight_core)
	_criar_hud_interacao()

func set_flashlight_active(ativa: bool) -> void:
	flashlight_active = ativa
	if flashlight != null:
		flashlight.visible = ativa
	if flashlight_mid != null:
		flashlight_mid.visible = ativa
	if flashlight_core != null:
		flashlight_core.visible = ativa
	_atualizar_penumbra_lanterna()

func set_flashlight_falloff_material(material: ShaderMaterial) -> void:
	if camera == null:
		return
	camera.set_meta("c18_flashlight_material", material)
	_atualizar_penumbra_lanterna()

func _atualizar_penumbra_lanterna() -> void:
	if camera == null or not camera.has_meta("c18_flashlight_material"):
		return
	var material := camera.get_meta("c18_flashlight_material") as ShaderMaterial
	if material == null:
		return
	var ativa := flashlight_active and flashlight != null and flashlight_mid != null and flashlight_core != null and flashlight.is_visible_in_tree() and flashlight_mid.is_visible_in_tree() and flashlight_core.is_visible_in_tree()
	# O escurecimento base é sempre aplicado: desligar a lanterna não pode
	# remover o filtro e clarear a casa. Só a abertura do feixe acompanha o estado.
	material.set_shader_parameter("flashlight_darkening_active", 1.0)
	material.set_shader_parameter("flashlight_beam_enabled", 1.0 if ativa else 0.0)
	if not ativa:
		return
	var viewport_size := camera.get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var aspect := viewport_size.x / viewport_size.y
	var tan_half_vertical := tan(deg_to_rad(camera.fov) * 0.5)
	if camera.keep_aspect == Camera3D.KEEP_WIDTH:
		tan_half_vertical /= aspect
	var origin := flashlight_core.global_position
	var direction := -flashlight_core.global_transform.basis.z.normalized()
	var reference_distance := 4.0
	if get_world_3d() != null:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * flashlight_core.spot_range)
		query.collision_mask = 3
		query.collide_with_areas = false
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var hit_position: Vector3 = hit["position"]
			reference_distance = clampf(origin.distance_to(hit_position), 0.5, flashlight_core.spot_range)
	var projected := camera.unproject_position(origin + direction * reference_distance)
	var center := projected / viewport_size
	material.set_shader_parameter("flashlight_center", center)
	material.set_shader_parameter("flashlight_aspect", aspect)
	material.set_shader_parameter("flashlight_tan_half_fov", tan_half_vertical)

func _criar_hud_interacao() -> void:
	var camada := CanvasLayer.new()
	camada.name = "HUDInteracao"
	add_child(camada)
	var mira := Label.new()
	mira.text = "+"
	mira.set_anchors_preset(Control.PRESET_CENTER)
	mira.offset_left = -8.0
	mira.offset_top = -14.0
	mira.offset_right = 8.0
	mira.offset_bottom = 14.0
	mira.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mira.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mira.add_theme_color_override("font_color", Color(0.86, 0.9, 0.94, 0.75))
	mira.add_theme_color_override("font_outline_color", Color(0.02, 0.025, 0.035, 0.9))
	mira.add_theme_constant_override("outline_size", 2)
	camada.add_child(mira)
	_dica_porta = Label.new()
	_dica_porta.visible = false
	_dica_porta.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dica_porta.offset_left = -150.0
	_dica_porta.offset_top = -120.0
	_dica_porta.offset_right = 150.0
	_dica_porta.offset_bottom = -84.0
	_dica_porta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica_porta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dica_porta.add_theme_color_override("font_color", Color("f3efe6"))
	_dica_porta.add_theme_color_override("font_outline_color", Color(0.02, 0.025, 0.035, 0.98))
	_dica_porta.add_theme_constant_override("outline_size", 4)
	camada.add_child(_dica_porta)

func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-evento.relative.x * SENSIBILIDADE_MOUSE)
		head.rotate_x(-evento.relative.y * SENSIBILIDADE_MOUSE)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))
	if evento.is_action_pressed("toggle_flashlight"):
		if evento is InputEventKey and (evento as InputEventKey).echo:
			return
		set_flashlight_active(not flashlight_active)
	if evento.is_action_pressed("interagir"):
		if evento is InputEventKey and (evento as InputEventKey).echo:
			return
		_interagir_com_porta()
	if evento.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _porta_mirada() -> Node:
	if camera == null or get_world_3d() == null:
		return null
	var inicio := camera.global_position
	var fim := inicio - camera.global_transform.basis.z * 2.65
	var consulta := PhysicsRayQueryParameters3D.create(inicio, fim)
	consulta.collision_mask = 3
	consulta.collide_with_areas = true
	consulta.exclude = [get_rid()]
	var resultado := get_world_3d().direct_space_state.intersect_ray(consulta)
	if resultado.is_empty():
		return null
	var alvo := resultado.get("collider") as Node
	if alvo is Area3D:
		alvo = alvo.get_parent()
	return alvo if alvo != null and alvo.has_method("alternar") and alvo.has_method("texto_interacao") else null

func _interagir_com_porta() -> void:
	var porta := _porta_mirada()
	if porta != null:
		porta.call("alternar")

func _process(_delta: float) -> void:
	_atualizar_penumbra_lanterna()
	if _dica_porta == null:
		return
	var porta := _porta_mirada()
	if porta == null:
		_dica_porta.visible = false
		return
	_dica_porta.text = porta.call("texto_interacao")
	_dica_porta.visible = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVIDADE * delta
	var entrada := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direcao := (transform.basis * Vector3(entrada.x, 0.0, entrada.y)).normalized()
	var velocidade := VELOCIDADE_CORRIDA if Input.is_action_pressed("sprint") else VELOCIDADE
	velocity.x = direcao.x * velocidade
	velocity.z = direcao.z * velocidade
	move_and_slide()
