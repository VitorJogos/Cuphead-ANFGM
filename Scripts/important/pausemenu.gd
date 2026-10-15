extends CanvasLayer

var numeroordem: int = 0
var options = false
var audio = false
var controls = false
var controllado = 0 # 0 = menu esquerdo, 1 = teclado (coluna 1), 2 = controle (coluna 2)
var language = false
var mods = false
var menulimit = 4
var irprobaixo = 0
var ondevoltar = 1
var menunorm = true
var stopthis = false
var action = 0
var esta_mudando_de_tela = false
# TENTAR DE NOVO em andamento (iris fechando): congela o menu até a fase recomeçar
var reiniciando = false

# Referências seguras
var winput = null
var wname: String = ""
@export var order = 3

var is_rebinding: bool = false
var entrada_sig: String = "" # Assinatura da lista de dispositivos (evita remontar a lista a toa)
# Rebind em grupo das linhas "Movimento horizontal/vertical" (sequência de 2 direções)
var grupo_fila: Array = []
var valor_etapa_anterior: int = -999999
var eixo_neutro_ok: bool = true
var fechando_rebind: bool = false

# ── Coluna visível na tabela: só teclado OU só controle (conforme o dropdown) ─
var coluna_visivel: int = 1 # 1 = só teclado, 2 = só controle (padrão: teclado)

# ── Prompt de nome do perfil (botão "Salvar Config") ────────────────────────
var prompt_aberto: bool = false
var _prompt_perfil: Control = null
var _linha_perfil: LineEdit = null
var _rotulo_prompt: Label = null
var _aviso_label: Label = null
var _aviso_token: int = 0
# Dropdown (dispositivo/perfil) aberto: as setas/Enter são do popup, não do menu
var _dropdown_saiu: bool = false
# "Excluir Config": 1º clique pede confirmação, o 2º (em até 3s) apaga
var _excluir_confirma: String = ""
var _excluir_hora: float = -99.0

# ── Telas de Áudio, Visual e Idioma (barras, no estilo do Cuphead) ───────────
# Cada linha do submenu Options abre a SUA PRÓPRIA TELA, como no Cuphead:
# rótulo à DIREITA terminando em ":", o controle "-----|------" logo depois e
# "VOLTAR" centralizado embaixo (mesma palavra do original).
#   Áudio   -> frame 1 (o cartão GRANDE 581x571, o mesmo do print original)
#   Visual  -> frame 1 (o mesmo cartão grande)
#   Idioma  -> frame 0 (o cartão normal 514x299)
# Linhas do Áudio igual ao original: VOLUME PRINCIPAL (Master) / EFEITOS
# SONOROS (SFX) / MÚSICA (Musica). O antigo "VOZES" não tinha bus e na prática
# já mexia no Master — virou VOLUME PRINCIPAL e herda o valor salvo.
# Tudo criado por código — o Pausemenu.tscn não é editado.
var _tela_atual: String = "" # "" = fechada, "audio", "visual" ou "idioma"
var audio_linha: int = 0 # linha selecionada da tela aberta (a última = VOLTAR)
# Idioma que a tela de Idioma está MOSTRANDO (cicla com <- -> e já vale na
# hora). Começa no que está valendo quando a tela abre.
var _idioma_indice: int = 0
var _telas: Dictionary = {} # nome -> {"no","rotulos","barras","reset","chaves",...}
var _valores: Dictionary = {} # chave -> float OU índice (volume_master, resolucao...)
var _brilho: ColorRect = null
# Camada fixa de brilho: fica FORA da visibilidade do menu, então vale também
# durante a partida (se fosse filho do menu, sumiria no Resume)
var _camada_fx: CanvasLayer = null
# Últimos valores que passaram pelo _aplicar_ajustes — servem pra emitir os
# sinais só quando o valor realmente muda.
var _tela_inicial_ind: int = -1
var _cor_desfoc_val: float = -1.0
# Lista das resoluções oferecidas. É VAR (e não const) porque a resolução que
# o jogador já estiver usando entra na lista quando não há escolha salva —
# assim o índice guardado no Keys.json nunca aponta pra um tamanho errado.
# Vai até 640x480, o mesmo piso do Cuphead.
var _resolucoes: Array[String] = ["640x480", "800x600", "1024x768", "1152x648",
		"1280x720", "1600x900", "1920x1080", "2560x1440"]

# TELA INICIAL e COR DESFOC. são os dois ajustes sem função definida aqui: o
# jogo conecta nesses sinais e decide o que fazer com o valor escolhido.
signal tela_inicial_mudou(indice: int)
signal cor_desfoc_mudou(valor: float)

const TELA_AUDIO := "audio"
const TELA_VISUAL := "visual"
const TELA_IDIOMA := "idioma"
const AUDIO_ROTULOS := ["VOLUME PRINCIPAL:", "EFEITOS SONOROS:", "MÚSICA:"]
const AUDIO_BUSES := ["Master", "SFX", "Musica"]
const AUDIO_CHAVES := ["volume_master", "volume_sfx", "volume_musica"]
# Tela VISUAL do original: 7 linhas. RESOLUÇÃO/TELA/VSYNC/TELA INICIAL têm
# valor em texto (ciclam com <- ->), OVERSCAN/BRILHO/COR DESFOC. têm barra.
const VISUAL_ROTULOS := ["RESOLUÇÃO:", "TELA:", "VSYNC:", "OVERSCAN:",
		"BRILHO:", "COR DESFOC.:", "TELA INICIAL:"]
const VISUAL_CHAVES := ["resolucao", "tela_modo", "vsync", "overscan",
		"brilho", "cor_desfoc", "tela_inicial"]
const VISUAL_TIPOS := ["escolha", "escolha", "escolha", "barra",
		"barra", "barra", "escolha"]
# Texto de cada linha de "escolha" (a resolução fica em _resolucoes)
const VISUAL_OPCOES := {
	"tela_modo": ["TELA CHEIA", "JANELA"],
	"vsync": ["ATIVADO", "DESATIVADO"],
	"tela_inicial": ["DLC", "ORIGINAL"],
}
# Valor inicial de cada ajuste quando nada está salvo. O padrão das barras é
# 1.0 (volume no máximo), mas BRILHO, OVERSCAN e COR DESFOC. começam onde o
# print do original mostra: BRILHO e COR DESFOC. no CENTRO (neutro) e
# OVERSCAN no ZERO (desligado).
const PADROES_AJUSTES := {
	"brilho": 0.5,
	"overscan": 0.0,
	"cor_desfoc": 0.5,
}
const IDIOMA_ROTULOS := ["Português:", "English:"]
const IDIOMA_VALORES := ["pt", "en"]
# Nome de cada idioma como ele se escreve NO PRÓPRIO idioma (o print japonês
# mostra 日本語 e não "Japanese") — por isso não passa pelo Tradutor.
const IDIOMA_NOMES := {"pt": "PORTUGUÊS (BR)", "en": "ENGLISH"}
const VOLTAR_ROTULO := "VOLTAR"
const BARRA_PASSOS := 10 # 10 traços + o "|" = 11 posições (0.0 .. 1.0, de 0.1 em 0.1)
const SUBMENU_LINHAS := 5 # ÁUDIO, VISUAL, CONTROLES, IDIOMA, VOLTAR
# Y das linhas do frame 1. O frame 1 é o options_bg.png (592x524 centrado em
# 568,319 -> y 57..581); as porcentagens vieram do print original (linha 1 =
# 15,4% da altura do cartão, linhas 2/3 = 22,6% e 30,1%, VOLTAR = 44,9%) e o
# rótulo tem caixa de 59px, então y = centro - 29,5.
const _Y_TELA := [108.0, 146.0, 185.0, 263.0] # frame 1 (Áudio): 3 linhas + VOLTAR
# Visual: 7 linhas com o MESMO passo do Áudio (38/39px, linhas 1 a 3 idênticas)
# e o VOLTAR 2 passos depois da última — igual ao print original (74,3% da altura)
const _Y_TELA_VISUAL := [108.0, 146.0, 185.0, 223.0, 262.0, 300.0, 339.0, 417.0]
# Y das linhas da tela de Idioma (frame 0 = pause_menu.png 514x299, centrado
# em 568,319 -> x 311..825 / y 170..469). Só o NOME do idioma e o VOLTAR,
# centralizados em x568 e medidos no print "idioma PT BR.jpeg".
const _Y_IDIOMA := [243.5, 312.5] # nome do idioma + VOLTAR

func _ready() -> void:
	$Controls.visible = false
	$Control/resume.self_modulate = Color.RED
	# Move/Move2 são sons de MENU (SFX). Apontados aqui por código para não editar
	# o Pausemenu.tscn (regra do projeto). Todos os outros SFX do jogo já estão no
	# bus SFX direto nas cenas (224 players) — assim o slider EFEITOS SONOROS
	# passa a valer para tudo.
	for _nome_sfx in ["Move", "Move2"]:
		var _sfx := get_node_or_null(_nome_sfx) as AudioStreamPlayer2D
		if _sfx != null:
			_sfx.bus = "SFX"
	# Dropdown "entrada": so o clique do usuario dispara a troca (nunca o foco/teclado)
	$Controls/entrada.focus_mode = Control.FOCUS_NONE
	$Controls/entrada.item_selected.connect(_on_entrada_item_selected)
	# Linha de cima do menu (Carregar / Excluir / Salvar) = SÓ toque/clique.
	# M_down é a KEY_DOWN e o ui_down do Godot também é a mesma seta, então a
	# seta andava o cursor do menu E ainda jogava o foco do Godot em cima desses
	# controles, fazendo o Carregar/Salvar/Excluir andarem junto com a navegação.
	# FOCUS_NONE também derruba grab_focus(), então nem por engano eles focam.
	for _nome_topo in ["carregar", "salvar", "Excluir"]:
		if $Controls.has_node(_nome_topo):
			$Controls.get_node(_nome_topo).focus_mode = Control.FOCUS_NONE
	# O "# nome" só serve pra DIGITAR: FOCUS_CLICK foca no clique do mouse, mas
	# fica de fora da cadeia de foco do teclado (as setas nunca puxam ele).
	var _campo_topo = _campo_nome_perfil()
	if _campo_topo != null:
		_campo_topo.focus_mode = Control.FOCUS_CLICK
	# Hotplug: lista de dispositivos reconectada ao ligar/desligar controle
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	atualizar_lista_dispositivos()
	# Linha "Trocar Arma" veio na cena só com a coluna 1 (teclado). Clona pra
	# existir também a coluna 2 (controle) — feito por código porque o .tscn
	# está aberto no editor. Precisa existir ANTES de aplicar_coluna_visivel().
	var _trocar = $"Controls/Controlstext/Trocar Arma"
	if _trocar != null and not _trocar.has_node("2"):
		var _col2 = _trocar.get_node("1").duplicate() as Label
		if _col2 != null:
			_col2.name = "2"
			# Coluna controle começa em x=870 (a teclado fica em 628.735), mesma largura
			_col2.offset_left = 870.0
			_col2.offset_right = 1075.0
			_trocar.add_child(_col2)
	# Coluna da tabela = o que está escolhido no dropdown (padrão: teclado)
	aplicar_coluna_visivel()
	# Botões de perfil: Salvar / Carregar / Excluir
	_conectar_botoes_perfil()
	_preparar_campo_nome()
	atualizar_lista_perfis()
	# Telas de Áudio/Visual + a linha VISUAL do submenu: criadas ANTES da
	# tradução pra já saírem traduzidas
	_criar_telas_opcoes()
	# Tradução: aplica o Traduction.csv em toda a interface desta tela
	Tradutor.aplicar(self)

func _process(_delta: float) -> void:
	# TENTAR DE NOVO em andamento: o iris está fechando com o jogo pausado —
	# nenhuma tecla do menu vale até a fase recomeçar.
	if reiniciando:
		return
	if $Controls/Mobile_HUD/Control/dt.button_pressed == true:
		$up.visible = false
		$left.visible = false
		$right.visible = false
		$down.visible = false
		$ok.visible = false
		$back.visible = false
	# Prompt de perfil aberto e o menu foi fechado → fecha junto
	if prompt_aberto and not gvar.pause:
		_fechar_prompt_perfil()
	# Tela de Áudio/Visual aberta e o pause foi solto → fecha junto
	if _tela_atual != "" and not gvar.pause:
		fechar_tela()
	if gvar.pause:
		$".".visible = true
	else:
		
		return
	# Prompt de perfil aberto: congela o menu e esconde as dicas de navegação
	if prompt_aberto:
		$up.visible = false
		$left.visible = false
		$right.visible = false
		$down.visible = false
		$ok.visible = false
		$back.visible = false
		return
	# Digitando num campo de texto: setas/Enter pertencem ao campo
	if _campo_digitando():
		return
	# Dropdown aberto (dispositivo/perfil): o popup é quem recebe setas/Enter
	if _dropdown_ativo():
		return
	# Tela de Áudio/Visual aberta: ela mesma cuida das setas, do Enter e do voltar
	if _tela_atual != "":
		_processar_tela()
		return
	if gvar.controls:
		$up.visible = true
		$left.visible = true
		$right.visible = true
		$down.visible = true
		$ok.visible = true
		$back.visible = true
		controls = true
	$"Controls/changer/text3".text = str(int($Timer3.time_left))
	if stopthis:
		trocar()
	else:
		$Controls/changer.visible = false
		
	carregar_teclas_no_menu()

	if numeroordem < 1:
		if irprobaixo == 0:
			numeroordem = 1
		else:
			numeroordem = menulimit
	if numeroordem > int(menulimit):
		numeroordem = ondevoltar
		
	$Controls/keyboard.material.set_shader_parameter("selecionado", true)
	
	if controls:
		controler()
		$Controls.visible = true
		$Control/Pausemenu.frame = 0
	else:
		$Controls.visible = false
		
	if menunorm:
		$Controls/Mobile_HUD.visible = false
		$Control/Pausemenu.visible = true
		irprobaixo = 1
		menulimit = 4
		ondevoltar = 1
		menunormal()
		$Control/resume.visible = true
		$Control/retry.visible = true
		$Control/options.visible = true
		$Control/exitthemap.visible = true
		$Control/Pausemenu.frame = 0
	else:
		$Control/resume.visible = false
		$Control/retry.visible = false
		$Control/options.visible = false
		$Control/exitthemap.visible = false
		
	if options:
		$Control/Pausemenu.visible = true
		irprobaixo = 1
		menulimit = SUBMENU_LINHAS
		ondevoltar = 1
		optionss()
		$Control/back.visible = true
		$Control/controls.visible = true
		$Control/language.visible = true
		$Control/audio.visible = true
		if $Control.has_node("visual"):
			$Control/visual.visible = true
		$Control/Pausemenu.frame = 0
	else:
		$Control/back.visible = false
		$Control/controls.visible = false
		$Control/language.visible = false
		$Control/audio.visible = false
		if $Control.has_node("visual"):
			$Control/visual.visible = false
		
	if not stopthis:
		if Input.is_action_just_pressed("M_up") or Input.is_action_pressed("M_up"):
			if Input.is_action_pressed("M_up"):
				if $Timer2.is_stopped():
					$Timer2.start()
					numeroordem -= 1
					if not controls:
						if player.location == 0: $Move.play()
						if player.location == 1: $Move2.play()
			elif Input.is_action_just_pressed("M_up"):
				numeroordem -= 1
				if not controls:
					if player.location == 0: $Move.play()
					if player.location == 1: $Move2.play()
						
		if Input.is_action_just_pressed("M_down") or Input.is_action_pressed("M_down"):
			if Input.is_action_pressed("M_down"):
				if $Timer2.is_stopped():
					$Timer2.start()
					numeroordem += 1
					if not controls:
						if player.location == 0: $Move.play()
						if player.location == 1: $Move2.play()
			elif Input.is_action_just_pressed("M_down"):
				numeroordem += 1
				if not controls:
					if player.location == 0: $Move.play()
					if player.location == 1: $Move2.play()

		if controllado < 0: controllado = 0
		if controllado > 2: controllado = 2
			
	if Input.is_action_just_pressed("M_ok"):
		if not controls:
			if player.location == 0: $Move.play()
			if player.location == 1: $Move2.play()
		if $Control/resume.self_modulate == Color.RED:
			$".".visible = false
			#get_tree().reload_current_scene() isso é pra o reset
			$Control/resume.self_modulate = Color.BLACK
			menunorm = true
			numeroordem = 1
			gvar.pause = false
			get_tree().paused = false
			$Controls/Mobile_HUD.visible = true
		elif $Control/retry.visible and $Control/retry.self_modulate == Color.RED:
			# Linha TENTAR DE NOVO: como no original, o iris FECHA com tudo
			# ainda pausado e só depois a fase recomeça do zero.
			$Control/retry.self_modulate = Color.BLACK
			_reiniciar_fase()
		elif $Control/options.self_modulate == Color.RED:
			#get_tree().reload_current_scene() isso é pra o reset
			$Control/options.self_modulate = Color.BLACK
			options = true
			menunorm = false
			numeroordem = 1
		elif $Control/controls.self_modulate == Color.RED:
			$Control/controls.self_modulate = Color.BLACK
			options = false
			menunorm = false
			controls = true
			$Controls/changer/text2.visible = false
			$Controls/changer/text3.visible = false
			numeroordem = 1
			controllado = 0
		elif $Control/audio.self_modulate == Color.RED:
			# Linha "AUDIO": era linha morta, agora abre a tela só de volume
			$Control/audio.self_modulate = Color.BLACK
			abrir_tela(TELA_AUDIO)
		elif $Control.has_node("visual") and $Control/visual.self_modulate == Color.RED:
			# Linha "VISUAL": tela própria, separada do áudio (brilho)
			$Control/visual.self_modulate = Color.BLACK
			abrir_tela(TELA_VISUAL)
		elif $Control/language.self_modulate == Color.RED:
			# Linha "IDIOMA": abre a própria tela (Português / English / VOLTAR)
			$Control/language.self_modulate = Color.BLACK
			abrir_tela(TELA_IDIOMA)
		elif $Control/back.self_modulate == Color.RED:
			$Control/back.self_modulate = Color.BLACK
			if menunorm == false and options == true:
				options = false
				menunorm = true
			numeroordem = 1
		elif order == 3 and stopthis:
			stopthis = false
			$Controls/changer.visible = false
		elif order == 1 and stopthis and not is_rebinding:
			# 1. Ativa o estado de rebind e inicia o Timer3 com 5 segundos
			is_rebinding = true
			# Linha de grupo (Movimento horizontal/vertical): monta a sequência de direções
			grupo_fila = _grupo_da_linha()
			valor_etapa_anterior = -999999
			eixo_neutro_ok = true
			fechando_rebind = false
			$Timer3.wait_time = 6
			$Timer3.start()
			# 2. Deixa o contador VISÍVEL para mostrar a contagem regressiva
			$"Controls/changer/input selected".visible = false 
			$Controls/changer/text2.visible = true
			$Controls/changer/red.visible = false
			$"Controls/changer/1".visible = false
			$"Controls/changer/2".visible = false
			$"Controls/changer/3".visible = false
			$Controls/changer/text3.visible = true
			$Controls/changer/text2.text = tr("Agora pressione um botão ou mova um eixo para defini-lo como") + " " + tr(_nome_do_passo())
			
			# 3. Aguarda os 5 segundos do Timer3 terminarem
			await $Timer3.timeout
			
			# 4. Se o tempo acabou e 'is_rebinding' CONTINUA true, significa que ele não apertou nada
			if is_rebinding:
				is_rebinding = false
				grupo_fila.clear()
				eixo_neutro_ok = true
				fechando_rebind = false
				stopthis = false
				$Controls/changer.visible = false
				print("Tempo esgotado! Modificação cancelada.")
		elif order == 2 and stopthis:
			# --- OPÇÃO REMOVER SELECIONADA ---
			# Linha de grupo remove as duas direções; linha simples remove só a ação dela
			var alvos: Array = _grupo_da_linha()
			if alvos.is_empty():
				var a_unica = obter_nome_da_acao()
				if a_unica != "":
					alvos = [a_unica]
			for acao_para_apagar in alvos:
				# Apaga SÓ a coluna que está sendo editada (teclado OU controle)
				var para_apagar: Array = []
				for e in InputMap.action_get_events(acao_para_apagar):
					if controllado == 1 and e is InputEventKey:
						para_apagar.append(e)
					elif controllado == 2 and (e is InputEventJoypadButton or e is InputEventJoypadMotion):
						para_apagar.append(e)
				for e in para_apagar:
					InputMap.action_erase_event(acao_para_apagar, e)
				gvar.update_single_key(acao_para_apagar, 0, controllado) # Salva a limpeza só daquela coluna
			carregar_teclas_no_menu()                      # Atualiza as labels na tela
			stopthis = false
			$Controls/changer.visible = false
		elif controllado !=0 and controls and not stopthis:
			#SE EU QUISER MUDAR AQUI PRA UMA CAIXA DE SELEÇAO, AQUI ATIVA O COISA DE TROCAR TECLA! bom, pelo menos o coisa visual
			stopthis = true
			order = 1
			$"Controls/changer/input selected".visible = true
			$Controls/changer/text2.visible = false
			$Controls/changer/red.visible = true
			$"Controls/changer/1".visible = true
			$"Controls/changer/2".visible = true
			$"Controls/changer/3".visible = true
			$Controls/changer/text3.visible = false
		elif controllado == 0:
			if numeroordem == 1 and controls:
				controls = false
				options = true
				numeroordem = 3 # linha CONTROLES agora é a 3 do submenu
			elif numeroordem == 6 and controls:
				$up.visible = false
				$left.visible = false
				$right.visible = false
				$down.visible = false
				$ok.visible = false
				$back.visible = false
				controls = false
				$Controls/Mobile_HUD/Control.modo_edicao = true
				$Controls/Mobile_HUD.visible = true
				$Control/Pausemenu.visible = false
			elif controls and not stopthis and numeroordem == 2:
						# 1. Restaura o InputMap original do motor do jogo (o que você configurou no Project Settings)
						InputMap.load_from_project_settings()
						
						# 2. Cria uma lista com todas as suas ações para atualizar o gvar e o JSON com os valores de fábrica
						var todas_as_acoes = ["right", "left", "up", "down", "jump", "shoot", "B move", "aim", "dash", "arm"]
						
						for acao in todas_as_acoes:
							var val_teclado = 0
							var val_controle = 0
							
							for ev in InputMap.action_get_events(acao):
								var input_val = 0
								
								# Faz a mesma conversão de ID que você usa no rebind normal
								if ev is InputEventKey:
									input_val = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
								elif ev is InputEventJoypadButton:
									input_val = ev.button_index + 500
								elif ev is InputEventJoypadMotion:
									input_val = (1000 + ev.axis) if ev.axis_value > 0 else (2000 + ev.axis)
								else:
									continue
								
								# Guarda o primeiro evento de cada coluna (teclado E controle)
								if ev is InputEventKey:
									if val_teclado == 0: val_teclado = input_val
								elif val_controle == 0:
									val_controle = input_val
							
							# Salva as 2 colunas no JSON (0 = aquela coluna sem padrão)
							gvar.update_single_key(acao, val_teclado, 1)
							gvar.update_single_key(acao, val_controle, 2)
						
						# 3. Atualiza os textos dos botões na tela imediatamente
						carregar_teclas_no_menu()
						print("Todos os controles foram restaurados e salvos no padrão!")
	if Input.is_action_just_pressed("M_back"):
		back()


func timernovo():
	is_rebinding = true

# TENTAR DE NOVO: a tela ESCURECE devagar até ficar toda preta e só então a
# fase recarrega — o iris novo da fase abre em cima do preto, como no original.
# O reset é o MESMO da morte (player_1.gd::die), que é onde o Cuphead já faz
# isso: vida = player.hp_max() (3, ou 4/5 com Heart/Twin), cartões zerados.
const RETRY_FADE := 0.75 # segundos do escurecimento

func _reiniciar_fase() -> void:
	if reiniciando:
		return
	reiniciando = true
	# Reset (mesma fonte do HUD, nunca somar): vida máxima e cartões zerados
	player.hp = player.hp_max()
	player.cards = 0
	player.cardcont = 0
	# O véu de preto fica ACIMA de tudo (menu e brilho inclusive) e o jogo
	# continua pausado enquanto ele escurece — o menu some aos olhos sem
	# precisar sair da tela.
	var veu := _veu_escuro()
	veu.color = Color(0, 0, 0, 0)
	var tr := create_tween()
	tr.tween_property(veu, "color:a", 1.0, RETRY_FADE)
	await tr.finished
	# Só agora recarrega. O iris da fase nova abre sozinho (iris.gd::_ready),
	# em cima do preto, e o _ready do menu novo zera o véu.
	get_tree().paused = false
	gvar.pause = false
	get_tree().reload_current_scene()

# Véu de preto do TENTAR DE NOVO: mora na camada de efeitos (por cima de
# tudo), sobrevive à recarga e é zerado pelo menu da fase nova.
func _veu_escuro() -> ColorRect:
	var veu := _camada_fx.get_node_or_null("Escurecer") as ColorRect
	if veu == null:
		veu = ColorRect.new()
		veu.name = "Escurecer"
		veu.color = Color(0, 0, 0, 0)
		veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
		veu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_camada_fx.add_child(veu)
	return veu

func back():
	print("BACK -> Modo Edição: ", $Controls/Mobile_HUD/Control.modo_edicao, " | Limite antes: ", menulimit)
	# Seu código atual com a checagem aqui...
	if $Timer.is_stopped():
		$Timer.start()
		
		# 🎯 NOVA CHECAGEM: Se o modo_edicao for true OU se a HUD do mobile ainda estiver visível
		if $Controls/Mobile_HUD/Control.modo_edicao == true or $Controls/Mobile_HUD.visible == true:
			menulimit = 6
			ondevoltar = 6
			$up.visible = true
			$left.visible = true
			$right.visible = true
			$down.visible = true
			$ok.visible = true 
			$back.visible = true
			controls = true
			$Controls/Mobile_HUD/Control.modo_edicao = false
			$Controls/Mobile_HUD.visible = false
			$Control/Pausemenu.visible = true
			numeroordem = 6 
			return # 🔥 Agora sim ele para aqui e não deixa o limite virar 4!
		# 🛠️ Menu de Controles normal
		elif controls and $Controls/Mobile_HUD/Control.modo_edicao == false:
			if not stopthis:
				controls = false
				options = true
				numeroordem = 3 # linha CONTROLES agora é a 3 do submenu
			elif stopthis:
				if is_rebinding:
					_cancelar_rebind_pro_changer()
					return
				stopthis = false
				order = 3
				$Controls/changer.visible = false
				
		# ⚙️ Menu de Opções
		elif options:
			await $Timer.timeout
			if not controls:
				options = false
				menunorm = true
				if player.location == 0: numeroordem = 3
				elif player.location == 1: numeroordem = 2
				
		# 🏠 Menu Principal do Pause
		elif menunorm:
			get_tree().paused = false
			$".".visible = false
			menunorm = true
			numeroordem = 1
			gvar.pause = false
			$Controls/Mobile_HUD.visible = true
			if $Timer.is_stopped():
				$Timer.start()
		elif controls:
			if not stopthis and $Controls/Mobile_HUD/Control.modo_edicao == false:
				controls = false
				options = true
				numeroordem = 3 # linha CONTROLES agora é a 3 do submenu
			elif stopthis and $Controls/Mobile_HUD/Control.modo_edicao == false:
				if is_rebinding:
					is_rebinding = false
					return
				stopthis = false
				order = 3
				$Controls/changer.visible = false
			elif $Controls/Mobile_HUD/Control.modo_edicao == true:
				menulimit = 6
				ondevoltar = 6
				$up.visible = true
				$left.visible = true
				$right.visible = true
				$down.visible = true
				$ok.visible = true
				$back.visible = true
				controls = true
				$Controls/Mobile_HUD/Control.modo_edicao = false
				$Controls/Mobile_HUD.visible = false
				$Control/Pausemenu.visible = true
		elif options:
			await $Timer.timeout
			if not controls:
				options = false
				menunorm = true
				if player.location == 0: numeroordem = 3
				elif player.location == 1: numeroordem = 2
		elif menunorm:
			get_tree().paused = false
			$".".visible = false
			#get_tree().reload_current_scene() isso é pra o reset
			menunorm = true
			numeroordem = 1
			gvar.pause = false
			$Controls/Mobile_HUD.visible = true
func menunormal():
	if menunorm:
		$Control/resume.self_modulate = Color.RED if numeroordem == 1 else Color.BLACK
		$Control/retry.self_modulate = Color.RED if numeroordem == 2 else Color.BLACK
		$Control/options.self_modulate = Color.RED if numeroordem == 3 else Color.BLACK
		$Control/exitthemap.self_modulate = Color.RED if numeroordem == 4 else Color.BLACK
	else:
		$Control/resume.self_modulate = Color.BLACK
		$Control/retry.self_modulate = Color.BLACK
		$Control/options.self_modulate = Color.BLACK
		$Control/exitthemap.self_modulate = Color.BLACK
	if numeroordem == 0: numeroordem = 4
	if numeroordem == 5: numeroordem = 1

func optionss():
	# Submenu com 5 linhas: 1 ÁUDIO, 2 VISUAL, 3 CONTROLES, 4 IDIOMA, 5 VOLTAR
	if options:
		$Control/audio.self_modulate = Color.RED if numeroordem == 1 else Color.BLACK
		if $Control.has_node("visual"):
			$Control/visual.self_modulate = Color.RED if numeroordem == 2 else Color.BLACK
		$Control/controls.self_modulate = Color.RED if numeroordem == 3 else Color.BLACK
		$Control/language.self_modulate = Color.RED if numeroordem == 4 else Color.BLACK
		$Control/back.self_modulate = Color.RED if numeroordem == 5 else Color.BLACK
	else:
		$Control/audio.self_modulate = Color.BLACK
		if $Control.has_node("visual"):
			$Control/visual.self_modulate = Color.BLACK
		$Control/language.self_modulate = Color.BLACK
		$Control/controls.self_modulate = Color.BLACK
		$Control/back.self_modulate = Color.BLACK
	if numeroordem == 0: numeroordem = SUBMENU_LINHAS
	if numeroordem == SUBMENU_LINHAS + 1: numeroordem = 1

func controler():
	$Controls/AnimationPlayer.play(str(numeroordem))
	if controls:
		if controllado > 2: controllado = 2
		if controllado < 0: controllado = 0
		# Coluna escondida não pode ficar selecionada (fica só teclado OU só controle)
		if controllado != 0 and controllado != coluna_visivel:
			controllado = 0
		
		if not stopthis:
			if Input.is_action_just_pressed("M_right"):
				if $Timer.is_stopped():
					$Timer.start()
					controllado = _proxima_coluna(controllado, 1)
			if Input.is_action_just_pressed("M_left"):
				if $Timer.is_stopped():
					$Timer.start()
					controllado = _proxima_coluna(controllado, -1)
					
			if controllado == 0:
				limpar_modulacao_teclas()
				irprobaixo = 0
				menulimit = 6
				ondevoltar = 6
				$Controls/coisinha.visible = false
				atualizar_botoes_esquerda()
				
			if controllado == 1 or controllado == 2:
				$Controls/coisinha.position.x = 740 if controllado == 1 else 980
				limpar_modulacao_teclas()
				
				# CORREÇÃO DEFINITIVA: wname recebe textos puros diretamente para eliminar erros de nós filhos!
				match numeroordem:
					1: wname = "Movimento horizontal"
					2: wname = "Direita"
					3: wname = "Esquerda"
					4: wname = "Movimento vertical"
					5: wname = "Cima"
					6: wname = "Baixo"
					7: wname = "Pular"
					8: wname = "Atirar"
					9: wname = "Tiro EX"
					10: wname = "Trocar Arma"
					11: wname = "Parar"
					12: wname = "Correr"
				
				# Mapeia e destaca visualmente o botão/tecla correspondente
				var acao_string = obter_nome_da_acao()
				var mapeamento_nos = {
					"right": "Direita", "left": "Esquerda", "up": "Cima", "down": "Baixo",
					"jump": "Pular", "shoot": "Atirar", "B move": "Tiro EX", "aim": "Parar", "dash": "Correr",
					"arm": "Trocar Arma"
				}
				
				winput = null
				if mapeamento_nos.has(acao_string):
					var nome_no_pai = mapeamento_nos[acao_string]
					if $"Controls/Controlstext".has_node(nome_no_pai):
						var no_pai = $"Controls/Controlstext".get_node(nome_no_pai)
						var no_sufixo = "1" if controllado == 1 else "2"
						if no_pai.has_node(no_sufixo):
							winput = no_pai.get_node(no_sufixo)
							winput.self_modulate = Color.WHITE
				
				irprobaixo = 0
				menulimit = 12
				ondevoltar = 12
				$Controls/coisinha.visible = true
				desativar_botoes_esquerda()

func limpar_modulacao_teclas():
	var acoes = ["Direita", "Esquerda", "Cima", "Baixo", "Pular", "Atirar", "Tiro EX", "Trocar Arma", "Parar", "Correr", "Movimento horizontal", "Movimento vertical"]
	for a in acoes:
		if $"Controls/Controlstext".has_node(a):
			var base = $"Controls/Controlstext".get_node(a)
			if base.has_node("1"): base.get_node("1").self_modulate = Color.BLACK
			if base.has_node("2"): base.get_node("2").self_modulate = Color.BLACK

func atualizar_botoes_esquerda():
	$Controls/ok.frame = 1 if numeroordem == 1 else 0
	$Controls/ok/Label.material.set_shader_parameter("selecionado", numeroordem == 1)
	$Controls/restartpadr.frame = 1 if numeroordem == 2 else 0
	$Controls/restartpadr/Label.material.set_shader_parameter("selecionado", numeroordem == 2)
	$Controls/vibration.frame = 1 if numeroordem == 3 else 0
	$Controls/vibration/Label.material.set_shader_parameter("selecionado", numeroordem == 3)
	$Controls/removecontroller.frame = 1 if numeroordem == 4 else 0
	$Controls/removecontroller/Label.material.set_shader_parameter("selecionado", numeroordem == 4)
	$Controls/remove.frame = 1 if numeroordem == 5 else 0
	$Controls/remove/Label.material.set_shader_parameter("selecionado", numeroordem == 5)
	$Controls/touch.frame = 1 if numeroordem == 6 else 0
	$Controls/touch/Label.material.set_shader_parameter("selecionado", numeroordem == 6)

func desativar_botoes_esquerda():
	$Controls/ok.frame = 0
	$Controls/ok/Label.material.set_shader_parameter("selecionado", false)
	$Controls/restartpadr.frame = 0
	$Controls/restartpadr/Label.material.set_shader_parameter("selecionado", false)
	$Controls/vibration.frame = 0
	$Controls/vibration/Label.material.set_shader_parameter("selecionado", false)
	$Controls/removecontroller.frame = 0
	$Controls/removecontroller/Label.material.set_shader_parameter("selecionado", false)
	$Controls/remove.frame = 0
	$Controls/remove/Label.material.set_shader_parameter("selecionado", false)

func trocar():
	$Controls/changer.visible = true
	
	if winput != null and is_instance_valid(winput):
		$"Controls/changer/input selected".text = winput.text
	else:
		$"Controls/changer/input selected".text = ""
			
	$Controls/changer/changename.text = wname
	
	if Input.is_action_just_pressed("M_left"): order -= 1
	if Input.is_action_just_pressed("M_right"): order += 1
	$Controls/changer/redam.play(str(order))
	if order > 3: order = 1
	elif order < 1: order = 3

func carregar_teclas_no_menu():
	var lista_acoes = {
		"right": "Direita", "left": "Esquerda", "up": "Cima", "down": "Baixo",
		"jump": "Pular", "shoot": "Atirar", "B move": "Tiro EX", "aim": "Parar", "dash": "Correr",
		"arm": "Trocar Arma"
	}
	
	for acao in lista_acoes.keys():
		var node_name = lista_acoes[acao]
		var events = InputMap.action_get_events(acao)
		
		var txt_teclado = ""
		var txt_controle = ""
		
		for e in events:
			if e is InputEventKey:
				txt_teclado = obter_texto_limpo(e)
			elif e is InputEventJoypadButton or e is InputEventJoypadMotion:
				txt_controle = obter_texto_limpo(e)
				
		if $"Controls/Controlstext".has_node(node_name):
			var base = $"Controls/Controlstext".get_node(node_name)
			if base.has_node("1"): Tradutor.definir(base.get_node("1"), txt_teclado)
			if base.has_node("2"): Tradutor.definir(base.get_node("2"), txt_controle)

func obter_texto_limpo(event: InputEvent) -> String:
	if event is InputEventKey:
		var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		# Nome da tecla vem em inglês do OS (Up, Space...) → vira Cima, Espaço...
		return tr(OS.get_keycode_string(code))
	
	if event is InputEventJoypadButton:
		# Mapeamento manual dos botões padrões (padrão Xbox/Geral do Godot)
		var botoes = {
			0: "Botão A",
			1: "Botão B",
			2: "Botão X",
			3: "Botão Y",
			4: "Back / Select",
			5: "Guia / Home",
			6: "Start / Options",
			7: "L3 (Analógico Esq)",
			8: "R3 (Analógico Dir)",
			9: "L1 / LB",
			10: "R1 / RB",
			11: "D-Pad Cima",
			12: "D-Pad Baixo",
			13: "D-Pad Esquerda",
			14: "D-Pad Direita"
		}
		if event.button_index in botoes:
			return tr(str(botoes[event.button_index]))
		return tr("Botão") + " " + str(event.button_index)
	
	if event is InputEventJoypadMotion:
		var direcao = " +" if event.axis_value > 0 else " -"
		# Mapeamento dos eixos analógicos e gatilhos
		match event.axis:
			0: return tr("Analógico Esq X") + direcao
			1: return tr("Analógico Esq Y") + direcao
			2: return tr("Analógico Dir X") + direcao
			3: return tr("Analógico Dir Y") + direcao
			4: return tr("Gatilho Esq (L2)")
			5: return tr("Gatilho Dir (R2)")
			_: return tr("Eixo") + " " + str(event.axis) + direcao
			
	return ""

func obter_nome_da_acao() -> String: # do numeroordem la, c vai entender
	match numeroordem:
		2: return "right"
		3: return "left"
		5: return "up"
		6: return "down"
		7: return "jump"
		8: return "shoot"
		9: return "B move"
		10: return "arm"
		11: return "aim"
		12: return "dash"
	return ""

func _input(event: InputEvent) -> void:
	# Prompt de perfil aberto: o menu fica mudo (só o LineEdit recebe o teclado)
	if prompt_aberto:
		if event.is_action_pressed("M_back"):
			_fechar_prompt_perfil()
		return
	# Digitando num campo do menu: Esc tira o foco, o resto é do campo
	if _campo_digitando():
		if event.is_action_pressed("M_back"):
			get_viewport().gui_release_focus()
		return
	if is_rebinding:
		if fechando_rebind: return # janela de 0.2s fechando: ignora eventos
		if event is InputEventMouseMotion: return

		if controllado == 1 and not (event is InputEventKey): return
		if controllado == 2 and not (event is InputEventJoypadButton or event is InputEventJoypadMotion): return

		if event is InputEventKey:
			if event.echo: return # ignora repetição de tecla segurada
			if event.is_pressed():
				_finalizar_rebind(event)
		elif event is InputEventJoypadButton:
			if event.is_pressed():
				_finalizar_rebind(event)
		elif event is InputEventJoypadMotion:
			if abs(event.axis_value) < 0.35:
				eixo_neutro_ok = true # eixo voltou ao centro: liberado pro próximo passo
			elif abs(event.axis_value) > 0.5 and eixo_neutro_ok:
				eixo_neutro_ok = false # exige soltar (voltar ao centro) antes de capturar de novo
				_finalizar_rebind(event)

func _finalizar_rebind(event):
	# Converte o evento em valor do JSON (mesma regra do save)
	var input_val = 0
	if event is InputEventKey:
		input_val = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	elif event is InputEventJoypadButton:
		input_val = event.button_index + 500
	elif event is InputEventJoypadMotion:
		input_val = (1000 + event.axis) if event.axis_value > 0 else (2000 + event.axis)

	# ── Fluxo em GRUPO: "Movimento horizontal" (Direita→Esquerda) e "Movimento vertical" (Cima→Baixo) ──
	if not grupo_fila.is_empty():
		if input_val == valor_etapa_anterior:
			return # não deixa capturar o mesmo valor 2 vezes seguidas
		_aplicar_rebind(grupo_fila[0], event, input_val)
		valor_etapa_anterior = input_val
		eixo_neutro_ok = not (event is InputEventJoypadMotion) # eixo precisa voltar ao centro
		grupo_fila.pop_front()
		carregar_teclas_no_menu()
		if not grupo_fila.is_empty():
			# Próximo passo da sequência: re-arma o contador e atualiza o texto
			$Controls/changer/text2.text = tr("Agora pressione um botão ou mova um eixo para defini-lo como") + " " + tr(_rotulo_acao(grupo_fila[0]))
			$Timer3.start()
			return
		# Sequência completa → finaliza igual ao fluxo normal (mesmo intervalo de 0.2s)
		fechando_rebind = true
		await get_tree().create_timer(0.2).timeout
		fechando_rebind = false
		grupo_fila.clear()
		is_rebinding = false
		stopthis = false
		$"Controls/changer/input selected".visible = false
		$Controls/changer/text2.visible = false
		$Controls/changer/red.visible = false
		$"Controls/changer/1".visible = false
		$"Controls/changer/2".visible = false
		$"Controls/changer/3".visible = false
		$Controls/changer/text3.visible = false
		$Controls/changer.visible = false
		carregar_teclas_no_menu()
		return

	# ── Fluxo normal (linha de ação única) ──
	var action_local = obter_nome_da_acao()
	if action_local == "":
		# Linha sem ação mapeada (ex.: "Trocar Arma"): volta pro menu em vez de travar o texto
		_cancelar_rebind_pro_changer()
		return

	_aplicar_rebind(action_local, event, input_val)

	await get_tree().create_timer(0.2).timeout
	is_rebinding = false
	stopthis = false
	$"Controls/changer/input selected".visible = false
	$Controls/changer/text2.visible = false
	$Controls/changer/red.visible = false
	$"Controls/changer/1".visible = false
	$"Controls/changer/2".visible = false
	$"Controls/changer/3".visible = false
	$Controls/changer/text3.visible = false
	$Controls/changer.visible = false

	carregar_teclas_no_menu()

func _aplicar_rebind(action_local: String, event: InputEvent, input_val: int) -> void:
	_remove_duplicate_mappings(event)
	var events = InputMap.action_get_events(action_local)
	for e in events:
		if controllado == 1 and e is InputEventKey:
			InputMap.action_erase_event(action_local, e)
		elif controllado == 2 and (e is InputEventJoypadButton or e is InputEventJoypadMotion):
			InputMap.action_erase_event(action_local, e)
	InputMap.action_add_event(action_local, event)
	gvar.update_single_key(action_local, input_val, controllado) # Salva na coluna que está sendo editada

func _grupo_da_linha() -> Array:
	# Linhas de grupo da tabela: rebind em sequência das duas direções
	if numeroordem == 1: return ["right", "left"]
	if numeroordem == 4: return ["up", "down"]
	return []

func _rotulo_acao(a: String) -> String:
	match a:
		"right": return "Direita"
		"left": return "Esquerda"
		"up": return "Cima"
		"down": return "Baixo"
		"jump": return "Pular"
		"shoot": return "Atirar"
		"B move": return "Tiro EX"
		"arm": return "Trocar Arma"
		"aim": return "Parar"
		"dash": return "Correr"
	return a

func _nome_do_passo() -> String:
	if not grupo_fila.is_empty():
		return _rotulo_acao(grupo_fila[0])
	return wname

func _cancelar_rebind_pro_changer() -> void:
	# Cancela o rebind e mostra de novo o menu Trocar/Remover/Cancelar
	is_rebinding = false
	fechando_rebind = false
	grupo_fila.clear()
	eixo_neutro_ok = true
	$Controls/changer/text2.visible = false
	$Controls/changer/text3.visible = false
	$"Controls/changer/input selected".visible = true
	$Controls/changer/red.visible = true
	$"Controls/changer/1".visible = true
	$"Controls/changer/2".visible = true
	$"Controls/changer/3".visible = true

func _remove_duplicate_mappings(new_event):
	for a in InputMap.get_actions():
		if a.begins_with("ui_") or a.begins_with("M_"): continue
		var events = InputMap.action_get_events(a)
		for e in events:
			# Remove SÓ o evento que colide de verdade com o novo (mesma tecla/botão/eixo)
			if gvar.eventos_iguais(e, new_event):
				InputMap.action_erase_event(a, e)
				var col = 2 if (e is InputEventJoypadButton or e is InputEventJoypadMotion) else 1
				gvar.update_single_key(a, 0, col) # Zera só a coluna afetada no JSON

# ── Dropdown de dispositivos (entrada) ─────────────────────────────────────
# Monta os itens com o que está conectado AGORA: "Teclado" + cada controle "Nome (id)"
# forcar = true reconstrui mesmo sem mudança de dispositivo (usado na troca de idioma)
func atualizar_lista_dispositivos(forcar: bool = false) -> void:
	var entrada = $Controls/entrada
	var lista: Array = Input.get_connected_joypads()
	var sig = "teclado"
	for id in lista:
		sig += "|" + str(id) + ":" + Input.get_joy_name(id)
	if not forcar and sig == entrada_sig and entrada.item_count > 0:
		return # nada mudou, mantém itens e seleção
	entrada_sig = sig

	# Guarda a seleção atual pra tentar restaurá-la
	var sel_atual = null
	if entrada.selected >= 0 and entrada.selected < entrada.item_count:
		sel_atual = entrada.get_item_metadata(entrada.selected)
	if sel_atual == null:
		sel_atual = gvar.entrada_sel # última escolha salva no Keys.json

	entrada.clear()
	entrada.add_item(tr("Teclado"))
	entrada.set_item_metadata(0, -1) # -1 = teclado
	for id in lista:
		var nome = Input.get_joy_name(id)
		if nome == "":
			nome = "Controle"
		entrada.add_item("%s (%d)" % [nome, id])
		entrada.set_item_metadata(entrada.item_count - 1, id)

	# Restaura a seleção (select() NÃO dispara item_selected → não reaplica nada)
	var novo_sel = 0
	for i in entrada.item_count:
		if int(entrada.get_item_metadata(i)) == int(sel_atual):
			novo_sel = i
			break
	entrada.select(novo_sel)

func _on_joy_connection_changed(_id: int, _connected: bool) -> void:
	atualizar_lista_dispositivos()

# Clicou num dispositivo → aplica o padrão do Cuphead SÓ pra ele e grava no Keys.json
func _on_entrada_item_selected(index: int) -> void:
	var entrada = $Controls/entrada
	var id = int(entrada.get_item_metadata(index))
	gvar.salvar_entrada_sel(id)
	if id == -1:
		_aplicar_padrao_cuphead(1) # Teclado → coluna de teclado
	else:
		_aplicar_padrao_cuphead(2) # Controle → coluna de controle
	aplicar_coluna_visivel() # esconde a coluna que não foi escolhida
	carregar_teclas_no_menu() # atualiza os textos das colunas na hora
	print("Padrão do Cuphead aplicado em ", entrada.get_item_text(index))

# Aplica o padrão do Cuphead (definido no project.godot) na coluna 1=teclado / 2=controle
func _aplicar_padrao_cuphead(coluna: int) -> void:
	var acoes = ["right", "left", "up", "down", "jump", "shoot", "B move", "aim", "dash", "arm"]
	for acao in acoes:
		if not InputMap.has_action(acao): continue
		var definicao = ProjectSettings.get_setting("input/" + acao)
		if not (definicao is Dictionary) or not definicao.has("events"): continue

		# 1. Apaga os eventos atuais SÓ da coluna escolhida (a outra fica intacta)
		var apagar: Array = []
		for e in InputMap.action_get_events(acao):
			if coluna == 1 and e is InputEventKey:
				apagar.append(e)
			elif coluna == 2 and (e is InputEventJoypadButton or e is InputEventJoypadMotion):
				apagar.append(e)
		for e in apagar:
			InputMap.action_erase_event(acao, e)

		# 2. Aplica o 1º evento padrão da coluna (é o que o JSON persiste) e salva
		var val_salvo = 0
		for ev in definicao["events"]:
			var pertence = (coluna == 1 and ev is InputEventKey) or (coluna == 2 and (ev is InputEventJoypadButton or ev is InputEventJoypadMotion))
			if pertence and val_salvo == 0:
				InputMap.action_add_event(acao, ev.duplicate())
				val_salvo = _event_pra_val(ev)
		gvar.update_single_key(acao, val_salvo, coluna)

# Conversão evento → valor do JSON (mesma regra usada no _finalizar_rebind)
func _event_pra_val(ev: InputEvent) -> int:
	if ev is InputEventKey:
		return ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
	elif ev is InputEventJoypadButton:
		return ev.button_index + 500
	elif ev is InputEventJoypadMotion:
		return (1000 + ev.axis) if ev.axis_value > 0 else (2000 + ev.axis)
	return 0

# ── Coluna visível: só teclado OU só controle (conforme o dropdown) ─────────
# Id escolhido no dropdown: -1 = Teclado, >= 0 = id do controle
func id_entrada_atual() -> int:
	var entrada = $Controls/entrada
	if entrada.selected >= 0 and entrada.selected < entrada.item_count:
		return int(entrada.get_item_metadata(entrada.selected))
	return int(gvar.entrada_sel)

# Esconde tudo da coluna que não foi escolhida (padrão: teclado)
func aplicar_coluna_visivel() -> void:
	var so_teclado = id_entrada_atual() == -1
	coluna_visivel = 1 if so_teclado else 2

	if $Controls.has_node("keyboard"):
		$Controls.get_node("keyboard").visible = so_teclado # cabeçalho TECLADO
	if $Controls.has_node("control"):
		$Controls.get_node("control").visible = not so_teclado # cabeçalho CONTROLE

	var linhas = ["Direita", "Esquerda", "Cima", "Baixo", "Pular", "Atirar",
			"Tiro EX", "Trocar Arma", "Parar", "Correr"]
	for nome in linhas:
		if not $"Controls/Controlstext".has_node(nome): continue
		var base = $"Controls/Controlstext".get_node(nome)
		if base.has_node("1"): base.get_node("1").visible = so_teclado
		if base.has_node("2"): base.get_node("2").visible = not so_teclado

	# Não deixa a navegação presa numa coluna que acabou de sumir
	if controllado != 0 and controllado != coluna_visivel:
		controllado = 0

# Próxima coluna andando `dir` (+1 direita / -1 esquerda), pulando a escondida
func _proxima_coluna(atual: int, dir: int) -> int:
	var c = atual
	for _i in 3:
		c += dir
		if c < 0 or c > 2:
			return atual # bateu na ponta: continua onde está
		if c == 0 or c == coluna_visivel:
			return c
	return atual

# Algum OptionButton do menu com o popup na tela?
func _dropdown_aberto() -> bool:
	if $Controls.has_node("entrada"):
		var e = $Controls.get_node("entrada")
		if e is OptionButton and e.get_popup().visible:
			return true
	if $Controls.has_node("carregar"):
		var c = $Controls.get_node("carregar")
		if c is OptionButton and c.get_popup().visible:
			return true
	return false

# true = congela o menu neste frame (popup aberto, ou fechou agora nesse frame)
# Sem isso, a seta/Enter que confirma o dropdown também acionaria o menu
# (dá pra chegar no "Restaurar padrões" e apagar as teclas sem querer).
func _dropdown_ativo() -> bool:
	if _dropdown_aberto():
		_dropdown_saiu = true
		return true
	if _dropdown_saiu:
		_dropdown_saiu = false # pula só o frame em que o popup fechou
		return true
	return false

# ── Perfis: Salvar Config / Carregar config ─────────────────────────────────
func _conectar_botoes_perfil() -> void:
	if $Controls.has_node("salvar"):
		var salvar = $Controls.get_node("salvar")
		if salvar is BaseButton and not salvar.is_connected("pressed", _on_salvar_pressed):
			salvar.pressed.connect(_on_salvar_pressed)
	if $Controls.has_node("Excluir"):
		var excluir = $Controls.get_node("Excluir")
		if excluir is BaseButton and not excluir.is_connected("pressed", _on_excluir_pressed):
			excluir.pressed.connect(_on_excluir_pressed)
	# Enter NÃO salva mais: só o botão "Salvar Config" grava o perfil (pedido do
	# usuário). _ao_submeter_campo continua de pé, caso queira reconectar.
	var campo = _campo_nome_perfil()
	if campo != null and campo.is_connected("text_submitted", _ao_submeter_campo):
		campo.text_submitted.disconnect(_ao_submeter_campo)
	if $Controls.has_node("carregar"):
		var carregar = $Controls.get_node("carregar")
		if carregar is OptionButton:
			# O OptionButton só emite "item_selected" quando a seleção MUDA.
			# atualizar_lista_perfis() já deixa o perfil atual destacado com
			# select(sel), então clicar naquele mesmo perfil (ou no primeiro,
			# que vem selecionado por padrão) não disparava nada → "clico no
			# perfil e ele não carrega". O PopupMenu emite "index_pressed" em
			# TODA escolha, então é esse sinal que passa a carregar — e o
			# item_selected é desconectado pra não aplicar o perfil duas vezes.
			if carregar.is_connected("item_selected", _on_carregar_selecionado):
				carregar.item_selected.disconnect(_on_carregar_selecionado)
			var pop_perfil = carregar.get_popup()
			if pop_perfil != null and not pop_perfil.is_connected("index_pressed", _on_carregar_selecionado):
				pop_perfil.index_pressed.connect(_on_carregar_selecionado)
		elif carregar is BaseButton and not carregar.is_connected("pressed", _on_carregar_pressed):
			# Ainda é um botão comum → recarrega o último perfil escolhido
			carregar.pressed.connect(_on_carregar_pressed)

# Campo de nome do perfil: é o LineEdit que você pôs dentro do "salvar"
func _campo_nome_perfil() -> Control:
	if not $Controls.has_node("salvar"): return null
	var salvar = $Controls.get_node("salvar")
	if not salvar.has_node("TextEdit"): return null
	var campo = salvar.get_node("TextEdit")
	return campo if (campo is LineEdit or campo is TextEdit) else null

# O "# nome" que estava escrito no campo vira placeholder (senão virava o nome do arquivo)
func _preparar_campo_nome() -> void:
	var campo = _campo_nome_perfil()
	if campo == null: return
	if campo.text.strip_edges() == "# nome":
		campo.text = ""
		if campo is LineEdit:
			Tradutor.definir(campo, "# nome")

# Tem campo de texto com foco agora? (setas/Enter são dele, não do menu)
func _campo_digitando() -> bool:
	var foco = get_viewport().gui_get_focus_owner()
	return foco is LineEdit or foco is TextEdit

# Monta a lista de perfis no "Carregar config" e deixa o último escolhido marcado
func atualizar_lista_perfis() -> void:
	if not $Controls.has_node("carregar"): return
	var carregar = $Controls.get_node("carregar")
	if not (carregar is OptionButton): return
	var perfis: Array = gvar.listar_perfis()
	carregar.clear()
	if perfis.is_empty():
		carregar.add_item(tr("(nenhum perfil salvo)"))
		carregar.set_item_metadata(0, "")
		return
	var sel = 0
	for i in perfis.size():
		var nome = str(perfis[i])
		carregar.add_item(nome)
		carregar.set_item_metadata(i, nome)
		if nome == gvar.perfil_atual: sel = i
	carregar.select(sel) # select() não dispara item_selected

func _selecionar_perfil_no_dropdown(nome: String) -> void:
	if not $Controls.has_node("carregar"): return
	var carregar = $Controls.get_node("carregar")
	if not (carregar is OptionButton): return
	for i in carregar.item_count:
		if str(carregar.get_item_metadata(i)) == nome:
			carregar.select(i)
			return

# Escolheu um perfil no dropdown
func _on_carregar_selecionado(index: int) -> void:
	var carregar = $Controls.get_node("carregar")
	var meta = carregar.get_item_metadata(index)
	var nome = "" if meta == null else str(meta)
	if nome == "":
		_mostrar_aviso(tr("Nenhum perfil salvo ainda"))
		return
	_aplicar_perfil(nome)

# Botão "Carregar config" que ainda não foi trocado por OptionButton
func _on_carregar_pressed() -> void:
	if gvar.perfil_atual == "":
		_mostrar_aviso(tr("Nenhum perfil escolhido ainda"))
		return
	_aplicar_perfil(gvar.perfil_atual)

func _aplicar_perfil(nome: String) -> void:
	if gvar.aplicar_perfil(nome):
		entrada_sig = "" # força remontar o dropdown
		atualizar_lista_dispositivos()
		_sincronizar_dropdown_entrada()
		aplicar_coluna_visivel()
		carregar_teclas_no_menu()
		atualizar_lista_perfis()
		_mostrar_aviso(tr("Perfil \"%s\" carregado!") % nome)
	else:
		_mostrar_aviso(tr("Não deu pra carregar \"%s\"") % nome)

# Marca no dropdown o dispositivo que veio salvo no perfil
func _sincronizar_dropdown_entrada() -> void:
	var entrada = $Controls/entrada
	for i in entrada.item_count:
		if int(entrada.get_item_metadata(i)) == int(gvar.entrada_sel):
			entrada.select(i)
			return
	entrada.select(0)

# ── Salvar: usa o campo que você pôs dentro do botão "salvar" ───────────────
func _on_salvar_pressed() -> void:
	var campo = _campo_nome_perfil()
	if campo != null:
		_salvar_perfil_direto(campo)
	else:
		_abrir_prompt_perfil() # cena sem campo → abre o painel de nome

func _salvar_perfil_direto(campo: Control) -> void:
	var nome = _nome_perfil_valido(campo.text)
	if nome == "":
		_mostrar_aviso(tr("Digite um nome pro perfil"))
		campo.grab_focus()
		return
	if _salvar_e_marcar(nome):
		campo.text = nome
		get_viewport().gui_release_focus()
		_mostrar_aviso(tr("Perfil \"%s\" salvo!") % nome)
	else:
		_mostrar_aviso(tr("Não deu pra salvar o perfil"))

func _ao_submeter_campo(_texto: String) -> void:
	var campo = _campo_nome_perfil()
	if campo != null:
		_salvar_perfil_direto(campo)

# Salva o arquivo e deixa ele marcado no dropdown (true = deu certo)
func _salvar_e_marcar(nome: String) -> bool:
	if not gvar.salvar_perfil(nome): return false
	atualizar_lista_perfis()
	_selecionar_perfil_no_dropdown(nome)
	return true

# ── Excluir: apaga o perfil escolhido no dropdown (2 cliques confirma) ──────
func _on_excluir_pressed() -> void:
	var nome = _perfil_selecionado()
	if nome == "":
		_mostrar_aviso(tr("Escolha um perfil em \"Carregar config\""))
		return
	var agora = Time.get_ticks_msec() / 1000.0
	if _excluir_confirma != nome or agora - _excluir_hora > 3.0:
		_excluir_confirma = nome
		_excluir_hora = agora
		_mostrar_aviso(tr("Excluir \"%s\"? Clique de novo pra confirmar") % nome)
		return
	_excluir_confirma = ""
	if gvar.excluir_perfil(nome):
		if gvar.perfil_atual == nome:
			gvar.limpar_perfil_atual()
		atualizar_lista_perfis()
		_mostrar_aviso(tr("Perfil \"%s\" excluído") % nome)
	else:
		_mostrar_aviso(tr("Não deu pra excluir \"%s\"") % nome)

# Perfil que está marcado agora no "Carregar config" ("" se não houver)
func _perfil_selecionado() -> String:
	if not $Controls.has_node("carregar"): return ""
	var carregar = $Controls.get_node("carregar")
	if not (carregar is OptionButton): return ""
	if carregar.selected < 0 or carregar.selected >= carregar.item_count: return ""
	var meta = carregar.get_item_metadata(carregar.selected)
	return "" if meta == null else str(meta)

func _abrir_prompt_perfil() -> void:
	prompt_aberto = true
	if _prompt_perfil != null and is_instance_valid(_prompt_perfil):
		_prompt_perfil.visible = true
		Tradutor.definir(_rotulo_prompt, "Nome do perfil:")
		_linha_perfil.text = gvar.perfil_atual
		_linha_perfil.grab_focus()
		_linha_perfil.select_all()
		return

	# Fundo escuro que também bloqueia os cliques do menu atrás
	var fundo = ColorRect.new()
	fundo.name = "prompt_perfil"
	fundo.color = Color(0, 0, 0, 0.85)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	fundo.gui_input.connect(_ao_clicar_fundo)
	add_child(fundo)
	fundo.anchor_left = 0
	fundo.anchor_top = 0
	fundo.anchor_right = 1
	fundo.anchor_bottom = 1
	fundo.offset_left = 0
	fundo.offset_top = 0
	fundo.offset_right = 0
	fundo.offset_bottom = 0
	_prompt_perfil = fundo

	var centro = CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(centro)
	centro.anchor_left = 0
	centro.anchor_top = 0
	centro.anchor_right = 1
	centro.anchor_bottom = 1
	centro.offset_left = 0
	centro.offset_top = 0
	centro.offset_right = 0
	centro.offset_bottom = 0

	var caixa = PanelContainer.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_STOP
	var fundo_caixa = StyleBoxFlat.new()
	fundo_caixa.bg_color = Color(0.09, 0.09, 0.11, 1)
	fundo_caixa.border_color = Color(1, 1, 1, 1)
	fundo_caixa.set_border_width_all(4)
	fundo_caixa.set_corner_radius_all(8)
	fundo_caixa.content_margin_left = 26.0
	fundo_caixa.content_margin_right = 26.0
	fundo_caixa.content_margin_top = 20.0
	fundo_caixa.content_margin_bottom = 22.0
	caixa.add_theme_stylebox_override("panel", fundo_caixa)
	centro.add_child(caixa)

	var coluna = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 14)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(coluna)

	_rotulo_prompt = Label.new()
	Tradutor.definir(_rotulo_prompt, "Nome do perfil:")
	_rotulo_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo_prompt.add_theme_font_size_override("font_size", 28)
	_rotulo_prompt.add_theme_color_override("font_color", Color.WHITE)
	coluna.add_child(_rotulo_prompt)

	_linha_perfil = LineEdit.new()
	Tradutor.definir(_linha_perfil, "ex.: abobrinha123")
	_linha_perfil.max_length = 40
	_linha_perfil.text = gvar.perfil_atual
	_linha_perfil.custom_minimum_size = Vector2(500, 46)
	_linha_perfil.text_submitted.connect(_ao_submeter_prompt)
	coluna.add_child(_linha_perfil)

	var linha_botoes = HBoxContainer.new()
	linha_botoes.add_theme_constant_override("separation", 12)
	linha_botoes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(linha_botoes)

	var botao_cancelar = Button.new()
	Tradutor.definir(botao_cancelar, "Cancelar")
	botao_cancelar.custom_minimum_size = Vector2(160, 46)
	botao_cancelar.pressed.connect(_fechar_prompt_perfil)
	linha_botoes.add_child(botao_cancelar)

	var botao_confirmar = Button.new()
	Tradutor.definir(botao_confirmar, "Salvar")
	botao_confirmar.custom_minimum_size = Vector2(160, 46)
	botao_confirmar.pressed.connect(_ao_confirmar_nome)
	linha_botoes.add_child(botao_confirmar)

	_linha_perfil.grab_focus()
	_linha_perfil.select_all()

func _ao_submeter_prompt(_texto: String) -> void:
	_ao_confirmar_nome()

func _ao_confirmar_nome() -> void:
	if _linha_perfil == null or not is_instance_valid(_linha_perfil): return
	var nome = _nome_perfil_valido(_linha_perfil.text)
	if nome == "":
		Tradutor.definir(_rotulo_prompt, "Nome inválido ou vazio!")
		_linha_perfil.grab_focus()
		return
	if _salvar_e_marcar(nome):
		_fechar_prompt_perfil()
		_mostrar_aviso(tr("Perfil \"%s\" salvo!") % nome)
	else:
		Tradutor.definir(_rotulo_prompt, "Não foi possível salvar!")

func _ao_clicar_fundo(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_fechar_prompt_perfil()

# Tira do nome tudo que não pode ir pra um arquivo
func _nome_perfil_valido(bruto: String) -> String:
	var nome = bruto.strip_edges()
	if nome == "# nome": return "" # era o texto/placeholder do campo, não um nome
	var invalidos = "\\/:*?\"<>|"
	for i in invalidos.length():
		nome = nome.replace(invalidos.substr(i, 1), "_")
	if nome == "" or nome == "." or nome == "..": return ""
	if nome.to_lower() == "keys": return "" # é o arquivo das teclas ativas
	return nome.substr(0, 40)

func _fechar_prompt_perfil() -> void:
	prompt_aberto = false
	if _prompt_perfil != null and is_instance_valid(_prompt_perfil):
		_prompt_perfil.queue_free()
	_prompt_perfil = null
	_linha_perfil = null
	_rotulo_prompt = null

# Avisinho na parte de baixo da tela (salvo / carregado / erro)
func _mostrar_aviso(txt: String) -> void:
	if _aviso_label == null or not is_instance_valid(_aviso_label):
		_aviso_label = Label.new()
		_aviso_label.name = "aviso_perfil"
		_aviso_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_aviso_label.add_theme_font_size_override("font_size", 32)
		_aviso_label.add_theme_color_override("font_color", Color.WHITE)
		_aviso_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_aviso_label.add_theme_constant_override("outline_size", 10)
		_aviso_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_aviso_label)
		_aviso_label.anchor_left = 0.5
		_aviso_label.anchor_right = 0.5
		_aviso_label.anchor_top = 1.0
		_aviso_label.anchor_bottom = 1.0
		_aviso_label.offset_left = -520
		_aviso_label.offset_right = 520
		_aviso_label.offset_top = -88
		_aviso_label.offset_bottom = -34
	_aviso_label.text = txt
	_aviso_label.visible = true
	_aviso_token += 1
	var meu = _aviso_token
	await get_tree().create_timer(2.0).timeout
	if meu == _aviso_token and is_instance_valid(_aviso_label):
		_aviso_label.visible = false

# ── Idioma (tela IDIOMA do submenu Options) ─────────────────────────────────
# Escolhe pt ou en, atualiza tudo que está na tela e guarda no Keys.json
func _definir_idioma(cod: String) -> void:
	if not Tradutor.trocar(cod):
		return
	_apos_troca_idioma(Tradutor.idioma)

func _alternar_idioma() -> void:
	_definir_idioma("en" if Tradutor.idioma == "pt" else "pt")

func _apos_troca_idioma(ficou: String) -> void:
	# Os dropdowns e as labels montados por código dependem do idioma também.
	# (true = reconstrói mesmo com a lista de dispositivos igual)
	atualizar_lista_dispositivos(true)
	atualizar_lista_perfis()
	_mostrar_aviso(Tradutor.nome_idioma(ficou))
	_atualizar_tela()

# A linha LANGUAGE do submenu fica SÓ com o nome do idioma ("IDIOMA" em pt,
# "LANGUAGE" em en) — sem juntar o idioma atual no texto, que era o "IDIOMA -
# Português" antigo. A tradução é do Tradutor, que troca na hora.

# ── Telas de Áudio, Visual e Idioma (controle "-----|------") ────────────────
# As telas estão NO Pausemenu.tscn (TelaAudio / TelaVisual / TelaIdioma e a
# linha VISUAL do submenu) — é você que arrasta e edita no editor. O código só
# CRIA os nodes se faltar algum na cena, e de qualquer forma monta o _telas com
# os filhos que encontrar. O visual é o MESMO do resto do menu — MESMA FONTE E
# MESMO TAMANHO (CupheadVogue 35, copiados do label_settings da linha "audio").
# Igual ao print do Cuphead original: rótulo à DIREITA terminando em ":", o
# controle "-----|------" encostado nele e o "VOLTAR" centralizado embaixo.
# Cada linha: NOME (fica preto) + controle "-----|------" (é ele que fica
# vermelho quando a linha está selecionada).

func _criar_telas_opcoes() -> void:
	# Camada fixa de efeitos: fica FORA da visibilidade do menu, então brilho e
	# cor desfocada valem também DURANTE a partida (o menu esconde o
	# CanvasLayer inteiro, então filho dele sumiria no Resume). A camada 6 é DE
	# PROPÓSITO ACIMA do menu (5): no Cuphead brilho e dessaturação são
	# pós-processo da tela INTEIRA, menu incluso — embaixo do cartão o ajuste
	# mal aparecia.
	# Por isso Efeitos/Brilho continuam no CÓDIGO e não na cena: eles precisam
	# viver na JANELA, fora da visibilidade do menu. Se já existir (uma
	# reinstância da fase), reaproveita — senão o véu duplicaria.
	_camada_fx = get_tree().root.get_node_or_null("Efeitos") as CanvasLayer
	if _camada_fx == null:
		_camada_fx = CanvasLayer.new()
		_camada_fx.name = "Efeitos"
		# ADIADO: na partida a janela ainda está montando os filhos quando o
		# menu nasce, e um add_child direto FALHA em silêncio ("Parent node is
		# busy setting up children") — o véu ficava órfão e o brilho não
		# aparecia. Com call_deferred ele entra no fim do quadro.
		get_tree().root.add_child.call_deferred(_camada_fx)
	_camada_fx.layer = 6
	self.layer = 5

	# BRILHO: véu de preto (abaixo do centro) ou branco (acima) por cima de
	# TUDO, menu incluso — no Cuphead o brilho vale pra tela inteira. O alpha
	# vai até 0.8 nos dois extremos: dá pra ENXERGAR o efeito em cada passo de
	# 10% da barra e o menu continua legível pra voltar.
	_brilho = _camada_fx.get_node_or_null("Brilho") as ColorRect
	if _brilho == null:
		_brilho = ColorRect.new()
		_brilho.name = "Brilho"
		_brilho.color = Color(0, 0, 0, 0)
		_brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_brilho.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_camada_fx.add_child(_brilho)

	# O véu de escurecer do TENTAR DE NOVER sobrevive à recarga (mora na
	# camada de efeitos, que fica na janela) — a fase nova zera ele aqui,
	# antes do iris começar a abrir.
	var veu_escuro := _camada_fx.get_node_or_null("Escurecer") as ColorRect
	if veu_escuro != null:
		veu_escuro.color = Color(0, 0, 0, 0)

	# O AnimatedSprite2D carrega em frame 1 (estado guardado no editor). Fixa
	# no 0 — o cartão normal — pra tela não abrir já com o cartão errado.
	$Control/Pausemenu.frame = 0

	_criar_linha_submenu()
	_criar_tela_barras(TELA_AUDIO)
	_criar_tela_barras(TELA_VISUAL)
	_criar_tela_idioma()

	_carregar_ajustes()
	_aplicar_ajustes()
	_atualizar_tela()

# Label com EXATAMENTE a mesma fonte/tamanho/contorno das linhas do menu
func _rotulo_menu(texto: String, pos: Vector2, tam: Vector2, alinhamento: int) -> Label:
	var rot := Label.new()
	rot.text = texto
	rot.position = pos
	rot.size = tam
	rot.horizontal_alignment = alinhamento
	rot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if $Control.has_node("audio"):
		rot.label_settings = $Control/audio.label_settings
	else:
		rot.add_theme_font_override("font", preload("res://Fonts/CupheadVogue-ExtraBold.ttf"))
		rot.add_theme_font_size_override("font_size", 35)
	return rot

# Linha "VISUAL" do submenu: nova, criada por código com a MESMA cara da
# "AUDIO". Depois as 5 linhas são encaixadas pra caber todas no cartão.
func _criar_linha_submenu() -> void:
	# As 5 linhas do submenu (AUDIO/VISUAL/CONTROLS/LANGUAGE/BACK) já vêm do
	# Pausemenu.tscn — inclusive a VISUAL, que foi criada por código. Quem manda
	# na posição agora é o EDITOR: o código só encaixa as linhas quando faltou
	# alguma na cena (aí elas não têm onde estar).
	if $Control.has_node("visual"):
		return
	var vis := _rotulo_menu("VISUAL", Vector2(334.7, 230.0), Vector2(463, 59), HORIZONTAL_ALIGNMENT_CENTER)
	vis.name = "visual"
	vis.self_modulate = Color.BLACK
	vis.visible = false
	$Control.add_child(vis)
	# 5 linhas de 59 de altura a cada 40px: 190..350, texto até ~392 e o
	# rodapé começa em 418 — cabe no cartão (175..460) sem encostar nele.
	var ys := [190.0, 230.0, 270.0, 310.0, 350.0]
	var nos := ["audio", "visual", "controls", "language", "back"]
	for i in nos.size():
		if not $Control.has_node(nos[i]):
			continue
		var alvo := $Control.get_node(nos[i]) as Control
		alvo.position = Vector2(alvo.position.x, float(ys[i]))

# Geometria de cada tela. Áudio e Visual usam o frame 1 = options_bg.png
# (592x524 centrado em 568,319 -> x 272..864 / y 57..581), que JÁ traz a
# moldura impressa e o rodapé "MDHR, INC., Options" — o mesmo do print
# original. O Idioma usa o frame 0 (pause_menu.png, 514x299 -> y 169..468).
# "rot_dir" = x onde o rótulo direito termina; "ctrl_x" = onde começam os traços.
# A moldura interna impressa vai de x291 a x840: rot_dir/ctrl_x ficam entre
# ela e a borda do papel, e o fim dos traços bate em ~88% da largura útil.
func _config_tela(nome: String) -> Dictionary:
	if nome == TELA_AUDIO:
		return {"rotulos": AUDIO_ROTULOS, "chaves": AUDIO_CHAVES,
				"frame": 1, "ys": _Y_TELA,
				"rot_dir": 660.0, "rot_larg": 380.0, "ctrl_x": 666.0}
	if nome == TELA_VISUAL:
		# Colunas medidas no print ORIGINAL (Visual1/Visual2.jpeg, foto do
		# cartão 592x524 em escala 1:1): o rótulo termina em 308 do cartão e o
		# controle começa em 317 — o cartão começa em x272, daí 579/589. O
		# maior rótulo ("COR DESFOC.:" / "TELA INICIAL:", 249px) então começa
		# em 330 (a moldura impressa vai de 291) e o valor mais largo
		# ("DESATIVADO", 226px) termina em 815 (moldura até 840).
		return {"rotulos": VISUAL_ROTULOS, "chaves": VISUAL_CHAVES,
				"frame": 1, "ys": _Y_TELA_VISUAL,
				"rot_dir": 579.0, "rot_larg": 380.0, "ctrl_x": 589.0}
	return {"rotulos": IDIOMA_ROTULOS, "chaves": [], "idioma": true,
			"frame": 0, "ys": _Y_IDIOMA,
			"rot_dir": 630.0, "rot_larg": 316.0, "ctrl_x": 636.0}

# Monta uma tela: rótulo à direita terminando em ":", controle "-----|------"
# logo depois e o "VOLTAR" centralizado embaixo, na linha seguinte.
func _criar_tela_barras(nome: String) -> void:
	var cfg := _config_tela(nome)
	var linhas: Array = cfg["rotulos"]
	var ys: Array = cfg["ys"]
	var nome_no := "Tela" + str(nome).capitalize()
	# As telas vêm prontas do Pausemenu.tscn (é você que arrasta no editor).
	# O código só monta se a cena não tiver — aí ele que põe na posição.
	var no := get_node_or_null(nome_no) as Control
	if no == null:
		no = Control.new()
		no.name = nome_no
		no.mouse_filter = Control.MOUSE_FILTER_IGNORE
		no.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(no)

		var rot_dir := float(cfg["rot_dir"])
		var rot_larg := float(cfg["rot_larg"])
		var ctrl_x := float(cfg["ctrl_x"])

		for i in linhas.size():
			var y := float(ys[i])
			# Rótulo ALINHADO À DIREITA: todas as linhas terminam no mesmo x e o
			# controle começa no mesmo ponto (no original é exatamente assim)
			var rot := _rotulo_menu(str(linhas[i]),
					Vector2(rot_dir - rot_larg, y), Vector2(rot_larg, 59),
					HORIZONTAL_ALIGNMENT_RIGHT)
			# O NOME nunca fica vermelho — quem destaca é o controle da linha
			rot.self_modulate = Color.BLACK
			no.add_child(rot)
			# O controle: "-----|------" ou o texto da escolha, na MESMA fonte e
			# tamanho do menu. A caixa do texto é maior (260) porque valores como
			# "TELA CHEIA" têm 213px e "DESATIVADO", 226px.
			var larg := 260.0 if _tipo_linha(cfg, i) == "escolha" else 140.0
			var barra := _rotulo_menu(_traco(0), Vector2(ctrl_x, y),
					Vector2(larg, 59), HORIZONTAL_ALIGNMENT_LEFT)
			no.add_child(barra)

		# "VOLTAR": centralizado no cartão, sem controle (a linha inteira acende)
		var voltar := _rotulo_menu(VOLTAR_ROTULO,
				Vector2(318, float(ys[linhas.size()])), Vector2(500, 59),
				HORIZONTAL_ALIGNMENT_CENTER)
		no.add_child(voltar)

	# As linhas são os FILHOS na ordem [rótulo, controle] por linha, e o
	# VOLTAR é o último — a mesma ordem em que foram escritas na cena.
	var filhos := no.get_children()
	var rotulos: Array = []
	var barras: Array = []
	var chaves: Array = []
	for i in linhas.size():
		rotulos.append(filhos[i * 2])
		barras.append(filhos[i * 2 + 1])
		chaves.append(str(cfg["chaves"][i]) if i < cfg["chaves"].size() else "")

	no.visible = false
	_telas[nome] = {"no": no, "rotulos": rotulos, "barras": barras,
			"reset": filhos[filhos.size() - 1], "chaves": chaves,
			"idioma": bool(cfg.get("idioma", false)), "frame": int(cfg["frame"])}

# Tela de Idioma do original (print "idioma PT BR.jpeg" e o japonês): legenda
# pequena em cima, o NOME do idioma grande e VERMELHO no meio e o VOLTAR
# embaixo — tudo centralizado no cartão, sem barra e sem rótulo à esquerda.
func _criar_tela_idioma() -> void:
	# Vem pronta do Pausemenu.tscn (TelaIdioma): o NOME do idioma e o VOLTAR.
	# O código só monta se a cena não tiver.
	var no := get_node_or_null("TelaIdioma") as Control
	if no == null:
		no = Control.new()
		no.name = "TelaIdioma"
		no.mouse_filter = Control.MOUSE_FILTER_IGNORE
		no.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(no)

		# Só o NOME do idioma (em vermelho) e o VOLTAR — sem legenda em cima
		var nome := _rotulo_menu("", Vector2(318, _Y_IDIOMA[0]), Vector2(500, 59),
				HORIZONTAL_ALIGNMENT_CENTER)
		nome.self_modulate = Color.BLACK
		no.add_child(nome)

		var voltar := _rotulo_menu(VOLTAR_ROTULO, Vector2(318, _Y_IDIOMA[1]),
				Vector2(500, 59), HORIZONTAL_ALIGNMENT_CENTER)
		no.add_child(voltar)

	var filhos := no.get_children()
	no.visible = false
	_telas[TELA_IDIOMA] = {"no": no, "rotulos": [], "barras": [filhos[0]],
			"reset": filhos[filhos.size() - 1], "chaves": [], "idioma": true,
			"frame": 0}

# Tipo do controle da linha i: "escolha" (texto que cicla) ou "barra".
# A lista VISUAL_TIPOS é a única fonte — para cada chave, ela procura a linha
# correspondente. Áudio/Idioma não estão lá, então são barra (ou o idioma,
# que tem o próprio ramo).
func _tipo_linha(cfg: Dictionary, i: int) -> String:
	var chaves: Array = cfg["chaves"]
	if i >= chaves.size():
		return "barra"
	return _tipo_da_chave(str(chaves[i]))

func _tipo_da_chave(chave: String) -> String:
	for i in VISUAL_CHAVES.size():
		if str(VISUAL_CHAVES[i]) == chave:
			return str(VISUAL_TIPOS[i])
	return "barra"

# Textos que a linha pode assumir. A RESOLUÇÃO é a exceção: a lista é var
# (_resolucoes) porque a resolução atual do jogador entra nela quando não há
# escolha salva, e o índice guardado precisa continuar apontando certo.
func _opcoes_da_chave(chave: String) -> Array:
	if chave == "resolucao":
		return _resolucoes
	return VISUAL_OPCOES.get(chave, [])

# O controle da linha: BARRA_PASSOS traços com o "|" onde o valor está.
# 0.0 = "|----------" ... 0.5 = "-----|-----" ... 1.0 = "----------|"
func _traco(pos: int) -> String:
	var esq := ""
	for k in pos:
		esq += "-"
	var dir := ""
	for k in BARRA_PASSOS - pos:
		dir += "-"
	return esq + "|" + dir

func abrir_tela(nome: String) -> void:
	if not _telas.has(nome):
		return
	_tela_atual = nome
	audio_linha = 0
	# A tela de Idioma abre mostrando o idioma que está valendo
	if nome == TELA_IDIOMA:
		_idioma_indice = maxi(IDIOMA_VALORES.find(Tradutor.idioma), 0)
	# Uma tela de cada vez: esconde as outras antes de abrir essa (senão elas
	# acabam uma por cima da outra)
	for outro in _telas:
		(_telas[outro]["no"] as Control).visible = (str(outro) == nome)
	# Áudio/Visual no cartão GRANDE (frame 1), Idioma no cartão normal (frame 0)
	var fr := int(_telas[nome]["frame"])
	$Control/Pausemenu.frame = fr
	# Como no Cuphead: a lista do submenu sai da tela, e o menu principal
	# também (só o cartão + as barras ficam)
	for n in ["audio", "visual", "controls", "language", "back",
			"resume", "retry", "options", "exitthemap"]:
		if $Control.has_node(n):
			$Control.get_node(n).visible = false
	_atualizar_tela()

func fechar_tela() -> void:
	var nome := _tela_atual
	_tela_atual = ""
	if nome != "" and _telas.has(nome):
		(_telas[nome]["no"] as Control).visible = false
	# Volta pro cartão normal do submenu (frame 0)
	$Control/Pausemenu.frame = 0
	# De volta pro submenu Options (só ele tem essas 5 linhas)
	for n in ["audio", "visual", "controls", "language", "back"]:
		if $Control.has_node(n):
			$Control.get_node(n).visible = options
	_atualizar_tela()

# ── Ajustes (Keys.json, junto com idioma/HUD/teclas) ─────────────────────────
func _chaves_de_tudo() -> Array:
	var tudo: Array = []
	for i in AUDIO_CHAVES.size():
		tudo.append(AUDIO_CHAVES[i])
	for i in VISUAL_CHAVES.size():
		tudo.append(VISUAL_CHAVES[i])
	return tudo

func _carregar_ajustes() -> void:
	var dados: Dictionary = gvar._ler_json(gvar.get_save_path())
	# Migração: o antigo "VOZES" não tinha bus e na prática já mexia no Master,
	# então o valor que o jogador tinha guardado vira o VOLUME PRINCIPAL.
	if not dados.has("volume_master") and dados.has("volume_vozes"):
		dados["volume_master"] = dados["volume_vozes"]
	# As três linhas de janela começam pelo que o jogo JÁ está usando quando
	# não há escolha salva — assim a primeira aplicação não força tela cheia
	# nem muda nada da vez que ninguém pediu.
	# A RESOLUÇÃO é a QUALIDADE (quantos pixels o jogo DESENHA, não o tamanho
	# da janela), então o padrão é o tamanho de desenho atual.
	if not dados.has("resolucao"):
		var janela0 := get_window()
		var tam := janela0.content_scale_size if janela0 != null else Vector2i.ZERO
		if tam.x <= 0 or tam.y <= 0:
			tam = DisplayServer.window_get_size()
		if tam.x > 0 and tam.y > 0:
			var atual := "%dx%d" % [tam.x, tam.y]
			if not _resolucoes.has(atual):
				_resolucoes.append(atual)
			dados["resolucao"] = _resolucoes.find(atual)
	if not dados.has("tela_modo"):
		var cheia := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		dados["tela_modo"] = 0 if cheia else 1
	if not dados.has("vsync"):
		var ligado := DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
		dados["vsync"] = 0 if ligado else 1
	for chave in _chaves_de_tudo():
		var eh_escolha := _tipo_da_chave(chave) == "escolha"
		# Escolha = ÍNDICE na lista (0..n-1); barra = 0.0..1.0
		var padrao: Variant = 0 if eh_escolha else PADROES_AJUSTES.get(chave, 1.0)
		var v = dados.get(chave, padrao)
		if not (v is float or v is int):
			v = padrao
		if eh_escolha:
			var n := _opcoes_da_chave(chave).size()
			_valores[chave] = clampi(int(v), 0, maxi(n - 1, 0))
		else:
			_valores[chave] = clampf(float(v), 0.0, 1.0)

func _salvar_ajustes() -> void:
	var path: String = gvar.get_save_path()
	var dados: Dictionary = gvar._ler_json(path)
	for chave in _valores:
		dados[chave] = _valores[chave]
	gvar._gravar_json(path, dados)

func _aplicar_ajustes() -> void:
	# ── Áudio: um bus por linha ──────────────────────────────────────────────
	for i in AUDIO_BUSES.size():
		var idx := AudioServer.get_bus_index(str(AUDIO_BUSES[i]))
		if idx >= 0:
			AudioServer.set_bus_volume_db(idx,
					linear_to_db(maxf(float(_valores.get(AUDIO_CHAVES[i], 1.0)), 0.001)))
	# ── BRILHO: barra no CENTRO = neutro. Abaixo escurece com véu preto, acima
	# clareia com véu branco — 0.1 de barra = 0.16 de alpha, então dá pra ver
	# o efeito andando. MÁX = 0.8 dos dois lados, pra nunca sumir com o menu. ─
	if _brilho != null:
		var br := float(_valores.get("brilho", 0.5))
		if br <= 0.5:
			_brilho.color = Color(0, 0, 0, clampf((0.5 - br) * 1.6, 0.0, 0.8))
		else:
			_brilho.color = Color(1, 1, 1, clampf((br - 0.5) * 1.6, 0.0, 0.8))
	# COR DESFOC.: só o valor e o aviso — o efeito em si é do jogo, não nosso.
	var cd := float(_valores.get("cor_desfoc", 0.5))
	if not is_equal_approx(cd, _cor_desfoc_val):
		_cor_desfoc_val = cd
		cor_desfoc_mudou.emit(cd)
	# ── OVERSCAN: AFASTA a imagem (zoom out) — é assim no Cuphead, não
	# aproxica. 0 = tamanho normal, 1 = 15% menor. ────────────────────────────
	var janela := get_window()
	if janela != null:
		var escala := 1.0 - 0.15 * float(_valores.get("overscan", 0.0))
		if not is_equal_approx(janela.content_scale_factor, escala):
			janela.content_scale_factor = escala
	# ── TELA INICIAL: só avisa quando o índice muda (é o jogo quem decide) ───
	var ti := int(_valores.get("tela_inicial", 0))
	if ti != _tela_inicial_ind:
		_tela_inicial_ind = ti
		tela_inicial_mudou.emit(ti)
	# ── RESOLUÇÃO = QUALIDADE: quantos pixels o jogo DESENHA — e NÃO o tamanho
	# da janela (a janela e o modo de tela da linha TELA é quem manda no
	# tamanho). O canvas inteiro (jogo e menu) é desenhado em "alvo" e
	# escalado pra janela, igual ao Cuphead: 640x480 fica leve e "amassado",
	# o máximo fica nítido. Aspecto diferente vira faixa preta, como no
	# original. ──────────────────────────────────────────────────────────────
	var ops_res := _opcoes_da_chave("resolucao")
	var ir := clampi(int(_valores.get("resolucao", 0)), 0, maxi(ops_res.size() - 1, 0))
	if janela != null and ir < ops_res.size():
		var partes := str(ops_res[ir]).split("x")
		if partes.size() == 2:
			var alvo := Vector2i(int(partes[0]), int(partes[1]))
			if alvo.x > 0 and alvo.y > 0:
				if janela.content_scale_mode != Window.CONTENT_SCALE_MODE_CANVAS_ITEMS:
					janela.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
				if janela.content_scale_size != alvo:
					janela.content_scale_size = alvo
	var cheia := int(_valores.get("tela_modo", 0)) == 0
	var modo := DisplayServer.WINDOW_MODE_FULLSCREEN if cheia else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != modo:
		DisplayServer.window_set_mode(modo)
	var vs_ligado := int(_valores.get("vsync", 0)) == 0
	var vs := DisplayServer.VSYNC_ENABLED if vs_ligado else DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != vs:
		DisplayServer.window_set_vsync_mode(vs)

# Posição do "|" + destaque (vermelho) no CONTROLE da linha selecionada
func _atualizar_tela() -> void:
	for nome in _telas:
		var cfg: Dictionary = _telas[nome]
		var ativa := (_tela_atual == str(nome))
		if bool(cfg.get("idioma", false)):
			_atualizar_idioma(cfg, ativa)
			continue
		var linhas: Array = cfg["rotulos"]
		for i in linhas.size():
			var barra := cfg["barras"][i] as Label
			var chave: String = str(cfg["chaves"][i])
			if _tipo_linha(cfg, i) == "escolha":
				# Linha de valor em texto: mostra a opção (já traduzida).
				# definir() guarda a frase de origem no nó, então a troca
				# de idioma retraduz direito na hora.
				var ops := _opcoes_da_chave(chave)
				if ops.is_empty():
					barra.text = ""
				else:
					var idx := clampi(int(_valores.get(chave, 0)), 0, ops.size() - 1)
					Tradutor.definir(barra, str(ops[idx]))
			else:
				var pos := clampi(int(round(float(_valores.get(chave, 1.0)) * BARRA_PASSOS)), 0, BARRA_PASSOS)
				barra.text = _traco(pos)
			# O nome fica preto; o vermelho é no "-----|------"
			barra.self_modulate = Color.RED if (ativa and audio_linha == i) else Color.BLACK
		# VOLTAR não tem controle: a linha inteira acende
		(cfg["reset"] as Label).self_modulate = Color.RED if (ativa and audio_linha == linhas.size()) else Color.BLACK

# Tela de Idioma: legenda + nome do idioma (vermelho quando selecionado) +
# VOLTAR. A legenda e o VOLTAR saem no idioma que está sendo escolhido, e o
# nome fica como ele se escreve — igual ao print, que mostra 日本語 e 戻る.
func _atualizar_idioma(cfg: Dictionary, ativa: bool) -> void:
	_idioma_indice = clampi(_idioma_indice, 0, IDIOMA_VALORES.size() - 1)
	var cod := str(IDIOMA_VALORES[_idioma_indice])
	Tradutor.definir(cfg["reset"], VOLTAR_ROTULO)
	var nome := cfg["barras"][0] as Label
	nome.text = str(IDIOMA_NOMES.get(cod, cod))
	nome.self_modulate = Color.RED if (ativa and audio_linha == 0) else Color.BLACK
	(cfg["reset"] as Label).self_modulate = Color.RED if (ativa and audio_linha == 1) else Color.BLACK

# Mesma lógica de repetição do resto do menu (segurando a seta = repete a cada 0.2s)
func _dir_tela(acao: String) -> int:
	var sinal := -1 if (acao == "M_up" or acao == "M_left") else 1
	if Input.is_action_just_pressed(acao) or Input.is_action_pressed(acao):
		if Input.is_action_pressed(acao):
			if $Timer2.is_stopped():
				$Timer2.start()
				return sinal
		elif Input.is_action_just_pressed(acao):
			return sinal
	return 0

func _tocar_move_tela() -> void:
	if player.location == 0: $Move.play()
	if player.location == 1: $Move2.play()

func _processar_tela() -> void:
	if not _telas.has(_tela_atual):
		return
	var cfg: Dictionary = _telas[_tela_atual]
	var linhas: Array = cfg["rotulos"]
	var eh_idioma := bool(cfg.get("idioma", false))
	# Idioma não tem linha de rótulo: são 2 linhas (nome do idioma + VOLTAR)
	var total := (2 if eh_idioma else linhas.size() + 1)

	var toque: bool = $Controls/Mobile_HUD/Control/dt.button_pressed == true
	$up.visible = not toque
	$left.visible = not toque
	$right.visible = not toque
	$down.visible = not toque
	$ok.visible = not toque
	$back.visible = not toque

	var mudou := false
	var d := _dir_tela("M_up")
	if d != 0:
		audio_linha = wrapi(audio_linha + d, 0, total)
		mudou = true
	d = _dir_tela("M_down")
	if d != 0:
		audio_linha = wrapi(audio_linha + d, 0, total)
		mudou = true

	# Setas esquerda/direita mexem o valor. Na tela de Idioma trocam o idioma
	# (e já valem na hora); nas outras, a barra ou a lista de opções. A última
	# linha é o VOLTAR e não tem valor pra mexer.
	if eh_idioma:
		if audio_linha == 0:
			for acao in ["M_left", "M_right"]:
				d = _dir_tela(acao)
				if d != 0:
					_idioma_indice = wrapi(_idioma_indice + d, 0, IDIOMA_VALORES.size())
					_definir_idioma(str(IDIOMA_VALORES[_idioma_indice]))
					_tocar_move_tela()
					mudou = true
	elif audio_linha < linhas.size():
		for acao in ["M_left", "M_right"]:
			d = _dir_tela(acao)
			if d != 0:
				var chave: String = str(cfg["chaves"][audio_linha])
				if _tipo_linha(cfg, audio_linha) == "escolha":
					# Valor em texto: <- -> percorrem a lista de opções
					var ops := _opcoes_da_chave(chave)
					if ops.size() < 2:
						continue
					_valores[chave] = wrapi(int(_valores.get(chave, 0)) + d, 0, ops.size())
				else:
					var novo: float = clampf(float(_valores.get(chave, 1.0)) + d * 0.1, 0.0, 1.0)
					_valores[chave] = snappedf(novo, 0.1)
				_aplicar_ajustes()
				_salvar_ajustes()
				_tocar_move_tela()
				mudou = true
	if mudou:
		_atualizar_tela()

	if Input.is_action_just_pressed("M_ok"):
		_tocar_move_tela()
		# Na tela de Idioma o idioma já valeu na hora da troca, então Enter só
		# confirma e fecha; nas outras, Enter na linha do VOLTAR volta pro
		# submenu Options (como no original)
		if eh_idioma or audio_linha == linhas.size():
			fechar_tela()
	elif Input.is_action_just_pressed("M_back"):
		fechar_tela()
