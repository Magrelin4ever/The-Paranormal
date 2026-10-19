extends Node3D

# Protótipo visual independente, sem lógica de investigação ou rede.
const ScriptJogador = preload("res://prototype/house_player.gd")

const MEIA_LARGURA_CASA := 9.3
const MEIA_PROFUNDIDADE_CASA := 8.0
const MEIA_LARGURA_ANDAR := 7.6
const MEIA_PROFUNDIDADE_ANDAR := 6.2
const MEIA_LARGURA_CORREDOR := 1.85
const ALTURA_ANDAR := 2.85
const ALTURA_PAREDE := 2.85
const ESPESSURA_PAREDE := 0.22
const ESPESSURA_LAJE := 0.20
const LARGURA_ESCADA := 1.48
const IDS_PAVIMENTOS: Array[StringName] = [&"porao", &"terreo", &"primeiro", &"sotao"]

var _materiais: Dictionary = {}
var _ferramentas_superficie: Dictionary = {}
var _corpos_colisao: Dictionary = {}
var _raiz_visual: Node3D
var _jogador: CharacterBody3D
var _audio_passos: AudioStreamPlayer3D
var _fase_caminhada := 0.0
var _temporizador_passos := 0.0
var _posicao_repouso_cabeca := Vector3(0.0, 1.6, 0.0)
var _inclinacao_repouso_cabeca := 0.0
var _contador_modelos := 0
var _contador_pratos_jantar := 0
var _feixes_lanterna_c15: Array[SpotLight3D] = []

const C15_LANTERNA_BASE := [1.0, 0.55, 0.65]
const C15_LANTERNA_LOCAL := [1.0, 0.50, 0.38]

func _ready() -> void:
	# Fonte única de layout: cenas persistentes, editáveis no viewport 3D.
	# O construtor legado abaixo é mantido apenas para histórico/ferramentas offline.
	_raiz_visual = get_node_or_null("Casa_Editavel") as Node3D
	if _raiz_visual == null:
		push_error("Casa_Editavel ausente. Abra prototype/house_environment.tscn.")
		return
	_criar_ambiente()
	_apagar_luzes_internas()
	_criar_ambiencia()
	_posicionar_jogador()
	_montar_dica_controles()
	_montar_filtro_visual()

func _construir_legado_apenas_ferramentas() -> void:
	_criar_materiais()
	_raiz_visual = Node3D.new()
	_raiz_visual.name = "AmbienteDaCasa"
	add_child(_raiz_visual)
	_criar_corpos_colisao()
	_criar_ambiente()
	_montar_pisos_e_estrutura()
	_montar_paredes_internas()
	_montar_escadas()
	_montar_telhado_exterior()
	_mobiliar_porao()
	_mobiliar_terreo()
	_mobiliar_primeiro_andar()
	_mobiliar_sotao()
	_montar_vizinhanca()
	_finalizar_malhas_visuais()
	_criar_ambiencia()
	_apagar_luzes_internas()
	_posicionar_jogador()
	_montar_dica_controles()
	_montar_filtro_visual()

func _atualizar_lanterna_escritorio_c15() -> void:
	# Só o núcleo/média da lanterna do jogador mudam neste volume; zero nova luz.
	# O halo amplo mantém energia para preservar a leitura de rota e saída.
	if _jogador == null:
		return
	if _feixes_lanterna_c15.is_empty():
		for propriedade in ["flashlight", "flashlight_mid", "flashlight_core"]:
			var feixe := _jogador.get(propriedade) as SpotLight3D
			if feixe != null:
				_feixes_lanterna_c15.append(feixe)
	if _feixes_lanterna_c15.size() != 3:
		return
	var p := _jogador.global_position
	var peso := 0.0
	if p.y >= -0.1 and p.y <= 0.5:
		peso = minf(minf(smoothstep(1.96, 2.41, p.x), 1.0 - smoothstep(8.74, 9.19, p.x)), minf(smoothstep(2.61, 3.06, p.z), 1.0 - smoothstep(7.44, 7.89, p.z)))
	for indice in range(3):
		_feixes_lanterna_c15[indice].light_energy = lerpf(float(C15_LANTERNA_BASE[indice]), float(C15_LANTERNA_LOCAL[indice]), peso)
	# Não toca visible/flashlight_active: entrar aqui nunca religa uma lanterna apagada.

func _criar_materiais() -> void:
	_adicionar_material(&"wall_ivory", Color("827d75"), 0.96)
	_adicionar_material(&"wall_basement", Color("686d70"), 0.98)
	_adicionar_material(&"wall_attic", Color("756f67"), 0.98)
	_adicionar_material(&"ceiling", Color("696760"), 0.98)
	_adicionar_material(&"wood_floor", Color("655242"), 0.93)
	_adicionar_material(&"wood_floor_alt", Color("59483b"), 0.94)
	_adicionar_material(&"wood_seam", Color("3d332c"), 0.99)
	_adicionar_material(&"tile", Color("686b6b"), 0.88)
	_adicionar_material(&"tile_alt", Color("595d60"), 0.9)
	_adicionar_material(&"kitchen_floor", Color("363b3e"), 0.82)
	_adicionar_material(&"kitchen_cabinet", Color("34383a"), 0.76)
	_adicionar_material(&"kitchen_front", Color("2c3032"), 0.62)
	_adicionar_material(&"kitchen_counter", Color("4b4e4e"), 0.64)
	_adicionar_material(&"kitchen_appliance_glass", Color("080b0d"), 0.20)
	_adicionar_material(&"kitchen_cookware", Color("303438"), 0.60)
	_adicionar_material(&"kitchen_wood", Color("4a3e32"), 0.78)
	_adicionar_material(&"kitchen_hardware", Color("777d80"), 0.44)
	_adicionar_material(&"kitchen_reveal", Color("0b0e10"), 0.62)
	_adicionar_material(&"kitchen_ceramic", Color("a29d93"), 0.48)
	_adicionar_material(&"kitchen_ceramic_dark", Color("464a4b"), 0.50)
	_adicionar_material(&"kitchen_coffee", Color("21170f"), 0.38)
	_adicionar_material(&"kitchen_linen", Color("7e766a"), 0.96)
	_adicionar_material(&"kitchen_spice_label", Color("a39a83"), 0.88)
	_adicionar_material(&"kitchen_stool_seat", Color("51483f"), 0.72)
	_adicionar_material(&"concrete", Color("505458"), 0.98)
	_adicionar_material(&"attic_wood", Color("51463b"), 0.98)
	_adicionar_material(&"trim", Color("72685c"), 0.9)
	_adicionar_material(&"trim_light", Color("8e8577"), 0.92)
	_adicionar_material(&"door_wood", Color("493b31"), 0.91)
	_adicionar_material(&"siding", Color("494e53"), 0.96)
	_adicionar_material(&"siding_alt", Color("55595d"), 0.95)
	_adicionar_material(&"roof", Color("30343a"), 0.98)
	_adicionar_material(&"roof_edge", Color("24282e"), 0.99)
	_adicionar_material(&"glass", Color(0.018, 0.035, 0.055, 0.34), 0.2, 0.0, BaseMaterial3D.TRANSPARENCY_ALPHA)
	_adicionar_material(&"metal", Color("555a5d"), 0.7)
	_adicionar_material(&"metal_dark", Color("303438"), 0.78)
	_adicionar_material(&"door_hardware", Color("8f7855"), 0.36)
	var hardware := _materiais[&"door_hardware"] as StandardMaterial3D
	hardware.metallic = 0.62
	var kitchen_hardware := _materiais[&"kitchen_hardware"] as StandardMaterial3D
	kitchen_hardware.metallic = 0.64
	kitchen_hardware.roughness = 0.44
	var kitchen_cookware := _materiais[&"kitchen_cookware"] as StandardMaterial3D
	kitchen_cookware.metallic = 0.18
	kitchen_cookware.roughness = 0.60
	var kitchen_front := _materiais[&"kitchen_front"] as StandardMaterial3D
	kitchen_front.metallic = 0.04
	kitchen_front.clearcoat_enabled = false
	kitchen_front.clearcoat = 0.0
	kitchen_front.roughness = 0.62
	var kitchen_wood := _materiais[&"kitchen_wood"] as StandardMaterial3D
	kitchen_wood.clearcoat_enabled = false
	kitchen_wood.clearcoat = 0.0
	kitchen_wood.roughness = 0.76
	var kitchen_ceramic := _materiais[&"kitchen_ceramic"] as StandardMaterial3D
	kitchen_ceramic.clearcoat_enabled = false
	kitchen_ceramic.clearcoat = 0.0
	kitchen_ceramic.roughness = 0.48
	var kitchen_ceramic_dark := _materiais[&"kitchen_ceramic_dark"] as StandardMaterial3D
	kitchen_ceramic_dark.roughness = 0.50
	_aplicar_textura_pbr(&"kitchen_floor", "wood_floor", Color(0.60, 0.53, 0.46))
	_aplicar_textura_ambientcg(&"kitchen_counter", "Marble002", Color(0.60, 0.61, 0.60))
	var kitchen_counter_pbr := _materiais[&"kitchen_counter"] as StandardMaterial3D
	kitchen_counter_pbr.roughness = 0.62
	kitchen_counter_pbr.normal_scale = 0.36
	kitchen_counter_pbr.ao_light_affect = 0.18
	kitchen_counter_pbr.albedo_texture = load("res://prototype/assets/textures/ambientcg/Marble002/Marble002_Kitchen_Color_2K.jpg") as Texture2D
	kitchen_counter_pbr.albedo_color = Color(0.92, 0.92, 0.90)
	_aplicar_textura_ambientcg(&"kitchen_wood", "Wood026", Color(0.68, 0.56, 0.44))
	var kitchen_wood_pbr := _materiais[&"kitchen_wood"] as StandardMaterial3D
	kitchen_wood_pbr.roughness = 0.76
	kitchen_wood_pbr.normal_scale = 0.64
	kitchen_wood_pbr.ao_light_affect = 0.20
	_adicionar_material(&"fabric_navy", Color("343f50"), 0.98)
	_adicionar_material(&"fabric_ochre", Color("71634e"), 0.98)
	_adicionar_material(&"fabric_rose", Color("694f54"), 0.98)
	_adicionar_material(&"fabric_sage", Color("596657"), 0.98)
	_adicionar_material(&"wood_warm", Color("584638"), 0.9)
	_adicionar_material(&"wood_light", Color("796753"), 0.91)
	_adicionar_material(&"upholstery", Color("555858"), 0.99)
	_adicionar_material(&"linen", Color("817d73"), 0.98)
	_adicionar_material(&"linen_blue", Color("4d5e70"), 0.98)
	_adicionar_material(&"linen_mauve", Color("755d68"), 0.98)
	_adicionar_material(&"linen_cream", Color("988b76"), 0.98)
	_adicionar_material(&"rug", Color("514b46"), 0.99)
	_adicionar_material(&"rug_detail", Color("756855"), 0.99)
	_adicionar_material(&"rug_living", Color("383c44"), 0.99)
	_adicionar_material(&"dining_rug", Color.WHITE, 0.99)
	_aplicar_textura_ambientcg(&"dining_rug", "Carpet012", Color.WHITE)
	var dining_rug_material := _materiais[&"dining_rug"] as StandardMaterial3D
	dining_rug_material.uv1_scale = Vector3(1.9, 1.0, 1.75)
	_adicionar_material(&"library_rug", Color.WHITE, 0.99)
	_aplicar_textura_ambientcg(&"library_rug", "Carpet012", Color(0.72, 0.65, 0.56, 1.0))
	var library_rug_material := _materiais[&"library_rug"] as StandardMaterial3D
	library_rug_material.uv1_scale = Vector3(1.7, 1.0, 1.55)
	library_rug_material.normal_scale = 0.36
	library_rug_material.roughness = 0.98
	library_rug_material.ao_light_affect = 0.25
	_adicionar_material(&"office_rug", Color.WHITE, 0.99)
	_aplicar_textura_ambientcg(&"office_rug", "Carpet012", Color(0.84, 0.75, 0.62, 1.0))
	var office_rug_material := _materiais[&"office_rug"] as StandardMaterial3D
	office_rug_material.uv1_scale = Vector3(1.55, 1.0, 1.4)
	office_rug_material.normal_scale = 0.34
	office_rug_material.roughness = 0.98
	office_rug_material.ao_light_affect = 0.25
	_adicionar_material(&"dining_plate", Color("5f584d"), 0.76)
	_adicionar_material(&"dining_child_cup", Color("747866"), 0.76)
	_adicionar_material(&"dining_cup_interior", Color("292722"), 0.92)
	_adicionar_material(&"dining_napkin", Color("625b50"), 0.94)
	_adicionar_material(&"dining_napkin_fold", Color("756c5e"), 0.94)
	for material_key in [&"dining_plate", &"dining_child_cup", &"dining_cup_interior", &"dining_napkin", &"dining_napkin_fold"]:
		var dining_detail_material := _materiais[material_key] as StandardMaterial3D
		dining_detail_material.metallic = 0.0
		dining_detail_material.clearcoat_enabled = false
		dining_detail_material.emission_enabled = false
		_adicionar_material(&"ceramic", Color("777775"), 0.78)
	_adicionar_material(&"porcelain", Color("a09b8e"), 0.72)
	_adicionar_material(&"dark_screen", Color("080b10"), 0.28)
	_adicionar_material(&"paper", Color("8a806e"), 0.95)
	_adicionar_material(&"toy_blue", Color("46617a"), 0.9)
	_adicionar_material(&"toy_red", Color("76514d"), 0.9)
	_adicionar_material(&"toy_yellow", Color("8a7855"), 0.9)
	_adicionar_material(&"toy_green", Color("50614f"), 0.92)
	_adicionar_material(&"grass", Color("222b2c"), 1.0)
	_adicionar_material(&"grass_alt", Color("293231"), 1.0)
	_adicionar_material(&"wood_shelf", Color("584638"), 0.9)
	_adicionar_material(&"wood_lacquer", Color("584638"), 0.42)
	_adicionar_material(&"driveway", Color("373b40"), 0.98)
	_adicionar_material(&"road", Color("282d34"), 0.99)
	_adicionar_material(&"fence", Color("34393b"), 0.99)
	_adicionar_material(&"tree_bark", Color("332d2a"), 1.0)
	_adicionar_material(&"tree_leaf", Color("26312f"), 1.0)
	_adicionar_material(&"car_body", Color("35434d"), 0.58)
	_adicionar_material(&"car_glass", Color("111a23"), 0.34)
	_adicionar_material(&"moon", Color("8990a1"), 0.9, 0.28)
	_adicionar_material(&"star", Color("7f91b0"), 0.7, 0.8)
	_aplicar_textura_pbr(&"wall_ivory", "beige_wall_001", Color(0.9, 0.87, 0.81))
	_aplicar_textura_pbr(&"wood_floor", "wood_floor", Color(0.95, 0.92, 0.86))
	_aplicar_textura_pbr(&"tile", "brown_floor_tiles", Color(0.95, 0.92, 0.88))
	_aplicar_textura_pbr(&"concrete", "concrete_floor_01", Color(0.88, 0.9, 0.91))
	_aplicar_textura_pbr(&"wood_shelf", "wood_floor", Color(0.68, 0.54, 0.42))
	_aplicar_textura_pbr(&"wood_lacquer", "wood_floor", Color(0.68, 0.54, 0.42))
	_aplicar_textura_ambientcg(&"rug_living", "Carpet012", Color(0.90, 0.86, 0.79))

func _adicionar_material(key: StringName, color: Color, roughness: float = 0.94, emission: float = 0.0, transparency_mode: int = BaseMaterial3D.TRANSPARENCY_DISABLED) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = transparency_mode
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	_materiais[key] = material
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	_ferramentas_superficie[key] = surface

func _aplicar_textura_pbr(material_key: StringName, textura_id: String, tonalidade: Color = Color.WHITE) -> void:
	var material := _materiais.get(material_key) as StandardMaterial3D
	if material == null:
		return
	var caminho := "res://prototype/assets/textures/polyhaven/%s/%s" % [textura_id, textura_id]
	material.albedo_texture = load("%s_diff_2k.jpg" % caminho) as Texture2D
	material.normal_texture = load("%s_nor_gl_2k.jpg" % caminho) as Texture2D
	material.normal_enabled = material.normal_texture != null
	material.normal_scale = 0.78
	material.roughness_texture = load("%s_rough_2k.jpg" % caminho) as Texture2D
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.ao_texture = load("%s_ao_2k.jpg" % caminho) as Texture2D
	material.ao_enabled = material.ao_texture != null
	material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.ao_light_affect = 0.35
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.albedo_color = tonalidade

func _aplicar_textura_ambientcg(material_key: StringName, textura_id: String, tonalidade: Color = Color.WHITE) -> void:
	var material := _materiais.get(material_key) as StandardMaterial3D
	if material == null:
		return
	var caminho := "res://prototype/assets/textures/ambientcg/%s/%s" % [textura_id, textura_id]
	material.albedo_texture = load("%s_Color_2K.jpg" % caminho) as Texture2D
	material.normal_texture = load("%s_NormalGL_2K.jpg" % caminho) as Texture2D
	material.normal_enabled = material.normal_texture != null
	material.normal_scale = 0.48
	material.roughness_texture = load("%s_Roughness_2K.jpg" % caminho) as Texture2D
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	var caminho_ao := "%s_AO_2K.jpg" % caminho
	material.ao_texture = load(caminho_ao) as Texture2D if ResourceLoader.exists(caminho_ao) else null
	material.ao_enabled = material.ao_texture != null
	material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.ao_light_affect = 0.34
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.albedo_color = tonalidade

func _criar_corpos_colisao() -> void:
	for floor_id in IDS_PAVIMENTOS:
		var body := StaticBody3D.new()
		body.name = "Colisoes_%s" % String(floor_id)
		body.collision_layer = 1
		body.collision_mask = 1
		add_child(body)
		_corpos_colisao[floor_id] = body
	var outside := StaticBody3D.new()
	outside.name = "Colisoes_Exterior"
	outside.collision_layer = 1
	outside.collision_mask = 1
	add_child(outside)
	_corpos_colisao[&"exterior"] = outside

func _criar_ambiente() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("07101d")
	sky_material.sky_horizon_color = Color("171c29")
	sky_material.ground_bottom_color = Color("070a10")
	sky_material.ground_horizon_color = Color("141821")
	sky_material.energy_multiplier = 0.58
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("53617a")
	environment.ambient_light_energy = 0.36
	environment.ambient_light_sky_contribution = 0.0
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("111722")
	environment.fog_density = 0.004
	var world := WorldEnvironment.new()
	world.name = "NoiteSemEnergia"
	world.environment = environment
	add_child(world)
	var moonlight := DirectionalLight3D.new()
	moonlight.name = "LuarFrio"
	moonlight.rotation_degrees = Vector3(-38.0, 26.0, 0.0)
	moonlight.light_color = Color("aab8d1")
	moonlight.light_energy = 0.28
	moonlight.shadow_enabled = true
	moonlight.directional_shadow_max_distance = 45.0
	add_child(moonlight)

func _montar_pisos_e_estrutura() -> void:
	var abertura_escada_principal := {"center": Vector2(0.0, 1.0), "size": Vector2(2.0, 4.4)}
	var abertura_escada_porao := {"center": Vector2(7.8, -5.6), "size": Vector2(2.0, 3.2)}
	var abertura_escada_sotao := {"center": Vector2(0.0, 2.95), "size": Vector2(2.0, 4.1)}
	var abertura_escada_principal_superior := {"center": Vector2(0.0, 1.0), "size": Vector2(2.0, 4.4)}
	_montar_laje_piso(&"porao", -ALTURA_ANDAR, &"concrete", [], MEIA_LARGURA_CASA, MEIA_PROFUNDIDADE_CASA)
	_montar_laje_piso(&"terreo", 0.0, &"wood_floor", [abertura_escada_porao], MEIA_LARGURA_CASA, MEIA_PROFUNDIDADE_CASA)
	_montar_laje_piso(&"primeiro", ALTURA_ANDAR, &"wood_floor", [abertura_escada_principal_superior], MEIA_LARGURA_ANDAR, MEIA_PROFUNDIDADE_ANDAR)
	_montar_laje_piso(&"sotao", ALTURA_ANDAR * 2.0, &"attic_wood", [abertura_escada_sotao], MEIA_LARGURA_ANDAR, MEIA_PROFUNDIDADE_ANDAR)
	_montar_laje_teto(&"porao", -0.22, [abertura_escada_porao], MEIA_LARGURA_CASA, MEIA_PROFUNDIDADE_CASA)
	_montar_laje_teto(&"terreo", ALTURA_ANDAR - 0.22, [abertura_escada_principal], MEIA_LARGURA_CASA, MEIA_PROFUNDIDADE_CASA)
	_montar_laje_teto(&"primeiro", ALTURA_ANDAR * 2.0 - 0.22, [abertura_escada_sotao], MEIA_LARGURA_ANDAR, MEIA_PROFUNDIDADE_ANDAR)
	var janelas_porao := [
		{"center": -4.9, "width": 1.55, "bottom": 1.45, "height": 0.55, "window": true},
		{"center": 4.9, "width": 1.55, "bottom": 1.45, "height": 0.55, "window": true}
	]
	_montar_estrutura(&"porao", -ALTURA_ANDAR, &"wall_basement", janelas_porao, janelas_porao, [], MEIA_LARGURA_CASA, MEIA_PROFUNDIDADE_CASA)
	var fachada_terreo := [
		{"center": 0.0, "width": 1.6, "bottom": 0.0, "height": 2.2, "door": true},
		{"center": -5.25, "width": 1.8, "bottom": 0.88, "height": 1.18, "window": true},
		{"center": 5.25, "width": 1.8, "bottom": 0.88, "height": 1.18, "window": true}
	]
	var fundos_terreo := [
		{"center": -4.9, "width": 1.8, "bottom": 0.88, "height": 1.18, "window": true},
		{"center": 4.9, "width": 1.8, "bottom": 0.88, "height": 1.18, "window": true}
	]
	var laterais_terreo := [
		{"center": -3.6, "width": 1.7, "bottom": 0.88, "height": 1.18, "window": true},
		{"center": 0.0, "width": 1.7, "bottom": 0.88, "height": 1.18, "window": true},
		{"center": 3.6, "width": 1.7, "bottom": 0.88, "height": 1.18, "window": true}
	]
	_montar_estrutura(&"terreo", 0.0, &"wall_ivory", fachada_terreo, fundos_terreo, laterais_terreo, MEIA_LARGURA_CASA, MEIA_PROFUNDIDADE_CASA)
	var fachada_superior := [
		{"center": -4.45, "width": 1.8, "bottom": 0.92, "height": 1.1, "window": true},
		{"center": 4.45, "width": 1.8, "bottom": 0.92, "height": 1.1, "window": true}
	]
	var laterais_superior := [
		{"center": -3.0, "width": 1.7, "bottom": 0.92, "height": 1.1, "window": true},
		{"center": 3.0, "width": 1.7, "bottom": 0.92, "height": 1.1, "window": true}
	]
	_montar_estrutura(&"primeiro", ALTURA_ANDAR, &"wall_ivory", fachada_superior, fachada_superior, laterais_superior, MEIA_LARGURA_ANDAR, MEIA_PROFUNDIDADE_ANDAR)
	var janela_sotao := [{"center": 0.0, "width": 1.25, "bottom": 1.05, "height": 0.8, "window": true}]
	_montar_estrutura(&"sotao", ALTURA_ANDAR * 2.0, &"wall_attic", janela_sotao, janela_sotao, [], MEIA_LARGURA_ANDAR, MEIA_PROFUNDIDADE_ANDAR)
	_adicionar_friso_piso(&"terreo", 0.015, &"wood_seam", -MEIA_LARGURA_CASA, MEIA_LARGURA_CASA, -MEIA_PROFUNDIDADE_CASA, MEIA_PROFUNDIDADE_CASA, 0.9, Rect2(Vector2(-9.3, 3.2), Vector2(7.45, 5.8)))
	_adicionar_friso_piso(&"primeiro", ALTURA_ANDAR + 0.015, &"wood_seam", -MEIA_LARGURA_ANDAR, MEIA_LARGURA_ANDAR, -MEIA_PROFUNDIDADE_ANDAR, MEIA_PROFUNDIDADE_ANDAR, 0.9)
	_adicionar_friso_piso(&"sotao", ALTURA_ANDAR * 2.0 + 0.015, &"attic_wood", -MEIA_LARGURA_ANDAR, MEIA_LARGURA_ANDAR, -MEIA_PROFUNDIDADE_ANDAR, MEIA_PROFUNDIDADE_ANDAR, 1.0)
	_adicionar_friso_piso(&"porao", -ALTURA_ANDAR + 0.015, &"tile_alt", -MEIA_LARGURA_CASA, MEIA_LARGURA_CASA, -MEIA_PROFUNDIDADE_CASA, MEIA_PROFUNDIDADE_CASA, 0.9)
	# O revestimento e os beirais acompanham a ampliação da planta.
	_montar_revestimento_exterior()

func _montar_laje_piso(floor_id: StringName, y: float, material_key: StringName, openings: Array, half_width: float = MEIA_LARGURA_CASA, half_depth: float = MEIA_PROFUNDIDADE_CASA) -> void:
	var xs: Array[float] = [-half_width, half_width]
	var zs: Array[float] = [-half_depth, half_depth]
	for opening in openings:
		var center: Vector2 = opening["center"]
		var size: Vector2 = opening["size"]
		_adicionar_limite(xs, center.x - size.x * 0.5, -half_width, half_width)
		_adicionar_limite(xs, center.x + size.x * 0.5, -half_width, half_width)
		_adicionar_limite(zs, center.y - size.y * 0.5, -half_depth, half_depth)
		_adicionar_limite(zs, center.y + size.y * 0.5, -half_depth, half_depth)
	xs.sort()
	zs.sort()
	for xi in range(xs.size() - 1):
		for zi in range(zs.size() - 1):
			var x0 := xs[xi]
			var x1 := xs[xi + 1]
			var z0 := zs[zi]
			var z1 := zs[zi + 1]
			var center := Vector2((x0 + x1) * 0.5, (z0 + z1) * 0.5)
			var inside_opening := false
			for opening in openings:
				var opening_center: Vector2 = opening["center"]
				var opening_size: Vector2 = opening["size"]
				if absf(center.x - opening_center.x) < opening_size.x * 0.5 and absf(center.y - opening_center.y) < opening_size.y * 0.5:
					inside_opening = true
					break
			if not inside_opening:
				_adicionar_caixa(Vector3(center.x, y - ESPESSURA_LAJE * 0.5, center.y), Vector3(x1 - x0, ESPESSURA_LAJE, z1 - z0), material_key, floor_id, true)

func _montar_laje_teto(floor_id: StringName, y: float, openings: Array, half_width: float = MEIA_LARGURA_CASA, half_depth: float = MEIA_PROFUNDIDADE_CASA) -> void:
	var xs: Array[float] = [-half_width, half_width]
	var zs: Array[float] = [-half_depth, half_depth]
	for opening in openings:
		var center: Vector2 = opening["center"]
		var size: Vector2 = opening["size"]
		_adicionar_limite(xs, center.x - size.x * 0.5, -half_width, half_width)
		_adicionar_limite(xs, center.x + size.x * 0.5, -half_width, half_width)
		_adicionar_limite(zs, center.y - size.y * 0.5, -half_depth, half_depth)
		_adicionar_limite(zs, center.y + size.y * 0.5, -half_depth, half_depth)
	xs.sort()
	zs.sort()
	for xi in range(xs.size() - 1):
		for zi in range(zs.size() - 1):
			var x0 := xs[xi]
			var x1 := xs[xi + 1]
			var z0 := zs[zi]
			var z1 := zs[zi + 1]
			var center := Vector2((x0 + x1) * 0.5, (z0 + z1) * 0.5)
			var inside_opening := false
			for opening in openings:
				var opening_center: Vector2 = opening["center"]
				var opening_size: Vector2 = opening["size"]
				if absf(center.x - opening_center.x) < opening_size.x * 0.5 and absf(center.y - opening_center.y) < opening_size.y * 0.5:
					inside_opening = true
					break
			if not inside_opening:
				_adicionar_caixa(Vector3(center.x, y, center.y), Vector3(x1 - x0, 0.045, z1 - z0), &"ceiling", floor_id, false)

func _adicionar_limite(values: Array[float], value: float, minimum: float, maximum: float) -> void:
	var clamped := clampf(value, minimum, maximum)
	for existing in values:
		if is_equal_approx(existing, clamped):
			return
	values.append(clamped)

func _montar_estrutura(floor_id: StringName, base_y: float, wall_material: StringName, front_openings: Array, rear_openings: Array, side_openings: Array, half_width: float = MEIA_LARGURA_CASA, half_depth: float = MEIA_PROFUNDIDADE_CASA) -> void:
	_montar_parede_eixo_x(floor_id, half_depth, base_y, 0.0, half_width * 2.0, ALTURA_PAREDE, ESPESSURA_PAREDE, wall_material, front_openings)
	_montar_parede_eixo_x(floor_id, -half_depth, base_y, 0.0, half_width * 2.0, ALTURA_PAREDE, ESPESSURA_PAREDE, wall_material, rear_openings)
	_montar_parede_eixo_z(floor_id, half_width, base_y, 0.0, half_depth * 2.0, ALTURA_PAREDE, ESPESSURA_PAREDE, wall_material, side_openings)
	_montar_parede_eixo_z(floor_id, -half_width, base_y, 0.0, half_depth * 2.0, ALTURA_PAREDE, ESPESSURA_PAREDE, wall_material, side_openings)
	for opening in front_openings:
		_adicionar_moldura_abertura_eixo_x(floor_id, MEIA_PROFUNDIDADE_CASA, 0.0, base_y, opening)
	for opening in rear_openings:
		_adicionar_moldura_abertura_eixo_x(floor_id, -MEIA_PROFUNDIDADE_CASA, 0.0, base_y, opening)
	for opening in side_openings:
		_adicionar_moldura_abertura_eixo_z(floor_id, MEIA_LARGURA_CASA, 0.0, base_y, opening)
		_adicionar_moldura_abertura_eixo_z(floor_id, -MEIA_LARGURA_CASA, 0.0, base_y, opening)

func _montar_parede_eixo_x(floor_id: StringName, z: float, base_y: float, center_x: float, length: float, height: float, thickness: float, material_key: StringName, openings: Array) -> void:
	var xs: Array[float] = [center_x - length * 0.5, center_x + length * 0.5]
	var ys: Array[float] = [0.0, height]
	for opening in openings:
		_adicionar_limite(xs, float(opening["center"]) - float(opening["width"]) * 0.5, center_x - length * 0.5, center_x + length * 0.5)
		_adicionar_limite(xs, float(opening["center"]) + float(opening["width"]) * 0.5, center_x - length * 0.5, center_x + length * 0.5)
		_adicionar_limite(ys, float(opening["bottom"]), 0.0, height)
		_adicionar_limite(ys, float(opening["bottom"]) + float(opening["height"]), 0.0, height)
	xs.sort()
	ys.sort()
	for xi in range(xs.size() - 1):
		for yi in range(ys.size() - 1):
			var x0 := xs[xi]
			var x1 := xs[xi + 1]
			var y0 := ys[yi]
			var y1 := ys[yi + 1]
			var center_x_cell := (x0 + x1) * 0.5
			var center_y_cell := (y0 + y1) * 0.5
			var inside_opening := false
			for opening in openings:
				if absf(center_x_cell - float(opening["center"])) < float(opening["width"]) * 0.5 and center_y_cell > float(opening["bottom"]) and center_y_cell < float(opening["bottom"]) + float(opening["height"]):
					inside_opening = true
					break
			if not inside_opening:
				var cell_center := Vector3(center_x_cell, base_y + (y0 + y1) * 0.5, z)
				var cell_size := Vector3(x1 - x0, y1 - y0, thickness)
				var is_foundation_under_entry := floor_id == &"porao" and is_equal_approx(z, MEIA_PROFUNDIDADE_CASA) and is_equal_approx(base_y, -ALTURA_ANDAR) and is_equal_approx(center_x_cell, 0.0) and is_equal_approx(y0, 2.0) and is_equal_approx(y1, ALTURA_PAREDE) and is_equal_approx(cell_size.x, 6.35)
				if is_foundation_under_entry:
					# Mantém a fundação visível, abrindo apenas a colisão no vão da porta frontal.
					_adicionar_caixa(cell_center, cell_size, material_key, floor_id, false)
					var half_door_width := 1.40 * 0.5
					var left_end := minf(x1, -half_door_width)
					if left_end > x0:
						var left_width := left_end - x0
						_adicionar_colisao_caixa(Vector3((x0 + left_end) * 0.5, cell_center.y, z), Vector3(left_width, cell_size.y, thickness), floor_id, &"BaseFrontalEsquerda")
					var right_start := maxf(x0, half_door_width)
					if x1 > right_start:
						var right_width := x1 - right_start
						_adicionar_colisao_caixa(Vector3((right_start + x1) * 0.5, cell_center.y, z), Vector3(right_width, cell_size.y, thickness), floor_id, &"BaseFrontalDireita")
				else:
					_adicionar_caixa(cell_center, cell_size, material_key, floor_id, true)

func _montar_parede_eixo_z(floor_id: StringName, x: float, base_y: float, center_z: float, depth: float, height: float, thickness: float, material_key: StringName, openings: Array) -> void:
	var zs: Array[float] = [center_z - depth * 0.5, center_z + depth * 0.5]
	var ys: Array[float] = [0.0, height]
	for opening in openings:
		_adicionar_limite(zs, float(opening["center"]) - float(opening["width"]) * 0.5, center_z - depth * 0.5, center_z + depth * 0.5)
		_adicionar_limite(zs, float(opening["center"]) + float(opening["width"]) * 0.5, center_z - depth * 0.5, center_z + depth * 0.5)
		_adicionar_limite(ys, float(opening["bottom"]), 0.0, height)
		_adicionar_limite(ys, float(opening["bottom"]) + float(opening["height"]), 0.0, height)
	zs.sort()
	ys.sort()
	for zi in range(zs.size() - 1):
		for yi in range(ys.size() - 1):
			var z0 := zs[zi]
			var z1 := zs[zi + 1]
			var y0 := ys[yi]
			var y1 := ys[yi + 1]
			var center_z_cell := (z0 + z1) * 0.5
			var center_y_cell := (y0 + y1) * 0.5
			var inside_opening := false
			for opening in openings:
				if absf(center_z_cell - float(opening["center"])) < float(opening["width"]) * 0.5 and center_y_cell > float(opening["bottom"]) and center_y_cell < float(opening["bottom"]) + float(opening["height"]):
					inside_opening = true
					break
			if not inside_opening:
				_adicionar_caixa(Vector3(x, base_y + (y0 + y1) * 0.5, center_z_cell), Vector3(thickness, y1 - y0, z1 - z0), material_key, floor_id, true)

func _adicionar_moldura_abertura_eixo_x(floor_id: StringName, z: float, center_x: float, base_y: float, opening: Dictionary) -> void:
	var cx := float(opening["center"])
	var width := float(opening["width"])
	var bottom := float(opening["bottom"])
	var height := float(opening["height"])
	var trim_depth := 0.10
	for side in [-1.0, 1.0]:
		_adicionar_caixa(Vector3(cx + side * width * 0.5, base_y + bottom + height * 0.5, z), Vector3(0.075, height, trim_depth), &"trim_light", floor_id, false)
	_adicionar_caixa(Vector3(cx, base_y + bottom + height, z), Vector3(width + 0.08, 0.08, trim_depth), &"trim_light", floor_id, false)
	if bool(opening.get("window", false)):
		_adicionar_caixa(Vector3(cx, base_y + bottom, z), Vector3(width + 0.08, 0.09, trim_depth), &"trim_light", floor_id, false)
		_adicionar_caixa(Vector3(cx, base_y + bottom + height * 0.5, z), Vector3(width - 0.1, 0.045, 0.035), &"trim", floor_id, false)
		_adicionar_caixa(Vector3(cx, base_y + bottom + height * 0.5, z), Vector3(0.045, height - 0.1, 0.035), &"trim", floor_id, false)
		_adicionar_caixa(Vector3(cx, base_y + bottom + height * 0.5, z + 0.015), Vector3(width - 0.13, height - 0.13, 0.025), &"glass", floor_id, false)

func _adicionar_moldura_abertura_eixo_z(floor_id: StringName, x: float, center_z: float, base_y: float, opening: Dictionary) -> void:
	var cz := float(opening["center"])
	var width := float(opening["width"])
	var bottom := float(opening["bottom"])
	var height := float(opening["height"])
	var trim_depth := 0.10
	for side in [-1.0, 1.0]:
		_adicionar_caixa(Vector3(x, base_y + bottom + height * 0.5, cz + side * width * 0.5), Vector3(trim_depth, height, 0.075), &"trim_light", floor_id, false)
	_adicionar_caixa(Vector3(x, base_y + bottom + height, cz), Vector3(trim_depth, 0.08, width + 0.08), &"trim_light", floor_id, false)
	if bool(opening.get("window", false)):
		_adicionar_caixa(Vector3(x, base_y + bottom, cz), Vector3(trim_depth, 0.09, width + 0.08), &"trim_light", floor_id, false)
		_adicionar_caixa(Vector3(x, base_y + bottom + height * 0.5, cz), Vector3(0.035, 0.045, width - 0.1), &"trim", floor_id, false)
		_adicionar_caixa(Vector3(x, base_y + bottom + height * 0.5, cz), Vector3(0.035, height - 0.1, 0.045), &"trim", floor_id, false)
		_adicionar_caixa(Vector3(x + 0.015, base_y + bottom + height * 0.5, cz), Vector3(0.025, height - 0.13, width - 0.13), &"glass", floor_id, false)

func _adicionar_friso_piso(floor_id: StringName, y: float, material_key: StringName, min_x: float, max_x: float, min_z: float, max_z: float, spacing: float, exclusion: Rect2 = Rect2()) -> void:
	var z := min_z + spacing
	while z < max_z:
		if exclusion.has_area() and z >= exclusion.position.y and z <= exclusion.position.y + exclusion.size.y:
			var exclusion_min_x := maxf(min_x, exclusion.position.x)
			var exclusion_max_x := minf(max_x, exclusion.position.x + exclusion.size.x)
			var left_width := exclusion_min_x - min_x
			var right_width := max_x - exclusion_max_x
			if left_width > 0.1:
				_adicionar_caixa(Vector3(min_x + left_width * 0.5, y, z), Vector3(left_width, 0.012, 0.014), material_key, floor_id, false)
			if right_width > 0.1:
				_adicionar_caixa(Vector3(exclusion_max_x + right_width * 0.5, y, z), Vector3(right_width, 0.012, 0.014), material_key, floor_id, false)
		else:
			_adicionar_caixa(Vector3((min_x + max_x) * 0.5, y, z), Vector3(max_x - min_x, 0.012, 0.014), material_key, floor_id, false)
		z += spacing

func _montar_paredes_internas() -> void:
	# Porão dividido em lavanderia, oficina e armazenamento, com passagens mantidas.
	var abertura_porao_frente := {"center": 0.0, "width": 1.55, "bottom": 0.0, "height": 2.15}
	_montar_parede_eixo_x(&"porao", 1.7, -ALTURA_ANDAR, 0.0, MEIA_LARGURA_CASA * 2.0, ALTURA_PAREDE, ESPESSURA_PAREDE, &"wall_basement", [abertura_porao_frente])
	_adicionar_moldura_abertura_eixo_x(&"porao", 1.7, 0.0, -ALTURA_ANDAR, abertura_porao_frente)
	_adicionar_porta_eixo_x(&"porao", 1.7, 0.0, -ALTURA_ANDAR, 1.55, 2.15, 82.0)
	var aberturas_porao_lateral := [
		{"center": 5.25, "width": 1.4, "bottom": 0.0, "height": 2.15},
		{"center": 0.0, "width": 1.4, "bottom": 0.0, "height": 2.15},
		{"center": -5.35, "width": 1.4, "bottom": 0.0, "height": 2.15}
	]
	_montar_parede_eixo_z(&"porao", -2.6, -ALTURA_ANDAR, 0.0, MEIA_PROFUNDIDADE_CASA * 2.0, ALTURA_PAREDE, ESPESSURA_PAREDE, &"wall_basement", aberturas_porao_lateral)
	for abertura in aberturas_porao_lateral:
		_adicionar_moldura_abertura_eixo_z(&"porao", -2.6, 0.0, -ALTURA_ANDAR, abertura)
		_adicionar_porta_eixo_z(&"porao", -2.6, float(abertura["center"]), -ALTURA_ANDAR, float(abertura["width"]), float(abertura["height"]), -78.0)
	var abertura_porao_lavanderia := {"center": -6.0, "width": 1.35, "bottom": 0.0, "height": 2.15}
	_montar_parede_eixo_x(&"porao", -3.0, -ALTURA_ANDAR, -6.0, 6.7, ALTURA_PAREDE, ESPESSURA_PAREDE, &"wall_basement", [abertura_porao_lavanderia])
	_adicionar_moldura_abertura_eixo_x(&"porao", -3.0, 0.0, -ALTURA_ANDAR, abertura_porao_lavanderia)
	_adicionar_porta_eixo_x(&"porao", -3.0, -6.0, -ALTURA_ANDAR, 1.35, 2.15, 78.0)
	# A baia de escada no porão agora é um cômodo de serviço próprio, com porta para a oficina.
	var abertura_baia_escada := {"center": -6.25, "width": 1.3, "bottom": 0.0, "height": 2.15}
	_montar_parede_eixo_z(&"porao", 5.25, -ALTURA_ANDAR, -5.4, 5.2, ALTURA_PAREDE, ESPESSURA_PAREDE, &"wall_basement", [abertura_baia_escada])
	_adicionar_moldura_abertura_eixo_z(&"porao", 5.25, 0.0, -ALTURA_ANDAR, abertura_baia_escada)
	_adicionar_porta_eixo_z(&"porao", 5.25, -6.25, -ALTURA_ANDAR, 1.3, 2.15, -82.0)
	# Térreo ampliado: corredor de 3,7 m, alas de 7,45 m e portas em vez de vãos estreitos.
	var aberturas_corredor := [
		{"center": 5.15, "width": 1.55, "bottom": 0.0, "height": 2.25},
		{"center": -0.2, "width": 1.55, "bottom": 0.0, "height": 2.25},
		{"center": -5.35, "width": 1.55, "bottom": 0.0, "height": 2.25}
	]
	for x in [-MEIA_LARGURA_CORREDOR, MEIA_LARGURA_CORREDOR]:
		_montar_parede_eixo_z(&"terreo", x, 0.0, 0.0, MEIA_PROFUNDIDADE_CASA * 2.0, ALTURA_PAREDE, ESPESSURA_PAREDE, &"wall_ivory", aberturas_corredor)
		for abertura in aberturas_corredor:
			_adicionar_moldura_abertura_eixo_z(&"terreo", x, 0.0, 0.0, abertura)
		_adicionar_porta_eixo_z(&"terreo", x, float(aberturas_corredor[0]["center"]), 0.0, 1.55, 2.25, -90.0 if x < 0.0 else 90.0)
		_adicionar_porta_eixo_z(&"terreo", x, float(aberturas_corredor[1]["center"]), 0.0, 1.55, 2.25, -90.0 if x < 0.0 else 90.0)
		_adicionar_porta_eixo_z(&"terreo", x, float(aberturas_corredor[2]["center"]), 0.0, 1.55, 2.25, -90.0 if x < 0.0 else 90.0)
	var largura_ala := MEIA_LARGURA_CASA - MEIA_LARGURA_CORREDOR
	var centro_ala := (MEIA_LARGURA_CASA + MEIA_LARGURA_CORREDOR) * 0.5
	for parede_z in [2.5, -2.8]:
		var abertura_esquerda := {"center": -5.55, "width": 1.45, "bottom": 0.0, "height": 2.25}
		var abertura_direita := {"center": 5.55, "width": 1.45, "bottom": 0.0, "height": 2.25}
		_montar_parede_eixo_x(&"terreo", parede_z, 0.0, -centro_ala, largura_ala, ALTURA_PAREDE, ESPESSURA_PAREDE, &"wall_ivory", [abertura_esquerda])
		_montar_parede_eixo_x(&"terreo", parede_z, 0.0, centro_ala, largura_ala, ALTURA_PAREDE, ESPESSURA_PAREDE, &"wall_ivory", [abertura_direita])
		_adicionar_moldura_abertura_eixo_x(&"terreo", parede_z, 0.0, 0.0, abertura_esquerda)
		_adicionar_moldura_abertura_eixo_x(&"terreo", parede_z, 0.0, 0.0, abertura_direita)
		_adicionar_porta_eixo_x(&"terreo", parede_z, -5.55, 0.0, 1.45, 2.25, 90.0)
		_adicionar_porta_eixo_x(&"terreo", parede_z, 5.55, 0.0, 1.45, 2.25, 90.0)
	# O fundo direito é uma área de serviço ampla; a despensa passa a ser armário dentro da cozinha.
	# Primeiro andar de 15,2 x 12,4 m: hall amplo, dois dormitórios e alas de banho/vestir.
	var aberturas_hall_superior := [
		{"center": -3.25, "width": 1.5, "bottom": 0.0, "height": 2.2},
		{"center": 0.55, "width": 1.5, "bottom": 0.0, "height": 2.2},
		{"center": 4.0, "width": 1.5, "bottom": 0.0, "height": 2.2}
	]
	for x in [-1.8, 1.8]:
		_montar_parede_eixo_z(&"primeiro", x, ALTURA_ANDAR, 0.0, MEIA_PROFUNDIDADE_ANDAR * 2.0, ALTURA_PAREDE, ESPESSURA_PAREDE, &"wall_ivory", aberturas_hall_superior)
		for abertura in aberturas_hall_superior:
			_adicionar_moldura_abertura_eixo_z(&"primeiro", x, 0.0, ALTURA_ANDAR, abertura)
			_adicionar_porta_eixo_z(&"primeiro", x, float(abertura["center"]), ALTURA_ANDAR, float(abertura["width"]), float(abertura["height"]), 62.0)
	var meia_ala_superior := MEIA_LARGURA_ANDAR - 1.8
	var centro_ala_superior := (MEIA_LARGURA_ANDAR + 1.8) * 0.5
	for parede_z in [-0.8, 2.0]:
		var abertura_esquerda := {"center": -4.4, "width": 1.2, "bottom": 0.0, "height": 2.15}
		var abertura_direita := {"center": 4.4, "width": 1.2, "bottom": 0.0, "height": 2.15}
		_montar_parede_eixo_x(&"primeiro", parede_z, ALTURA_ANDAR, -centro_ala_superior, meia_ala_superior, ALTURA_PAREDE, ESPESSURA_PAREDE, &"wall_ivory", [abertura_esquerda])
		_montar_parede_eixo_x(&"primeiro", parede_z, ALTURA_ANDAR, centro_ala_superior, meia_ala_superior, ALTURA_PAREDE, ESPESSURA_PAREDE, &"wall_ivory", [abertura_direita])
		_adicionar_moldura_abertura_eixo_x(&"primeiro", parede_z, 0.0, ALTURA_ANDAR, abertura_esquerda)
		_adicionar_moldura_abertura_eixo_x(&"primeiro", parede_z, 0.0, ALTURA_ANDAR, abertura_direita)
		_adicionar_porta_eixo_x(&"primeiro", parede_z, -4.4, ALTURA_ANDAR, 1.2, 2.15, 64.0)
		_adicionar_porta_eixo_x(&"primeiro", parede_z, 4.4, ALTURA_ANDAR, 1.2, 2.15, -64.0)
	# O sótão permanece um único espaço de armazenamento familiar.
	var abertura_sotao := {"center": 0.0, "width": 2.0, "bottom": 0.0, "height": 2.1}
	_montar_parede_eixo_x(&"sotao", -0.15, ALTURA_ANDAR * 2.0, 0.0, MEIA_LARGURA_ANDAR * 2.0, ALTURA_PAREDE, ESPESSURA_PAREDE, &"wall_attic", [abertura_sotao])
	_adicionar_moldura_abertura_eixo_x(&"sotao", -0.15, 0.0, ALTURA_ANDAR * 2.0, abertura_sotao)
	_adicionar_porta_eixo_x(&"sotao", -0.15, 0.0, ALTURA_ANDAR * 2.0, 2.0, 2.1, 64.0)

func _montar_escadas() -> void:
	# Três escadas contínuas, com os vãos correspondentes nas lajes de cada pavimento.
	_adicionar_escada(&"terreo", Vector3(0.0, 0.0, 2.8), Vector3(0.0, ALTURA_ANDAR, -0.8), &"wood_warm")
	_adicionar_escada(&"terreo", Vector3(7.8, -ALTURA_ANDAR, -7.15), Vector3(7.8, 0.0, -4.05), &"concrete", true)
	_adicionar_escada(&"primeiro", Vector3(0.0, ALTURA_ANDAR, 4.5), Vector3(0.0, ALTURA_ANDAR * 2.0, 1.4), &"wood_warm", true)

func _adicionar_escada(floor_id: StringName, lower: Vector3, upper: Vector3, material_key: StringName, open_lower_approach: bool = false) -> void:
	if floor_id == &"terreo" and material_key == &"concrete":
		_adicionar_escada_servico_porao(lower, upper, open_lower_approach)
		return
	var rise := absf(upper.y - lower.y)
	var run := absf(upper.z - lower.z)
	var angle_abs := atan2(rise, run)
	var sign := 1.0 if lower.z > upper.z else -1.0
	var angle := angle_abs * sign
	var length := sqrt(rise * rise + run * run)
	var midpoint := (lower + upper) * 0.5
	var normal_up := Vector3(0.0, cos(angle), sin(angle))
	var rotation := Vector3(angle, 0.0, 0.0)
	_adicionar_caixa(midpoint - normal_up * 0.10, Vector3(LARGURA_ESCADA, 0.20, length + 0.12), material_key, floor_id, true, rotation)
	var step_count := 15
	for step_index in range(1, step_count):
		var t := float(step_index) / float(step_count)
		var point := lower.lerp(upper, t)
		_adicionar_caixa(point + normal_up * 0.025, Vector3(LARGURA_ESCADA - 0.12, 0.035, 0.12), &"trim", floor_id, false, rotation)
		for side in [-1.0, 1.0]:
			var lower_side_approach: bool = open_lower_approach and (floor_id == &"primeiro" or side < 0.0)
			var rail_shift := 0.6 if lower_side_approach else 0.0
			var lateral_offset := Vector3(side * (LARGURA_ESCADA * 0.5 + 0.08), 0.0, 0.0)
			var rail_center := midpoint + (upper - lower).normalized() * rail_shift + normal_up * 0.68 + lateral_offset
			var rail_shortening := 1.2 if lower_side_approach else 0.25
			var rail_length := length - rail_shortening
			var rail_size := Vector3(0.075, 1.25, rail_length)
			var post_offset := normal_up * 0.52
			var post_size := Vector3(0.065, 1.0, 0.065)
			if floor_id == &"terreo":
				rail_center = midpoint + (upper - lower).normalized() * rail_shift + Vector3(0.0, 1.02, 0.0) + lateral_offset
				rail_size = Vector3(0.095, 0.12, rail_length)
				post_offset = Vector3(0.0, 0.48, 0.0)
				post_size = Vector3(0.065, 0.96, 0.065)
			_adicionar_caixa(rail_center, rail_size, &"trim", floor_id, true, rotation)
			var post_count := 5
			for post_index in range(post_count):
				if lower_side_approach and post_index == 0:
					continue
				var post_t := float(post_index) / float(post_count - 1)
				var post_point := lower.lerp(upper, post_t)
				_adicionar_caixa(post_point + post_offset + lateral_offset, post_size, &"trim", floor_id, false)

func _adicionar_escada_servico_porao(lower: Vector3, upper: Vector3, open_lower_approach: bool) -> void:
	var rise := absf(upper.y - lower.y)
	var run := absf(upper.z - lower.z)
	var angle_abs := atan2(rise, run)
	var sign := 1.0 if lower.z > upper.z else -1.0
	var angle := angle_abs * sign
	var length := sqrt(rise * rise + run * run)
	var midpoint := (lower + upper) * 0.5
	var normal_up := Vector3(0.0, cos(angle), sin(angle))
	var rotation := Vector3(angle, 0.0, 0.0)
	_adicionar_colisao_caixa(midpoint - normal_up * 0.10, Vector3(LARGURA_ESCADA, 0.20, length + 0.12), &"terreo", &"RampaEscadaPorao", rotation)
	var step_count := 15
	var step_rise := rise / float(step_count)
	var step_run := run / float(step_count)
	var direction_z := 1.0 if upper.z > lower.z else -1.0
	for step_index in range(1, step_count + 1):
		var t0 := float(step_index - 1) / float(step_count)
		var t1 := float(step_index) / float(step_count)
		var z_start := lower.z + (upper.z - lower.z) * t0
		var z_end := lower.z + (upper.z - lower.z) * t1
		var previous_y := lower.y + (upper.y - lower.y) * t0
		var tread_y := lower.y + (upper.y - lower.y) * t1
		_adicionar_caixa(Vector3(midpoint.x, tread_y - 0.04, (z_start + z_end) * 0.5), Vector3(LARGURA_ESCADA - 0.16, 0.08, step_run + 0.035), &"concrete", &"terreo", false)
		_adicionar_caixa(Vector3(midpoint.x, (previous_y + tread_y) * 0.5, z_start + direction_z * 0.015), Vector3(LARGURA_ESCADA - 0.16, step_rise + 0.02, 0.045), &"trim", &"terreo", false)
	for side in [-1.0, 1.0]:
		var side_x: float = side * (LARGURA_ESCADA * 0.5 - 0.05)
		_adicionar_caixa(midpoint - normal_up * 0.10 + Vector3(side_x, 0.0, 0.0), Vector3(0.10, 0.18, length + 0.08), &"concrete", &"terreo", false, rotation)
	# Corrimãos e guarda-corpo locais são montados por _adicionar_acabamento_escada_c17.

func _montar_telhado_exterior() -> void:
	var pitch := atan2(1.65, MEIA_LARGURA_CASA)
	var slope_length := sqrt(MEIA_LARGURA_CASA * MEIA_LARGURA_CASA + 1.65 * 1.65)
	var eave_y := ALTURA_ANDAR * 3.0
	var ridge_y := eave_y + 1.65
	for side in [-1.0, 1.0]:
		var center := Vector3(side * MEIA_LARGURA_CASA * 0.5, (eave_y + ridge_y) * 0.5, 0.0)
		_adicionar_caixa(center, Vector3(slope_length, 0.16, MEIA_PROFUNDIDADE_CASA * 2.0 + 0.45), &"roof", &"", false, Vector3(0.0, 0.0, -side * pitch))
		_adicionar_caixa(Vector3(side * MEIA_LARGURA_CASA, eave_y - 0.05, 0.0), Vector3(0.22, 0.22, MEIA_PROFUNDIDADE_CASA * 2.0 + 0.6), &"roof_edge", &"", false)
	_adicionar_triangulo(Vector3(-MEIA_LARGURA_CASA, eave_y, MEIA_PROFUNDIDADE_CASA + 0.13), Vector3(MEIA_LARGURA_CASA, eave_y, MEIA_PROFUNDIDADE_CASA + 0.13), Vector3(0.0, ridge_y, MEIA_PROFUNDIDADE_CASA + 0.13), &"siding")
	_adicionar_triangulo(Vector3(MEIA_LARGURA_CASA, eave_y, -MEIA_PROFUNDIDADE_CASA - 0.13), Vector3(-MEIA_LARGURA_CASA, eave_y, -MEIA_PROFUNDIDADE_CASA - 0.13), Vector3(0.0, ridge_y, -MEIA_PROFUNDIDADE_CASA - 0.13), &"siding")
	# Varanda proporcional à nova fachada, ainda sem luz elétrica.
	_adicionar_caixa(Vector3(0.0, 2.48, MEIA_PROFUNDIDADE_CASA + 0.55), Vector3(5.6, 0.16, 1.7), &"roof", &"", false)
	_adicionar_caixa(Vector3(-2.65, 2.35, MEIA_PROFUNDIDADE_CASA + 1.25), Vector3(0.18, 2.35, 0.18), &"trim", &"", true)
	_adicionar_caixa(Vector3(2.65, 2.35, MEIA_PROFUNDIDADE_CASA + 1.25), Vector3(0.18, 2.35, 0.18), &"trim", &"", true)
	_adicionar_caixa(Vector3(0.0, 0.07, MEIA_PROFUNDIDADE_CASA + 0.85), Vector3(2.5, 0.14, 1.35), &"concrete", &"exterior", false)
	_adicionar_caixa(Vector3(0.0, -0.08, MEIA_PROFUNDIDADE_CASA + 1.55), Vector3(2.5, 0.18, 0.8), &"concrete", &"exterior", false)
	# Rampa física alinhada ao limiar frontal ampliado, sem substituir os degraus visuais.
	var rampa_inicio := Vector3(0.0, -0.02, MEIA_PROFUNDIDADE_CASA + 3.0)
	var rampa_fim := Vector3(0.0, 0.0, MEIA_PROFUNDIDADE_CASA)
	var diferenca_rampa := rampa_fim - rampa_inicio
	var angulo_rampa := atan2(diferenca_rampa.y, absf(diferenca_rampa.z))
	var espessura_rampa := 0.14
	var normal_rampa := Vector3(0.0, cos(angulo_rampa), sin(angulo_rampa))
	var colisao_rampa := CollisionShape3D.new()
	colisao_rampa.name = "RampaAcessoSpawn"
	var forma_rampa := BoxShape3D.new()
	forma_rampa.size = Vector3(2.3, espessura_rampa, diferenca_rampa.length() + 0.06)
	colisao_rampa.shape = forma_rampa
	colisao_rampa.position = (rampa_inicio + rampa_fim) * 0.5 - normal_rampa * (espessura_rampa * 0.5)
	colisao_rampa.rotation = Vector3(angulo_rampa, 0.0, 0.0)
	(_corpos_colisao[&"exterior"] as StaticBody3D).add_child(colisao_rampa)
	_adicionar_porta_eixo_x(&"terreo", MEIA_PROFUNDIDADE_CASA, 0.0, 0.0, 1.6, 2.2, 72.0)
	_adicionar_caixa_correio(Vector3(-5.4, 0.0, MEIA_PROFUNDIDADE_CASA + 3.8))

func _montar_revestimento_exterior() -> void:
	# Filetes e frisos dimensionados por pavimento, com recuo do volume superior.
	for floor_index in range(3):
		var y := float(floor_index) * ALTURA_ANDAR
		var half_width := MEIA_LARGURA_CASA if floor_index == 0 else MEIA_LARGURA_ANDAR
		var half_depth := MEIA_PROFUNDIDADE_CASA if floor_index == 0 else MEIA_PROFUNDIDADE_ANDAR
		for x in range(-int(half_width), int(half_width) + 1):
			_adicionar_caixa(Vector3(float(x), y + 1.35, half_depth + 0.14), Vector3(0.035, 2.55, 0.06), &"siding_alt", &"", false)
			_adicionar_caixa(Vector3(float(x), y + 1.35, -half_depth - 0.14), Vector3(0.035, 2.55, 0.06), &"siding_alt", &"", false)
		for z in range(-int(half_depth) + 1, int(half_depth)):
			_adicionar_caixa(Vector3(half_width + 0.14, y + 1.35, float(z)), Vector3(0.06, 2.55, 0.035), &"siding_alt", &"", false)
			_adicionar_caixa(Vector3(-half_width - 0.14, y + 1.35, float(z)), Vector3(0.06, 2.55, 0.035), &"siding_alt", &"", false)
		for edge_z in [-half_depth - 0.2, half_depth + 0.2]:
			_adicionar_caixa(Vector3(0.0, y + 0.08, edge_z), Vector3(half_width * 2.0 + 0.2, 0.11, 0.13), &"trim", &"", false)
		_adicionar_caixa(Vector3(half_width + 0.2, y + 0.08, 0.0), Vector3(0.13, 0.11, half_depth * 2.0), &"trim", &"", false)
		_adicionar_caixa(Vector3(-half_width - 0.2, y + 0.08, 0.0), Vector3(0.13, 0.11, half_depth * 2.0), &"trim", &"", false)

func _mobiliar_porao() -> void:
	var y := -ALTURA_ANDAR
	# Lavanderia: lavadora/secadora de escala real, com corredor frontal livre.
	_adicionar_tapete(&"porao", Vector3(-6.25, y + 0.022, -1.05), Vector2(4.0, 2.25), &"rug_detail")
	_adicionar_modelo_glb("LavadoraSecadora", "washer-dryer.glb", Vector3(-7.85, y, -2.05), 1.0, 0.0, &"porao", Vector3(0.62, 0.88, 0.62))
	_adicionar_modelo_glb("Secadora", "tumble-dryer.glb", Vector3(-6.95, y, -2.05), 1.0, 0.0, &"porao", Vector3(0.62, 0.88, 0.64))
	_adicionar_modelo_mobiliario("wicker_basket_01", Vector3(-5.45, y, -1.65), 1.35, 0.0, &"porao", Vector3(0.52, 0.16, 0.4))
	_adicionar_placa_sala("LAVANDERIA", Vector3(-6.0, y + 2.45, -2.91), 0.0, 1.35)
	# Depósito oeste: prateleira metálica e caixas organizadas junto às paredes.
	_adicionar_modelo_mobiliario("worn_metal_rack", Vector3(-8.7, y, -5.35), 0.9, 90.0, &"porao", Vector3(0.95, 1.95, 0.66))
	_adicionar_modelo_mobiliario("wooden_crate_01", Vector3(-7.65, y, -7.25), 0.88, 0.0, &"porao", Vector3(0.9, 0.4, 0.45))
	_adicionar_modelo_mobiliario("wooden_crate_01", Vector3(-6.75, y, -7.25), 0.7, 0.0, &"porao", Vector3(0.72, 0.36, 0.38))
	_adicionar_modelo_mobiliario("plastic_crate_01", Vector3(-7.55, y + 0.38, -7.25), 1.25, 0.0, &"porao", Vector3(0.38, 0.34, 0.52))
	_adicionar_placa_sala("DEPÓSITO", Vector3(-6.0, y + 2.45, -3.09), 180.0, 1.35)
	# Oficina: bancada e carrinho reais, separados da baia das escadas por parede e porta.
	_adicionar_modelo_glb("BancadaOficina", "workbench-with-pegboard.glb", Vector3(3.35, y, -6.8), 1.0, 0.0, &"porao", Vector3(1.5, 1.8, 0.65))
	_adicionar_modelo_mobiliario("vintage_oil_lamp", Vector3(3.72, y + 0.92, -6.54), 0.34, 0.0, &"porao")
	_adicionar_luz_de_oleo(Vector3(3.72, y + 1.13, -6.54))
	_adicionar_modelo_mobiliario("tool_cart", Vector3(1.15, y, -5.45), 0.85, 0.0, &"porao", Vector3(1.1, 0.9, 0.72))
	_adicionar_modelo_mobiliario("metal_trash_can", Vector3(-0.55, y, -6.6), 0.58, 0.0, &"porao", Vector3(0.58, 0.62, 0.42))
	_adicionar_placa_sala("OFICINA", Vector3(3.35, y + 2.45, -7.88), 0.0, 1.2)
	_adicionar_modelo_mobiliario("hanging_picture_frame_02", Vector3(-4.0, y + 1.8, -2.865), 0.82, 0.0, &"porao")
	# Cestos de serviço ficam fora da área de abertura e do percurso de escada.
	_adicionar_modelo_mobiliario("wicker_basket_01", Vector3(8.95, y, -5.05), 1.1, 0.0, &"porao", Vector3(0.45, 0.14, 0.34))

func _adicionar_eletrodomestico(center: Vector3, body_material: StringName, floor_id: StringName) -> void:
		_adicionar_caixa(center + Vector3(0.0, 0.55, 0.0), Vector3(1.25, 1.1, 0.76), body_material, floor_id, true)
		_adicionar_caixa(center + Vector3(0.0, 0.57, 0.393), Vector3(0.74, 0.74, 0.04), &"metal_dark", floor_id, false)
		_adicionar_caixa(center + Vector3(0.0, 0.57, 0.42), Vector3(0.54, 0.54, 0.025), &"metal", floor_id, false)
		_adicionar_caixa(center + Vector3(0.42, 1.02, 0.405), Vector3(0.16, 0.035, 0.025), &"trim_light", floor_id, false)

func _mobiliar_terreo() -> void:
	var y := 0.0
	_preparar_materiais_servico_c17()
	# Materiais de piso delimitam as duas áreas de trabalho no fundo da casa.
	_adicionar_caixa(Vector3(-5.575, y + 0.012, -5.4), Vector3(7.45, 0.018, 5.2), &"kitchen_floor", &"", false)
	# O revestimento da lavanderia contorna a abertura e não a esconde por cima.
	_adicionar_caixa(Vector3(4.325, y + 0.012, -5.4), Vector3(4.95, 0.018, 5.2), &"service_floor_c17", &"", false)
	_adicionar_caixa(Vector3(9.05, y + 0.012, -5.4), Vector3(0.5, 0.018, 5.2), &"service_floor_c17", &"", false)
	_adicionar_caixa(Vector3(5.575, y + 0.012, -7.6), Vector3(7.45, 0.018, 0.8), &"service_floor_c17", &"", false)
	_adicionar_caixa(Vector3(5.575, y + 0.012, -3.4), Vector3(7.45, 0.018, 1.2), &"service_floor_c17", &"", false)
	_mobiliar_hall_c19(y)
	# Sala de estar: zona de conversa em L, alinhada à TV e concentrada no tapete.
	_adicionar_tapete(&"terreo", Vector3(-5.65, y + 0.022, 6.0), Vector2(4.6, 4.0), &"rug_living")
	_adicionar_modelo_glb("CortinaJanelaSala", "curtain-pair-open-original-interior-furnishing.glb", Vector3(-5.25, y + 0.16, 7.82), 1.12, 0.0, &"terreo")
	_adicionar_painel_midia_estar()
	_adicionar_modelo_mobiliario("modern_wooden_cabinet", Vector3(-8.98, y, 6.0), 0.75, 90.0, &"terreo", Vector3(2.44, 0.68, 0.52))
	_adicionar_modelo_glb("TelevisaoSala", "television-modern.glb", Vector3(-8.90, y + 0.51, 6.0), 1.75, 90.0, &"terreo")
	_adicionar_modelo_mobiliario("book_encyclopedia_set_01", Vector3(-8.98, y + 0.70, 4.98), 0.42, 0.0, &"terreo")
	_adicionar_modelo_mobiliario("ceramic_vase_02", Vector3(-8.98, y + 0.69, 7.0), 0.42, 0.0, &"terreo")
	_adicionar_modelo_glb("EstanteSala", "filled-bookshelf-large-original-interior-furnishing.glb", Vector3(-2.25, y, 6.9), 0.92, 270.0, &"terreo", Vector3(1.5, 2.1, 0.32))
	_adicionar_modelo_mobiliario("hanging_picture_frame_02", Vector3(-9.02, y + 1.92, 5.0), 0.66, 90.0, &"terreo")
	_adicionar_modelo_mobiliario("hanging_picture_frame_02", Vector3(-9.02, y + 1.92, 7.2), 0.66, 90.0, &"terreo")
	_adicionar_modelo_mobiliario("sofa_02", Vector3(-5.55, y, 6.0), 1.08, 270.0, &"terreo", Vector3(1.95, 0.85, 0.92))
	_adicionar_modelo_mobiliario("sofa_02", Vector3(-6.70, y, 7.38), 1.08, 180.0, &"terreo", Vector3(1.95, 0.85, 0.92))
	_adicionar_modelo_glb("AlmofadasSofaSala", "polyhaven-throw-pillows-01.glb", Vector3(-5.55, y + 0.43, 6.35), 0.68, 90.0, &"terreo")
	_adicionar_modelo_glb("MantaSofaSala", "throw-blanket-original-interior-decor.glb", Vector3(-6.70, y + 0.43, 7.38), 0.42, 90.0, &"terreo")
	_adicionar_modelo_mobiliario("coffee_table_round_01", Vector3(-7.35, y, 6.0), 0.76, 0.0, &"terreo", Vector3(1.301, 0.491, 1.301))
	_adicionar_modelo_mobiliario("book_encyclopedia_set_01", Vector3(-7.52, y + 0.38, 5.92), 0.38, 0.0, &"terreo")
	_adicionar_modelo_mobiliario("binder_notebook", Vector3(-7.22, y + 0.38, 5.96), 0.50, -8.0, &"terreo")
	_adicionar_modelo_mobiliario("wooden_bowl_01", Vector3(-7.13, y + 0.38, 6.20), 0.66, 0.0, &"terreo")
	_adicionar_modelo_mobiliario("food_apple_01", Vector3(-7.13, y + 0.45, 6.20), 0.70, 0.0, &"terreo")
	_adicionar_modelo_mobiliario("ArmChair_01", Vector3(-4.75, y, 7.1), 0.84, 225.0, &"terreo", Vector3(0.848, 1.065, 0.766))
	_adicionar_modelo_glb("LuminariaTripodeSala", "tripod-floor-lamp.glb", Vector3(-8.62, y, 4.35), 0.92, 0.0, &"terreo")
	_adicionar_modelo_glb("VentiladorSala", "ceiling-fan-polyhaven.glb", Vector3(-5.65, y + ALTURA_ANDAR - 0.22, 6.0), 0.92, 0.0, &"terreo")
	_adicionar_luz_ambiente_estar()
	# Planta interna em vaso único junto à estante, mantendo a circulação livre.
	_adicionar_modelo_mobiliario("potted_plant_02", Vector3(-3.12, y, 7.48), 1.0, 0.0, &"terreo")
	# Quadro decorativo na parede lateral, alinhado à face interna e voltado para a sala.
	_adicionar_modelo_mobiliario("hanging_picture_frame_02", Vector3(-1.97, y + 1.82, 5.25), 0.82, 270.0, &"terreo")

	# Piloto: móveis do jantar agora pertencem à instância SalaJantar_Editavel na cena.
	_contador_modelos += 15 # Preserva identificadores dos outros cômodos.

	# C16: cozinha kitchen004 fornecida por Richard, licença ainda desconhecida.
	_adicionar_cozinha_kitchen004_c16(y)
	_adicionar_modelo_glb("Geladeira", "refrigerator.glb", Vector3(-8.65, y, -5.15), 1.0, 90.0, &"terreo", Vector3(0.71, 1.82, 0.62))
	# A ilha pertence ao asset; não duplicar a antiga ilha procedural.
	_adicionar_banquetas_cozinha(Vector3(-6.70, y, -4.10))
	_adicionar_banquetas_cozinha(Vector3(-5.80, y, -4.10))
	_adicionar_modelo_mobiliario("wooden_cutting_board", Vector3(-6.82, y + 0.8455, -4.76), 1.05, -8.0, &"terreo")
	_adicionar_faca_preparo_cozinha(Vector3(-6.82, y + 0.8855, -4.76), "Ilha")
	_adicionar_modelo_mobiliario("yellow_onion", Vector3(-6.70, y + 0.8755, -4.76), 0.95, 0.0, &"terreo")
	_adicionar_modelo_mobiliario("wooden_bowl_01", Vector3(-5.62, y + 0.8455, -4.74), 1.0, 0.0, &"terreo")
	_adicionar_modelo_mobiliario("food_apple_01", Vector3(-5.675, y + 0.8655, -4.795), 0.78, -12.0, &"terreo")
	_adicionar_modelo_mobiliario("food_apple_01", Vector3(-5.565, y + 0.8655, -4.685), 0.76, 18.0, &"terreo")
	_adicionar_pano_cozinha(Vector3(-7.04, y + 0.8485, -5.00), "Ilha")
	# Escritório doméstico conectado à biblioteca: madeira, assento próximo e mesa limpa.
	_adicionar_tapete(&"terreo", Vector3(5.575, y + 0.022, 6.0), Vector2(4.2, 3.8), &"office_rug")
	_adicionar_modelo_glb("MesaEscritorioC15", "custom/c15/c15_furniture_original.glb", Vector3(5.75, y, 6.72), 1.05, 180.0, &"terreo")
	_adicionar_colisao_caixa(Vector3(5.75, y + 0.40, 6.96), Vector3(1.47, 0.80, 0.63), &"terreo", &"Hitbox_Mesa_Escritorio_C15")
	_adicionar_colisao_caixa(Vector3(6.0, y + 0.57, 6.225), Vector3(0.60, 1.14, 0.55), &"terreo", &"Hitbox_Cadeira_Escritorio_C15")
	_adicionar_modelo_mobiliario("desk_lamp_arm_01", Vector3(5.12, y + 0.8715, 6.78), 0.68, 0.0, &"terreo")
	_adicionar_modelo_mobiliario("classic_laptop", Vector3(6.0, y + 0.8163, 6.85), 0.42, 180.0, &"terreo")
	_adicionar_modelo_glb("EstanteEscritorio", "filled-bookshelf-large-original-interior-furnishing.glb", Vector3(8.92, y, 6.35), 1.0, 270.0, &"terreo", Vector3(1.5, 2.1, 0.32))
	_adicionar_modelo_mobiliario("modern_wooden_cabinet", Vector3(3.05, y, 7.35), 0.62, 0.0, &"terreo", Vector3(1.7, 0.55, 0.42))
	_adicionar_modelo_mobiliario("potted_plant_02", Vector3(3.35, y + 0.422, 7.35), 0.55, 0.0, &"terreo")
	_adicionar_modelo_mobiliario("hanging_picture_frame_02", Vector3(7.4, y + 1.85, 2.72), 0.9, 0.0, &"terreo")
	_adicionar_arte_quadro_escritorio_c15(Vector3(7.4, y + 1.822, 2.732), Vector2(0.54, 0.32))

	# Biblioteca ao lado do escritório: estantes cheias, duas poltronas e mesa de leitura.
	_adicionar_tapete(&"terreo", Vector3(5.575, y + 0.022, 0.0), Vector2(4.5, 4.1), &"library_rug")
	_adicionar_modelo_glb("EstanteBibliotecaA", "filled-bookshelf-large-original-interior-furnishing.glb", Vector3(9.08, y, -1.55), 1.0, 270.0, &"terreo", Vector3(1.5, 2.1, 0.32))
	_adicionar_modelo_glb("EstanteBibliotecaB", "filled-bookshelf-large-original-interior-furnishing.glb", Vector3(9.08, y, 0.0), 1.0, 270.0, &"terreo", Vector3(1.5, 2.1, 0.32))
	_adicionar_modelo_glb("EstanteBibliotecaC", "filled-bookshelf-large-original-interior-furnishing.glb", Vector3(9.08, y, 1.55), 1.0, 270.0, &"terreo", Vector3(1.5, 2.1, 0.32))
	_adicionar_modelo_glb("EstanteCompletaBibliotecaA", "filled-bookshelf-large-original-interior-furnishing.glb", Vector3(3.25, y, -2.55), 1.0, 0.0, &"terreo", Vector3(1.5, 2.1, 0.32))
	_adicionar_modelo_glb("EstanteCompletaBibliotecaB", "filled-bookshelf-large-original-interior-furnishing.glb", Vector3(7.8, y, -2.55), 1.0, 0.0, &"terreo", Vector3(1.5, 2.1, 0.32))
	_adicionar_modelo_mobiliario("ArmChair_01", Vector3(4.15, y, -0.8), 0.94, 90.0, &"terreo", Vector3(0.85, 1.06, 0.77))
	_adicionar_modelo_mobiliario("ArmChair_01", Vector3(6.85, y, 0.95), 0.94, 225.0, &"terreo", Vector3(0.85, 1.06, 0.77))
	_adicionar_modelo_mobiliario("coffee_table_round_01", Vector3(5.5, y, 0.05), 0.84, 0.0, &"terreo", Vector3(1.03, 0.45, 1.03))
	_adicionar_modelo_mobiliario("book_encyclopedia_set_01", Vector3(5.5, y + 0.43, 0.05), 0.52, 15.0, &"terreo")
	_adicionar_modelo_mobiliario("small_wooden_table_01", Vector3(4.15, y, -1.55), 0.72, 0.0, &"terreo", Vector3(0.75, 0.55, 0.45))
	_adicionar_modelo_mobiliario("vintage_oil_lamp", Vector3(4.15, y + 0.4, -1.55), 0.38, 0.0, &"terreo")
	_adicionar_luz_de_oleo(Vector3(4.15, y + 0.63, -1.55))
	_adicionar_modelo_mobiliario("hanging_picture_frame_02", Vector3(1.97, y + 1.82, 1.42), 0.88, -90.0, &"terreo")
	_adicionar_arte_quadro_biblioteca(Vector3(2.04, y + 1.82, 1.42), Vector2(0.52, 0.34))
	_adicionar_planta_interior(&"terreo", Vector3(2.65, y, 2.0), 0.4)

	# Área de serviço no fundo à direita: lavanderia junto à janela e passagem livre até a escada.
	_adicionar_area_servico_c17(y)

func _adicionar_modelo_mobiliario(asset_id: String, origem: Vector3, escala: float, rotacao_y_graus: float, floor_id: StringName, tamanho_colisao: Vector3 = Vector3.ZERO) -> Node3D:
	var asset_path := "res://prototype/assets/models/polyhaven/%s/%s_1k.gltf" % [asset_id, asset_id]
	var cena_asset := load(asset_path) as PackedScene
	if cena_asset == null:
		push_warning("Modelo Poly Haven indisponível: %s" % asset_path)
		return null
	var modelo := cena_asset.instantiate() as Node3D
	if modelo == null:
		push_warning("A raiz do modelo não é Node3D: %s" % asset_path)
		return null
	var asset_index := _contador_modelos
	modelo.name = "Asset_%02d_%s" % [asset_index, asset_id]
	_contador_modelos += 1
	modelo.position = origem
	modelo.rotation.y = deg_to_rad(rotacao_y_graus)
	modelo.scale = Vector3.ONE * escala
	var quadro_estar := floor_id == &"terreo" and ((origem.x < -8.9 and origem.z > 4.8 and origem.z < 7.3) or (absf(origem.x + 1.97) < 0.1 and absf(origem.z - 5.25) < 0.1))
	if asset_id == "hanging_picture_frame_02" and floor_id == &"terreo" and origem.x < -7.0 and origem.z < -2.0:
		_configurar_quadro_jantar(modelo)
	elif asset_id == "sofa_02" and floor_id == &"terreo":
		_configurar_tecido_sofa_sala(modelo)
	elif asset_id == "ArmChair_01" and floor_id == &"terreo" and origem.x < 0.0:
		_configurar_poltrona_sala(modelo)
	elif asset_id == "ArmChair_01" and floor_id == &"terreo" and origem.x > 0.0 and origem.x < 8.0 and absf(origem.z) < 2.0:
		_configurar_poltrona_biblioteca(modelo)
	elif asset_id == "hanging_picture_frame_02" and floor_id == &"terreo" and origem.x > 1.8 and origem.x < 2.2 and origem.z > 0.5 and origem.z < 2.2:
		_configurar_quadro_biblioteca(modelo)
	elif asset_id == "hanging_picture_frame_02" and floor_id == &"terreo" and origem.x > 6.8 and origem.z > 2.5:
		_configurar_quadro_biblioteca(modelo)
	elif asset_id == "hanging_picture_frame_02" and quadro_estar:
		_configurar_quadro_estar(modelo)
	elif asset_id == "coffee_table_round_01" and floor_id == &"terreo" and origem.x < -7.0:
		_configurar_mesa_reflexiva_estar(modelo)
	elif asset_id == "coffee_table_round_01" and floor_id == &"terreo" and origem.x > 0.0 and absf(origem.z) < 2.0:
		_configurar_mesa_biblioteca(modelo)
	elif asset_id == "vintage_cabinet_01" and floor_id == &"terreo":
		_configurar_materiais_reflexivos_adega(modelo)
	elif asset_id == "dining_table" and floor_id == &"terreo":
		_configurar_mesa_jantar(modelo)
	elif asset_id == "dining_chair_02" and floor_id == &"terreo":
		_configurar_cadeira_jantar(modelo)
	elif asset_id == "Chandelier_03" and floor_id == &"terreo":
		_configurar_lustre_jantar(modelo)
	elif asset_id == "tea_set_01" and floor_id == &"terreo" and origem.z > -1.0:
		_configurar_louca_jantar(modelo)
	elif asset_id == "desk_lamp_arm_01" and floor_id == &"terreo" and origem.z > 2.5:
		_configurar_luminaria_escritorio_c15(modelo)
	elif asset_id == "classic_laptop" and floor_id == &"terreo" and origem.z > 2.5:
		_configurar_laptop_escritorio_c15(modelo)
	elif asset_id == "vintage_microwave" and floor_id == &"terreo":
		_configurar_microondas_polyhaven(modelo)
	_raiz_visual.add_child(modelo)
	if tamanho_colisao != Vector3.ZERO and _corpos_colisao.has(floor_id):
		var tamanho_final := tamanho_colisao * escala
		_adicionar_colisao_caixa(origem + Vector3(0.0, tamanho_final.y * 0.5, 0.0), tamanho_final, floor_id, StringName("Hitbox_%02d_%s" % [asset_index, asset_id]), Vector3(0.0, deg_to_rad(rotacao_y_graus), 0.0))
	return modelo

func _adicionar_arte_quadro_jantar(centro: Vector3, tamanho: Vector2) -> void:
	var tela := MeshInstance3D.new()
	tela.name = "ArteQuadroJantar_CC0"
	var plano := QuadMesh.new()
	plano.size = tamanho
	tela.mesh = plano
	tela.position = centro
	tela.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://prototype/assets/models/polyhaven/hanging_picture_frame_02/textures/hanging_picture_frame_02_artwork_diff_1k.jpg") as Texture2D
	material.albedo_color = Color(0.72, 0.72, 0.68, 1.0)
	material.uv1_offset = Vector3(0.1, 0.22, 0.0)
	material.uv1_scale = Vector3(0.8, 0.53, 1.0)
	material.roughness = 0.95
	material.metallic = 0.0
	material.emission_enabled = false
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	tela.material_override = material
	_raiz_visual.add_child(tela)

func _configurar_quadro_jantar(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			var nome_material := String(material_original.resource_name).to_lower()
			if "artwork" in nome_material:
				material_local.albedo_color = material_original.albedo_color * Color(0.72, 0.72, 0.68, 1.0)
				material_local.roughness = 0.94
				material_local.metallic = 0.0
			elif "glass" in nome_material:
				material_local.albedo_color = material_original.albedo_color * Color(0.62, 0.58, 0.52, 1.0)
				material_local.roughness = 0.68
				material_local.metallic = 0.0
			else:
				material_local.albedo_color = material_original.albedo_color * Color(0.68, 0.56, 0.42, 1.0)
				material_local.roughness = 0.76
				material_local.metallic = 0.0
			material_local.clearcoat_enabled = false
			material_local.emission_enabled = false
			malha.set_surface_override_material(superficie, material_local)

func _configurar_mesa_jantar(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		if "cloth" in String(malha.name).to_lower():
			malha.visible = false
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			material_local.albedo_color = material_original.albedo_color * Color(0.62, 0.59, 0.54, 1.0)
			material_local.roughness = 0.80
			material_local.metallic = 0.0
			material_local.clearcoat_enabled = false
			material_local.emission_enabled = false
			malha.set_surface_override_material(superficie, material_local)

func _configurar_louca_jantar(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			material_local.albedo_color = material_original.albedo_color * Color(0.68, 0.65, 0.58, 1.0)
			material_local.roughness = 0.75
			material_local.metallic = 0.0
			material_local.clearcoat_enabled = false
			material_local.emission_enabled = false
			malha.set_surface_override_material(superficie, material_local)

func _configurar_cadeira_jantar(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			material_local.albedo_color = material_original.albedo_color * Color(1.32, 1.24, 1.12, 1.0)
			material_local.roughness = 0.78
			material_local.metallic = 0.0
			material_local.clearcoat_enabled = false
			material_local.emission_enabled = false
			malha.set_surface_override_material(superficie, material_local)

func _configurar_lustre_jantar(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			if "glass" in String(material_original.resource_name).to_lower():
				material_local.albedo_color = material_original.albedo_color * Color(0.68, 0.72, 0.75, 1.0)
				material_local.metallic = 0.05
				material_local.roughness = 0.48
			else:
				material_local.albedo_color = material_original.albedo_color * Color(0.66, 0.57, 0.43, 1.0)
				material_local.metallic = 0.58
				material_local.roughness = 0.40
			material_local.emission_enabled = false
			malha.set_surface_override_material(superficie, material_local)

func _adicionar_prato_jantar(centro: Vector3) -> void:
	var prato_mesh := CylinderMesh.new()
	prato_mesh.top_radius = 0.145
	prato_mesh.bottom_radius = 0.155
	prato_mesh.height = 0.018
	prato_mesh.radial_segments = 40
	var prato := MeshInstance3D.new()
	prato.name = "PratoJantar_%02d" % _contador_pratos_jantar
	prato.mesh = prato_mesh
	prato.position = centro
	prato.material_override = _materiais[&"dining_plate"]
	_raiz_visual.add_child(prato)
	var aro_mesh := TorusMesh.new()
	aro_mesh.inner_radius = 0.137
	aro_mesh.outer_radius = 0.15
	aro_mesh.rings = 32
	aro_mesh.ring_segments = 8
	var aro := MeshInstance3D.new()
	aro.name = "AroPratoJantar_%02d" % _contador_pratos_jantar
	aro.mesh = aro_mesh
	aro.position = centro + Vector3(0.0, 0.009, 0.0)
	aro.material_override = _materiais[&"dining_plate"]
	_raiz_visual.add_child(aro)
	_contador_pratos_jantar += 1

func _adicionar_guardanapo_jantar(centro: Vector3) -> void:
	var guardanapo := Node3D.new()
	guardanapo.name = "GuardanapoJantar"
	guardanapo.position = centro
	_raiz_visual.add_child(guardanapo)
	var tecido_mesh := BoxMesh.new()
	tecido_mesh.size = Vector3(0.28, 0.006, 0.20)
	var tecido := MeshInstance3D.new()
	tecido.name = "GuardanapoJantar_Tecido"
	tecido.mesh = tecido_mesh
	tecido.rotation.y = deg_to_rad(-5.0)
	tecido.material_override = _materiais[&"dining_napkin"]
	guardanapo.add_child(tecido)
	var dobra_mesh := BoxMesh.new()
	dobra_mesh.size = Vector3(0.13, 0.005, 0.20)
	var dobra := MeshInstance3D.new()
	dobra.name = "GuardanapoJantar_Dobra"
	dobra.mesh = dobra_mesh
	dobra.position = Vector3(0.055, 0.0055, 0.012)
	dobra.rotation.y = deg_to_rad(8.0)
	dobra.material_override = _materiais[&"dining_napkin_fold"]
	guardanapo.add_child(dobra)

func _adicionar_copo_infantil_jantar(centro: Vector3) -> void:
	var copo := Node3D.new()
	copo.name = "CopoInfantilJantar"
	copo.position = centro
	_raiz_visual.add_child(copo)
	var corpo_mesh := CylinderMesh.new()
	corpo_mesh.top_radius = 0.038
	corpo_mesh.bottom_radius = 0.035
	corpo_mesh.height = 0.084
	corpo_mesh.radial_segments = 32
	var corpo := MeshInstance3D.new()
	corpo.name = "CopoInfantilJantar_Corpo"
	corpo.mesh = corpo_mesh
	corpo.material_override = _materiais[&"dining_child_cup"]
	copo.add_child(corpo)
	var interior_mesh := CylinderMesh.new()
	interior_mesh.top_radius = 0.031
	interior_mesh.bottom_radius = 0.031
	interior_mesh.height = 0.002
	interior_mesh.radial_segments = 24
	var interior := MeshInstance3D.new()
	interior.name = "CopoInfantilJantar_Interior"
	interior.mesh = interior_mesh
	interior.position.y = 0.043
	interior.material_override = _materiais[&"dining_cup_interior"]
	copo.add_child(interior)
	var aro_mesh := TorusMesh.new()
	aro_mesh.inner_radius = 0.034
	aro_mesh.outer_radius = 0.039
	aro_mesh.rings = 32
	aro_mesh.ring_segments = 8
	var aro := MeshInstance3D.new()
	aro.name = "CopoInfantilJantar_Aro"
	aro.mesh = aro_mesh
	aro.position.y = 0.0445
	aro.material_override = _materiais[&"dining_child_cup"]
	copo.add_child(aro)
	var alca_mesh := TorusMesh.new()
	alca_mesh.inner_radius = 0.019
	alca_mesh.outer_radius = 0.027
	alca_mesh.rings = 24
	alca_mesh.ring_segments = 8
	var alca := MeshInstance3D.new()
	alca.name = "CopoInfantilJantar_Alca"
	alca.mesh = alca_mesh
	alca.position = Vector3(0.041, 0.0, 0.0)
	alca.rotation.x = deg_to_rad(90.0)
	alca.material_override = _materiais[&"dining_child_cup"]
	copo.add_child(alca)

func _configurar_tecido_sofa_sala(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
				var material_local := material_original.duplicate() as StandardMaterial3D
				material_local.albedo_color = material_original.albedo_color * Color(1.42, 1.30, 1.18, 1.0)
				material_local.roughness = 0.62
				material_local.metallic = 0.0
				malha.set_surface_override_material(superficie, material_local)

func _configurar_poltrona_sala(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			material_local.albedo_color = material_original.albedo_color * Color(0.48, 0.44, 0.40, 1.0)
			material_local.roughness = 0.78
			material_local.metallic = 0.0
			material_local.emission_enabled = false
			malha.set_surface_override_material(superficie, material_local)

func _configurar_mesa_reflexiva_estar(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			# Mármore carvão neutro: mantém veios/textura, sem o tom azul de plástico.
			material_local.albedo_color = material_original.albedo_color * Color(0.48, 0.44, 0.40, 1.0)
			material_local.roughness = 0.30
			material_local.metallic = 0.0
			material_local.emission_enabled = false
			material_local.emission = Color.BLACK
			malha.set_surface_override_material(superficie, material_local)

func _configurar_materiais_reflexivos_adega(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var nome_material := material_original.resource_name.to_lower()
			if "glass" not in nome_material and "vintage_cabinet_01_a" not in nome_material:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			if "glass" in nome_material:
				material_local.roughness = 0.20
				if "wine_bottles_01_glass_" in nome_material:
					var tonalidade_vidro := Color(0.45, 0.48, 0.46, 1.0)
					if "green" in nome_material:
						tonalidade_vidro = Color(0.30, 0.43, 0.30, 1.0)
					elif "orange" in nome_material:
						tonalidade_vidro = Color(0.50, 0.31, 0.16, 1.0)
					elif "yellow" in nome_material:
						tonalidade_vidro = Color(0.50, 0.43, 0.20, 1.0)
					material_local.albedo_color = material_original.albedo_color * tonalidade_vidro
				material_local.metallic = 0.0
			else:
				material_local.roughness = 0.52
			malha.set_surface_override_material(superficie, material_local)

func _atenuar_tecido_sala(modelo: Node3D, matiz: Color) -> void:
	var cache_texturas: Dictionary = {}
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			if material_original.albedo_texture != null:
				var chave_textura := str(material_original.albedo_texture.resource_path)
				if chave_textura.is_empty():
					chave_textura = str(material_original.albedo_texture.get_instance_id())
				var textura_local := cache_texturas.get(chave_textura) as Texture2D
				if textura_local == null:
					var imagem := material_original.albedo_texture.get_image()
					if imagem != null and not imagem.is_empty():
						if imagem.is_compressed():
							imagem.decompress()
						imagem.adjust_bcs(0.82, 1.04, 0.28)
						textura_local = ImageTexture.create_from_image(imagem)
						cache_texturas[chave_textura] = textura_local
				if textura_local != null:
					material_local.albedo_texture = textura_local
			material_local.albedo_color = material_original.albedo_color * matiz
			material_local.roughness = maxf(material_local.roughness, 0.88)
			material_local.metallic = 0.0
			material_local.emission_enabled = false
			malha.set_surface_override_material(superficie, material_local)

func _configurar_quadro_estar(modelo: Node3D) -> void:
	var vidro := StandardMaterial3D.new()
	vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidro.albedo_color = Color(1.0, 1.0, 1.0, 0.08)
	vidro.roughness = 0.2
	vidro.cull_mode = BaseMaterial3D.CULL_DISABLED
	vidro.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var nome_material := material_original.resource_name.to_lower()
			if "glass" in nome_material:
				malha.set_surface_override_material(superficie, vidro)
			elif "artwork" in nome_material:
				var arte_local := material_original.duplicate() as StandardMaterial3D
				arte_local.cull_mode = BaseMaterial3D.CULL_DISABLED
				arte_local.roughness = 0.92
				arte_local.emission_enabled = false
				malha.set_surface_override_material(superficie, arte_local)

func _adicionar_modelo_glb(asset_name: String, file_name: String, origem: Vector3, escala: float, rotacao_y_graus: float, floor_id: StringName, tamanho_colisao: Vector3 = Vector3.ZERO) -> void:
	var asset_path := "res://prototype/assets/models/innerscene/%s" % file_name
	if file_name.begins_with("custom/"):
		asset_path = "res://prototype/assets/models/%s" % file_name
	var cena_asset := load(asset_path) as PackedScene
	if cena_asset == null:
		push_warning("Modelo GLB indisponível: %s" % asset_path)
		return
	var modelo := cena_asset.instantiate() as Node3D
	if modelo == null:
		push_warning("A raiz do GLB não é Node3D: %s" % asset_path)
		return
	var asset_index := _contador_modelos
	modelo.name = "Asset_C2_%02d_%s" % [asset_index, asset_name]
	_contador_modelos += 1
	modelo.position = origem
	modelo.rotation.y = deg_to_rad(rotacao_y_graus)
	modelo.scale = Vector3.ONE * escala
	if asset_name == "MesaEscritorioC15" and file_name.begins_with("custom/"):
		_configurar_estofado_autoral_c15(modelo)
	elif asset_name == "MesaEscritorioC15" and not file_name.begins_with("custom/"):
		_configurar_mesa_escritorio_c15(modelo)
	elif asset_name == "EstanteEscritorio" or asset_name.begins_with("EstanteBiblioteca") or asset_name.begins_with("EstanteCompletaBiblioteca"):
		_configurar_estante_biblioteca(modelo)
	elif asset_name == "MantaLeituraBiblioteca":
		_configurar_manta_biblioteca(modelo)
	elif asset_name == "TelevisaoSala":
		_configurar_tv_desligada(modelo)
	elif asset_name == "EstanteSala":
		_configurar_estante_sala(modelo)
	elif asset_name == "VentiladorSala":
		_configurar_ventilador_apagado(modelo)
	elif asset_name == "MaquinaCafeCozinha":
		_configurar_maquina_cafe_cozinha(modelo)
	elif asset_name in ["FogaoCozinha", "Geladeira", "Microondas"]:
		_configurar_aparelho_cozinha(modelo, asset_name)
	elif asset_name in ["PiaDuplaCozinha", "TorneiraCozinha"]:
		_configurar_metal_cozinha(modelo, asset_name)
	elif asset_name == "LuminariaTripodeSala":
		_configurar_luminaria_apagada(modelo)
	elif asset_name == "CortinaJanelaSala":
		_atenuar_tecido_sala(modelo, Color(0.80, 0.82, 0.85, 1.0))
	elif asset_name == "AlmofadasSofaSala":
		_atenuar_tecido_sala(modelo, Color(0.85, 0.80, 0.73, 1.0))
	elif asset_name == "MantaSofaSala":
		_atenuar_tecido_sala(modelo, Color(0.86, 0.82, 0.76, 1.0))
	_raiz_visual.add_child(modelo)
	if tamanho_colisao != Vector3.ZERO and _corpos_colisao.has(floor_id):
		var tamanho_final := tamanho_colisao * escala
		_adicionar_colisao_caixa(origem + Vector3(0.0, tamanho_final.y * 0.5, 0.0), tamanho_final, floor_id, StringName("Hitbox_C2_%02d_%s" % [asset_index, asset_name]), Vector3(0.0, deg_to_rad(rotacao_y_graus), 0.0))

func _configurar_luminaria_apagada(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var nome_material := material_original.resource_name.to_lower()
			if "fabric" not in nome_material and "diffuser" not in nome_material:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			material_local.emission_enabled = false
			material_local.emission = Color.BLACK
			material_local.albedo_color = material_original.albedo_color * (Color(0.34, 0.37, 0.41, 1.0) if "fabric" in nome_material else Color(0.14, 0.16, 0.18, 1.0))
			material_local.roughness = 0.94
			material_local.metallic = 0.0
			malha.set_surface_override_material(superficie, material_local)

func _configurar_maquina_cafe_cozinha(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			material_local.emission_enabled = false
			material_local.emission = Color.BLACK
			var nome_material := material_original.resource_name.to_lower()
			if "metalmedium" in nome_material:
				material_local.albedo_color = Color("171b1f")
				material_local.metallic = 0.22
				material_local.roughness = 0.46
			elif "carpetwhite" in nome_material:
				material_local.albedo_color = Color("b0aca1")
				material_local.metallic = 0.02
				material_local.roughness = 0.66
			else:
				material_local.albedo_color = Color("727b80")
				material_local.metallic = 0.52
				material_local.roughness = 0.32
			malha.set_surface_override_material(superficie, material_local)

func _configurar_aparelho_cozinha(modelo: Node3D, asset_name: String) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			material_local.emission_enabled = false
			material_local.emission = Color.BLACK
			var nome_material := material_original.resource_name.to_lower()
			if asset_name == "Geladeira":
				if "handle" in nome_material or "pull" in nome_material:
					material_local.albedo_color = Color("74797b")
					material_local.roughness = 0.30
					material_local.metallic = 0.58
				else:
					material_local.albedo_color = Color("222629")
					material_local.roughness = 0.40
					material_local.metallic = 0.30
			else:
				material_local.albedo_color = material_original.albedo_color * Color(0.48, 0.50, 0.52, 1.0)
				material_local.roughness = 0.32
				material_local.metallic = maxf(material_original.metallic, 0.18)
			malha.set_surface_override_material(superficie, material_local)

func _configurar_metal_cozinha(modelo: Node3D, asset_name: String) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			var nome_material := material_original.resource_name.to_lower()
			material_local.emission_enabled = false
			material_local.emission = Color.BLACK
			if "rubber" in nome_material or "felt" in nome_material:
				material_local.albedo_color = Color("1b1e20")
				material_local.metallic = 0.0
				material_local.roughness = 0.84
			elif "galvanized" in nome_material:
				material_local.albedo_color = Color("aeb4b6")
				material_local.metallic = 0.72
				material_local.roughness = 0.40
			else:
				material_local.albedo_color = Color("b5bbbe")
				material_local.metallic = 0.84
				material_local.roughness = 0.25 if asset_name == "TorneiraCozinha" else 0.29
			malha.set_surface_override_material(superficie, material_local)

func _configurar_microondas_polyhaven(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			var nome_material := material_original.resource_name.to_lower()
			material_local.emission_enabled = false
			material_local.emission = Color.BLACK
			if "glass" in nome_material:
				material_local.albedo_color = Color("101416")
				material_local.metallic = 0.24
				material_local.roughness = 0.18
			else:
				material_local.albedo_color = Color("34383b")
				material_local.metallic = 0.46
				material_local.roughness = 0.32
			malha.set_surface_override_material(superficie, material_local)

func _desligar_emissao_modelo(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.name == "Lua":
			continue
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null or not material_original.emission_enabled:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			material_local.emission_enabled = false
			material_local.emission = Color.BLACK
			malha.set_surface_override_material(superficie, material_local)

func _configurar_tv_desligada(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.mesh.surface_get_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_escuro := material_original.duplicate() as StandardMaterial3D
			material_escuro.emission_enabled = false
			material_escuro.emission = Color.BLACK
			material_escuro.albedo_color = Color("090c10") if material_original.resource_name == "metal" else Color("202428")
			material_escuro.roughness = 0.28 if material_original.resource_name == "metal" else 0.42
			material_escuro.metallic = 0.05
			malha.set_surface_override_material(superficie, material_escuro)

func _configurar_estante_sala(modelo: Node3D) -> void:
	var madeira := _materiais.get(&"wood_shelf") as StandardMaterial3D
	if madeira == null:
		return
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if "cabinet" in malha.name.to_lower():
			malha.material_override = madeira

func _configurar_ventilador_apagado(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_apagado := material_original.duplicate() as StandardMaterial3D
			material_apagado.emission_enabled = false
			material_apagado.emission = Color.BLACK
			material_apagado.albedo_color = material_original.albedo_color * Color(0.34, 0.36, 0.40, 1.0)
			material_apagado.roughness = 0.68
			material_apagado.metallic = 0.10
			malha.set_surface_override_material(superficie, material_apagado)

func _adicionar_painel_midia_estar() -> void:
	var centro_z := 6.15
	_adicionar_caixa(Vector3(-9.145, 1.34, centro_z), Vector3(0.07, 2.48, 3.0), &"wood_shelf", &"terreo", false)
	# O painel contínuo dá textura à parede sem ripas que pareçam colunas sobre os móveis.

func _adicionar_armario_cozinha(center: Vector3, width: float, recorte_pia: bool = false) -> void:
	var depth := 0.62
	var cabinet_height := 0.72
	_adicionar_caixa(center + Vector3(0.0, cabinet_height * 0.5, 0.0), Vector3(width, cabinet_height, depth), &"kitchen_cabinet", &"terreo", true)
	var panel_width := (width - 0.08) / 3.0
	for door_index in range(3):
		var panel_x := center.x - width * 0.5 + 0.04 + panel_width * (float(door_index) + 0.5)
		var panel_z := center.z + depth * 0.5 + 0.02
		_adicionar_caixa(Vector3(panel_x, center.y + 0.60, panel_z), Vector3(panel_width - 0.025, 0.15, 0.035), &"kitchen_front", &"terreo", false)
		_adicionar_caixa(Vector3(panel_x, center.y + 0.315, panel_z), Vector3(panel_width - 0.025, 0.41, 0.035), &"kitchen_front", &"terreo", false)
		_adicionar_puxador_cozinha(Vector3(panel_x, center.y + 0.60, panel_z + 0.04), Vector3.RIGHT, Vector3.FORWARD, 0.15)
		_adicionar_puxador_cozinha(Vector3(panel_x + panel_width * 0.31, center.y + 0.315, panel_z + 0.04), Vector3.UP, Vector3.FORWARD, 0.11)
	if recorte_pia:
		var opening_width := 1.04
		var opening_depth := 0.57
		var side_width := (width - opening_width) * 0.5
		for side in [-1.0, 1.0]:
			var side_x: float = center.x + side * (opening_width * 0.5 + side_width * 0.5)
			_adicionar_caixa(Vector3(side_x, center.y + 0.76, center.z), Vector3(side_width, 0.08, depth + 0.04), &"kitchen_counter", &"terreo", false)
		var bridge_depth := (depth + 0.04 - opening_depth) * 0.5
		for side in [-1.0, 1.0]:
			var bridge_z: float = center.z + side * (opening_depth * 0.5 + bridge_depth * 0.5)
			_adicionar_caixa(Vector3(center.x, center.y + 0.76, bridge_z), Vector3(opening_width, 0.08, bridge_depth), &"kitchen_counter", &"terreo", false)
	else:
		_adicionar_caixa(center + Vector3(0.0, 0.76, 0.0), Vector3(width, 0.08, depth + 0.04), &"kitchen_counter", &"terreo", false)

func _adicionar_puxador_cozinha(center: Vector3, direction: Vector3, normal: Vector3, length: float) -> void:
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.006
	handle_mesh.bottom_radius = 0.006
	handle_mesh.height = length
	handle_mesh.radial_segments = 12
	var handle := MeshInstance3D.new()
	handle.name = "PuxadorCozinha"
	handle.mesh = handle_mesh
	handle.material_override = _materiais[&"kitchen_hardware"]
	handle.position = center
	handle.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
	_raiz_visual.add_child(handle)
	for side in [-1.0, 1.0]:
		var mount_mesh := CylinderMesh.new()
		mount_mesh.top_radius = 0.007
		mount_mesh.bottom_radius = 0.007
		mount_mesh.height = 0.020
		mount_mesh.radial_segments = 10
		var mount := MeshInstance3D.new()
		mount.name = "BasePuxadorCozinha"
		mount.mesh = mount_mesh
		mount.material_override = _materiais[&"kitchen_hardware"]
		mount.position = center + direction * (length * 0.34 * side) - normal * 0.011
		mount.basis = Basis(Quaternion(Vector3.UP, normal.normalized()))
		_raiz_visual.add_child(mount)

func _adicionar_botao_cozinha(center: Vector3, normal: Vector3, radius: float, depth: float, material_key: StringName) -> void:
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = radius
	disc_mesh.bottom_radius = radius
	disc_mesh.height = depth
	disc_mesh.radial_segments = 20
	var disc := MeshInstance3D.new()
	disc.name = "BotaoFornoCozinha"
	disc.mesh = disc_mesh
	disc.material_override = _materiais[material_key]
	disc.position = center
	disc.basis = Basis(Quaternion(Vector3.UP, normal.normalized()))
	_raiz_visual.add_child(disc)

func _adicionar_caixa_local(parent: Node3D, mesh_name: String, local_position: Vector3, size: Vector3, material_key: StringName) -> MeshInstance3D:
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = box_mesh
	instance.material_override = _materiais[material_key]
	instance.position = local_position
	parent.add_child(instance)
	return instance

func _adicionar_forno_procedural(center: Vector3) -> void:
	var forno := Node3D.new()
	forno.name = "FornoProceduralCozinha"
	forno.position = center + Vector3(-0.05, 0.0, 0.0)
	_raiz_visual.add_child(forno)
	_adicionar_caixa_local(forno, "CarcacaForno", Vector3.ZERO, Vector3(0.32, 0.62, 0.64), &"metal_dark")
	# Moldura estreita de aço ao redor do vidro, com display e controles completamente apagados.
	_adicionar_caixa_local(forno, "AroFornoLateralA", Vector3(-0.177, 0.0, -0.247), Vector3(0.018, 0.52, 0.026), &"kitchen_hardware")
	_adicionar_caixa_local(forno, "AroFornoLateralB", Vector3(-0.177, 0.0, 0.247), Vector3(0.018, 0.52, 0.026), &"kitchen_hardware")
	_adicionar_caixa_local(forno, "AroFornoInferior", Vector3(-0.177, -0.25, 0.0), Vector3(0.018, 0.02, 0.53), &"kitchen_hardware")
	_adicionar_caixa_local(forno, "AroFornoSuperior", Vector3(-0.177, 0.225, 0.0), Vector3(0.018, 0.02, 0.53), &"kitchen_hardware")
	_adicionar_caixa_local(forno, "VidroEscuroForno", Vector3(-0.19, 0.0, 0.0), Vector3(0.012, 0.38, 0.46), &"kitchen_appliance_glass")
	_adicionar_caixa_local(forno, "FaixaControlesForno", Vector3(-0.177, 0.28, 0.0), Vector3(0.018, 0.055, 0.58), &"kitchen_hardware")
	_adicionar_caixa_local(forno, "DisplayApagadoForno", Vector3(-0.19, 0.28, 0.0), Vector3(0.012, 0.026, 0.075), &"kitchen_reveal")
	_adicionar_puxador_cozinha(forno.position + Vector3(-0.21, 0.21, 0.0), Vector3.FORWARD, Vector3.LEFT, 0.42)
	for knob_z in [-0.21, 0.21]:
		_adicionar_botao_cozinha(forno.position + Vector3(-0.20, 0.28, knob_z), Vector3.LEFT, 0.018, 0.018, &"kitchen_hardware")

func _adicionar_cilindro_cozinha(mesh_name: String, center: Vector3, height: float, top_radius: float, bottom_radius: float, material_key: StringName, segments: int = 24) -> MeshInstance3D:
	var cylinder_mesh := CylinderMesh.new()
	cylinder_mesh.top_radius = top_radius
	cylinder_mesh.bottom_radius = bottom_radius
	cylinder_mesh.height = height
	cylinder_mesh.radial_segments = segments
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = cylinder_mesh
	instance.material_override = _materiais[material_key]
	instance.position = center
	_raiz_visual.add_child(instance)
	return instance

func _adicionar_segmento_cozinha(mesh_name: String, start: Vector3, finish: Vector3, radius: float, material_key: StringName) -> void:
	var axis := finish - start
	var segment_mesh := CylinderMesh.new()
	segment_mesh.top_radius = radius
	segment_mesh.bottom_radius = radius
	segment_mesh.height = axis.length()
	segment_mesh.radial_segments = 12
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = segment_mesh
	instance.material_override = _materiais[material_key]
	instance.position = (start + finish) * 0.5
	instance.basis = Basis(Quaternion(Vector3.UP, axis.normalized()))
	_raiz_visual.add_child(instance)

func _adicionar_caneca_cozinha(base: Vector3, id: String, material_key: StringName, cheia: bool = false) -> void:
	_adicionar_cilindro_cozinha("Caneca_%s_Corpo" % id, base + Vector3(0.0, 0.045, 0.0), 0.09, 0.044, 0.036, material_key)
	var conteudo_key: StringName = &"kitchen_coffee" if cheia else &"kitchen_reveal"
	_adicionar_cilindro_cozinha("Caneca_%s_Interior" % id, base + Vector3(0.0, 0.079, 0.0), 0.003, 0.034, 0.034, conteudo_key)
	_adicionar_segmento_cozinha("Caneca_%s_AlcaSuperior" % id, base + Vector3(0.037, 0.070, 0.0), base + Vector3(0.066, 0.070, 0.0), 0.005, material_key)
	_adicionar_segmento_cozinha("Caneca_%s_AlcaLateral" % id, base + Vector3(0.066, 0.070, 0.0), base + Vector3(0.066, 0.022, 0.0), 0.005, material_key)
	_adicionar_segmento_cozinha("Caneca_%s_AlcaInferior" % id, base + Vector3(0.066, 0.022, 0.0), base + Vector3(0.037, 0.022, 0.0), 0.005, material_key)

func _adicionar_pratos_cozinha(base: Vector3, id: String, count: int, material_key: StringName) -> void:
	for index in range(count):
		var plate_y := 0.007 + float(index) * 0.016
		_adicionar_cilindro_cozinha("Prato_%s_%02d" % [id, index + 1], base + Vector3(0.0, plate_y, 0.0), 0.014, 0.116, 0.094, material_key, 32)

func _adicionar_pote_tempero_cozinha(base: Vector3, id: String, material_key: StringName) -> void:
	_adicionar_cilindro_cozinha("Tempero_%s_Corpo" % id, base + Vector3(0.0, 0.046, 0.0), 0.092, 0.031, 0.034, material_key)
	_adicionar_cilindro_cozinha("Tempero_%s_Rotulo" % id, base + Vector3(0.0, 0.045, 0.0), 0.024, 0.034, 0.035, &"kitchen_spice_label")
	_adicionar_cilindro_cozinha("Tempero_%s_Tampa" % id, base + Vector3(0.0, 0.100, 0.0), 0.014, 0.034, 0.034, &"kitchen_hardware")

func _adicionar_utensilios_cozinha(base: Vector3, id: String) -> void:
	var offsets := [Vector3(-0.025, 0.0, -0.018), Vector3(0.0, 0.0, 0.012), Vector3(0.025, 0.0, -0.004)]
	for index in range(offsets.size()):
		var offset: Vector3 = offsets[index]
		var start := base + offset + Vector3(0.0, 0.105, 0.0)
		var finish := base + offset + Vector3(0.012 * float(index - 1), 0.292 - float(index % 2) * 0.025, 0.012)
		_adicionar_segmento_cozinha("Utensilio_%s_Cabo_%02d" % [id, index + 1], start, finish, 0.006, &"kitchen_wood")
		var spoon_mesh := SphereMesh.new()
		spoon_mesh.radius = 0.018
		spoon_mesh.height = 0.034
		spoon_mesh.radial_segments = 16
		spoon_mesh.rings = 8
		var spoon := MeshInstance3D.new()
		spoon.name = "Utensilio_%s_Ponta_%02d" % [id, index + 1]
		spoon.mesh = spoon_mesh
		spoon.material_override = _materiais[&"kitchen_wood"]
		spoon.scale = Vector3(0.72, 1.0, 0.52)
		spoon.position = finish + Vector3(0.0, 0.014, 0.0)
		_raiz_visual.add_child(spoon)

func _adicionar_faca_preparo_cozinha(base: Vector3, id: String) -> void:
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.026, 0.008, 0.15)
	var blade := MeshInstance3D.new()
	blade.name = "Faca_%s_Lamina" % id
	blade.mesh = blade_mesh
	blade.material_override = _materiais[&"kitchen_hardware"]
	blade.position = base + Vector3(0.0, 0.007, -0.035)
	blade.rotation.y = deg_to_rad(-8.0)
	_raiz_visual.add_child(blade)
	var blunt_tip_mesh := SphereMesh.new()
	blunt_tip_mesh.radius = 0.013
	blunt_tip_mesh.height = 0.013
	var blunt_tip := MeshInstance3D.new()
	blunt_tip.name = "Faca_%s_PontaArredondada" % id
	blunt_tip.mesh = blunt_tip_mesh
	blunt_tip.material_override = _materiais[&"kitchen_hardware"]
	blunt_tip.scale = Vector3(0.9, 0.4, 0.9)
	blunt_tip.position = base + Vector3(0.0, 0.008, -0.112)
	blunt_tip.rotation.y = deg_to_rad(-8.0)
	_raiz_visual.add_child(blunt_tip)
	var handle_mesh := CapsuleMesh.new()
	handle_mesh.radius = 0.013
	handle_mesh.height = 0.078
	handle_mesh.radial_segments = 12
	handle_mesh.rings = 6
	var handle := MeshInstance3D.new()
	handle.name = "Faca_%s_Cabo" % id
	handle.mesh = handle_mesh
	handle.material_override = _materiais[&"kitchen_front"]
	handle.position = base + Vector3(0.0, 0.011, 0.09)
	handle.rotation.x = deg_to_rad(90.0)
	handle.rotation.y = deg_to_rad(-8.0)
	_raiz_visual.add_child(handle)

func _adicionar_pano_cozinha(center: Vector3, id: String) -> void:
	var cloth_surface := SurfaceTool.new()
	cloth_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments_x := 10
	var segments_z := 8
	var positions := PackedVector3Array()
	var uvs := PackedVector2Array()
	for zi in range(segments_z + 1):
		for xi in range(segments_x + 1):
			var u := float(xi) / float(segments_x)
			var v := float(zi) / float(segments_z)
			var ripple := 0.003 * (1.0 + sin(u * PI * 3.0 + v * PI * 1.4) * sin(v * PI))
			positions.append(Vector3((u - 0.5) * 0.30, ripple, (v - 0.5) * 0.22))
			uvs.append(Vector2(u, v))
	for zi in range(segments_z):
		for xi in range(segments_x):
			var p00 := zi * (segments_x + 1) + xi
			var p10 := p00 + 1
			var p01 := p00 + segments_x + 1
			var p11 := p01 + 1
			for vertex_index in PackedInt32Array([p00, p01, p11, p00, p11, p10]):
				cloth_surface.set_uv(uvs[vertex_index])
				cloth_surface.add_vertex(positions[vertex_index])
	cloth_surface.index()
	cloth_surface.generate_normals()
	var towel_mesh := cloth_surface.commit()
	var towel := MeshInstance3D.new()
	towel.name = "Pano_%s_Base" % id
	towel.mesh = towel_mesh
	towel.material_override = _materiais[&"kitchen_linen"]
	towel.position = center
	towel.rotation.y = deg_to_rad(-12.0)
	_raiz_visual.add_child(towel)

func _adicionar_armario_aereo(center: Vector3, width: float) -> void:
	var height := 0.90
	var depth := 0.42
	_adicionar_caixa(center, Vector3(width, height, depth), &"kitchen_cabinet", &"terreo", false)
	var panel_width := width * 0.5 - 0.025
	for door_index in range(2):
		var panel_x := center.x + (float(door_index) - 0.5) * width * 0.5
		var panel_z := center.z + depth * 0.5 + 0.02
		_adicionar_caixa(Vector3(panel_x, center.y, panel_z), Vector3(panel_width, height - 0.08, 0.035), &"kitchen_front", &"terreo", false)
		var handle_x := panel_x + panel_width * 0.34 if door_index == 0 else panel_x - panel_width * 0.34
		_adicionar_puxador_cozinha(Vector3(handle_x, center.y, panel_z + 0.04), Vector3.UP, Vector3.FORWARD, 0.12)
	_adicionar_caixa(Vector3(center.x, center.y - height * 0.5 - 0.025, center.z), Vector3(width, 0.05, depth), &"kitchen_wood", &"terreo", false)

func _adicionar_torre_cozinha(center: Vector3) -> void:
	# Carcaça aberta em nichos reais; o volume de colisão permanece idêntico ao anterior.
	var depth := 0.42
	var width := 0.92
	var height := 2.64
	var front_x := center.x - depth * 0.5
	_adicionar_colisao_caixa(center + Vector3(0.0, height * 0.5, 0.0), Vector3(depth, height, width), &"terreo", &"ColisaoTorreFornoCozinha")
	for side in [-1.0, 1.0]:
		_adicionar_caixa(center + Vector3(0.0, height * 0.5, side * (width * 0.5 - 0.025)), Vector3(depth, height, 0.05), &"kitchen_wood", &"terreo", false)
	_adicionar_caixa(center + Vector3(depth * 0.5 - 0.02, height * 0.5, 0.0), Vector3(0.04, height - 0.08, width - 0.08), &"kitchen_wood", &"terreo", false)
	_adicionar_caixa(center + Vector3(0.0, 0.03, 0.0), Vector3(depth, 0.06, width), &"kitchen_wood", &"terreo", false)
	_adicionar_caixa(center + Vector3(0.0, height - 0.03, 0.0), Vector3(depth, 0.06, width), &"kitchen_wood", &"terreo", false)
	var panel_x := front_x - 0.02
	for side in [-1.0, 1.0]:
		var door_z: float = center.z + side * 0.205
		_adicionar_caixa(Vector3(panel_x, center.y + 2.29, door_z), Vector3(0.035, 0.62, 0.38), &"kitchen_wood", &"terreo", false)
		var upper_handle_z: float = center.z + (0.14 if side < 0.0 else -0.14)
		_adicionar_puxador_cozinha(Vector3(panel_x - 0.04, center.y + 2.29, upper_handle_z), Vector3.UP, Vector3.LEFT, 0.11)
		_adicionar_caixa(Vector3(panel_x, center.y + 0.34, door_z), Vector3(0.035, 0.55, 0.38), &"kitchen_wood", &"terreo", false)
		var lower_handle_z: float = center.z + (0.14 if side < 0.0 else -0.14)
		_adicionar_puxador_cozinha(Vector3(panel_x - 0.04, center.y + 0.34, lower_handle_z), Vector3.UP, Vector3.LEFT, 0.11)
	_adicionar_caixa(Vector3(panel_x, center.y + 0.71, center.z), Vector3(0.035, 0.12, 0.78), &"kitchen_wood", &"terreo", false)
	_adicionar_puxador_cozinha(Vector3(panel_x - 0.04, center.y + 0.71, center.z), Vector3.FORWARD, Vector3.LEFT, 0.16)
	# Nichos escuros sem emissividade; a prateleira separa o forno do micro-ondas.
	_adicionar_caixa(Vector3(front_x + 0.05, center.y + 1.10, center.z), Vector3(0.02, 0.70, 0.74), &"kitchen_reveal", &"terreo", false)
	_adicionar_caixa(Vector3(center.x, center.y + 1.48, center.z), Vector3(depth - 0.06, 0.035, width - 0.10), &"kitchen_wood", &"terreo", false)
	_adicionar_caixa(Vector3(front_x + 0.05, center.y + 1.72, center.z), Vector3(0.02, 0.42, 0.74), &"kitchen_reveal", &"terreo", false)
	# O forno, sua face e seus controles apagados são montados separadamente sem GLB de IA.

func _adicionar_fogao_inducao_cozinha(center: Vector3) -> void:
	# Cooktop discreto embutido na bancada; o forno permanece na torre de nogueira.
	_adicionar_caixa(center + Vector3(0.0, 0.804, 0.0), Vector3(0.55, 0.012, 0.44), &"kitchen_appliance_glass", &"terreo", false)
	var material_anel := StandardMaterial3D.new()
	material_anel.albedo_color = Color("343a3e")
	material_anel.metallic = 0.28
	material_anel.roughness = 0.38
	for offset_x in [-0.14, 0.14]:
		for offset_z in [-0.10, 0.10]:
			var disco_mesh := CylinderMesh.new()
			disco_mesh.top_radius = 0.060
			disco_mesh.bottom_radius = 0.060
			disco_mesh.height = 0.004
			disco_mesh.radial_segments = 32
			var disco := MeshInstance3D.new()
			disco.name = "CooktopDiscoInducao"
			disco.mesh = disco_mesh
			disco.material_override = material_anel
			disco.position = center + Vector3(offset_x, 0.813, offset_z)
			_raiz_visual.add_child(disco)

func _adicionar_panela_apagada_cozinha(base: Vector3) -> void:
	_adicionar_cilindro_cozinha("PanelaCozinhaCorpo", base + Vector3(0.0, 0.067, 0.0), 0.134, 0.096, 0.087, &"kitchen_cookware", 32)
	_adicionar_cilindro_cozinha("PanelaCozinhaTampa", base + Vector3(0.0, 0.143, 0.0), 0.018, 0.018, 0.094, &"kitchen_cookware", 32)
	var knob_mesh := SphereMesh.new()
	knob_mesh.radius = 0.012
	knob_mesh.height = 0.020
	knob_mesh.radial_segments = 16
	knob_mesh.rings = 8
	var knob := MeshInstance3D.new()
	knob.name = "PanelaCozinhaPuxadorTampa"
	knob.mesh = knob_mesh
	knob.material_override = _materiais[&"kitchen_hardware"]
	knob.position = base + Vector3(0.0, 0.166, 0.0)
	_raiz_visual.add_child(knob)
	for side in [-1.0, 1.0]:
		var z_offset: float = side * 0.092
		var z_tip: float = side * 0.132
		_adicionar_segmento_cozinha("PanelaCozinhaAlcaSuporteA_%s" % str(side), base + Vector3(-0.032, 0.104, z_offset), base + Vector3(-0.032, 0.104, z_tip), 0.006, &"kitchen_hardware")
		_adicionar_segmento_cozinha("PanelaCozinhaAlcaSuporteB_%s" % str(side), base + Vector3(0.032, 0.104, z_offset), base + Vector3(0.032, 0.104, z_tip), 0.006, &"kitchen_hardware")
		_adicionar_segmento_cozinha("PanelaCozinhaAlca_%s" % str(side), base + Vector3(-0.032, 0.104, z_tip), base + Vector3(0.032, 0.104, z_tip), 0.006, &"kitchen_hardware")

func _adicionar_ilha_cozinha(center: Vector3) -> void:
	# Gavetas superiores e portas inferiores no lado de preparo; as banquetas ficam no lado oposto.
	_adicionar_caixa(center + Vector3(0.0, 0.40, -0.02), Vector3(1.90, 0.80, 0.82), &"kitchen_cabinet", &"terreo", true)
	var panel_width := 1.82 / 3.0
	for module_index in range(3):
		var panel_x := center.x - 0.91 + panel_width * (float(module_index) + 0.5)
		var front_z := center.z - 0.45
		_adicionar_caixa(Vector3(panel_x, center.y + 0.65, front_z), Vector3(panel_width - 0.025, 0.15, 0.025), &"kitchen_front", &"terreo", false)
		_adicionar_caixa(Vector3(panel_x, center.y + 0.32, front_z), Vector3(panel_width - 0.025, 0.42, 0.025), &"kitchen_front", &"terreo", false)
		_adicionar_puxador_cozinha(Vector3(panel_x, center.y + 0.65, center.z - 0.49), Vector3.RIGHT, Vector3.BACK, 0.15)
		_adicionar_puxador_cozinha(Vector3(panel_x + panel_width * 0.31, center.y + 0.32, center.z - 0.49), Vector3.UP, Vector3.BACK, 0.12)
	# Painéis de extremidade de acabamento, sem colisão adicional sobre o corpo estrutural.
	for side in [-1.0, 1.0]:
		_adicionar_caixa(center + Vector3(side * 0.94, 0.40, 0.0), Vector3(0.035, 0.76, 0.78), &"kitchen_front", &"terreo", false)
	# Linha de sombra discreta sob o tampo, antes do balanço de nogueira.
	_adicionar_caixa(center + Vector3(0.0, 0.786, -0.02), Vector3(1.94, 0.022, 0.84), &"kitchen_front", &"terreo", false)
	_adicionar_caixa(center + Vector3(0.0, 0.84, 0.07), Vector3(2.12, 0.08, 1.16), &"kitchen_wood", &"terreo", false)

func _adicionar_banquetas_cozinha(center: Vector3) -> void:
	var indice := _contador_modelos
	_contador_modelos += 1
	_adicionar_colisao_caixa(center + Vector3(0.0, 0.34, 0.0), Vector3(0.42, 0.68, 0.42), &"terreo", StringName("ColisaoBanquetaCozinha_%02d" % indice))
	var aro := CylinderMesh.new()
	aro.top_radius = 0.18
	aro.bottom_radius = 0.17
	aro.height = 0.035
	var suporte := MeshInstance3D.new()
	suporte.name = "AroBanquetaCozinha_%02d" % indice
	suporte.mesh = aro
	suporte.material_override = _materiais[&"kitchen_hardware"]
	suporte.position = center + Vector3(0.0, 0.61, 0.0)
	_raiz_visual.add_child(suporte)
	var assento_mesh := CylinderMesh.new()
	assento_mesh.top_radius = 0.20
	assento_mesh.bottom_radius = 0.20
	assento_mesh.height = 0.075
	var assento := MeshInstance3D.new()
	assento.name = "AssentoBanquetaCozinha_%02d" % indice
	assento.mesh = assento_mesh
	assento.material_override = _materiais[&"kitchen_stool_seat"]
	assento.position = center + Vector3(0.0, 0.67, 0.0)
	_raiz_visual.add_child(assento)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var perna_mesh := CylinderMesh.new()
			perna_mesh.top_radius = 0.018
			perna_mesh.bottom_radius = 0.021
			perna_mesh.height = 0.62
			var perna := MeshInstance3D.new()
			perna.name = "PernaBanquetaCozinha_%02d" % indice
			perna.mesh = perna_mesh
			perna.material_override = _materiais[&"kitchen_hardware"]
			perna.position = center + Vector3(sx * 0.145, 0.32, sz * 0.145)
			perna.rotation = Vector3(-sz * 0.08, 0.0, sx * 0.08)
			_raiz_visual.add_child(perna)
	for sz in [-1.0, 1.0]:
		_adicionar_caixa(center + Vector3(0.0, 0.28, sz * 0.115), Vector3(0.29, 0.022, 0.022), &"kitchen_hardware", &"terreo", false)
	for sx in [-1.0, 1.0]:
		_adicionar_caixa(center + Vector3(sx * 0.115, 0.28, 0.0), Vector3(0.022, 0.022, 0.29), &"kitchen_hardware", &"terreo", false)

func _adicionar_prateleiras_cozinha(y: float) -> void:
	# Estrutura aberta rente à parede leste, com painel de fundo e prateleiras de nogueira.
	var x := -2.16
	var z := -5.30
	_adicionar_caixa(Vector3(x + 0.165, y + 1.79, z), Vector3(0.035, 1.38, 1.48), &"kitchen_wood", &"terreo", false)
	for nivel in [1.36, 1.79, 2.22]:
		_adicionar_caixa(Vector3(x, y + nivel, z), Vector3(0.28, 0.045, 1.48), &"kitchen_wood", &"terreo", false)
	for suporte_z in [z - 0.66, z + 0.66]:
		_adicionar_caixa(Vector3(x + 0.11, y + 1.79, suporte_z), Vector3(0.035, 1.30, 0.035), &"kitchen_hardware", &"terreo", false)

func _adicionar_placa_sala(texto: String, origem: Vector3, rotacao_y_graus: float, largura: float = 1.2) -> void:
	var conjunto := Node3D.new()
	conjunto.name = "Placa_%s" % texto.replace(" ", "_")
	conjunto.position = origem
	conjunto.rotation.y = deg_to_rad(rotacao_y_graus)
	_raiz_visual.add_child(conjunto)
	var suporte := MeshInstance3D.new()
	var suporte_mesh := BoxMesh.new()
	suporte_mesh.size = Vector3(largura, 0.22, 0.045)
	suporte.mesh = suporte_mesh
	suporte.material_override = _materiais[&"wood_warm"]
	conjunto.add_child(suporte)
	var legenda := Label3D.new()
	legenda.text = texto
	legenda.font_size = 30
	legenda.pixel_size = 0.004
	legenda.position.z = 0.026
	legenda.modulate = Color("eee2c9")
	legenda.outline_size = 5
	legenda.outline_modulate = Color("191714")
	legenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legenda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	conjunto.add_child(legenda)

func _adicionar_luz_de_oleo(origem: Vector3) -> void:
	var luz := OmniLight3D.new()
	luz.name = "LuzQuenteLamparina"
	luz.position = origem
	luz.light_color = Color("ffc98a")
	luz.light_energy = 1.25
	luz.omni_range = 3.2
	luz.shadow_enabled = false
	_raiz_visual.add_child(luz)

func _adicionar_luz_ambiente_estar() -> void:
	var luar_janela := SpotLight3D.new()
	luar_janela.name = "LuarFrioSalaEstar"
	luar_janela.position = Vector3(-8.95, 1.95, 3.65)
	luar_janela.rotation.y = deg_to_rad(-90.0)
	luar_janela.light_color = Color("91a7c9")
	luar_janela.light_energy = 0.34
	luar_janela.spot_range = 6.0
	luar_janela.spot_angle = 52.0
	luar_janela.shadow_enabled = true
	_raiz_visual.add_child(luar_janela)
	var luz_teto := OmniLight3D.new()
	luz_teto.name = "ReflexoVentiladorSala"
	luz_teto.position = Vector3(-5.65, 1.70, 6.0)
	luz_teto.light_color = Color("8599bc")
	luz_teto.light_energy = 0.08
	luz_teto.omni_range = 3.0
	luz_teto.shadow_enabled = false
	_raiz_visual.add_child(luz_teto)
	var luz_lamparina := OmniLight3D.new()
	luz_lamparina.name = "LuzQuenteLamparinaSala"
	luz_lamparina.position = Vector3(-4.15, 0.84, 6.2)
	luz_lamparina.light_color = Color("ffc88b")
	luz_lamparina.light_energy = 0.72
	luz_lamparina.omni_range = 3.6
	luz_lamparina.shadow_enabled = false
	_raiz_visual.add_child(luz_lamparina)

func _apagar_luzes_internas() -> void:
	# A casa está sem energia; as luminárias permanecem como props, mas apagadas.
	# O luar global e a lanterna do jogador ficam fora desta raiz visual.
	for nodo_luz in _raiz_visual.find_children("*", "Light3D", true, false):
		var luz := nodo_luz as Light3D
		if luz != null:
			luz.visible = false
	# Apaga também as superfícies emissivas de lâmpadas; a malha externa "Lua" é preservada.
	_desligar_emissao_modelo(_raiz_visual)

func _adicionar_planta_interior(floor_id: StringName, origem: Vector3, escala_folhagem: float) -> void:
	_adicionar_modelo_mobiliario("planter_pot_clay", origem, 1.0, 0.0, floor_id)
	_adicionar_modelo_mobiliario("fern_02", origem + Vector3(0.0, 0.2, 0.0), escala_folhagem, 0.0, floor_id)

func _mobiliar_primeiro_andar() -> void:
	var y := ALTURA_ANDAR
	# Quarto compartilhado das crianças, dimensionado para circulação ao redor das duas camas.
	_adicionar_tapete(&"primeiro", Vector3(-4.4, y + 0.02, -3.25), Vector2(4.0, 3.0), &"rug")
	_adicionar_cama(&"primeiro", Vector3(-5.85, y, -3.2), Vector2(1.15, 2.15), &"linen_blue", &"wood_warm")
	_adicionar_cama(&"primeiro", Vector3(-3.65, y, -3.2), Vector2(1.15, 2.15), &"linen_mauve", &"wood_warm")
	_adicionar_caixa(Vector3(-5.5, y + 0.36, -1.45), Vector3(0.62, 0.72, 0.58), &"wood_light", &"primeiro", true)
	_adicionar_caixa(Vector3(-4.4, y + 0.42, -4.95), Vector3(1.55, 0.84, 0.58), &"wood_warm", &"primeiro", true)
	_adicionar_caixa(Vector3(-4.4, y + 0.87, -4.95), Vector3(1.62, 0.08, 0.68), &"wood_light", &"primeiro", false)
	_adicionar_cadeira(&"primeiro", Vector3(-4.4, y, -4.2), &"wood_warm", &"fabric_sage")
	_adicionar_caixa(Vector3(-4.82, y + 1.45, -5.22), Vector3(0.24, 0.32, 0.28), &"toy_blue", &"primeiro", false)
	_adicionar_caixa(Vector3(-4.52, y + 1.44, -5.22), Vector3(0.2, 0.28, 0.22), &"toy_red", &"primeiro", false)
	_adicionar_quadro_eixo_x(&"primeiro", Vector3(-4.4, y + 2.1, -5.36), Vector2(1.05, 0.72), &"wood_light", &"toy_blue")
	# Suíte do casal no lado oposto, com área livre entre cama e porta.
	_adicionar_tapete(&"primeiro", Vector3(4.35, y + 0.02, -3.25), Vector2(4.0, 3.0), &"rug_detail")
	_adicionar_cama(&"primeiro", Vector3(4.35, y, -3.25), Vector2(2.25, 2.25), &"linen_cream", &"wood_warm")
	_adicionar_caixa(Vector3(2.55, y + 0.42, -4.2), Vector3(0.58, 0.82, 0.58), &"wood_warm", &"primeiro", true)
	_adicionar_caixa(Vector3(6.15, y + 0.42, -4.2), Vector3(0.58, 0.82, 0.58), &"wood_warm", &"primeiro", true)
	_adicionar_caixa(Vector3(6.4, y + 0.62, -1.65), Vector3(0.82, 1.25, 0.65), &"wood_light", &"primeiro", true)
	_adicionar_caixa(Vector3(6.4, y + 1.28, -1.65), Vector3(0.88, 0.08, 0.72), &"wood_warm", &"primeiro", false)
	_adicionar_quadro_eixo_x(&"primeiro", Vector3(4.35, y + 2.1, -5.36), Vector2(1.0, 0.72), &"wood_light", &"fabric_rose")
	# Closet compartilhado/roupa de cama da ala esquerda, adjacente ao dormitório infantil.
	_adicionar_tapete(&"primeiro", Vector3(-4.4, y + 0.02, 0.55), Vector2(3.6, 2.0), &"rug_detail")
	_adicionar_caixa(Vector3(-6.35, y + 1.0, 0.55), Vector3(0.85, 2.0, 2.2), &"wood_warm", &"primeiro", true)
	_adicionar_caixa(Vector3(-5.9, y + 1.0, 0.55), Vector3(0.08, 1.88, 2.08), &"wood_light", &"primeiro", false)
	_adicionar_caixa(Vector3(3.0, y + 0.45, 1.4), Vector3(1.7, 0.9, 0.75), &"wood_warm", &"primeiro", true)
	_adicionar_caixa(Vector3(3.0, y + 0.94, 1.4), Vector3(1.8, 0.08, 0.82), &"wood_light", &"primeiro", false)
	_adicionar_caixa(Vector3(6.4, y + 1.0, 0.55), Vector3(0.85, 2.0, 2.1), &"wood_warm", &"primeiro", true)
	# Banheiro familiar e banho da suíte, ambos separados dos dormitórios por portas.
	_adicionar_caixa(Vector3(-4.4, y + 0.025, 3.75), Vector3(3.8, 0.035, 2.5), &"tile_alt", &"primeiro", false)
	_adicionar_caixa(Vector3(-5.8, y + 0.42, 3.9), Vector3(2.15, 0.84, 1.45), &"porcelain", &"primeiro", true)
	_adicionar_caixa(Vector3(-5.8, y + 0.87, 3.9), Vector3(1.92, 0.06, 1.25), &"ceramic", &"primeiro", false)
	_adicionar_caixa(Vector3(-3.15, y + 0.28, 4.45), Vector3(0.82, 0.56, 0.95), &"porcelain", &"primeiro", true)
	_adicionar_caixa(Vector3(-3.15, y + 0.58, 4.45), Vector3(0.76, 0.12, 0.72), &"ceramic", &"primeiro", false)
	_adicionar_caixa(Vector3(-6.0, y + 0.9, 2.85), Vector3(1.65, 0.22, 0.65), &"wood_light", &"primeiro", true)
	_adicionar_caixa(Vector3(-6.0, y + 1.1, 2.85), Vector3(1.42, 0.12, 0.46), &"porcelain", &"primeiro", false)
	_adicionar_caixa(Vector3(4.4, y + 0.025, 3.75), Vector3(3.8, 0.035, 2.5), &"tile_alt", &"primeiro", false)
	_adicionar_caixa(Vector3(5.8, y + 0.42, 3.9), Vector3(2.15, 0.84, 1.45), &"porcelain", &"primeiro", true)
	_adicionar_caixa(Vector3(5.8, y + 0.87, 3.9), Vector3(1.92, 0.06, 1.25), &"ceramic", &"primeiro", false)
	_adicionar_caixa(Vector3(3.15, y + 0.28, 4.45), Vector3(0.82, 0.56, 0.95), &"porcelain", &"primeiro", true)
	_adicionar_caixa(Vector3(3.15, y + 0.58, 4.45), Vector3(0.76, 0.12, 0.72), &"ceramic", &"primeiro", false)
	_adicionar_caixa(Vector3(6.0, y + 0.9, 2.85), Vector3(1.65, 0.22, 0.65), &"wood_light", &"primeiro", true)
	_adicionar_caixa(Vector3(6.0, y + 1.1, 2.85), Vector3(1.42, 0.12, 0.46), &"porcelain", &"primeiro", false)
	# Hall superior de 3,6 m, sem mobiliário no trajeto das escadas.
	_adicionar_tapete(&"primeiro", Vector3(0.0, y + 0.02, 3.75), Vector2(2.8, 1.2), &"rug_detail")

func _mobiliar_sotao() -> void:
	var y := ALTURA_ANDAR * 2.0
	# Armazenamento sazonal organizado, sem converter o sótão em sala de brinquedos.
	_adicionar_tapete(&"sotao", Vector3(-2.0, y + 0.02, 2.7), Vector2(4.2, 2.2), &"rug")
	_adicionar_caixa(Vector3(-5.75, y + 1.15, -3.9), Vector3(1.6, 2.3, 0.72), &"wood_warm", &"sotao", true)
	for shelf_y in [y + 0.55, y + 1.15, y + 1.75]:
		_adicionar_caixa(Vector3(-5.75, shelf_y, -3.4), Vector3(1.65, 0.075, 0.82), &"wood_light", &"sotao", false)
	for box_pos in [Vector3(-6.1, y + 0.8, -3.3), Vector3(-5.4, y + 0.8, -3.3), Vector3(-6.0, y + 1.43, -3.3), Vector3(-5.4, y + 2.02, -3.3)]:
		_adicionar_caixa(box_pos, Vector3(0.48, 0.45, 0.46), &"paper", &"sotao", false)
	_adicionar_caixa(Vector3(4.7, y + 0.55, -3.9), Vector3(2.0, 1.05, 1.1), &"wood_warm", &"sotao", true)
	_adicionar_caixa(Vector3(4.7, y + 1.12, -3.9), Vector3(1.85, 0.08, 1.0), &"wood_light", &"sotao", false)
	_adicionar_caixa(Vector3(4.7, y + 1.55, -3.9), Vector3(1.6, 0.72, 0.8), &"linen_cream", &"sotao", false)
	_adicionar_caixa(Vector3(-2.0, y + 0.38, 2.25), Vector3(1.1, 0.74, 0.9), &"paper", &"sotao", false)
	_adicionar_caixa(Vector3(-0.2, y + 0.32, 2.35), Vector3(0.85, 0.62, 0.75), &"paper", &"sotao", false)
	_adicionar_caixa(Vector3(1.3, y + 0.05, 2.4), Vector3(1.35, 0.08, 0.8), &"wood_light", &"sotao", false)

func _montar_vizinhanca() -> void:
	# Jardim, calçada e rua em escala para a casa maior, sem piso/colisão sob o porão.
	_adicionar_caixa(Vector3(0.0, -0.16, -17.45), Vector3(80.0, 0.28, 18.9), &"grass", &"exterior", true)
	_adicionar_caixa(Vector3(0.0, -0.16, 20.75), Vector3(80.0, 0.28, 28.5), &"grass", &"exterior", true)
	_adicionar_caixa(Vector3(-24.0, -0.16, 0.0), Vector3(32.0, 0.28, 10.7), &"grass", &"exterior", true)
	_adicionar_caixa(Vector3(24.0, -0.16, 0.0), Vector3(32.0, 0.28, 10.7), &"grass", &"exterior", true)
	_adicionar_caixa(Vector3(0.0, -0.005, 20.0), Vector3(80.0, 0.12, 5.5), &"road", &"exterior", false)
	_adicionar_caixa(Vector3(0.0, 0.02, 8.2), Vector3(3.8, 0.08, 3.5), &"driveway", &"exterior", false)
	_adicionar_caixa(Vector3(0.0, 0.015, 12.8), Vector3(1.55, 0.075, 10.5), &"concrete", &"exterior", false)
	_adicionar_caixa(Vector3(4.6, 0.025, 11.8), Vector3(4.8, 0.08, 8.2), &"driveway", &"exterior", false)
	_adicionar_caixa(Vector3(0.0, 0.015, 5.75), Vector3(2.4, 0.07, 2.2), &"concrete", &"exterior", false)
	# Cercas laterais mantêm um corredor externo para contornar a casa.
	for x in [-12.5, 12.5]:
		_adicionar_caixa(Vector3(x, 0.62, 5.5), Vector3(0.18, 1.24, 19.0), &"fence", &"exterior", true)
	# Postes da cerca frontal acompanham os painéis junto ao portão, fora do interior.
	for post_x in [-10.6, -8.9, -7.2, 7.2, 8.9, 10.6]:
		_adicionar_caixa(Vector3(post_x, 0.58, 16.0), Vector3(0.12, 1.16, 0.12), &"trim", &"exterior", false)
	_adicionar_caixa(Vector3(0.0, 0.58, -9.5), Vector3(25.0, 1.16, 0.18), &"fence", &"exterior", true)
	# Portão frontal alinhado ao caminho da entrada; deixa 4 m livres para acesso e fuga.
	_adicionar_caixa(Vector3(-7.25, 0.58, 16.0), Vector3(10.5, 1.16, 0.18), &"fence", &"exterior", true)
	_adicionar_caixa(Vector3(7.25, 0.58, 16.0), Vector3(10.5, 1.16, 0.18), &"fence", &"exterior", true)
	_montar_carro(Vector3(4.6, 0.0, 11.4))
	for tree_pos in [Vector3(-10.6, 0.0, 1.2), Vector3(10.7, 0.0, 0.4), Vector3(-10.0, 0.0, 13.3), Vector3(11.4, 0.0, 14.0), Vector3(-16.5, 0.0, 4.0), Vector3(17.0, 0.0, 2.8)]:
		_adicionar_arvore(tree_pos)
	_montar_casa_vizinha(Vector3(-19.0, 0.0, 1.5), 0.82)
	_montar_casa_vizinha(Vector3(19.0, 0.0, 3.2), 0.68)
	_montar_lua_e_estrelas()
	# Limite jogável visual; sem corredor invisível aparente.
	for x in [-28.0, 28.0]:
		_adicionar_caixa(Vector3(x, 1.3, 8.0), Vector3(0.28, 2.6, 44.0), &"fence", &"exterior", true)
	_adicionar_caixa(Vector3(0.0, 1.3, -14.0), Vector3(56.0, 2.6, 0.28), &"fence", &"exterior", true)
	_adicionar_caixa(Vector3(0.0, 1.3, 30.0), Vector3(56.0, 2.6, 0.28), &"fence", &"exterior", true)

func _montar_carro(origin: Vector3) -> void:
	_adicionar_caixa(origin + Vector3(0.0, 0.6, 0.0), Vector3(4.0, 0.68, 1.85), &"car_body", &"exterior", true)
	_adicionar_caixa(origin + Vector3(0.0, 1.2, -0.05), Vector3(2.2, 0.72, 1.48), &"car_glass", &"exterior", false)
	_adicionar_caixa(origin + Vector3(0.0, 1.58, -0.04), Vector3(2.0, 0.08, 1.32), &"car_body", &"exterior", false)
	for x in [-1.3, 1.3]:
		for z in [-0.76, 0.76]:
			_adicionar_caixa(origin + Vector3(x, 0.34, z), Vector3(0.52, 0.65, 0.26), &"metal_dark", &"exterior", false)
	_adicionar_caixa(origin + Vector3(0.0, 0.56, -0.94), Vector3(0.58, 0.16, 0.035), &"trim_light", &"exterior", false)

func _adicionar_arvore(origin: Vector3) -> void:
	_adicionar_caixa(origin + Vector3(0.0, 1.35, 0.0), Vector3(0.42, 2.7, 0.42), &"tree_bark", &"exterior", true)
	_adicionar_caixa(origin + Vector3(0.0, 3.25, 0.0), Vector3(2.25, 2.8, 2.25), &"tree_leaf", &"exterior", false)
	_adicionar_caixa(origin + Vector3(0.0, 4.35, 0.0), Vector3(1.45, 1.9, 1.45), &"tree_leaf", &"exterior", false)

func _montar_casa_vizinha(origin: Vector3, scale: float) -> void:
	_adicionar_caixa(origin + Vector3(0.0, 1.7 * scale, 0.0), Vector3(10.0 * scale, 3.4 * scale, 8.0 * scale), &"siding", &"exterior", true)
	_adicionar_caixa(origin + Vector3(0.0, 4.15 * scale, 0.0), Vector3(11.2 * scale, 1.25 * scale, 9.0 * scale), &"roof", &"exterior", false)
	for x in [-2.8, 2.8]:
		_adicionar_caixa(origin + Vector3(x * scale, 1.9 * scale, 4.05 * scale), Vector3(1.05 * scale, 1.0 * scale, 0.04), &"glass", &"exterior", false)

func _montar_lua_e_estrelas() -> void:
	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 1.05
	moon_mesh.height = 2.1
	moon_mesh.radial_segments = 12
	moon_mesh.rings = 6
	var moon_instance := MeshInstance3D.new()
	moon_instance.name = "Lua"
	moon_instance.mesh = moon_mesh
	moon_instance.material_override = _materiais[&"moon"]
	moon_instance.position = Vector3(-10.0, 34.0, -28.0)
	_raiz_visual.add_child(moon_instance)
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.055
	star_mesh.height = 0.11
	star_mesh.radial_segments = 4
	star_mesh.rings = 2
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = star_mesh
	multimesh.instance_count = 78
	var rng := RandomNumberGenerator.new()
	rng.seed = 24715
	for index in range(multimesh.instance_count):
		var x := rng.randf_range(-42.0, 42.0)
		var y := rng.randf_range(13.0, 38.0)
		var z := rng.randf_range(-30.0, 38.0)
		multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
	var stars := MultiMeshInstance3D.new()
	stars.name = "Estrelas"
	stars.multimesh = multimesh
	stars.material_override = _materiais[&"star"]
	_raiz_visual.add_child(stars)

func _adicionar_caixa_correio(origin: Vector3) -> void:
	_adicionar_caixa(origin + Vector3(0.0, 0.9, 0.0), Vector3(0.12, 1.8, 0.12), &"metal_dark", &"exterior", true)
	_adicionar_caixa(origin + Vector3(0.0, 1.82, 0.0), Vector3(0.62, 0.44, 0.42), &"metal", &"exterior", false)

func _adicionar_tapete(floor_id: StringName, center: Vector3, size: Vector2, material_key: StringName) -> void:
	_adicionar_caixa(center, Vector3(size.x, 0.035, size.y), material_key, floor_id, false)
	_adicionar_caixa(center + Vector3(0.0, 0.019, -size.y * 0.5 + 0.1), Vector3(size.x * 0.78, 0.012, 0.035), &"rug_detail", floor_id, false)
	_adicionar_caixa(center + Vector3(0.0, 0.019, size.y * 0.5 - 0.1), Vector3(size.x * 0.78, 0.012, 0.035), &"rug_detail", floor_id, false)

func _adicionar_mesa(floor_id: StringName, origin: Vector3, size: Vector2, material_key: StringName, height: float) -> void:
	_adicionar_caixa(origin + Vector3(0.0, height, 0.0), Vector3(size.x, 0.12, size.y), material_key, floor_id, true)
	for x in [-size.x * 0.42, size.x * 0.42]:
		for z in [-size.y * 0.38, size.y * 0.38]:
			_adicionar_caixa(origin + Vector3(x, height * 0.5, z), Vector3(0.11, height, 0.11), &"wood_warm", floor_id, false)

func _adicionar_cadeira(floor_id: StringName, origin: Vector3, wood: StringName, fabric: StringName) -> void:
	_adicionar_caixa(origin + Vector3(0.0, 0.48, 0.0), Vector3(0.58, 0.12, 0.58), wood, floor_id, true)
	_adicionar_caixa(origin + Vector3(0.0, 0.57, 0.0), Vector3(0.54, 0.08, 0.54), fabric, floor_id, false)
	_adicionar_caixa(origin + Vector3(0.0, 0.9, -0.24), Vector3(0.58, 0.72, 0.09), wood, floor_id, false)
	for x in [-0.23, 0.23]:
		for z in [-0.22, 0.22]:
			_adicionar_caixa(origin + Vector3(x, 0.24, z), Vector3(0.08, 0.48, 0.08), wood, floor_id, false)

func _adicionar_sofa(origin: Vector3, fabric: StringName, floor_id: StringName) -> void:
	_adicionar_caixa(origin + Vector3(0.0, 0.38, 0.0), Vector3(2.75, 0.52, 0.92), fabric, floor_id, true)
	_adicionar_caixa(origin + Vector3(0.0, 0.83, 0.31), Vector3(2.8, 0.9, 0.28), &"upholstery", floor_id, true)
	for x in [-1.3, 1.3]:
		_adicionar_caixa(origin + Vector3(x, 0.62, -0.04), Vector3(0.18, 0.56, 0.98), fabric, floor_id, false)
	for x in [-0.78, 0.0, 0.78]:
		_adicionar_caixa(origin + Vector3(x, 0.68, -0.06), Vector3(0.74, 0.12, 0.67), &"linen", floor_id, false)

func _adicionar_cama(floor_id: StringName, origin: Vector3, size: Vector2, cover: StringName, frame: StringName) -> void:
	_adicionar_caixa(origin + Vector3(0.0, 0.22, 0.0), Vector3(size.x + 0.12, 0.32, size.y + 0.12), frame, floor_id, true)
	_adicionar_caixa(origin + Vector3(0.0, 0.48, 0.0), Vector3(size.x, 0.22, size.y), &"linen", floor_id, false)
	_adicionar_caixa(origin + Vector3(0.0, 0.62, 0.16), Vector3(size.x - 0.08, 0.12, size.y * 0.72), cover, floor_id, false)
	_adicionar_caixa(origin + Vector3(0.0, 0.62, -size.y * 0.33), Vector3(size.x * 0.54, 0.12, 0.42), &"linen_cream", floor_id, false)
	_adicionar_caixa(origin + Vector3(0.0, 0.82, -size.y * 0.5), Vector3(size.x + 0.15, 1.45, 0.16), frame, floor_id, false)

func _adicionar_quadro_eixo_x(floor_id: StringName, center: Vector3, size: Vector2, frame: StringName, image: StringName) -> void:
	_adicionar_caixa(center, Vector3(size.x, size.y, 0.08), frame, floor_id, false)
	_adicionar_caixa(center + Vector3(0.0, 0.0, 0.05), Vector3(size.x - 0.12, size.y - 0.12, 0.025), image, floor_id, false)

func _adicionar_quadro_eixo_z(floor_id: StringName, center: Vector3, size: Vector2, frame: StringName, image: StringName) -> void:
	_adicionar_caixa(center, Vector3(0.08, size.y, size.x), frame, floor_id, false)
	_adicionar_caixa(center + Vector3(0.05, 0.0, 0.0), Vector3(0.025, size.y - 0.12, size.x - 0.12), image, floor_id, false)

func _adicionar_porta_eixo_x(floor_id: StringName, z: float, center_x: float, base_y: float, width: float, height: float, open_angle: float) -> void:
	var hinge := Vector3(center_x - width * 0.5, base_y, z)
	_criar_porta_articulada(floor_id, hinge, width, height, true, open_angle)

func _adicionar_porta_eixo_z(floor_id: StringName, x: float, center_z: float, base_y: float, width: float, height: float, open_angle: float) -> void:
	var hinge := Vector3(x, base_y, center_z - width * 0.5)
	_criar_porta_articulada(floor_id, hinge, width, height, false, open_angle)

func _criar_porta_articulada(floor_id: StringName, dobradica: Vector3, largura: float, altura: float, eixo_x: bool, angulo_abertura: float) -> void:
	var porta := AnimatableBody3D.new()
	porta.name = "Porta_%s" % String(floor_id)
	porta.position = dobradica
	porta.set_script(load("res://prototype/interactive_door.gd"))
	porta.set("angulo_abertura_graus", angulo_abertura)
	porta.set_meta("pavimento", floor_id)
	_raiz_visual.add_child(porta)
	var painel := MeshInstance3D.new()
	var malha_painel := BoxMesh.new()
	malha_painel.size = Vector3(largura, altura, 0.075) if eixo_x else Vector3(0.075, altura, largura)
	painel.mesh = malha_painel
	painel.material_override = _materiais[&"door_wood"]
	painel.position = Vector3(largura * 0.5, altura * 0.5, 0.0) if eixo_x else Vector3(0.0, altura * 0.5, largura * 0.5)
	porta.add_child(painel)
	var forma := BoxShape3D.new()
	forma.size = Vector3(largura, altura, 0.09) if eixo_x else Vector3(0.09, altura, largura)
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	colisao.position = painel.position
	porta.add_child(colisao)
	# Alvo fixo no vão: a folha aberta pode sair da mira, mas a área não bloqueia o jogador.
	var alvo_interacao := Area3D.new()
	alvo_interacao.name = "AlvoInteracao"
	alvo_interacao.collision_layer = 2
	alvo_interacao.collision_mask = 0
	porta.add_child(alvo_interacao)
	alvo_interacao.top_level = true
	alvo_interacao.global_position = dobradica + (Vector3(largura * 0.5, altura * 0.5, 0.0) if eixo_x else Vector3(0.0, altura * 0.5, largura * 0.5))
	var forma_alvo := CollisionShape3D.new()
	var caixa_alvo := BoxShape3D.new()
	caixa_alvo.size = Vector3(largura + 0.35, altura, 0.14) if eixo_x else Vector3(0.14, altura, largura + 0.35)
	forma_alvo.shape = caixa_alvo
	alvo_interacao.add_child(forma_alvo)
	_adicionar_puxador_porta(porta, largura, altura, eixo_x)

func _adicionar_puxador_porta(porta: Node3D, largura: float, altura: float, eixo_x: bool) -> void:
	var centro_y := minf(1.0, altura * 0.52)
	var centro_x := largura * 0.82 if eixo_x else 0.0
	var centro_z := 0.0 if eixo_x else largura * 0.82
	for lado in [-1.0, 1.0]:
		var placa := MeshInstance3D.new()
		placa.name = "RosetaMaçaneta"
		var disco := CylinderMesh.new()
		disco.top_radius = 0.034
		disco.bottom_radius = 0.034
		disco.height = 0.012
		disco.radial_segments = 16
		placa.mesh = disco
		placa.material_override = _materiais[&"door_hardware"]
		placa.rotation = Vector3(PI * 0.5, 0.0, 0.0) if eixo_x else Vector3(0.0, 0.0, PI * 0.5)
		placa.position = Vector3(centro_x, centro_y, lado * 0.044) if eixo_x else Vector3(lado * 0.044, centro_y, centro_z)
		porta.add_child(placa)
		var haste := MeshInstance3D.new()
		haste.name = "HasteMaçaneta"
		var haste_mesh := CylinderMesh.new()
		haste_mesh.top_radius = 0.012
		haste_mesh.bottom_radius = 0.012
		haste_mesh.height = 0.045
		haste_mesh.radial_segments = 12
		haste.mesh = haste_mesh
		haste.material_override = _materiais[&"door_hardware"]
		haste.rotation = placa.rotation
		haste.position = Vector3(centro_x, centro_y, lado * 0.068) if eixo_x else Vector3(lado * 0.068, centro_y, centro_z)
		porta.add_child(haste)
		var alavanca := MeshInstance3D.new()
		alavanca.name = "AlavancaMaçaneta"
		var alavanca_mesh := CylinderMesh.new()
		alavanca_mesh.top_radius = 0.012
		alavanca_mesh.bottom_radius = 0.012
		alavanca_mesh.height = 0.12
		alavanca_mesh.radial_segments = 12
		alavanca.mesh = alavanca_mesh
		alavanca.material_override = _materiais[&"door_hardware"]
		alavanca.rotation = Vector3(0.0, 0.0, PI * 0.5) if eixo_x else Vector3(PI * 0.5, 0.0, 0.0)
		alavanca.position = Vector3(centro_x - 0.035, centro_y, lado * 0.087) if eixo_x else Vector3(lado * 0.087, centro_y, centro_z - 0.035)
		porta.add_child(alavanca)

func _criar_ambiencia() -> void:
	# O áudio real roda no jogo; headless só valida cena/colisões e encerra sem playback ativo.
	if DisplayServer.get_name() == "headless":
		return
	var ambience_stream := load("res://prototype/assets/audio/noite.wav") as AudioStreamWAV
	if ambience_stream != null:
		ambience_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		ambience_stream.loop_begin = 0
		ambience_stream.loop_end = ambience_stream.data.size() / 2
		var ambience := AudioStreamPlayer.new()
		ambience.name = "AmbienciaNoturna"
		ambience.stream = ambience_stream
		ambience.volume_db = -25.0
		add_child(ambience)
		ambience.play()
	_audio_passos = AudioStreamPlayer3D.new()
	_audio_passos.name = "Passos"
	_audio_passos.volume_db = -10.0
	_audio_passos.max_distance = 13.0
	_audio_passos.unit_size = 1.0
	add_child(_audio_passos)

func _posicionar_jogador() -> void:
	var player_node := ScriptJogador.new()
	player_node.name = "Player"
	player_node.position = Vector3(0.0, 0.08, 17.2)
	add_child(player_node)
	_jogador = player_node as CharacterBody3D
	if _jogador != null:
		_jogador.flashlight_active = true
		var head: Node3D = _jogador.get("head")
		if head != null:
			head.rotation.x = deg_to_rad(5.0)
			_posicao_repouso_cabeca = head.position
			_inclinacao_repouso_cabeca = head.rotation.z
		if _audio_passos != null:
			var previous_parent := _audio_passos.get_parent()
			if previous_parent != null:
				previous_parent.remove_child(_audio_passos)
			_jogador.add_child(_audio_passos)
			_audio_passos.position = Vector3(0.0, 0.1, 0.0)
		if _audio_passos != null:
			var night_step := load("res://prototype/assets/audio/passo_madeira.wav") as AudioStreamWAV
			if night_step != null:
				_audio_passos.stream = night_step
				_audio_passos.max_db = -6.0

func _montar_dica_controles() -> void:
	var layer := CanvasLayer.new()
	layer.name = "AjudaPrototipo"
	add_child(layer)
	var label := Label.new()
	label.position = Vector2(18.0, 16.0)
	label.text = "WASD mover  ·  mouse olhar  ·  Shift correr  ·  F lanterna  ·  E abrir/fechar portas  ·  Esc liberar cursor"
	label.add_theme_color_override("font_color", Color("c4c7cb"))
	label.add_theme_color_override("font_shadow_color", Color(0.015, 0.02, 0.035, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(label)

func _montar_filtro_visual() -> void:
	var shader := load("res://prototype/haunted_film_grain_c18.gdshader") as Shader
	if shader == null:
		push_warning("Shader de granulação cinematográfica indisponível.")
		return
	var layer := CanvasLayer.new()
	layer.name = "FiltroCinematografico"
	layer.layer = 0
	add_child(layer)
	var overlay := ColorRect.new()
	overlay.name = "VinhetaEGrãoSutil"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("grain_strength", 0.018)
	material.set_shader_parameter("vignette_strength", 0.075)
	material.set_shader_parameter("cool_tint_strength", 0.025)
	material.set_shader_parameter("flashlight_darkening_strength", 0.74)
	material.set_shader_parameter("flashlight_inner_angle", 18.0)
	material.set_shader_parameter("flashlight_outer_angle", 55.0)
	overlay.material = material
	layer.add_child(overlay)
	if _jogador != null:
		_jogador.call("set_flashlight_falloff_material", material)

func _process(delta: float) -> void:
	_atualizar_lanterna_escritorio_c15()
	if _jogador == null:
		return
	var head: Node3D = _jogador.get("head")
	if head == null:
		return
	var horizontal_speed := Vector2(_jogador.velocity.x, _jogador.velocity.z).length()
	var moving := horizontal_speed > 0.22 and _jogador.is_on_floor()
	var target_bob := 0.0
	var target_sway := 0.0
	if moving:
		var running := horizontal_speed > 4.0
		_fase_caminhada += delta * (14.0 if running else 10.5)
		target_bob = sin(_fase_caminhada) * (0.026 if running else 0.018)
		target_sway = cos(_fase_caminhada * 0.5) * 0.008
		head.rotation.z = lerpf(head.rotation.z, _inclinacao_repouso_cabeca + target_sway, clampf(delta * 5.5, 0.0, 1.0))
		_temporizador_passos += delta
		var step_interval := 0.42 if running else 0.57
		if _temporizador_passos >= step_interval and _audio_passos != null:
			_temporizador_passos = 0.0
			if _jogador.global_position.y < -0.8:
				_audio_passos.stream = load("res://prototype/assets/audio/passo_concreto.wav")
			elif _jogador.global_position.y > ALTURA_ANDAR * 2.0 - 0.35:
				_audio_passos.stream = load("res://prototype/assets/audio/passo_madeira.wav")
			else:
				_audio_passos.stream = load("res://prototype/assets/audio/passo_madeira.wav")
			_audio_passos.play()
	else:
		_fase_caminhada += delta * 1.1
		target_bob = sin(_fase_caminhada) * 0.004
		target_sway = sin(_fase_caminhada * 0.7) * 0.003
		_temporizador_passos = 0.0
		head.rotation.z = lerpf(head.rotation.z, _inclinacao_repouso_cabeca + target_sway, clampf(delta * 3.0, 0.0, 1.0))
	head.position.y = lerpf(head.position.y, _posicao_repouso_cabeca.y + target_bob, clampf(delta * 8.0, 0.0, 1.0))

func _adicionar_caixa(center: Vector3, size: Vector3, material_key: StringName, floor_id: StringName = &"", solid: bool = false, rotation: Vector3 = Vector3.ZERO) -> void:
	if not _ferramentas_superficie.has(material_key):
		return
	var half := size * 0.5
	var points := [
		Vector3(-half.x, -half.y, -half.z), Vector3(half.x, -half.y, -half.z),
		Vector3(half.x, half.y, -half.z), Vector3(-half.x, half.y, -half.z),
		Vector3(-half.x, -half.y, half.z), Vector3(half.x, -half.y, half.z),
		Vector3(half.x, half.y, half.z), Vector3(-half.x, half.y, half.z)
	]
	var faces := [
		[0, 1, 2, 3, Vector3(0.0, 0.0, -1.0)],
		[5, 4, 7, 6, Vector3(0.0, 0.0, 1.0)],
		[4, 0, 3, 7, Vector3(-1.0, 0.0, 0.0)],
		[1, 5, 6, 2, Vector3(1.0, 0.0, 0.0)],
		[3, 2, 6, 7, Vector3(0.0, 1.0, 0.0)],
		[4, 5, 1, 0, Vector3(0.0, -1.0, 0.0)]
	]
	var basis := Basis.from_euler(rotation)
	var tool: SurfaceTool = _ferramentas_superficie[material_key]
	for face in faces:
		var normal: Vector3 = (basis * face[4]).normalized()
		for vertex_index in [face[0], face[1], face[2], face[0], face[2], face[3]]:
			tool.set_normal(normal)
			var ponto_local: Vector3 = points[vertex_index]
			var uv: Vector2
			if absf(float(face[4].y)) > 0.5:
				uv = Vector2(ponto_local.x + half.x, ponto_local.z + half.z)
			elif absf(float(face[4].x)) > 0.5:
				uv = Vector2(ponto_local.z + half.z, ponto_local.y + half.y)
			else:
				uv = Vector2(ponto_local.x + half.x, ponto_local.y + half.y)
			tool.set_uv(uv * 0.5)
			tool.add_vertex(center + basis * points[vertex_index])
	if solid and _corpos_colisao.has(floor_id):
		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		collider.position = center
		collider.rotation = rotation
		(_corpos_colisao[floor_id] as StaticBody3D).add_child(collider)

func _adicionar_colisao_caixa(center: Vector3, size: Vector3, floor_id: StringName, collider_name: StringName, rotation: Vector3 = Vector3.ZERO) -> void:
	if not _corpos_colisao.has(floor_id):
		return
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.name = collider_name
	collider.shape = shape
	collider.position = center
	collider.rotation = rotation
	(_corpos_colisao[floor_id] as StaticBody3D).add_child(collider)

func _adicionar_triangulo(a: Vector3, b: Vector3, c: Vector3, material_key: StringName) -> void:
	if not _ferramentas_superficie.has(material_key):
		return
	var tool: SurfaceTool = _ferramentas_superficie[material_key]
	var normal := (b - a).cross(c - a).normalized()
	for vertex in [a, b, c]:
		tool.set_normal(normal)
		tool.set_uv(Vector2.ZERO)
		tool.add_vertex(vertex)

func _finalizar_malhas_visuais() -> void:
	var mesh := ArrayMesh.new()
	for key in _ferramentas_superficie:
		var tool: SurfaceTool = _ferramentas_superficie[key]
		tool.index()
		tool.commit(mesh)
	var instance := MeshInstance3D.new()
	instance.name = "MalhasEstaticasAgrupadas"
	instance.mesh = mesh
	_raiz_visual.add_child(instance)

func _adicionar_esfera(name: String, center: Vector3, radius: float, material_key: StringName, floor_id: StringName = &"") -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	var instance := MeshInstance3D.new()
	instance.name = name
	instance.mesh = sphere
	instance.material_override = _materiais[material_key]
	instance.position = center
	_raiz_visual.add_child(instance)


func _configurar_poltrona_biblioteca(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			material_local.albedo_color = material_original.albedo_color * Color(0.84, 0.76, 0.66, 1.0)
			material_local.roughness = 0.88
			material_local.metallic = 0.0
			material_local.clearcoat_enabled = false
			material_local.emission_enabled = false
			malha.set_surface_override_material(superficie, material_local)

func _configurar_mesa_biblioteca(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			material_local.albedo_color = material_original.albedo_color * Color(0.72, 0.63, 0.52, 1.0)
			material_local.roughness = 0.80
			material_local.metallic = 0.0
			material_local.clearcoat_enabled = false
			material_local.emission_enabled = false
			malha.set_surface_override_material(superficie, material_local)

func _configurar_quadro_biblioteca(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			var nome_material := String(material_original.resource_name).to_lower()
			if "artwork" in nome_material:
				material_local.albedo_color = material_original.albedo_color * Color(0.76, 0.75, 0.69, 1.0)
				material_local.roughness = 0.95
			elif "glass" in nome_material:
				material_local.albedo_color = material_original.albedo_color * Color(0.72, 0.68, 0.60, 1.0)
				material_local.roughness = 0.72
			else:
				material_local.albedo_color = material_original.albedo_color * Color(0.70, 0.59, 0.46, 1.0)
				material_local.roughness = 0.80
			material_local.metallic = 0.0
			material_local.clearcoat_enabled = false
			material_local.emission_enabled = false
			malha.set_surface_override_material(superficie, material_local)

func _adicionar_arte_quadro_biblioteca(centro: Vector3, tamanho: Vector2) -> void:
	var tela := MeshInstance3D.new()
	tela.name = "ArteQuadroBiblioteca_CC0"
	var plano := QuadMesh.new()
	plano.size = tamanho
	tela.mesh = plano
	tela.position = centro
	tela.rotation.y = PI * 0.5
	tela.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://prototype/assets/models/polyhaven/hanging_picture_frame_02/textures/hanging_picture_frame_02_artwork_diff_1k.jpg") as Texture2D
	material.albedo_color = Color(0.78, 0.75, 0.68, 1.0)
	material.uv1_offset = Vector3(0.1, 0.22, 0.0)
	material.uv1_scale = Vector3(0.8, 0.53, 1.0)
	material.roughness = 0.95
	material.metallic = 0.0
	material.emission_enabled = false
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	tela.material_override = material
	_raiz_visual.add_child(tela)

func _adicionar_arte_quadro_escritorio_c15(centro: Vector3, tamanho: Vector2) -> void:
	var tela := MeshInstance3D.new()
	tela.name = "ArteQuadroEscritorioC15_CC0"
	var plano := QuadMesh.new()
	plano.size = tamanho
	tela.mesh = plano
	tela.position = centro
	tela.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://prototype/assets/models/polyhaven/hanging_picture_frame_02/textures/hanging_picture_frame_02_artwork_diff_1k.jpg") as Texture2D
	material.albedo_color = Color(0.78, 0.75, 0.68, 1.0)
	material.uv1_offset = Vector3(0.1, 0.22, 0.0)
	material.uv1_scale = Vector3(0.8, 0.53, 1.0)
	material.roughness = 0.95
	material.metallic = 0.0
	material.emission_enabled = false
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	tela.material_override = material
	_raiz_visual.add_child(tela)

func _configurar_mesa_escritorio_c15(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			var nome_material := String(material_original.resource_name).to_lower()
			material_local.emission_enabled = false
			material_local.emission = Color.BLACK
			material_local.clearcoat_enabled = false
			material_local.metallic = 0.0
			material_local.roughness = 0.90
			if "walnut grain" in nome_material or "oak grain" in nome_material:
				material_local.albedo_color = material_original.albedo_color * Color(0.80, 0.72, 0.60, 1.0)
				material_local.roughness = 0.72
			elif "brass" in nome_material:
				material_local.albedo_color = material_original.albedo_color * Color(0.88, 0.78, 0.60, 1.0)
				material_local.metallic = 0.18
				material_local.roughness = 0.52
			elif "pages" in nome_material:
				material_local.albedo_color = material_original.albedo_color * Color(0.94, 0.90, 0.82, 1.0)
				material_local.roughness = 0.96
			elif "teal" in nome_material and "upholstery" in nome_material:
				material_local.albedo_color = material_original.albedo_color * Color(0.48, 0.54, 0.48, 1.0)
				material_local.roughness = 0.96
			elif "blue_fabric" in nome_material:
				material_local.albedo_color = material_original.albedo_color * Color(0.76, 0.80, 0.82, 1.0)
				material_local.roughness = 0.96
			elif "rust upholstery" in nome_material:
				material_local.albedo_color = material_original.albedo_color * Color(0.86, 0.78, 0.66, 1.0)
				material_local.roughness = 0.96
			elif "sage upholstery" in nome_material:
				material_local.albedo_color = material_original.albedo_color * Color(0.80, 0.82, 0.72, 1.0)
				material_local.roughness = 0.96
			elif "upholstery" in nome_material or "fabric" in nome_material:
				material_local.roughness = 0.94
			elif "charcoal" in nome_material:
				material_local.metallic = 0.10
				material_local.roughness = 0.76
			malha.set_surface_override_material(superficie, material_local)

func _configurar_estofado_autoral_c15(modelo: Node3D) -> void:
	# A trama original continua no GLB; apenas a tintura local evita um encosto branco.
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var original := malha.get_active_material(superficie) as StandardMaterial3D
			if original == null or not "woven oatmeal" in String(original.resource_name).to_lower():
				continue
			var tecido := original.duplicate() as StandardMaterial3D
			tecido.albedo_color = original.albedo_color * Color(0.42, 0.45, 0.40, 1.0)
			tecido.roughness = 0.94
			tecido.metallic = 0.0
			tecido.metallic_specular = 0.25
			tecido.clearcoat_enabled = false
			tecido.emission_enabled = false
			malha.set_surface_override_material(superficie, tecido)

func _configurar_luminaria_escritorio_c15(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			var nome_material := String(material_original.resource_name).to_lower()
			material_local.emission_enabled = false
			material_local.emission = Color.BLACK
			material_local.clearcoat_enabled = false
			if "light" in nome_material:
				material_local.albedo_color = Color(0.10, 0.09, 0.07, 1.0)
				material_local.metallic = 0.0
				material_local.roughness = 0.92
			else:
				material_local.albedo_color = material_original.albedo_color * Color(0.50, 0.43, 0.31, 1.0)
				material_local.metallic = 0.38
				material_local.roughness = 0.48
			malha.set_surface_override_material(superficie, material_local)

func _configurar_laptop_escritorio_c15(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			var nome_material := String(material_original.resource_name).to_lower()
			material_local.emission_enabled = false
			material_local.emission = Color.BLACK
			material_local.clearcoat_enabled = false
			if "screen" in nome_material:
				material_local.albedo_color = Color(0.018, 0.021, 0.025, 1.0)
				material_local.metallic = 0.02
				material_local.roughness = 0.50
			else:
				material_local.albedo_color = material_original.albedo_color * Color(0.68, 0.72, 0.76, 1.0)
				material_local.metallic = 0.32
				material_local.roughness = 0.42
			malha.set_surface_override_material(superficie, material_local)

func _configurar_estante_biblioteca(modelo: Node3D) -> void:
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			var nome_material := String(material_original.resource_name).to_lower()
			var tonalidade := Color(0.88, 0.85, 0.80, 1.0)
			material_local.roughness = 0.90
			material_local.metallic = 0.0
			if "walnut" in nome_material or "oak grain" in nome_material or "painted timber" in nome_material:
				tonalidade = Color(0.76, 0.69, 0.59, 1.0)
				material_local.roughness = 0.84
			elif "brass" in nome_material:
				tonalidade = Color(0.78, 0.68, 0.52, 1.0)
				material_local.roughness = 0.62
				material_local.metallic = 0.14
			elif "pages" in nome_material:
				tonalidade = Color(0.84, 0.80, 0.72, 1.0)
				material_local.roughness = 0.96
			material_local.albedo_color = material_original.albedo_color * tonalidade
			material_local.clearcoat_enabled = false
			material_local.emission_enabled = false
			malha.set_surface_override_material(superficie, material_local)

func _configurar_manta_biblioteca(modelo: Node3D) -> void:
	modelo.rotation.x = deg_to_rad(70.0)
	modelo.position.y += 0.22
	for item in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := item as MeshInstance3D
		if malha == null or malha.mesh == null:
			continue
		for superficie in range(malha.mesh.get_surface_count()):
			var material_original := malha.get_active_material(superficie) as StandardMaterial3D
			if material_original == null:
				continue
			var material_local := material_original.duplicate() as StandardMaterial3D
			material_local.albedo_color = material_original.albedo_color * Color(0.82, 0.76, 0.67, 1.0)
			material_local.roughness = 0.94
			material_local.metallic = 0.0
			material_local.clearcoat_enabled = false
			material_local.emission_enabled = false
			material_local.cull_mode = BaseMaterial3D.CULL_DISABLED
			malha.set_surface_override_material(superficie, material_local)


func _c16_recolher_nos(node: Node, output: Array[Node]) -> void:
	output.append(node)
	for child in node.get_children():
		_c16_recolher_nos(child, output)

func _adicionar_cozinha_kitchen004_c16(y: float) -> void:
	var packed := load("res://prototype/assets/models/custom/kitchen004/kitchen004_fitted.glb") as PackedScene
	if packed == null:
		push_error("C16: kitchen004 fitted ausente")
		return
	var model := packed.instantiate() as Node3D
	model.name = "Kitchen004C16"
	model.position = Vector3(-3.467222, y + 0.022, -6.9333043)
	model.rotation_degrees.y = -90.0
	model.scale = Vector3.ONE * 0.90
	_raiz_visual.add_child(model)
	var nodes: Array[Node] = []
	_c16_recolher_nos(model, nodes)
	var solid_names := ["kitchen_modern64_001", "kitchen_modern64_011", "kitchen_modern64_015", "kitchen_modern64_016", "kitchen_modern64_017", "kitchen_modern64_018", "kitchen_modern64_019", "kitchen_modern64_020", "kitchen_modern64_021", "kitchen_modern64_029", "kitchen_modern64_031", "kitchen_modern64_032", "kitchen_modern64_033", "kitchen_modern64_063"]
	var colliders := 0
	for node in nodes:
		if node is Light3D:
			(node as Light3D).visible = false
			(node as Light3D).light_energy = 0.0
		if not node is MeshInstance3D:
			continue
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		for surface in range(mesh_node.mesh.get_surface_count()):
			var original := mesh_node.get_active_material(surface) as BaseMaterial3D
			if original != null:
				var local := original.duplicate() as BaseMaterial3D
				local.emission_enabled = false
				mesh_node.set_surface_override_material(surface, local)
		if String(node.name) in solid_names:
			var bounds: AABB = mesh_node.global_transform * mesh_node.get_aabb()
			_adicionar_colisao_caixa(bounds.get_center(), bounds.size, &"terreo", StringName("C16_" + String(node.name)))
			colliders += 1
	print("C16_MODEL_INSTANCED scale=0.9 rotation_y=-90 colliders=%d" % colliders)
func _preparar_materiais_servico_c17() -> void:
	_adicionar_material(&"service_floor_c17", Color(0.92, 0.91, 0.87), 0.90)
	_aplicar_textura_pbr(&"service_floor_c17", "brown_floor_tiles", Color(0.92, 0.91, 0.87))
	var piso := _materiais[&"service_floor_c17"] as StandardMaterial3D
	piso.roughness_texture = null
	piso.roughness = 0.90
	piso.metallic_specular = 0.24
	piso.normal_scale = 0.28
	piso.clearcoat_enabled = false
	_adicionar_material(&"service_wall_c17", Color(0.78, 0.77, 0.72), 0.93)
	_aplicar_textura_pbr(&"service_wall_c17", "beige_wall_001", Color(0.78, 0.77, 0.72))
	var parede := _materiais[&"service_wall_c17"] as StandardMaterial3D
	parede.normal_scale = 0.22
	parede.metallic_specular = 0.20
	_adicionar_material(&"service_rail_c17", Color(0.27, 0.20, 0.14), 0.58)
	_adicionar_material(&"service_iron_c17", Color(0.075, 0.08, 0.075), 0.66)
	(_materiais[&"service_iron_c17"] as StandardMaterial3D).metallic = 0.55

func _configurar_eletros_servico_c17() -> void:
	# Cópias locais: não toca nos mesmos aparelhos existentes no porão.
	for model in _raiz_visual.get_children():
		if not String(model.name).ends_with("LavadoraServico") and not String(model.name).ends_with("SecadoraServico"):
			continue
		for item in model.find_children("*", "MeshInstance3D", true, false):
			var mesh := item as MeshInstance3D
			if mesh.mesh == null:
				continue
			for surface in range(mesh.mesh.get_surface_count()):
				var original := mesh.get_active_material(surface) as StandardMaterial3D
				if original == null:
					continue
				var mat := original.duplicate() as StandardMaterial3D
				var material_name := String(original.resource_name).to_lower()
				mat.emission_enabled = false
				mat.clearcoat_enabled = false
				if material_name.contains("enamel"):
					mat.albedo_color = original.albedo_color * Color(0.66, 0.67, 0.64, 1.0)
					mat.roughness = 0.47
					mat.metallic_specular = 0.30
				elif material_name.contains("display"):
					mat.albedo_texture = null
					mat.albedo_color = Color(0.015, 0.02, 0.018)
					mat.roughness = 0.28
				elif material_name.contains("inox"):
					mat.roughness = 0.42
				elif material_name.contains("optical"):
					mat.roughness = 0.20
				mesh.set_surface_override_material(surface, mat)

func _adicionar_tubo_servico_c17(a: Vector3, b: Vector3, raio: float, material_key: StringName) -> void:
	var direction := b - a
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = raio
	cylinder.bottom_radius = raio
	cylinder.height = direction.length()
	cylinder.radial_segments = 16
	cylinder.rings = 1
	# Reutiliza os lotes por material já finalizados pela casa: não cria 48 draws novos.
	var surface := _ferramentas_superficie[material_key] as SurfaceTool
	var rotation := Basis(Quaternion(Vector3.UP, direction.normalized()))
	surface.append_from(cylinder, 0, Transform3D(rotation, (a + b) * 0.5))

func _adicionar_acabamento_escada_c17() -> void:
	# A rampa original, o vão 2,0 x 3,2 e seus degraus continuam no lugar.
	# Aro apoiado no piso, sem criar uma tampa sobre a abertura.
	for x in [6.76, 8.84]:
		_adicionar_caixa(Vector3(x, 0.026, -5.6), Vector3(0.10, 0.028, 3.24), &"service_rail_c17", &"terreo", false)
	for z in [-7.24, -3.98]:
		_adicionar_caixa(Vector3(7.8, 0.026, z), Vector3(2.18, 0.028, 0.12), &"service_rail_c17", &"terreo", false)
	# Guarda-corpo nas laterais e no fundo; a boca frontal permanece aberta.
	for x in [6.76, 8.84]:
		_adicionar_tubo_servico_c17(Vector3(x, 1.03, -7.24), Vector3(x, 1.03, -4.08), 0.031, &"service_rail_c17")
		_adicionar_colisao_caixa(Vector3(x, 0.52, -5.66), Vector3(0.08, 1.04, 3.16), &"terreo", &"GuardaLateralServicoC17")
		for index in range(12):
			var z: float = lerpf(-7.24, -4.08, float(index) / 11.0)
			_adicionar_tubo_servico_c17(Vector3(x, 0.04, z), Vector3(x, 1.01, z), 0.014, &"service_iron_c17")
	_adicionar_tubo_servico_c17(Vector3(6.76, 1.03, -7.24), Vector3(8.84, 1.03, -7.24), 0.031, &"service_rail_c17")
	_adicionar_colisao_caixa(Vector3(7.8, 0.52, -7.24), Vector3(2.16, 1.04, 0.08), &"terreo", &"GuardaFundoServicoC17")
	for index in range(8):
		var x: float = lerpf(6.76, 8.84, float(index) / 7.0)
		_adicionar_tubo_servico_c17(Vector3(x, 0.04, -7.24), Vector3(x, 1.01, -7.24), 0.014, &"service_iron_c17")
	# Corrimãos realmente alinhados aos degraus, não deslocados pela normal da rampa.
	var lower := Vector3(7.8, -ALTURA_ANDAR, -7.15)
	var upper := Vector3(7.8, 0.0, -4.05)
	for side in [-1.0, 1.0]:
		var offset := Vector3(side * 0.70, 0.0, 0.0)
		var start_t := 0.20 if side < 0.0 else 0.0
		var first := lower.lerp(upper, start_t) + offset + Vector3(0.0, 0.92, 0.0)
		var last := upper + offset + Vector3(0.0, 0.92, 0.0)
		_adicionar_tubo_servico_c17(first, last, 0.032, &"service_rail_c17")
		_adicionar_tubo_servico_c17(last, last + Vector3(0.0, 0.0, 0.24), 0.032, &"service_rail_c17")
		for index in range(5):
			var t := float(index) / 4.0
			if t < start_t:
				continue
			var foot := lower.lerp(upper, t) + offset
			_adicionar_tubo_servico_c17(foot, foot + Vector3(0.0, 0.90, 0.0), 0.018, &"service_iron_c17")

func _adicionar_area_servico_c17(y: float) -> void:
	_adicionar_tapete(&"terreo", Vector3(4.25, y + 0.022, -5.55), Vector2(2.65, 1.05), &"rug_detail")
	_adicionar_modelo_glb("LavadoraServico", "washer-dryer.glb", Vector3(3.0, y + 0.022, -7.48), 1.0, 0.0, &"terreo", Vector3(0.62, 0.86, 0.62))
	_adicionar_modelo_glb("SecadoraServico", "tumble-dryer.glb", Vector3(3.9, y + 0.022, -7.48), 1.0, 0.0, &"terreo", Vector3(0.62, 0.86, 0.64))
	_adicionar_modelo_glb("ConjuntoServicoC18", "custom/c18/c18_laundry_service_original.glb", Vector3(4.25, y + 0.022, -7.48), 1.0, 0.0, &"terreo")
	_adicionar_colisao_caixa(Vector3(4.375, y + 0.65, -7.48), Vector3(3.67, 1.30, 0.74), &"terreo", &"BancadaServicoC18")
	_adicionar_colisao_caixa(Vector3(2.305, y + 1.31, -7.23), Vector3(0.61, 2.60, 1.28), &"terreo", &"RetornoServicoC18")
	_adicionar_colisao_caixa(Vector3(3.23, y + 2.08, -7.65), Vector3(1.20, 1.04, 0.46), &"terreo", &"AereoEsquerdoC18")
	_adicionar_colisao_caixa(Vector3(4.83, y + 2.37, -7.65), Vector3(1.96, 0.46, 0.46), &"terreo", &"SobrejanelaC18")
	_adicionar_colisao_caixa(Vector3(6.18, y + 2.10, -7.65), Vector3(0.66, 1.00, 0.46), &"terreo", &"AereoDireitoC18")
	_adicionar_colisao_caixa(Vector3(6.36, y + 0.71, -7.65), Vector3(0.32, 1.40, 0.28), &"terreo", &"AspiradorC18")
	_adicionar_colisao_caixa(Vector3(6.50, y + 0.22, -7.17), Vector3(0.30, 0.43, 0.30), &"terreo", &"BaldeC18")
	_adicionar_caixa(Vector3(4.25, y + 0.40, -7.866), Vector3(3.9, 0.76, 0.024), &"service_wall_c17", &"terreo", false)
	_configurar_eletros_servico_c17()
	_adicionar_modelo_mobiliario("painted_wooden_bench", Vector3(2.25, y + 0.022, -3.80), 0.82, 90.0, &"terreo", Vector3(1.17, 0.9, 0.5))
	_adicionar_modelo_mobiliario("hanging_picture_frame_02", Vector3(7.8, y + 1.82, -2.94), 0.86, 180.0, &"terreo")
	_adicionar_acabamento_escada_c17()

func _mobiliar_hall_c19(y: float) -> void:
	# C19: apenas o foyer. Não muda arquitetura, piso físico, escada ou lanterna.
	_adicionar_modelo_glb("ConjuntoHallC19", "custom/c19/c19_hall_entry_original.glb", Vector3(0.0, y, 0.0), 1.0, 0.0, &"terreo")
	_adicionar_colisao_caixa(Vector3(-1.515, y + 0.47, 6.625), Vector3(0.43, 0.94, 1.10), &"terreo", &"C19_Console_Perimetro")
	_adicionar_colisao_caixa(Vector3(1.53, y + 0.99, 6.625), Vector3(0.44, 1.98, 1.10), &"terreo", &"C19_Banco_Perimetro")
	_adicionar_material(&"hall_capacho_c19", Color("696151"), 0.98)
	var capacho := _materiais[&"hall_capacho_c19"] as StandardMaterial3D
	capacho.albedo_texture = load("res://prototype/assets/textures/ambientcg/Carpet012/Carpet012_Color_2K.jpg") as Texture2D
	capacho.emission_enabled = false
	_adicionar_tapete(&"terreo", Vector3(0.0, y + 0.025, 7.28), Vector2(1.24, 0.68), &"hall_capacho_c19")
	# A folha frontal recebe recursos próprios: não reescrever material compartilhado.
	for item in get_tree().get_nodes_in_group("porta_interativa"):
		var porta := item as Node3D
		if porta == null or porta.global_position.distance_to(Vector3(-0.8, 0.0, 8.0)) > 0.02:
			continue
		var madeira := (_materiais[&"door_wood"] as StandardMaterial3D).duplicate(true) as StandardMaterial3D
		madeira.resource_name = "MadeiraPortaFrontalC19"
		madeira.albedo_color = Color(0.72, 0.67, 0.58)
		madeira.albedo_texture = load("res://prototype/assets/textures/ambientcg/Wood026/Wood026_Color_2K.jpg") as Texture2D
		madeira.roughness = 0.62
		madeira.metallic = 0.0
		madeira.emission_enabled = false
		var metal := (_materiais[&"door_hardware"] as StandardMaterial3D).duplicate(true) as StandardMaterial3D
		metal.albedo_color = Color(0.59, 0.54, 0.43)
		metal.roughness = 0.40
		metal.emission_enabled = false
		for child in porta.get_children():
			var mesh := child as MeshInstance3D
			if mesh == null: continue
			if mesh.mesh is BoxMesh: mesh.material_override = madeira
			else: mesh.material_override = metal
		for px in [0.42, 1.18]:
			for py in [0.58, 1.49]:
				var painel := MeshInstance3D.new()
				painel.name = "C19_AlmofadaPorta"
				var box := BoxMesh.new()
				box.size = Vector3(0.62, 0.73, 0.016)
				painel.mesh = box
				painel.material_override = madeira
				painel.position = Vector3(px, py, -0.045)
				porta.add_child(painel)
		var fechadura := MeshInstance3D.new()
		fechadura.name = "C19_FechaduraSaida"
		var disco := CylinderMesh.new()
		disco.top_radius = 0.025
		disco.bottom_radius = 0.025
		disco.height = 0.010
		disco.radial_segments = 16
		fechadura.mesh = disco
		fechadura.material_override = metal
		fechadura.position = Vector3(1.312, 0.87, -0.047)
		fechadura.rotation.x = PI * 0.5
		porta.add_child(fechadura)
