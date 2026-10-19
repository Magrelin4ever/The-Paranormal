extends SceneTree

const CENA := preload("res://prototype/house_environment.tscn")
var falhas: Array[String] = []
var jogador: CharacterBody3D
var frames_totais := 0

func _initialize() -> void:
	call_deferred("_executar")

func _executar() -> void:
	var casa := CENA.instantiate()
	root.add_child(casa)
	await process_frame
	await physics_frame
	await physics_frame
	jogador = casa.get_node_or_null("Player") as CharacterBody3D
	if jogador == null:
		printerr("C13_ROUTE FAIL: jogador não encontrado")
		quit(1)
		return
	var portas := get_nodes_in_group("porta_interativa")
	for porta in portas:
		porta.call("alternar")
	await create_timer(0.45).timeout
	print("C13_ROUTE_SCOPE doors_opened_for_test=true horizontal_tolerance=0.34 vertical_tolerance=0.45 doors_opened=", portas.size(), " spawn=", jogador.global_position)
	var pontos: Array[Dictionary] = [
		{"p": Vector3(0.0, 0.0, 6.05), "n": "entrada frontal"},
		{"p": Vector3(0.0, 0.0, 5.15), "n": "foyer"},
		{"p": Vector3(-1.5, 0.0, 5.15), "n": "hall esquerdo frontal"},
		{"p": Vector3(-2.8, 0.0, 5.15), "n": "entrada da sala de estar"},
		{"p": Vector3(-4.35, 0.0, 5.2), "n": "sala de estar, faixa de circulação"},
		{"p": Vector3(-2.8, 0.0, 5.15), "n": "retorno da sala de estar"},
		{"p": Vector3(-5.55, 0.0, 2.8), "n": "porta estar–jantar"},
		{"p": Vector3(-5.55, 0.0, 2.0), "n": "jantar, entrada livre"},
		{"p": Vector3(-4.0, 0.0, 1.6), "n": "jantar, corredor leste"},
		{"p": Vector3(-4.0, 0.0, -2.0), "n": "jantar, contorno da mesa"},
		{"p": Vector3(-5.55, 0.0, -2.0), "n": "porta jantar–cozinha"},
		{"p": Vector3(-5.55, 0.0, -3.1), "n": "cozinha, entrada"},
		{"p": Vector3(-4.0, 0.0, -4.8), "n": "cozinha, circulação central"},
		{"p": Vector3(-4.0, 0.0, -6.3), "n": "cozinha, corredor diante da bancada"},
		{"p": Vector3(-4.0, 0.0, -4.8), "n": "cozinha, retorno"},
		{"p": Vector3(-5.55, 0.0, -2.0), "n": "cozinha, volta ao jantar"},
		{"p": Vector3(-4.0, 0.0, -2.0), "n": "jantar, retorno pelo corredor leste"},
		{"p": Vector3(-4.0, 0.0, 1.6), "n": "jantar, retorno ao hall"},
		{"p": Vector3(-5.55, 0.0, 2.0), "n": "jantar, acesso à sala"},
		{"p": Vector3(-2.8, 0.0, 5.15), "n": "sala, retorno ao hall"},
		{"p": Vector3(-1.3, 0.0, 5.15), "n": "foyer pelo hall central"},
		{"p": Vector3(1.3, 0.0, 5.15), "n": "hall direito frontal"},
		{"p": Vector3(2.8, 0.0, 5.15), "n": "entrada do escritório"},
		{"p": Vector3(3.8, 0.0, 5.3), "n": "escritório, corredor de circulação"},
		{"p": Vector3(4.2, 0.0, 4.7), "n": "escritório, aproximação à mesa"},
		{"p": Vector3(5.55, 0.0, 2.8), "n": "porta escritório–biblioteca"},
		{"p": Vector3(5.55, 0.0, 2.0), "n": "biblioteca, entrada"},
		{"p": Vector3(7.8, 0.0, 1.8), "n": "biblioteca, corredor das estantes"},
		{"p": Vector3(7.8, 0.0, -1.5), "n": "biblioteca, faixa de leitura"},
		{"p": Vector3(5.55, 0.0, -2.0), "n": "porta biblioteca–serviço"},
		{"p": Vector3(5.55, 0.0, -3.2), "n": "área de serviço, entrada"},
		{"p": Vector3(5.6, 0.0, -4.8), "n": "serviço, faixa livre da escada"},
		{"p": Vector3(4.5, 0.0, -5.8), "n": "serviço, acesso à lavanderia"},
		{"p": Vector3(5.6, 0.0, -4.8), "n": "serviço, retorno"},
		{"p": Vector3(2.8, 0.0, -5.35), "n": "serviço, porta para o hall"},
		{"p": Vector3(1.3, 0.0, -5.35), "n": "reentrada no hall direito"},
		{"p": Vector3(1.3, 0.0, 5.15), "n": "retorno ao foyer"},
		{"p": Vector3(0.0, 0.0, 10.0), "n": "saída frontal"}
	]
	var completo := true
	for item in pontos:
		var resultado := await _andar_ate(item["p"], String(item["n"]), 8.0)
		if not bool(resultado["alcançou"]):
			falhas.append(String(item["n"]))
			completo = false
			break
	print("C13_ROUTE_RESULT status=%s waypoints=%d frames=%d final=%s" % ["PASS" if completo else "BLOCK", pontos.size(), frames_totais, str(jogador.global_position)])
	if falhas.is_empty():
		print("C13_ROUTE PASS")
		quit(0)
	else:
		printerr("C13_ROUTE FAIL bloqueado_em=", falhas)
		quit(1)

func _andar_ate(destino: Vector3, rotulo: String, limite_s: float) -> Dictionary:
	var inicio := jogador.global_position
	var delta := Vector2(destino.x - inicio.x, destino.z - inicio.z)
	var ultimo_colisor := "nenhum"
	if delta.length() > 0.03:
		jogador.rotation.y = atan2(-delta.x, -delta.y)
		Input.action_press("move_forward")
		Input.action_press("sprint")
		var distancia_anterior := INF
		var quadros_sem_progresso := 0
		for _i in range(int(ceil(limite_s * float(Engine.physics_ticks_per_second)))):
			var delta_atual := Vector2(destino.x - jogador.global_position.x, destino.z - jogador.global_position.z)
			if delta_atual.length() > 0.03:
				jogador.rotation.y = atan2(-delta_atual.x, -delta_atual.y)
			await physics_frame
			frames_totais += 1
			for colisao_i in range(jogador.get_slide_collision_count()):
				var colisao := jogador.get_slide_collision(colisao_i)
				if absf(colisao.get_normal().y) < 0.7:
					var corpo := colisao.get_collider() as Node
					ultimo_colisor = corpo.name if corpo != null else "objeto sem nó"
					if corpo is Node3D:
						var corpo_3d := corpo as Node3D
						ultimo_colisor += " path=%s pos=%s rot=%s" % [corpo.get_path(), corpo_3d.global_position, corpo_3d.rotation_degrees]
			var horizontal := Vector2(destino.x - jogador.global_position.x, destino.z - jogador.global_position.z).length()
			var vertical := absf(destino.y - jogador.global_position.y)
			if horizontal <= 0.2 and vertical <= 0.45:
				break
			if horizontal < distancia_anterior - 0.002:
				quadros_sem_progresso = 0
				distancia_anterior = horizontal
			else:
				quadros_sem_progresso += 1
			if quadros_sem_progresso >= 45:
				break
		Input.action_release("move_forward")
		Input.action_release("sprint")
		for _settle in range(4):
			await physics_frame
			frames_totais += 1
	var pos := jogador.global_position
	var h_error := Vector2(destino.x - pos.x, destino.z - pos.z).length()
	var y_error := absf(destino.y - pos.y)
	var alcançou := h_error <= 0.34 and y_error <= 0.45
	print("C13_WAYPOINT ", rotulo, " end=", pos, " target=", destino, " h=", snappedf(h_error, 0.001), " floor=", jogador.is_on_floor(), " reached=", alcançou)
	if not alcançou:
		print("C13_COLLIDER waypoint=", rotulo, " last=", ultimo_colisor)
	return {"alcançou": alcançou}
