extends SceneTree

## Auditoria somente leitura da casa inteira.
## Uso opcional: godot --headless --path . --script res://qa/whole_house/audit_static.gd
## Não instancia a cena e não dispara importação/bake.
const BUILDER := "res://prototype/house_environment.gd"
const HOUSE_SCENE := "res://prototype/house_environment.tscn"
const DOOR_SCRIPT := "res://prototype/interactive_door.gd"

func _init() -> void:
	var findings: Array[String] = []
	var source := FileAccess.get_file_as_string(BUILDER)
	var scene := FileAccess.get_file_as_string(HOUSE_SCENE)
	var door := FileAccess.get_file_as_string(DOOR_SCRIPT)
	_check(source, "const IDS_PAVIMENTOS: Array[StringName] = [&\"porao\", &\"terreo\", &\"primeiro\", &\"sotao\"]", "PISOS", findings)
	_check(source, "_criar_corpos_colisao()", "COLISAO_ROOT", findings)
	_check(source, "_montar_escadas()", "ESCADAS", findings)
	_check(source, "_adicionar_cozinha_kitchen004_c16(y)", "COZINHA_RICHARD_C16", findings)
	_check(source, "_adicionar_modelo_mobiliario", "MOBILIARIO", findings)
	_check(source, "var tamanho_final := tamanho_colisao * escala", "HITBOX_ESCALA", findings)
	_check(source, "_adicionar_colisao_caixa(origem + Vector3(0.0, tamanho_final.y * 0.5, 0.0)", "HITBOX_ORIGEM", findings)
	_check(door, "extends AnimatableBody3D", "PORTA_ANIMATABLE", findings)
	_check(door, "add_to_group(\"porta_interativa\")", "PORTA_GROUP", findings)
	_check(scene, "SalaJantar_Editavel", "CENA_DINING_INSTANCE", findings)
	if source.find("owner =") < 0:
		findings.append("CRITICO OWNERSHIP: builder não define owner; nós criados em runtime não entram automaticamente no bake editável.")
	if source.find("_raiz_visual.add_child(modelo)") >= 0 and source.find("modelo.add_child") < 0:
		findings.append("CRITICO COLLIDER: hitboxes são filhos de StaticBody3D por piso, não filhos do modelo; rotação/escala do asset pode divergir do collider.")
	if source.find("_adicionar_porta_") >= 0 and scene.find("interactive_door") < 0:
		findings.append("CRITICO PORTAS: portas são geradas pelo script; a cena persistida não contém instâncias de porta/script para edição/bake.")
	if findings.is_empty():
		print("AUDIT_STATIC PASS: invariantes encontradas")
	else:
		print("AUDIT_STATIC READ_ONLY")
		for finding in findings:
			print(finding)
	quit(0)

func _check(text: String, needle: String, label: String, findings: Array[String]) -> void:
	if text.find(needle) < 0:
		findings.append("ERRO %s: padrão ausente: %s" % [label, needle])
