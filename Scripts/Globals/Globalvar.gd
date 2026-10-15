extends Node

var dir = 0
const FOLDER_NAME = "keys"
const FILE_NAME = "Keys.json"
# Ações que um perfil salva/carrega (as teclas do jogo)
const ACOES_CONFIG = ["right", "left", "up", "down", "jump", "shoot", "B move", "aim", "dash", "arm"]
signal knockout
signal bravo
signal victory
signal bossexplode
signal abr
signal fch
var pause = false
var desatshots = false
var stopfix = false
var controls = false
var canpause = true
var stopall = false
var entrada_sel: int = -1 # Último dispositivo escolhido no dropdown (-1 = Teclado)
var perfil_atual: String = "" # Último perfil escolhido no menu (arquivo dentro de keys/)
func _ready():
	load_keys()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("M_start"):
		get_tree().paused = true
		pause = true
func get_save_path():
	var base_path = ""
	if OS.has_feature("editor"):
		base_path = "res://"
	else:
		base_path = OS.get_executable_path().get_base_dir() + "/"

	var root_folder = base_path + FOLDER_NAME + "/"
	if not DirAccess.dir_exists_absolute(root_folder):
		DirAccess.make_dir_absolute(root_folder)
		
	return root_folder + FILE_NAME

func update_single_key(action: String, val: int, coluna: int = 0):
	var path = get_save_path()
	var data = {}

	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		var parsed = JSON.parse_string(content)
		if parsed is Dictionary:
			data = parsed

	# coluna: 0 = automática (500+ = controle, 31-499 = tecla, 0 = legado "limpa tudo")
	#         1 = teclado, 2 = controle
	var col = coluna
	if col == 0:
		if val >= 500:
			col = 2
		elif val > 30:
			col = 1

	if col == 0:
		# Formato legado: um valor por ação (usado só para val 0 sem coluna definida)
		data[action] = val
	else:
		# Formato novo: {"k": teclado, "c": controle} — as duas colunas convivem no save
		var novo: Dictionary = {}
		var atual = data.get(action)
		if atual is Dictionary:
			novo = atual.duplicate()
		elif atual is int or atual is float:
			# Converte o formato antigo (1 valor) para o de 2 colunas
			var av = int(atual)
			if av == 0:
				novo = {"k": 0, "c": 0}
			elif av >= 500:
				novo = {"c": av}
			elif av > 30:
				novo = {"k": av}
		if col == 1:
			novo["k"] = val
		else:
			novo["c"] = val
		data[action] = novo

	var file_write = FileAccess.open(path, FileAccess.WRITE)
	if file_write:
		file_write.store_string(JSON.stringify(data, "\t"))
		file_write.close()

func load_keys():
	var path = get_save_path()
	if not FileAccess.file_exists(path): return

	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data is Dictionary:
		if data.has("entrada_sel"):
			entrada_sel = int(data["entrada_sel"]) # restaura o dropdown (só exibe, não reaplica)
		var pa = data.get("perfil_atual", "")
		perfil_atual = str(pa) if pa != null else "" # restaura o perfil escolhido
		for action in data.keys():
			# 🛑 CORREÇÃO AQUI: Pula o HUD, não tente carregar ele como tecla!
# Altere a linha 67 para ignorar tanto o hud_layout quanto o touch_screen_enabled
			if action == "hud_layout" or action == "touch_screen_enabled":
				continue
			var val = data[action]
# 🚨 TRAVA DE SEGURANÇA: Ignora os dados do HUD e do Touch para não quebrar o rebind de teclas!
			if action == "touch_desativado" or action == "hud_layout":
				continue
			if not InputMap.has_action(action): continue
			if val is Dictionary:
				# Novo formato: {"k": teclado, "c": controle} — aplica cada coluna sem mexer na outra
				if val.has("k"): _aplicar_val_coluna(action, val["k"], 1)
				if val.has("c"): _aplicar_val_coluna(action, val["c"], 2)
			elif val == 0:
				# Formato antigo: 0 = limpava a ação inteira
				InputMap.action_erase_events(action)
			else:
				# Formato antigo (1 valor por ação): deduz a coluna pelo valor salvo
				_aplicar_val_coluna(action, val, 0)
		get_tree().call_group("rebind_buttons", "update_button_text")

# Aplica um valor salvo no InputMap apagando SÓ os eventos da coluna indicada.
# coluna: 0 = deduzir pelo valor, 1 = teclado, 2 = controle. val 0 = só limpa a coluna.
func _aplicar_val_coluna(action: String, val, coluna: int) -> void:
	var col = coluna
	var v = int(val)
	if col == 0:
		# Teclas especiais (setas/Shift = 4194304+) são teclado, NÃO analógico
		if v >= 500 and v < 4194305:
			col = 2 # analógico (1000/2000+eixo) ou botão (500+índice)
		elif v > 30:
			col = 1 # teclado (letras 31-499 ou especiais 4194304+)

	# Apaga somente os eventos da coluna alvo (a outra coluna fica intacta)
	var para_apagar: Array = []
	for e in InputMap.action_get_events(action):
		if col == 1 and e is InputEventKey:
			para_apagar.append(e)
		elif col == 2 and (e is InputEventJoypadButton or e is InputEventJoypadMotion):
			para_apagar.append(e)
		elif col == 0:
			para_apagar.append(e)
	for e in para_apagar:
		InputMap.action_erase_event(action, e)

	if v <= 30: return # 0 = limpeza da coluna; abaixo de 31 não é valor válido

	if col == 1:
		# 1. TECLADO — inclui teclas especiais (setas, Shift, etc. valem 4194304+)
		var new_key = InputEventKey.new()
		new_key.physical_keycode = v
		new_key.keycode = v
		InputMap.action_add_event(action, new_key)
	elif v >= 1000 and v <= 2999:
		# 2. ANALÓGICO (1000+eixo positivo, 2000+eixo negativo)
		var new_joy = InputEventJoypadMotion.new()
		if v < 2000:
			new_joy.axis = v - 1000
			new_joy.axis_value = 1.0
		else:
			new_joy.axis = v - 2000
			new_joy.axis_value = -1.0
		InputMap.action_add_event(action, new_joy)
	elif v >= 500:
		# 3. BOTÃO DE CONTROLE (500 até 999)
		var new_btn = InputEventJoypadButton.new()
		new_btn.button_index = v - 500 # Subtrai os 500 para voltar ao ID real (0, 1, 2...)
		InputMap.action_add_event(action, new_btn)

# Compara 2 eventos: mesma tecla, mesmo botão ou mesmo eixo/direção do analógico
func eventos_iguais(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var ka = a.physical_keycode if a.physical_keycode != 0 else a.keycode
		var kb = b.physical_keycode if b.physical_keycode != 0 else b.keycode
		return ka != 0 and ka == kb
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and ((a.axis_value > 0) == (b.axis_value > 0))
	return false

# Salva qual dispositivo o jogador escolheu no dropdown (só registro; só reaplica quando ele escolher)
func salvar_entrada_sel(id: int) -> void:
	entrada_sel = id
	var path = get_save_path()
	var data = {}
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(content)
		if parsed is Dictionary:
			data = parsed
	data["entrada_sel"] = id
	var file_write = FileAccess.open(path, FileAccess.WRITE)
	if file_write:
		file_write.store_string(JSON.stringify(data, "\t"))
		file_write.close()

# ── Perfis de configuração (arquivos .json dentro da pasta keys/) ───────────
# O Keys.json guarda as teclas ATIVAS. Cada perfil é uma cópia salva com nome
# ("abobrinha123.json") e o Salvar/Carregar do menu servem pra trocar de cópia.

func pasta_perfis() -> String:
	var p = get_save_path().get_base_dir()
	if not DirAccess.dir_exists_absolute(p):
		DirAccess.make_dir_absolute(p)
	return p

func caminho_perfil(nome: String) -> String:
	return pasta_perfis() + "/" + nome + ".json"

# Só os arquivos de perfil (o Keys.json é a config ativa, não é perfil)
func listar_perfis() -> Array:
	var nomes: Array = []
	var dir = DirAccess.open(pasta_perfis())
	if dir == null:
		return nomes
	for f in dir.get_files():
		if f.get_extension().to_lower() != "json": continue
		if f.get_basename().to_lower() == "keys": continue
		nomes.append(f.get_basename())
	nomes.sort()
	return nomes

func _ler_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func _gravar_json(path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

# Evento do InputMap → valor usado pelo JSON (mesma regra do rebind)
func evento_pra_val(ev: InputEvent) -> int:
	if ev is InputEventKey:
		return ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
	elif ev is InputEventJoypadButton:
		return ev.button_index + 500
	elif ev is InputEventJoypadMotion:
		return (1000 + ev.axis) if ev.axis_value > 0 else (2000 + ev.axis)
	return 0

# Conteúdo do perfil = as teclas que estão valendo AGORA (2 colunas) + entrada
func montar_dados_teclas() -> Dictionary:
	var dados: Dictionary = {}
	for a in ACOES_CONFIG:
		if not InputMap.has_action(a): continue
		var k = 0
		var c = 0
		for e in InputMap.action_get_events(a):
			if e is InputEventKey:
				if k == 0: k = evento_pra_val(e)
			else:
				if c == 0: c = evento_pra_val(e)
		dados[a] = {"k": k, "c": c}
	dados["entrada_sel"] = entrada_sel
	return dados

# Grava o perfil e deixa ele como o "escolhido" (ele volta marcado no próximo jogo)
func salvar_perfil(nome: String) -> bool:
	if nome.strip_edges() == "": return false
	if not _gravar_json(caminho_perfil(nome), montar_dados_teclas()): return false
	perfil_atual = nome
	var path = get_save_path()
	var data = _ler_json(path)
	data["perfil_atual"] = nome
	_gravar_json(path, data)
	return true

# Lê o perfil e joga ele por cima do Keys.json (mantendo HUD/toque) e reaplica
func aplicar_perfil(nome: String) -> bool:
	if nome.strip_edges() == "": return false
	var dados = _ler_json(caminho_perfil(nome))
	if dados.is_empty(): return false
	var path = get_save_path()
	var atual = _ler_json(path)
	for k in dados.keys():
		atual[k] = dados[k]
	atual["perfil_atual"] = nome
	if not _gravar_json(path, atual): return false
	perfil_atual = nome
	load_keys()
	return true

# Apaga o arquivo do perfil (devolve false se não existir / não der pra apagar)
func excluir_perfil(nome: String) -> bool:
	if nome.strip_edges() == "": return false
	var dir = DirAccess.open(pasta_perfis())
	if dir == null: return false
	if not dir.file_exists(nome + ".json"): return false
	return dir.remove(nome + ".json") == OK

# Deixou de ter perfil escolhido (apagou o que estava marcado)
func limpar_perfil_atual() -> void:
	perfil_atual = ""
	var path = get_save_path()
	var data = _ler_json(path)
	data["perfil_atual"] = ""
	_gravar_json(path, data)
