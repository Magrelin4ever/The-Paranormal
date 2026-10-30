extends SceneTree

## Auditoria somente leitura do projeto single-player e do pacote de assets ativo.
## Uso: godot --headless --path . --script res://qa/whole_house/audit_static.gd
const ACTIVE_FILES := [
	"res://project.godot",
	"res://game/investigation.tscn",
	"res://prototype/house_environment.tscn",
	"res://prototype/whole_house/casa_editavel.tscn",
	"res://prototype/whole_house/rooms/terreo__Cozinha_Richard.tscn",
]
const ALLOWED_KITCHEN_NOTES := [
	"res://prototype/assets/models/custom/kitchen004/DISTRIBUTION_BLOCKED.md",
	"res://prototype/assets/models/custom/kitchen004/source/.gdignore",
]

func _initialize() -> void:
	var failures: Array[String] = []
	var project := FileAccess.get_file_as_string(ACTIVE_FILES[0])
	if not project.contains("run/main_scene=\"res://game/main_menu.tscn\""):
		failures.append("A cena principal não inicia pelo menu single-player.")
	var investigation := FileAccess.get_file_as_string(ACTIVE_FILES[1])
	if not investigation.contains("res://prototype/house_environment.tscn"):
		failures.append("A investigação não referencia a cena de ambiente.")
	var house_environment := FileAccess.get_file_as_string(ACTIVE_FILES[2])
	if not house_environment.contains("res://prototype/whole_house/casa_editavel.tscn"):
		failures.append("A cena de ambiente não referencia a casa editável salva.")
	for path in ACTIVE_FILES:
		if not FileAccess.file_exists(path):
			failures.append("Arquivo ativo ausente: %s" % path)
			continue
		var source := FileAccess.get_file_as_string(path)
		if source.contains("Kitchen004C16") or source.contains("kitchen004_fitted.glb") or source.contains("kitchen_builtin_oven_c1.glb"):
			failures.append("Cena ativa contém referência a asset bloqueado: %s" % path)
	for path in ALLOWED_KITCHEN_NOTES:
		if not FileAccess.file_exists(path):
			failures.append("Nota de bloqueio/proteção ausente: %s" % path)
	var blocked_mesh_paths: Array[String] = []
	for index in range(1678, 1755):
		blocked_mesh_paths.append("res://prototype/whole_house/resources/mesh_%d.res" % index)
	blocked_mesh_paths.append("res://prototype/whole_house/resources/mesh_1757.res")
	for path in blocked_mesh_paths:
		if FileAccess.file_exists(path):
			failures.append("Mesh C16 exclusivo ainda está no pacote: %s" % path)
	for index in range(7, 92):
		var path := "res://prototype/whole_house/resources/material_%04d.res" % index
		if FileAccess.file_exists(path):
			failures.append("Material C16 exclusivo ainda está no pacote: %s" % path)
	if failures.is_empty():
		print("AUDIT_STATIC_PASS active_scenes=%d blocked_assets=0" % ACTIVE_FILES.size())
	else:
		for failure in failures:
			printerr("AUDIT_STATIC_FAIL ", failure)
	quit(0 if failures.is_empty() else 1)
