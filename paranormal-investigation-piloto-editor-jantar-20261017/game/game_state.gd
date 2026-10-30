extends Node

signal changed

const PROFILE_PATH := "user://paranormal_profile.cfg"
const EQUIPMENT_CAPACITY := 5
const TOOL_CATALOG := {
	"lantern": {"name": "Lanterna", "price": 0, "category": "light", "description": "Feixe triplo para percorrer a casa sem energia."},
	"meter": {"name": "Medidor de campo", "price": 0, "category": "field", "description": "Localiza assinaturas de energia anômala."},
	"thermometer": {"name": "Termômetro infravermelho", "price": 85, "category": "cold", "description": "Confirma quedas de temperatura fora do padrão."},
	"recorder": {"name": "Gravador EVP", "price": 110, "category": "voice", "description": "Registra vozes e ruídos que não aparecem a olho nu."},
	"camera": {"name": "Câmera de espectro", "price": 120, "category": "visual", "description": "Documenta distorções e figuras no ambiente."},
	"battery": {"name": "Bateria reserva", "price": 65, "category": "upgrade", "description": "Aumenta a margem da lanterna durante a varredura."},
	"filter": {"name": "Filtro de áudio", "price": 75, "category": "upgrade", "description": "Amplia a recompensa por evidências de voz."}
}

var credits: int = 260
var owned_equipment: Array[String] = ["lantern", "meter"]
var equipped_equipment: Array[String] = ["lantern", "meter"]
var active_equipment: String = "meter"
var mouse_sensitivity: float = 0.002
var master_volume: float = 0.82
var cases_completed: int = 0
var total_evidence: int = 0
var family_contacted: bool = false
var current_case: Dictionary = {}
var evidence_found: Dictionary = {}
var elapsed_seconds: float = 0.0
var entity_events: int = 0
var catches: int = 0
var session_active: bool = false
var last_report: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_load_profile()
	_apply_volume()

func start_new_case() -> void:
	var cases := _case_catalog()
	var template: Dictionary = cases[rng.randi_range(0, cases.size() - 1)]
	current_case = template.duplicate(true)
	evidence_found.clear()
	family_contacted = false
	elapsed_seconds = 0.0
	entity_events = 0
	catches = 0
	session_active = false
	last_report.clear()
	changed.emit()

func contact_family() -> Dictionary:
	if current_case.is_empty():
		start_new_case()
	if family_contacted:
		return {"ok": false, "message": "A família já foi contatada para este caso."}
	family_contacted = true
	credits += 125
	_save_profile()
	changed.emit()
	return {"ok": true, "message": str(current_case.get("family_message", "Obrigado por atender. A gente precisa saber o que aconteceu."))}

func buy_equipment(item_id: String) -> Dictionary:
	if not TOOL_CATALOG.has(item_id):
		return {"ok": false, "message": "Equipamento não encontrado."}
	if owned_equipment.has(item_id):
		return {"ok": false, "message": "Este item já está no inventário."}
	var item: Dictionary = TOOL_CATALOG[item_id]
	var price := int(item.get("price", 0))
	if credits < price:
		return {"ok": false, "message": "Saldo insuficiente para este equipamento."}
	credits -= price
	owned_equipment.append(item_id)
	_save_profile()
	changed.emit()
	return {"ok": true, "message": "%s comprado por $%d." % [item["name"], price]}

func equip_equipment(item_id: String) -> Dictionary:
	if not owned_equipment.has(item_id):
		return {"ok": false, "message": "Compre o item antes de equipá-lo."}
	if str(TOOL_CATALOG[item_id].get("category", "")) == "upgrade":
		return {"ok": false, "message": "Esta melhoria é passiva e não ocupa espaço na carga."}
	if equipped_equipment.has(item_id):
		if item_id == "lantern":
			return {"ok": false, "message": "A lanterna é equipamento obrigatório."}
		equipped_equipment.erase(item_id)
		if active_equipment == item_id:
			active_equipment = _first_active_equipment()
		_save_profile()
		changed.emit()
		return {"ok": true, "message": "%s removido da carga." % TOOL_CATALOG[item_id]["name"]}
	if equipped_equipment.size() >= EQUIPMENT_CAPACITY:
		return {"ok": false, "message": "A carga comporta %d itens. Retire um para equipar outro." % EQUIPMENT_CAPACITY}
	equipped_equipment.append(item_id)
	if item_id != "lantern":
		active_equipment = item_id
	_save_profile()
	changed.emit()
	return {"ok": true, "message": "%s pronto para a investigação." % TOOL_CATALOG[item_id]["name"]}

func can_launch_case() -> bool:
	if not family_contacted:
		return false
	for tool_id in ["meter", "thermometer", "recorder", "camera"]:
		if not equipped_equipment.has(tool_id):
			return false
	return true

func launch_case() -> bool:
	if not can_launch_case():
		return false
	session_active = true
	elapsed_seconds = 0.0
	_save_profile()
	changed.emit()
	return true

func cycle_equipment() -> String:
	var available: Array[String] = []
	for item_id in equipped_equipment:
		if item_id != "lantern" and str(TOOL_CATALOG.get(item_id, {}).get("category", "")) != "upgrade":
			available.append(item_id)
	if available.is_empty():
		active_equipment = "lantern"
	else:
		var current_index := available.find(active_equipment)
		active_equipment = available[(current_index + 1) % available.size()]
	changed.emit()
	return active_equipment

func get_active_equipment_name() -> String:
	if TOOL_CATALOG.has(active_equipment):
		return str(TOOL_CATALOG[active_equipment]["name"])
	return "Lanterna"

func get_active_category() -> String:
	if TOOL_CATALOG.has(active_equipment):
		return str(TOOL_CATALOG[active_equipment]["category"])
	return "light"

func find_evidence(point: Dictionary) -> Dictionary:
	var point_id := str(point.get("id", ""))
	if point_id.is_empty() or evidence_found.has(point_id):
		return {"ok": false, "message": "Este ponto já foi registrado."}
	var required_category := str(point.get("category", "field"))
	if get_active_category() != required_category:
		var needed := _tool_name_for_category(required_category)
		return {"ok": false, "message": "A leitura exige %s. Pressione Q para trocar de ferramenta." % needed}
	evidence_found[point_id] = {
		"id": point_id,
		"name": str(point.get("name", "Sinal anômalo")),
		"category": required_category,
		"floor": str(point.get("floor", "")),
		"description": str(point.get("description", "")),
		"required": bool(point.get("required", true))
	}
	if bool(point.get("required", true)):
		total_evidence += 1
	_save_profile()
	changed.emit()
	return {"ok": true, "message": str(point.get("discovery_message", "Leitura registrada no caderno de campo."))}

func required_evidence_count() -> int:
	var count := 0
	for clue in current_case.get("clues", []):
		if bool(clue.get("required", true)) and evidence_found.has(str(clue.get("id", ""))):
			count += 1
	return count

func required_evidence_total() -> int:
	var count := 0
	for clue in current_case.get("clues", []):
		if bool(clue.get("required", true)):
			count += 1
	return count

func evidence_for_type(category: String) -> bool:
	for item in evidence_found.values():
		if str(item.get("category", "")) == category:
			return true
	return false

func record_entity_event() -> void:
	entity_events += 1
	changed.emit()

func record_catch() -> void:
	catches += 1
	changed.emit()

func finish_case() -> Dictionary:
	if current_case.is_empty():
		return {}
	var count := required_evidence_count()
	var total := required_evidence_total()
	var optional_count := maxi(0, evidence_found.size() - count)
	var resolved := count == total and total > 0
	var reward := 75 + count * 55 + optional_count * 18
	if resolved:
		reward += 125
	if owned_equipment.has("filter") and evidence_for_type("voice"):
		reward += 25
	credits += reward
	cases_completed += 1
	last_report = {
		"case_title": str(current_case.get("title", "Caso sem identificação")),
		"family": str(current_case.get("family", "Família")),
		"resolved": resolved,
		"evidence_count": count,
		"evidence_total": total,
		"optional_count": optional_count,
		"entity_events": entity_events,
		"catches": catches,
		"elapsed_seconds": elapsed_seconds,
		"reward": reward,
		"credits": credits,
		"evidence": evidence_found.values().duplicate(true),
		"closing": str(current_case.get("resolved_text" if resolved else "partial_text", "A investigação foi encerrada."))
	}
	session_active = false
	_save_profile()
	changed.emit()
	return last_report.duplicate(true)

func start_another_case() -> void:
	start_new_case()

func get_launch_blocker() -> String:
	if not family_contacted:
		return "Ligue para a família no console de contatos."
	for tool_id in ["meter", "thermometer", "recorder", "camera"]:
		if not equipped_equipment.has(tool_id):
			return "Equipe os quatro instrumentos de investigação no console de equipamento."
	return "Pronto para sair."

func set_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.0007, 0.0045)
	_save_profile()
	changed.emit()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	_save_profile()
	changed.emit()

func _tool_name_for_category(category: String) -> String:
	for item in TOOL_CATALOG.values():
		if str(item.get("category", "")) == category:
			return str(item.get("name", "instrumento"))
	return "instrumento correspondente"

func _first_active_equipment() -> String:
	for item_id in equipped_equipment:
		if item_id != "lantern":
			return item_id
	return "lantern"

func _case_catalog() -> Array[Dictionary]:
	return [
		{
			"id": "case_01", "title": "A casa que chama de volta", "family": "Família Azevedo", "area": "Residência Azevedo · bairro Monte Claro", "reward_base": 200,
			"brief": "Há três noites, a família ouve a voz de alguém que não está em casa. O rádio desliga sozinho e a porta do porão amanhece aberta.",
			"news": "Jornal do bairro: três noites de relatos sobre vozes em uma residência recém-ocupada; vizinhos dizem que o rádio para sempre à mesma hora.",
			"family_message": "A gente não quer que você machuque ninguém. Minha filha diz que a voz chama pelo nome dela. Deixei uma chave extra na caixa da entrada.",
			"resolved_text": "A gravação isolou uma voz adulta repetindo um nome, enquanto a câmera confirmou a mesma figura vista na escada. A família foi orientada a passar a noite fora; o fenômeno perdeu intensidade depois da documentação completa.",
			"partial_text": "Algumas anomalias foram registradas, mas a origem permaneceu inconclusiva. A família recebeu instruções de segurança e o caso foi encaminhado para nova visita.",
			"clues": [
				{"id":"az_field","name":"Pulso no painel do porão","category":"field","floor":"Porão · oficina","position":Vector3(2.45,-2.78,-5.70),"description":"O medidor registra uma assinatura repetitiva, concentrada perto da parede leste.","discovery_message":"Pulso eletromagnético documentado. A frequência repete em intervalos de 17 segundos.","required":true},
				{"id":"az_cold","name":"Queda térmica na lavanderia","category":"cold","floor":"Térreo · área de serviço","position":Vector3(6.35,0.20,-5.55),"description":"Uma faixa fria atravessa o ambiente sem corrente de ar correspondente.","discovery_message":"Anomalia térmica registrada: queda de 8,4 °C em uma área estreita.","required":true},
				{"id":"az_voice","name":"Voz no patamar","category":"voice","floor":"Primeiro andar · hall","position":Vector3(0.20,3.05,0.40),"description":"O gravador captura uma resposta curta, embora o cômodo esteja vazio.","discovery_message":"Resposta EVP registrada. A voz parece dizer “estou aqui”.", "required":true},
				{"id":"az_visual","name":"Figura no arquivo","category":"visual","floor":"Sótão · arquivo","position":Vector3(-4.45,5.90,-4.25),"description":"A imagem perde contraste por um instante e revela uma silhueta parada atrás das caixas.","discovery_message":"Imagem espectral capturada. A silhueta não aparece no reflexo da janela.","required":true},
				{"id":"az_optional","name":"Rastro no corredor","category":"field","floor":"Térreo · corredor central","position":Vector3(-0.80,0.15,2.0),"description":"Um rastro secundário, fraco e intermitente.","discovery_message":"Rastro secundário registrado como pista complementar.","required":false}
			]
		},
		{
			"id": "case_02", "title": "O quarto que ninguém usa", "family": "Família Nogueira", "area": "Residência Nogueira · Rua do Cedro", "reward_base": 220,
			"brief": "Uma criança insiste que há alguém atrás da porta do antigo quarto de hóspedes. Os adultos ouvem passos no andar de cima quando todos estão reunidos na sala.",
			"news": "Boletim da vizinhança: uma antiga casa da Rua do Cedro voltou a ser ocupada; moradores ouvem passos no andar superior antes do amanhecer.",
			"family_message": "Meu pai morou nessa casa por décadas. Depois que ele se foi, o quarto ficou fechado. Não acho que seja ele, mas a casa não parece vazia.",
			"resolved_text": "A leitura térmica, o pulso de campo e os registros de áudio e imagem formaram um padrão coerente ligado ao quarto fechado. A família foi tranquilizada: nenhuma pessoa estava escondida na residência.",
			"partial_text": "O quarto continua sem uma explicação suficiente. Os registros parciais ajudam, mas não isolam a origem do fenômeno.",
			"clues": [
				{"id":"no_field","name":"Ponto cego de energia","category":"field","floor":"Térreo · área de serviço","position":Vector3(6.35,0.20,-5.55),"description":"Uma leitura de campo pulsa perto da parede compartilhada com a lavanderia.","discovery_message":"A assinatura se repete em quatro medições independentes.","required":true},
				{"id":"no_cold","name":"Ar frio no depósito","category":"cold","floor":"Porão · depósito","position":Vector3(-6.25,-2.78,0.20),"description":"O termômetro acusa uma queda localizada, sem diferença na ventilação.","discovery_message":"Queda térmica confirmada e registrada no relatório.","required":true},
				{"id":"no_voice","name":"Passos no quarto compartilhado","category":"voice","floor":"Primeiro andar · ala dos quartos","position":Vector3(-4.15,3.05,-2.10),"description":"O gravador identifica dois passos e uma respiração curta.","discovery_message":"Sequência de áudio limpa, com dois passos e uma voz sussurrada.","required":true},
				{"id":"no_visual","name":"Marca no sótão","category":"visual","floor":"Sótão · arquivo","position":Vector3(-4.45,5.90,-4.25),"description":"A câmera registra uma marca vertical no vidro embaçado.","discovery_message":"Marca capturada e comparada com o padrão de temperatura.","required":true},
				{"id":"no_optional","name":"Eco no arquivo da biblioteca","category":"voice","floor":"Térreo · biblioteca","position":Vector3(6.10,0.20,-0.75),"description":"Um eco breve se repete quando o gravador é ativado.","discovery_message":"Eco secundário adicionado como pista complementar.","required":false}
			]
		},
		{
			"id": "case_03", "title": "A janela do fundo", "family": "Família Martins", "area": "Residência Martins · Travessa das Laranjeiras", "reward_base": 240,
			"brief": "Vizinhos relatam uma pessoa parada na janela do sótão, sempre depois da meia-noite. A família diz que o cômodo está trancado e vazio.",
			"news": "Aviso comunitário: moradores viram uma figura na janela do sótão após a meia-noite; a família afirma que o cômodo está trancado e vazio.",
			"family_message": "A figura nunca olha para a rua. Ela olha para dentro da casa. Eu só quero que meus filhos consigam dormir sem medo.",
			"resolved_text": "O registro visual coincide com uma onda de temperatura e a mesma sequência de voz no gravador. A família recebeu cópias do laudo e um plano de segurança doméstica.",
			"partial_text": "A visita encontrou sinais reais, mas não foi possível confirmar se a figura observada é a origem ou um efeito secundário.",
			"clues": [
				{"id":"ma_field","name":"Traço no closet","category":"field","floor":"Primeiro andar · closet","position":Vector3(-6.20,3.05,0.55),"description":"O medidor reage por poucos segundos diante da parede externa.","discovery_message":"Traço de energia localizado e documentado.","required":true},
				{"id":"ma_cold","name":"Frio no porão","category":"cold","floor":"Porão · oficina","position":Vector3(2.45,-2.78,-5.70),"description":"Uma ilha fria persiste mesmo depois de duas leituras.","discovery_message":"Frio anômalo confirmado: a diferença se mantém sem variação de vento.","required":true},
				{"id":"ma_voice","name":"Sussurro na biblioteca","category":"voice","floor":"Térreo · biblioteca","position":Vector3(6.10,0.20,-0.75),"description":"O gravador capta um sussurro voltado para a janela dos fundos.","discovery_message":"Voz registrada; o padrão coincide com o horário relatado pelos vizinhos.","required":true},
				{"id":"ma_visual","name":"Reflexo no sótão","category":"visual","floor":"Sótão · depósito","position":Vector3(-5.15,5.90,4.10),"description":"A câmera revela um reflexo que não acompanha o movimento do jogador.","discovery_message":"Reflexo anômalo capturado. Nenhuma pessoa estava atrás da câmera.","required":true},
				{"id":"ma_optional","name":"Campo na lavanderia","category":"field","floor":"Térreo · área de serviço","position":Vector3(6.35,0.20,-5.55),"description":"Uma leitura fraca acompanha a parede externa.","discovery_message":"Leitura complementar adicionada ao relatório.","required":false}
			]
		}
	]

func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_linear(bus, master_volume)

func _load_profile() -> void:
	var config := ConfigFile.new()
	if config.load(PROFILE_PATH) != OK:
		return
	credits = int(config.get_value("profile", "credits", credits))
	cases_completed = int(config.get_value("profile", "cases_completed", cases_completed))
	total_evidence = int(config.get_value("profile", "total_evidence", total_evidence))
	mouse_sensitivity = clampf(float(config.get_value("settings", "mouse_sensitivity", mouse_sensitivity)), 0.0007, 0.0045)
	master_volume = clampf(float(config.get_value("settings", "master_volume", master_volume)), 0.0, 1.0)
	var saved_owned: Variant = config.get_value("profile", "owned_equipment", owned_equipment)
	var saved_equipped: Variant = config.get_value("profile", "equipped_equipment", equipped_equipment)
	if saved_owned is Array:
		owned_equipment.clear()
		for item in saved_owned:
			if TOOL_CATALOG.has(str(item)) and not owned_equipment.has(str(item)):
				owned_equipment.append(str(item))
	if not owned_equipment.has("lantern"):
		owned_equipment.push_front("lantern")
	if saved_equipped is Array:
		equipped_equipment.clear()
		for item in saved_equipped:
			if owned_equipment.has(str(item)) and not equipped_equipment.has(str(item)) and equipped_equipment.size() < EQUIPMENT_CAPACITY:
				equipped_equipment.append(str(item))
	if not equipped_equipment.has("lantern"):
		equipped_equipment.push_front("lantern")
	active_equipment = str(config.get_value("profile", "active_equipment", _first_active_equipment()))
	if not equipped_equipment.has(active_equipment):
		active_equipment = _first_active_equipment()

func _save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "credits", credits)
	config.set_value("profile", "cases_completed", cases_completed)
	config.set_value("profile", "total_evidence", total_evidence)
	config.set_value("profile", "owned_equipment", owned_equipment)
	config.set_value("profile", "equipped_equipment", equipped_equipment)
	config.set_value("profile", "active_equipment", active_equipment)
	config.set_value("settings", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("settings", "master_volume", master_volume)
	config.save(PROFILE_PATH)
