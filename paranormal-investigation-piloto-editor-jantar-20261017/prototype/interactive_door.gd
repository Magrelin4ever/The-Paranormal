extends AnimatableBody3D

@export var angulo_abertura_graus: float = 84.0
@export var duracao_transicao: float = 0.24

var _aberta := false
var _animacao: Tween

func _ready() -> void:
	add_to_group("porta_interativa")
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	set_meta("interativo", "porta")

func alternar() -> void:
	_aberta = not _aberta
	if _animacao != null and _animacao.is_running():
		_animacao.kill()
	_animacao = create_tween()
	_animacao.set_trans(Tween.TRANS_CUBIC)
	_animacao.set_ease(Tween.EASE_IN_OUT)
	var destino := deg_to_rad(angulo_abertura_graus) if _aberta else 0.0
	_animacao.tween_property(self, "rotation:y", destino, duracao_transicao)

func texto_interacao() -> String:
	return "E  ·  Fechar porta" if _aberta else "E  ·  Abrir porta"

func esta_aberta() -> bool:
	return _aberta
