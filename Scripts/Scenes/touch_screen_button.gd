extends Button

@export var action_name: String = "jump"
var is_rebinding: bool = false

func _ready():
	add_to_group("rebind_buttons")
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	await get_tree().process_frame
	update_button_text()

func update_button_text():
	var action = action_name.strip_edges()
	var events = InputMap.action_get_events(action)
	
	if events.size() > 0:
		var event = events[0]
		
		# 1. PEGA O VALOR NUMÉRICO (baseado na lógica do seu gvar)
		var val = 0
		if event is InputEventKey:
			val = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		elif event is InputEventJoypadButton:
			val = event.button_index
		elif event is InputEventJoypadMotion:
			# Reconstrói o ID (1000 ou 2000) para facilitar o match abaixo
			if event.axis_value > 0: val = 1000 + event.axis
			else: val = 2000 + event.axis

		# 2. LÓGICA DE EXIBIÇÃO:
		
		# TECLADO (Valores que o gvar entende como tecla)
		if event is InputEventKey or (val > 30 and val < 1000):
			var letra = OS.get_keycode_string(val)
			text = letra
			
		# BOTÃO DE CONTROLE
		elif event is InputEventJoypadButton or (val <= 30):
			text = "Botão " + str(val)
			
		# ANALÓGICO (Aqui está a tradução dos nomes!)
		elif event is InputEventJoypadMotion or val >= 1000:
			match val:
				1000: text = "LS Direita"
				2000: text = "LS Esquerda"
				1001: text = "LS Baixo"
				2001: text = "LS Cima"
				1002: text = "RS Direita"
				2002: text = "RS Esquerda"
				1003: text = "RS Baixo"
				2003: text = "RS Cima"
				_: text = "Eixo " + str(val) # Caso seja um controle diferente
	else:
		text = "---"

func _on_pressed():
	text = "..."
	is_rebinding = true

func _input(event):
	if is_rebinding:
		if event is InputEventMouseMotion: return
		
		if event is InputEventKey or event is InputEventJoypadButton:
			if event.is_pressed():
				_finalizar_rebind(event)
		elif event is InputEventJoypadMotion:
			if abs(event.axis_value) > 0.5:
				_finalizar_rebind(event)

func _finalizar_rebind(event):
	var action = action_name.strip_edges()
	_remove_duplicate_mappings(event)

	var input_val = 0
	
	# CALCULA O NOVO VALOR PARA O SAVE:
	if event is InputEventKey:
		# Pega a tecla física
		input_val = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		
	elif event is InputEventJoypadButton:
		# Soma 500 para NUNCA se misturar com o teclado no gvar
		input_val = event.button_index + 500
		
	elif event is InputEventJoypadMotion:
		input_val = (1000 + event.axis) if event.axis_value > 0 else (2000 + event.axis)

	# Apaga SÓ os eventos do mesmo tipo do novo (não destrói a outra coluna)
	var eh_teclado = event is InputEventKey
	var para_apagar: Array = []
	for e in InputMap.action_get_events(action):
		if eh_teclado == (e is InputEventKey):
			para_apagar.append(e)
	for e in para_apagar:
		InputMap.action_erase_event(action, e)
	InputMap.action_add_event(action, event)
	
	is_rebinding = false
	
	gvar.update_single_key(action, input_val, 1 if eh_teclado else 2)
	get_tree().call_group("rebind_buttons", "update_button_text")

func _remove_duplicate_mappings(new_event):
	for a in InputMap.get_actions():
		if a.begins_with("ui_"): continue
		if a.begins_with("M_"):
			print("Tecla de sistema protegida, escolha outra!")
			return # Para a função aqui e não faz nada
		var events = InputMap.action_get_events(a)
		for e in events:
			# Remove SÓ o evento idêntico ao novo (mesma tecla, mesmo botão ou mesmo eixo/direção)
			if gvar.eventos_iguais(e, new_event):
				InputMap.action_erase_event(a, e)
				var col = 2 if (e is InputEventJoypadButton or e is InputEventJoypadMotion) else 1
				gvar.update_single_key(a, 0, col) # Zera só a coluna afetada no JSON
