extends SceneTree

const SHADER_PATH := "res://prototype/haunted_film_grain_c18.gdshader"
const PLAYER_PATH := "res://prototype/house_player.gd"
const RESULT_PATH := "res://qa/whole_house/lighting_results.json"
const EPSILON := 0.0001

var failures: Array[String] = []
var checks: Array[Dictionary] = []

func _check(name: String, passed: bool, detail: String = "") -> void:
	checks.append({"name": name, "pass": passed, "detail": detail})
	if not passed:
		failures.append(name + ": " + detail)

func _transmission(active: float, beam_enabled: float, outside_beam: float, strength: float) -> float:
	var beam_falloff := lerpf(1.0, outside_beam, beam_enabled)
	return 1.0 - active * strength * beam_falloff

func _init() -> void:
	var shader_text := FileAccess.get_file_as_string(SHADER_PATH)
	var player_text := FileAccess.get_file_as_string(PLAYER_PATH)
	_check("shader_has_base_darkening", shader_text.contains("flashlight_darkening_active"))
	_check("shader_separates_beam_state", shader_text.contains("flashlight_beam_enabled") and shader_text.contains("mix(1.0, outside_beam, flashlight_beam_enabled)"), "o feixe deve variar sem remover o escurecimento base")
	_check("player_keeps_darkening_when_off", player_text.contains('set_shader_parameter("flashlight_darkening_active", 1.0)'))
	_check("player_sets_beam_state", player_text.contains('set_shader_parameter("flashlight_beam_enabled", 1.0 if ativa else 0.0)'))
	_check("three_beams_preserved", player_text.contains("LanternaFeixeAmplo") and player_text.contains("LanternaFaixaMedia") and player_text.contains("LanternaNucleo"), "os três SpotLight3D permanecem")

	var strength := 0.20
	var center_on := _transmission(1.0, 1.0, 0.0, strength)
	var edge_on := _transmission(1.0, 1.0, 1.0, strength)
	var center_off := _transmission(1.0, 0.0, 0.0, strength)
	var edge_off := _transmission(1.0, 0.0, 1.0, strength)
	_check("center_beam_remains_legible", center_on > edge_on and center_on > 0.95, "centro=%.4f periferia=%.4f" % [center_on, edge_on])
	_check("off_matches_dark_periphery", is_equal_approx(center_off, edge_on) and is_equal_approx(edge_off, edge_on), "desligado=%.4f periferia=%.4f" % [center_off, edge_on])
	_check("off_never_brighter", center_off <= center_on and edge_off <= center_on, "off centro=%.4f borda=%.4f" % [center_off, edge_off])
	_check("shader_variation_is_monotonic", _transmission(1.0, 1.0, 0.5, strength) < center_on and _transmission(1.0, 1.0, 0.5, strength) > edge_on, "a transição do feixe é contínua")

	var result := {
		"test": "lighting_darkness_test",
		"mode": "shader-equivalent automated render contract",
		"shader": SHADER_PATH,
		"camera_samples": {
			"center": {"flashlight_on": center_on, "flashlight_off": center_off},
			"periphery": {"flashlight_on": edge_on, "flashlight_off": edge_off},
			"variation": {"mid_beam": _transmission(1.0, 1.0, 0.5, strength)}
		},
		"three_beams": ["LanternaFeixeAmplo", "LanternaFaixaMedia", "LanternaNucleo"],
		"checks": checks,
		"passed": failures.is_empty(),
		"limitations": "Validação determinística do contrato do shader; não substitui captura visual da casa completa."
	}
	var file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	if failures.is_empty():
		print("LIGHTING TEST PASS: %d checks" % checks.size())
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
