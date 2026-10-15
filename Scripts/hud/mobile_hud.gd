extends Control

var elemento_selecionado: Node = null
var arrastando: bool = false
var offset: Vector2 = Vector2.ZERO
var joy = find_child("Virtual Joystick", true, false)
var modo_edicao: bool = false # Ative isso pelo seu menu de pausa para editar!
# Lista com o nome exato dos nós que NÃO podem ser movidos/arrastados
@export var botoes_travados: Array[String] = ["SliderTamanho", "SliderOpacidade", "voltarbut", "Resetbut", "savebut", "dt", "umfundo"]
@onready var slider_tamanho = $SliderTamanho
@onready var slider_opacidade = $SliderOpacidade
var dados_originais : Dictionary = {}


func _ready() -> void:
	# Salva os dados iniciais de todos os botões antes de o jogador mexer
	for no in get_children():
		if no is Control or no is Node2D: # Pega botões UI e TouchScreen
			dados_originais[no.name] = {
				"pos": no.position,
				"esc": no.scale
			}
			# Se for um botão de UI normal, salva o 'size' dele também por garantia
			if no is Control:
				dados_originais[no.name]["tam"] = no.size
	# Configurações do Slider de Tamanho (De 50% até 200%)
	slider_tamanho.min_value = 0.5
	slider_tamanho.max_value = 2.0
	slider_tamanho.step = 0.05
	
	# Configurações do Slider de Opacidade (De 10% até 100%)
	slider_opacidade.min_value = 0.1
	slider_opacidade.max_value = 1.0
	slider_opacidade.step = 0.05
	
	# Esconde os sliders no início do jogo
	slider_tamanho.visible = false
	slider_opacidade.visible = false

	# O "umfundo" (fundinho preto atrás do editor de HUD) já vem VISÍVEL no .tscn e
	# só era escondido dentro de _input() — ou seja, a tela ficava ~29% mais escura
	# até o primeiro evento de input. Sincroniza com o modo atual já de cara.
	$umfundo.visible = modo_edicao

	# Conecta os sliders para alterarem as propriedades em tempo real
	slider_tamanho.value_changed.connect(_on_slider_tamanho_changed)
	slider_opacidade.value_changed.connect(_on_slider_opacidade_changed)
	
	# Carrega as configurações guardadas no Keys.json
	carregar_layout_do_hud()

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("M_back") and modo_edicao:
		# 1. Desativa as variáveis de edição normais
		modo_edicao = false
		gvar.stopfix = false
		
		# 2. 🎨 RESET DE CORES RGB PRESERVANDO A OPACIDADE:
		for no in get_children():
			if no is Control or no is TouchScreenButton:
				# Reseta o tom de cor (RGB) para branco para tirar o azul do destaque, 
				# mas segura o Alpha (.a) original do próprio botão!
				no.modulate.r = 1.0
				no.modulate.g = 1.0
				no.modulate.b = 1.0
				no.self_modulate = Color.WHITE
				
				if "cor_padrao" in no:
					no.modulate = no.cor_padrao
			
			# Limpa os sub-filhos se houver containers, mantendo a opacidade deles
			for sub_no in no.get_children():
				if sub_no is Control or sub_no is TouchScreenButton:
					sub_no.modulate.r = 1.0
					sub_no.modulate.g = 1.0
					sub_no.modulate.b = 1.0
					sub_no.self_modulate = Color.WHITE
					
					if "cor_padrao" in sub_no:
						sub_no.modulate = sub_no.cor_padrao
		# 3. Garante que salva o arquivo atualizado antes de fechar de vez
		salvar_layout_do_hud()
		# 4. Dá o reset clássico no joystick por garantia
		var joy = find_child("Virtual Joystick", true, false)
		if joy:
			if "_tip" in joy and "_default_color" in joy:
				joy._tip.modulate = joy._default_color
			joy._reset()
			
		gvar.controls = true
		await get_tree().create_timer(0.02).timeout
		$"..".visible = false
		gvar.controls = false
# Procura o teu joystick de forma segura na árvore

# Procura o teu joystick na árvore de nós
	# Procura o "Buttons" da fase subindo na árvore: funciona em qualquer
	# profundidade e não quebra quando o Pausemenu roda isolado (F6, sem fase)
	var buttons = null
	var pai: Node = get_parent()
	for i in 6:
		if pai == null: break
		var possivel = pai.get_node_or_null("Buttons")
		if possivel != null:
			buttons = possivel
			break
		pai = pai.get_parent()

	if modo_edicao:
		$umfundo.visible = true
		if buttons: buttons.visible = false
		$voltarbut.visible = true
		$Resetbut.visible = true
		$savebut.visible = true
		$dt.visible = true
		gvar.stopfix = true
		# 🛑 FORÇA DIRETAMENTE O VALOR NUMÉRICO 0 (que significa FIXED)
	else:
		$umfundo.visible = false
		if buttons: buttons.visible = true
		gvar.stopfix = false
		# Só solta o foco de controles comuns. Mantém o foco em:
		#  • campos de texto (o nome do perfil em "Salvar Config") — senão o foco
		#    morre no mesmo evento em que foi dado e não dá pra digitar nada;
		#  • botões — o BaseButton limpa a intenção de clique (press_attempt) no
		#    NOTIFICATION_FOCUS_EXIT. Soltar o foco entre "pressionar" e "soltar"
		#    matava o clique: Salvar Config e Excluir Config nunca disparavam.
		var foco = get_viewport().gui_get_focus_owner()
		if foco != null and not (foco is LineEdit or foco is TextEdit or foco is BaseButton):
			foco.release_focus()
		$SliderTamanho.visible = false
		$SliderOpacidade.visible = false
		$voltarbut.visible = false
		$Resetbut.visible = false
		$savebut.visible = false
		$dt.visible = false
		# 🛑 FORÇA DIRETAMENTE O VALOR NUMÉRICO 1 (que significa DYNAMIC)
	if not modo_edicao: return
	
	# Funciona tanto para o clique do mouse (PC) quanto para o toque (Celular)
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var pressionado = event.pressed if event is InputEventMouseButton else event.is_pressed()
		
		if pressionado:
			# Passa pelos elementos de trás para frente para selecionar quem está no topo
			var filhos = get_children()
			filhos.reverse()
			for filho in filhos:
				if filho.name in botoes_travados:
					continue # Isso faz o código ignorar o botão atual e ir para o próximo
				# Ignora os próprios sliders de configuração
				if filho == slider_tamanho or filho == slider_opacidade: 
					continue
					
				var rect = obter_rect_do_elemento(filho)
				if rect.has_point(get_local_mouse_position()):
					elemento_selecionado = filho
					arrastando = true
					offset = filho.position - get_local_mouse_position()
					
					destacar_elemento_selecionado()
					break
		else:
			if arrastando:
				arrastando = false
				 # Salva no JSON assim que soltar o dedo!

	# Gerencia o movimento de arrastar o botão pela tela
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and arrastando and elemento_selecionado:
		elemento_selecionado.position = get_local_mouse_position() + offset

# Função inteligente para descobrir o tamanho/área tanto de Control quanto de TouchScreenButton
func obter_rect_do_elemento(elemento: Node) -> Rect2:
	if elemento is Control:
		return elemento.get_rect()
	elif elemento is TouchScreenButton and elemento.texture_normal:
		var tamanho = elemento.texture_normal.get_size() * elemento.scale
		return Rect2(elemento.position, tamanho)
	return Rect2()

func destacar_elemento_selecionado():
	# Reseta a cor (RGB) dos outros elementos mantendo suas opacidades individuais intactas
	for filho in get_children():
		if filho != slider_tamanho and filho != slider_opacidade:
			filho.modulate.r = 1.0
			filho.modulate.g = 1.0
			filho.modulate.b = 1.0
			
	if elemento_selecionado:
		# Dá um destaque azulado/ciano no botão selecionado no menu de edição
		elemento_selecionado.modulate.r = 0.4
		elemento_selecionado.modulate.g = 0.8
		elemento_selecionado.modulate.b = 1.0
		
		# Atualiza os Sliders com as informações atuais desse botão específico
		slider_tamanho.value = elemento_selecionado.scale.x
		slider_opacidade.value = elemento_selecionado.modulate.a
		
		slider_tamanho.visible = true
		slider_opacidade.visible = true

func _on_slider_tamanho_changed(novo_valor: float):
	if elemento_selecionado:
		elemento_selecionado.scale = Vector2(novo_valor, novo_valor)
		salvar_layout_do_hud()

func _on_slider_opacidade_changed(novo_valor: float):
	if elemento_selecionado:
		# Modifica apenas o canal Alpha (a) que dita a transparência/opacidade
		elemento_selecionado.modulate.a = novo_valor
		salvar_layout_do_hud()

# --- SALVAMENTO E CARREGAMENTO NO ARQUIVO ÚNICO (Keys.json) ---

# --- SALVAMENTO E CARREGAMENTO DENTRO DA "PASTA" KEYS DO GLOBAL ---

func salvar_layout_do_hud():
	var dicionario_hud = {}
	
	for filho in self.get_children():
		if filho.name in botoes_travados or filho == slider_tamanho or filho == slider_opacidade or filho.name == "CheckBox": 
			continue
			
		dicionario_hud[filho.name] = {
			"x": filho.position.x,
			"y": filho.position.y,
			"scale": filho.scale.x,
			"alpha": filho.modulate.a
		}
	
	var caminho = gvar.get_save_path()
	var dados_totais = {}
	
	if FileAccess.file_exists(caminho):
		var file = FileAccess.open(caminho, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		var parsed = JSON.parse_string(content)
		if parsed is Dictionary:
			dados_totais = parsed

	# 💾 Salva o layout E também o estado da CheckBox
# ... resto do código de salvamento anterior ...

	# 💾 Salva o layout E o estado exato da sua caixinha CheckBox
	dados_totais["hud_layout"] = dicionario_hud
	dados_totais["touch_desativado"] = $dt.button_pressed # Guardamos se ele está desativado
	
	var file_write = FileAccess.open(caminho, FileAccess.WRITE)
	if file_write:
		file_write.store_string(JSON.stringify(dados_totais, "\t"))
		file_write.close()
		print("HUD e preferência de Touch salvos no Keys.json!")
func carregar_layout_do_hud():
	var caminho = gvar.get_save_path()
	
	if not FileAccess.file_exists(caminho):
		# Se não existir arquivo, assume que o touch começa ATIVADO (Desativar = false)
		$dt.button_pressed = false
		return 
		
	var file = FileAccess.open(caminho, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var dados_totais = JSON.parse_string(content)
	if not dados_totais is Dictionary: return
	
	# 📂 1. Carrega o estado da caixinha (se não achar, o padrão é o touch ativo/caixa desmarcada)
	var touch_desativado = dados_totais.get("touch_desativado", false)
	$dt.button_pressed = touch_desativado
	var toque_ativo = not touch_desativado
	
	# 📐 2. Aplica as posições, escalas e opacidades normais dos botões
	if dados_totais.has("hud_layout"):
		var dados_hud = dados_totais["hud_layout"]
		
		for filho in self.get_children():
			# Aplica as transformações visuais primeiro
			if dados_hud.has(filho.name):
				var configs = dados_hud[filho.name]
				filho.position = Vector2(configs["x"], configs["y"])
				filho.scale = Vector2(configs["scale"], configs["scale"])
				filho.modulate.a = configs["alpha"]
			
			# Depois aplica a visibilidade correta com base na preferência carregada
			if filho is Control or filho is TouchScreenButton:
				if not filho.name in botoes_travados and filho != slider_tamanho and filho != slider_opacidade and filho.name != "CheckBox":
					filho.visible = toque_ativo

	# 🕹️ 3. 🎯 BLOQUEIO DO JOYSTICK NO LOAD (Agora usando o Nome Único de Cena)
	var joystick = %"Virtual Joystick"
	
	if joystick:
		joystick.visible = toque_ativo
		joystick.set_process(toque_ativo)
		joystick.set_process_input(toque_ativo)
		joystick.set_physics_process(toque_ativo)
		
		# Se o toque não estiver ativo, força o reset visual dele por garantia
		if not toque_ativo and joystick.has_method("_reset"):
			joystick._reset()
					
	print("HUD e estado do Touch carregados com sucesso!")
	# Tradução: os rótulos desse HUD (Tamanho/Opacidade/VOLTAR...) vêm da cena
	Tradutor.aplicar(self)
func _on_savebut_pressed() -> void:
	salvar_layout_do_hud()


func _on_resetbut_pressed() -> void:
	
	# 1. Pega o caminho do arquivo Keys.json usando seu gvar
	var caminho = gvar.get_save_path()
	
	if FileAccess.file_exists(caminho):
		# Abre o arquivo atual para ler as configurações de teclas
		var file = FileAccess.open(caminho, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		var dados = JSON.parse_string(content)
		if dados is Dictionary:
			# 🛑 DELETA apenas a parte do HUD. As teclas configuradas continuam salvas!
			dados.erase("hud_layout")
			
			# Salva o arquivo de volta sem os dados do HUD
			var file_write = FileAccess.open(caminho, FileAccess.WRITE)
			if file_write:
				file_write.store_string(JSON.stringify(dados, "\t"))
				file_write.close()
	
	# 1. Devolve a posição, escala e tamanho de fábrica para cada botão
	for no in get_children():
		if no.name in dados_originais:
			var fabrica = dados_originais[no.name]
			
			no.position = fabrica["pos"]
			no.scale = fabrica["esc"]
			
			# Se o nó tiver o tamanho salvo, restaura ele também
			if no is Control and "tam" in fabrica:
				no.size = fabrica["tam"]
				
	# 2. Mantém aquela limpeza do modulate que funcionou antes!
	for no in get_children():
		if no is Control or no is TouchScreenButton:
			no.modulate = Color.WHITE
			no.self_modulate = Color.WHITE
			if "cor_padrao" in no:
				no.modulate = no.cor_padrao
	
	print("Configurações do HUD resetadas para o padrão!")


func _on_voltarbut_pressed() -> void:
	# 1. Desativa as variáveis de edição normais
	modo_edicao = false
	gvar.stopfix = false
	
	# 2. 🎨 RESET DE CORES RGB PRESERVANDO A OPACIDADE:
	for no in get_children():
		if no is Control or no is TouchScreenButton:
			# Reseta o tom de cor (RGB) para branco para tirar o azul do destaque, 
			# mas segura o Alpha (.a) original do próprio botão!
			no.modulate.r = 1.0
			no.modulate.g = 1.0
			no.modulate.b = 1.0
			no.self_modulate = Color.WHITE
			
			if "cor_padrao" in no:
				no.modulate = no.cor_padrao
		
		# Limpa os sub-filhos se houver containers, mantendo a opacidade deles
		for sub_no in no.get_children():
			if sub_no is Control or sub_no is TouchScreenButton:
				sub_no.modulate.r = 1.0
				sub_no.modulate.g = 1.0
				sub_no.modulate.b = 1.0
				sub_no.self_modulate = Color.WHITE
				
				if "cor_padrao" in sub_no:
					sub_no.modulate = sub_no.cor_padrao

	# 3. Garante que salva o arquivo atualizado antes de fechar de vez
	salvar_layout_do_hud()

	# 4. Dá o reset clássico no joystick por garantia
	var joy = find_child("Virtual Joystick", true, false)
	if joy:
		if "_tip" in joy and "_default_color" in joy:
			joy._tip.modulate = joy._default_color
		joy._reset()
		
	gvar.controls = true
	await get_tree().create_timer(0.02).timeout
	$"..".visible = false
	gvar.controls = false


func _on_check_box_pressed() -> void:
	# 🚨 INVERSÃO DA LÓGICA: Se "Desativar Touch" está checado (true), 
	# então o toque_ativo deve ser falso (false)!
	var toque_ativo = not $dt.button_pressed
	
	# 1. Esconde ou mostra os botões normais do HUD
	for filho in get_children():
		if filho.name in botoes_travados or filho == slider_tamanho or filho == slider_opacidade or filho.name == "CheckBox":
			continue
		
		if filho is Control or filho is TouchScreenButton:
			filho.visible = toque_ativo
			
	# 2. 🛑 BLOQUEIO DO JOYSTICK VIRTUAL (Agora 100% seguro com Nome Único):
	# Coloque entre aspas exatamente o nome que está na árvore com o %
	var joystick = %"Virtual Joystick" 
	
	if joystick:
		joystick.visible = toque_ativo
		
		# Desativa/Ativa os scripts e inputs do próprio joystick
		joystick.set_process(toque_ativo)
		joystick.set_process_input(toque_ativo)
		joystick.set_physics_process(toque_ativo)
		
		if not toque_ativo and joystick.has_method("_reset"):
			joystick._reset()

	# 3. Salva a preferência no arquivo
	salvar_layout_do_hud()
