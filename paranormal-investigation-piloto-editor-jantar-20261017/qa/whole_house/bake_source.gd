extends "res://prototype/house_environment.gd"
# Adaptador OFFLINE. Só qa/whole_house/bake_house.gd o executa.
var bake_phase := "Estrutura"
var bake_serial := 0
var bake_box_count := 0
var bake_triangle_count := 0

func _ready() -> void:
	set_process(false)
	_criar_materiais()
	_raiz_visual = Node3D.new()
	_raiz_visual.name = "ConteudoConvertido"
	add_child(_raiz_visual)
	_criar_corpos_colisao()
	for method in ["_montar_pisos_e_estrutura", "_montar_paredes_internas", "_montar_escadas", "_montar_telhado_exterior", "_mobiliar_porao", "_mobiliar_terreo", "_mobiliar_primeiro_andar", "_mobiliar_sotao", "_montar_vizinhanca"]:
		bake_phase = method
		call(method)
	_apagar_luzes_internas()

func bake_enter(label: String, piso: StringName = &"") -> Node3D:
	var item := Node3D.new()
	bake_serial += 1
	item.name = "%s_%03d" % [label, bake_serial]
	item.set_meta("origem_conversao", label)
	item.set_meta("fase_conversao", bake_phase)
	item.set_meta("pavimento", piso)
	item.set_meta("_edit_group_", true)
	_raiz_visual.add_child(item)
	_raiz_visual = item
	return item

func bake_exit(previous: Node3D, item: Node3D, pivot: Vector3) -> void:
	_raiz_visual = previous
	# Os helpers originais escrevem coordenadas da casa. Recentrar conserva o mundo.
	for child in item.get_children():
		if child is Node3D and not child.top_level:
			child.position -= pivot
	item.position = pivot
	item.set_meta("pivot_original", pivot)

func bake_body(parent: Node3D, center: Vector3, size: Vector3, angle: Vector3, label: String) -> void:
	var body := StaticBody3D.new()
	body.name = label.validate_node_name()
	body.collision_layer = 1
	body.collision_mask = 1
	body.position = center
	body.rotation = angle
	parent.add_child(body)
	var shape := CollisionShape3D.new()
	shape.name = "Forma"
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	body.add_child(shape)

func _adicionar_colisao_caixa(center: Vector3, size: Vector3, floor_id: StringName, collider_name: StringName, rotation: Vector3 = Vector3.ZERO) -> void:
	# Colisão pertence à peça, nunca a um corpo global fixo.
	bake_body(_raiz_visual, center, size, rotation, String(collider_name))

func _finalizar_malhas_visuais() -> void:
	pass # Cada peça já tem malha própria e editável.

func _adicionar_triangulo(a: Vector3, b: Vector3, c: Vector3, material_key: StringName) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(_materiais[material_key])
	var pivot := (a+b+c)/3.0
	var normal := (b-a).cross(c-a).normalized()
	for vertex in [a,b,c]:
		st.set_normal(normal)
		st.set_uv(Vector2.ZERO)
		st.add_vertex(vertex-pivot)
	var mesh := MeshInstance3D.new()
	bake_triangle_count += 1
	mesh.name = "Triangulo_%s_%03d" % [material_key, bake_triangle_count]
	mesh.mesh = st.commit()
	mesh.position = pivot
	mesh.set_meta("fase_conversao", bake_phase)
	_raiz_visual.add_child(mesh)

func _adicionar_tubo_servico_c17(a: Vector3, b: Vector3, raio: float, material_key: StringName) -> void:
	var direction := b-a
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = raio
	cylinder.bottom_radius = raio
	cylinder.height = direction.length()
	cylinder.radial_segments = 16
	cylinder.rings = 1
	var mesh := MeshInstance3D.new()
	mesh.name = "Tubo_%s" % material_key
	mesh.mesh = cylinder
	mesh.material_override = _materiais[material_key]
	mesh.position = (a+b)*0.5
	mesh.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
	mesh.set_meta("fase_conversao", bake_phase)
	_raiz_visual.add_child(mesh)

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
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(_materiais[material_key])
	for face in faces:
		var normal: Vector3 = face[4]
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
			tool.add_vertex(points[vertex_index])
	tool.index()
	var piece := MeshInstance3D.new()
	bake_box_count += 1
	piece.name = "Peca_%s_%04d" % [material_key, bake_box_count]
	piece.mesh = tool.commit()
	piece.position = center
	piece.rotation = rotation
	piece.set_meta("fase_conversao", bake_phase)
	piece.set_meta("pavimento", floor_id)
	piece.set_meta("material_original", material_key)
	piece.set_meta("_edit_group_", true)
	_raiz_visual.add_child(piece)
	if solid and _corpos_colisao.has(floor_id):
		bake_body(piece, Vector3.ZERO, size, Vector3.ZERO, "Colisao_Acompanha_Peca")

func _adicionar_modelo_mobiliario(asset_id: String, origem: Vector3, escala: float, rotacao_y_graus: float, floor_id: StringName, tamanho_colisao: Vector3 = Vector3.ZERO) -> Node3D:
	var previous := _raiz_visual
	var item := bake_enter("Modelo_" + asset_id, floor_id)
	var result = super._adicionar_modelo_mobiliario(asset_id, origem, escala, rotacao_y_graus, floor_id, tamanho_colisao)
	bake_exit(previous, item, origem)
	return result

func _adicionar_modelo_glb(asset_name: String, file_name: String, origem: Vector3, escala: float, rotacao_y_graus: float, floor_id: StringName, tamanho_colisao: Vector3 = Vector3.ZERO) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Modelo_" + asset_name, floor_id)
	super._adicionar_modelo_glb(asset_name, file_name, origem, escala, rotacao_y_graus, floor_id, tamanho_colisao)
	bake_exit(previous, item, origem)

func _adicionar_cozinha_kitchen004_c16(y: float) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Cozinha_Richard_Preservada", &"terreo")
	super._adicionar_cozinha_kitchen004_c16(y)
	bake_exit(previous, item, Vector3(-3.467222, y + 0.022, -6.9333043))

func _adicionar_tapete(floor_id: StringName, center: Vector3, size: Vector2, material_key: StringName) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Tapete", floor_id)
	super._adicionar_tapete(floor_id, center, size, material_key)
	bake_exit(previous, item, center)

func _adicionar_mesa(floor_id: StringName, origin: Vector3, size: Vector2, material_key: StringName, height: float) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Mesa", floor_id)
	super._adicionar_mesa(floor_id, origin, size, material_key, height)
	bake_exit(previous, item, origin)

func _adicionar_cadeira(floor_id: StringName, origin: Vector3, wood: StringName, fabric: StringName) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Cadeira", floor_id)
	super._adicionar_cadeira(floor_id, origin, wood, fabric)
	bake_exit(previous, item, origin)

func _adicionar_sofa(origin: Vector3, fabric: StringName, floor_id: StringName) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Sofa", floor_id)
	super._adicionar_sofa(origin, fabric, floor_id)
	bake_exit(previous, item, origin)

func _adicionar_cama(floor_id: StringName, origin: Vector3, size: Vector2, cover: StringName, frame: StringName) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Cama", floor_id)
	super._adicionar_cama(floor_id, origin, size, cover, frame)
	bake_exit(previous, item, origin)

func _adicionar_quadro_eixo_x(floor_id: StringName, center: Vector3, size: Vector2, frame: StringName, image: StringName) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Quadro", floor_id)
	super._adicionar_quadro_eixo_x(floor_id, center, size, frame, image)
	bake_exit(previous, item, center)

func _adicionar_quadro_eixo_z(floor_id: StringName, center: Vector3, size: Vector2, frame: StringName, image: StringName) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Quadro", floor_id)
	super._adicionar_quadro_eixo_z(floor_id, center, size, frame, image)
	bake_exit(previous, item, center)

func _adicionar_banquetas_cozinha(center: Vector3) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Banqueta_Cozinha", &"terreo")
	super._adicionar_banquetas_cozinha(center)
	bake_exit(previous, item, center)

func _adicionar_faca_preparo_cozinha(base: Vector3, id: String) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Faca_" + id, &"terreo")
	super._adicionar_faca_preparo_cozinha(base, id)
	bake_exit(previous, item, base)

func _adicionar_pano_cozinha(center: Vector3, id: String) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Pano_" + id, &"terreo")
	super._adicionar_pano_cozinha(center, id)
	bake_exit(previous, item, center)

func _adicionar_arte_quadro_escritorio_c15(centro: Vector3, tamanho: Vector2) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Arte_Escritorio", &"terreo")
	super._adicionar_arte_quadro_escritorio_c15(centro, tamanho)
	bake_exit(previous, item, centro)

func _adicionar_arte_quadro_biblioteca(centro: Vector3, tamanho: Vector2) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Arte_Biblioteca", &"terreo")
	super._adicionar_arte_quadro_biblioteca(centro, tamanho)
	bake_exit(previous, item, centro)

func _adicionar_placa_sala(texto: String, origem: Vector3, rotacao_y_graus: float, largura: float = 1.2) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Placa_" + texto, &"")
	super._adicionar_placa_sala(texto, origem, rotacao_y_graus, largura)
	bake_exit(previous, item, origem)

func _adicionar_escada(floor_id: StringName, lower: Vector3, upper: Vector3, material_key: StringName, open_lower_approach: bool = false) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Escada_" + String(floor_id), floor_id)
	super._adicionar_escada(floor_id, lower, upper, material_key, open_lower_approach)
	bake_exit(previous, item, lower)

func _adicionar_escada_servico_porao(lower: Vector3, upper: Vector3, open_lower_approach: bool) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Escada_Servico_Porao", &"porao")
	super._adicionar_escada_servico_porao(lower, upper, open_lower_approach)
	bake_exit(previous, item, lower)

func _adicionar_acabamento_escada_c17() -> void:
	var previous := _raiz_visual
	var item := bake_enter("GuardaCorpo_Servico", &"terreo")
	super._adicionar_acabamento_escada_c17()
	bake_exit(previous, item, Vector3(7.8,0.0,-5.6))

func _adicionar_planta_interior(floor_id: StringName, origem: Vector3, escala_folhagem: float) -> void:
	var previous := _raiz_visual
	var item := bake_enter("Planta", floor_id)
	super._adicionar_planta_interior(floor_id, origem, escala_folhagem)
	bake_exit(previous, item, origem)
