extends AnimatableBody3D

@export var angulo_abertura_graus: float = 95.0
@export var duracao_transicao: float = 0.24

var _aberta := false
var _animacao: Tween
var _rotacao_fechada := 0.0

func _ready() -> void:
	add_to_group("porta_interativa")
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	set_meta("interativo", "porta")
	# A orientação salva no viewport é a posição FECHADA, não precisa ser zero.
	_rotacao_fechada = rotation.y
	# O alvo fica fixo no vão durante a animação, mas acompanha mudanças salvas
	# de posição/rotação da porta antes de o jogo iniciar.
	var alvo := get_node_or_null("AlvoInteracao") as Area3D
	if alvo != null:
		for child in get_children():
			if child is CollisionShape3D:
				var ponto_local: Vector3 = child.position
				alvo.top_level = true
				alvo.global_transform = global_transform * Transform3D(Basis.IDENTITY, ponto_local)
				break

func alternar() -> void:
	_aberta = not _aberta
	if _animacao != null and _animacao.is_running():
		_animacao.kill()
	_animacao = create_tween()
	_animacao.set_trans(Tween.TRANS_CUBIC)
	_animacao.set_ease(Tween.EASE_IN_OUT)
	var destino := _rotacao_fechada + (deg_to_rad(angulo_abertura_graus) if _aberta else 0.0)
	_animacao.tween_property(self, "rotation:y", destino, duracao_transicao)

func texto_interacao() -> String:
	return "E  ·  Fechar porta" if _aberta else "E  ·  Abrir porta"

func esta_aberta() -> bool:
	return _aberta
