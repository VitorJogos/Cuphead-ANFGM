extends CharacterBody2D
# Direção atual do joystick (0 = solto, 1-8 = 8 direções)
# 1 = Direita, 2 = Baixo-Direita, 3 = Baixo, 4 = Baixo-Esquerda
# 5 = Esquerda, 6 = Cima-Esquerda, 7 = Cima, 8 = Cima-Direita
var duck = false
var duck_start = false
var up = false
var indano = false
var down = false
var damg = false
var candashoraxe = false
var upcard = false
var updo = false
var left = false
var right = false
var leri = false
var shoot = false
var aim = false
var mobile = false
var moving = false
var gravity = 5000
var jump_str = -1500
var speed = 400
var mov_up = false
var dieg = false
var jumped = false
var jumpcor = false
var dowt = false
var uping = false
var stopspamjump = false
var startboss = randi_range(1, 2)
var stopall = false
var dash = false
# Como no original: SÓ 1 dash no ar, reativa ao tocar o chão.
var dash_ar_usado = false
var bex = false
# Gatilho do EX: o frame 7 da animação de EX dura só ~0,4ms (duration 0.01 a
# 24fps) e o _physics_process só roda a cada 16,7ms — então o "== 7" quase
# nunca era visto e o EX não saía (especialmente no chão). Agora usamos
# ">= 7" com um gatilho ÚNICO por uso, para não criar o projétil toda frame.
var bex_spawn = false # projétil do EX já foi criado neste uso
var bex_gasto = false # cartas do EX já foram gastas neste uso
var superart = 0 #0 = none 1= I 2=II 3=III
var hit = false
var was_in_air = false # Coloque no topo do script
var reliq = 0 # 0 =none 1 =1hp 2=2hp 3=coffe 4=smokebomb
var parryslap = preload("res://Scenes/objects/test/parryslap.tscn")
var shotcreator = preload("res://Scenes/Player/shoots/shotcreator.tscn")
var shootf = shotcreator.instantiate()
var peashotex = preload("res://Scenes/Player/shoots/peashooter_ex.tscn")
var obex = preload("res://Scenes/Player/shoots/obus_ex.tscn")
var spreadex = preload("res://Scenes/Player/shoots/spreadshoot_ex.tscn")
var rondex = preload("res://Scenes/Player/shoots/roundabount_ex.tscn")
var perseguex = preload("res://Scenes/Player/shoots/homing_ex.tscn")
var chargex = preload("res://Scenes/Player/shoots/charge_ex.tscn")
var smokecreator = preload ("res://Scenes/Player/smoke.tscn")
var super1 = preload("res://Scenes/Player/super_1.tscn")
var jumpsound = randi_range(1,3)
var parrysound = randi_range(1,2)
var cardsound = randi_range(1,2)
var dashsound = randi_range(1,3)
var landsound = randi_range(1,2)
var startshootsound = randi_range(1,2)
var shootsound = randi_range(1,2)
# Última arma vista no frame anterior (pra detectar a troca de arma e tocar
# o som de início da arma nova — sem isso ela sairia muda até soltar/apertar).
var _arm_ante := -1
# Geração da corrente de sons do roundabout. Cada novo round_1.play() sobe o
# número; correntes velhas (suspensas num await por um stop()) abortam ao
# acordar, então nunca tocam junto com a nova = sem som duplicado.
var _round_gen := 0
var shootdup = false
var savedir = 0
signal turnduck
var backsshoot = false
var befx = false
var addingcard = false
var superative = false
var super2 = preload("res://Scenes/Player/super_ii.tscn")
var super3 = preload("res://Scenes/Player/super_iii.tscn")
var super2ative = false
var super2card = false
var playerpos = 0
var landsuper = false
var super2canflip = false
var super2_tempo = 0.0
# Garante que o Super II gaste as cartas UMA única vez, e só quando ficar dourado.
var super2_gastou_cartas = false
var invencible = false
var parring = false
# Parry — _parry_conseguido é gravado DENTRO do _checkparry(), que roda
# sincrono até o primeiro await, então quem chama já consegue ler o resultado.
# _parry_pose_frames segura a pose por UMA DURAÇÃO COMPLETA de "parry"/
# "parry_axe" antes de voltar pro pulo (é calculado a partir do SpriteFrames:
# 8 quadros a 24fps = 0,333s = 20 frames físicos a 60Hz — usar "8" ali cortava
# a tapa em ~40%). Essas animações têm loop=true, nunca emitem
# "animation_finished" e o guard lá embaixo segura o "jump": sem isto a pose
# ficaria presa até pousar.
var _parry_conseguido := false
var _parry_pose_frames := 0
# P. Açúcar (P. Sugar) — o pulo que SAI DO CHÃO fica "armado": a qualquer
# momento do voo, se cruzar um objeto rosa, o parry dispara SOZINHO (no
# original: "for every first jump you will automatically parry an object —
# you don't need to press the same key again"). Ao disparar ele DESCARREGA,
# então é um parry por pulo; só um novo pulo do chão rearma. É esse "um por
# pulo" que impede o parry infinito por contato.
var _sugar_armado := false
var watshoot = 0 # 0 = shoot1 1 = shoot2
@onready var sinput = Input.is_action_just_pressed("shoot")
@onready var SpriteAnimated2D = $AnimatedSprite2D
func _ready() -> void:
	player.actualshoot = player.shoot1
	if player.boss == true:
		_intro()
@onready var player_sprite = SpriteAnimated2D
@onready var glow = 0
func _input(event: InputEvent) -> void:
	# 🛠️ CORREÇÃO: Tiramos o "_just" do event
	if event.is_action_pressed("ui_focus_next") or Input.is_key_pressed(KEY_T):
		player.tiro_automatico = not player.tiro_automatico
		print("Modo Automático Ativado? ", player.tiro_automatico)
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("arm"):
		if watshoot == 0:
			player.actualshoot = player.shoot2
			watshoot = 1
		elif watshoot == 1:
			player.actualshoot = player.shoot1
			watshoot = 0
	if player.relic == 3:
		if $Coffe.is_stopped():
			$Coffe.start()
			# Coffee do original enche o super meter em ~25s:
			# 0,125 a cada 0,1s = 30 unidades (5 cartas) em ~24s.
			player.cardsadd += 0.125
	if is_on_floor():
		candashoraxe = true
		dash_ar_usado = false # reativa o dash no ar ao pousar (como no original)
	if player.cards !=30 and player.special !=0 and not addingcard:
		player.supercarged = false
	if player.cards ==30 and player.special !=0:
		player.supercarged = true
	if indano: 
		invencible = true
	if SpriteAnimated2D.animation == "duck_start" or SpriteAnimated2D.animation == "duck_s" or SpriteAnimated2D.animation == "duck" or SpriteAnimated2D.animation == "turn_duck":
		$CollisionShape2D.disabled = true
		$CollisionShape2D2.disabled = false
	else:
		$CollisionShape2D.disabled = false
		$CollisionShape2D2.disabled = true
# Proteção para garantir que os nós de colisão existem na cena antes de mexer neles
# 🛡️ Proteção total das colisões para não crashar o jogo
	if has_node("dmgarea/CollisionShape2D2") and has_node("CollisionShape2D3"):
		$dmgarea/CollisionShape2D2.disabled = $CollisionShape2D3.disabled
	if has_node("dmgarea/CollisionShape2D") and has_node("CollisionShape2D2"):
		$dmgarea/CollisionShape2D.disabled = $CollisionShape2D2.disabled
	player.playerdir = player.dir
	#low.animation = player_sprite.animation
	#glow.frame = player_sprite.frame
	#glow.flip_h = player_sprite.flip_h
	#glow.offset = player_sprite.offset
	# SAFETY: nunca deixa o Super II travar o controle para sempre.
	# A animação do super2 emite o sinal em ~1.3s; se não chegar, libera mesmo assim.
	if super2ative:
		super2_tempo += delta
		if super2_tempo > 4.0:
			super2_tempo = 0.0
			super2ative = false
			stopall = false
	else:
		super2_tempo = 0.0
	if super2ative:
		stopall = true
	if bex:
		if not superative and not super2ative:
			if SpriteAnimated2D.frame >= 7 and not bex_spawn:
				bex_spawn = true
				var fxe = preload("res://Scenes/Player/exfx.tscn")
				var fxex = fxe.instantiate()
				var ex = 0
				fxex.is_charge = 0
				add_child(fxex)
				fxex.global_position = SpriteAnimated2D.global_position
				if player.actualshoot == 0:
					ex = peashotex.instantiate()
					get_parent().add_child(ex)
					ex.global_position = $Ex.global_position
					excreate(ex, fxex)
				elif player.actualshoot == 4:
					ex = obex.instantiate()
					get_parent().add_child(ex)
					ex.global_position = $Ex.global_position
					excreate(ex, fxex)
				elif player.actualshoot == 2:
					ex = rondex.instantiate()
					get_parent().add_child(ex)
					ex.global_position = $Ex.global_position
					excreate(ex, fxex)
				elif player.actualshoot == 3:
					ex = perseguex.instantiate()
					get_parent().add_child(ex)
					ex.global_position = $Ex.global_position
					excreate(ex, fxex)
				elif player.actualshoot == 5:
					ex = chargex.instantiate()
					get_parent().add_child(ex)
					ex.global_position = SpriteAnimated2D.global_position
					excreate(ex, fxex)
				elif player.actualshoot == 1:
					var angulo_atual = 0 # Começa em 0° (Direita)
					
					for i in range(8):
						# Instancia o tiro do Spread EX (supondo que a variável seja 'spreadex')
						var ex_spread = spreadex.instantiate() 
						get_parent().add_child(ex_spread)
						ex_spread.global_position = SpriteAnimated2D.global_position
						
						# Aplica o ângulo diretamente no projétil (sem chamar o excreate)
						if ex_spread.has_method("iniciar"):
							# Se o seu script do tiro tiver uma função para receber o ângulo:
							ex_spread.iniciar(angulo_atual)
						else:
							# Caso mude direto pelas propriedades do Godot:
							ex_spread.rotation_degrees = angulo_atual
						
						angulo_atual += 45 # Prepara a próxima direção
						
						# Pequena pausa antes de criar o próximo projétil do círculo
						#await get_tree().create_timer(0.05).timeout
						excreate(null, fxex)
		else:
			if SpriteAnimated2D.frame >= 7 and not bex_spawn:
				bex_spawn = true
				var ex = super2.instantiate()
				if ex.frame == 19:
					if player.special == 2 and superative:
						super2jump(ex)
						ex.z_index = -1
						velocity.y = -1500
				if player.special == 1:
					if SpriteAnimated2D.animation == "super1":
						ex = super1.instantiate()
						get_parent().add_child(ex)
						ex.global_position = $Super1.global_position
				if player.special == 3:
					ex = super3.instantiate()
					get_parent().add_child(ex)
					ex.global_position = SpriteAnimated2D.global_position
					ex.global_position.y -= 100
				if player.special == 2 and SpriteAnimated2D.animation == "super2":
					ex.position()
					ex = super2.instantiate()
					get_parent().add_child(ex)
					ex.z_index = 1
					ex.global_position = SpriteAnimated2D.global_position
					ex.global_position.y += -70
					playerpos = SpriteAnimated2D.global_position
					player.heposition = ex.heposition
					ex.flip_h = SpriteAnimated2D.flip_h
					super2jump(ex)
					SpriteAnimated2D.play("jump")
					print(ex.heposition)
					
					$".".position.y += -100
	if player.cardaudio and not player.carddiminuiu:
		if player.cardcont !=5:
			cardsound = randi_range(1,2)
			if cardsound == 1:
				$card1.play()
			if cardsound == 2:
				$card2.play()
		else:
			$card_max.play()
	player.shootfposition = $shootm.position
	if not shoot:
		$round_1.stop()
		$round_2.stop()
		$round_3.stop()
		$round_4.stop()
		$round_5.stop()
		$round_6.stop()
		$round_7.stop()
		$round_8.stop()
		$round_9.stop()
		$round_10.stop()
		$pea_loop1.stop()
		$pea_loop2.stop()
		$sped_1.stop()
		$sped_2.stop()
		$sped_3.stop()
		$sped_4.stop()
		# pea_start também: ele nunca era parado, então duas variantes podiam
		# terminar juntas e cada uma chamar loopshoot() => 2 loops tocando.
		$pea_start1.stop()
		$pea_start2.stop()
	if stopall:
		$round_1.stop()
		$round_2.stop()
		$round_3.stop()
		$round_4.stop()
		$round_5.stop()
		$round_6.stop()
		$round_7.stop()
		$round_8.stop()
		$round_9.stop()
		$round_10.stop()
		$pea_loop1.stop()
		$pea_loop2.stop()
		$sped_1.stop()
		$sped_2.stop()
		$sped_3.stop()
		$sped_4.stop()
		player.stopall = true
	else:
		player.stopall = false
	if shoot:
		player.shooting = true
		backsshoot = true
	else:
		player.shooting = false
	if duck or duck_start:
		player.duck = true
	if not duck and not duck_start:
		player.duck = false
	if SpriteAnimated2D.flip_h == true:
		$Super2.play("L")
		player.mirror = true
	else:
		$Super2.play("R")
		player.mirror = false
	if player.cards == 30 and player.special !=0:
		superative = true
	else:
		superative = false
	if Input.is_action_just_pressed("B move") and $Extimer.is_stopped() and not bex and not gvar.desatshots and not super2card and not parring and not dieg and not damg:
		if player.cards >5:
			_bex()  
			if player.special == 0 or player.cards <30:
				savedir = player.dir
				if savedir != 0:
					$Exam.play(str(savedir))
					befx = true
				if savedir == 0:
					if SpriteAnimated2D.flip_h:
						$Exam.play("5")
					else:
						$Exam.play("0")
				
	if SpriteAnimated2D.frame >= 7 and bex and not bex_gasto:
		bex_gasto = true
		if not superative:
			$Cardtimer.wait_time = 0.05
			exend() 
		else:
			# Um EX vira SUPER quando superative (5 cartas cheias + super equipado).
			# Todos os supers (I, II, III) gastam as 5 cartas cheias da NESMA forma.
			if player.special == 1 :
				$Cardtimer.wait_time = 0.1
			# O Super II é exceção: ele NÃO gasta as cartas aqui. As 5 barras só
			# começam a ser gastas quando o personagem fica dourado (em super2jump).
			# 🛑 O dreno com await NÃO pode ficar dentro de _physics_process: a
			# chamada virava coroutine, suspendia, e o motor seguia chamando
			# _physics_process nos quadros seguintes => DUAS execuções concorrentes
			# (a suspensa retomava no idle e rodava o bloco de movimento +
			# move_and_slide() uma 2ª vez, fora do passo de física).
			if player.special != 2:
				_drena_cartas()
	player.dir = gvar.dir

	if gvar.desatshots:
		shoot = false

	if not aim:
		if player.dir == 6 or player.dir == 8:
			mov_up = true
		else:
			mov_up = false

	if is_on_floor() and was_in_air:
		_ao_pousar() # Chama a sua função de pouso
		$Bombam.play("jump")
		
		# 2. Atualiza a variável para o próximo frame
	was_in_air = not is_on_floor()

	if player.dir == 2 or player.dir == 4:
		dowt = true
	else:
		dowt = false

	if left and right:
		leri = true
	else:
		leri = false
	if up and down:
		updo = true
	else:
		updo = false


# MOVIMENTOS INPUT//////////////
	if mobile == false:
		if Input.is_action_pressed("right"):
			if not Input.is_action_pressed("up") and not Input.is_action_pressed("down"):
				player.dir = 1
			if Input.is_action_pressed("up"):
				player.dir = 8
			if Input.is_action_pressed("down"):
				player.dir = 2
		if Input.is_action_pressed("left"):
			if not Input.is_action_pressed("up") and not Input.is_action_pressed("down"):
				player.dir = 5
			if Input.is_action_pressed("up"):
				player.dir = 6
			if Input.is_action_pressed("down"):
				player.dir = 4
		if Input.is_action_pressed("up"):
			if not Input.is_action_pressed("left") and not Input.is_action_pressed("right"):
				player.dir = 7
		if Input.is_action_pressed("down"):
			if not Input.is_action_pressed("left") and not Input.is_action_pressed("right"):
				player.dir = 3
#////////////////////////////////////////////////////////

		if player.dir == 0:
			up = false
			down = false
			left = false
			right = false
		if player.dir == 1 or player.dir == 8 or player.dir == 2:
			right = true
		else:
			right = false
		if player.dir == 3 or player.dir == 4 or player.dir == 2:
			down = true
		else:
			down = false
		if player.dir == 7 or player.dir == 6 or player.dir == 8:
			up = true
		else:
			up = false
		if player.dir == 5 or player.dir == 6 or player.dir == 4:
			left = true
		else:
			left = false



	# 🔧 Gravidade: FICA CONGELADA dentro do stopall (como no original 4.6), para o
	# EX / dash / super no ar manterem o jogador parado em vez de deixá-lo cair.
	# A ÚNICA exceção é o dano (damg): ele define velocity.y = -300 uma única vez,
	# e sem gravidade o Cuphead PLANAVA durante toda a animação de hit/hit_air
	# (bug "segurar pular e andar"). damg cobre exatamente a janela do knockback.
	gravity = 5000 * delta
	var _congelado = (stopall or gvar.stopall) and not damg
	if not is_on_floor():
		if not dieg and not _congelado:
			velocity.y += gravity
	elif not landsuper:
		velocity.y = 0

	if not stopall and not gvar.stopall:
		if not is_on_floor():
			duck = false
			duck_start = false
		else:
			if not landsuper:
				velocity.y = 0
				stopspamjump = false
			# Pousou => o pulo do Açúcar acabou, ele volta a ser normal.
			# Este "else" roda ANTES do bloco de pulo lá embaixo, então no
			# frame do clique ele zera e o próprio clique rearma em seguida.
			_sugar_armado = false


		# P. Açúcar: o pulo que SAI DO CHÃO fica armado, e a checagem roda a CADA
		# FRAME do voo — a qualquer momento, se cruzar o rosa, o parry dispara
		# sozinho (no original: "you don't need to press the same key again").
		# Ao disparar ele DESCARREGA: é um parry por pulo, e só um novo pulo do
		# chão rearma. É esse "um por pulo" que impede o parry infinito por
		# contato (o parry antigo se repetia sozinho enquanto caía em cima do rosa).
		if _sugar_armado and not is_on_floor() and _tem_alvo_de_parry():
			_sugar_armado = false
			_tapa_de_parry()

		if Input.is_action_just_pressed("jump") and jumped == false:
			if is_on_floor():
				jumpsound = randi_range(1,3)
				jumped = true
				velocity.y = jump_str
				if player.relic ==6:
					# O PRÓPRIO pulo já entra na tapa e ARMAS o Açúcar pro resto
					# do voo. Se já tiver rosa encostando, ele parrya aqui mesmo
					# e já nasce descarregado.
					_sugar_armado = true
					_tapa_de_parry()
					if _parry_conseguido:
						_sugar_armado = false
				else:
					SpriteAnimated2D.play("jump")
				if jumpsound == 1:
					$jump1.play()
				if jumpsound == 2:
					$jump2.play()
				if jumpsound == 3:
					$jump3.play()
			if not is_on_floor():
				# Apertar pulo no ar dá a TAPA SEMPRE (normal e Whetstone); quem
				# decide se o parry de fato roda é o _checkparry(), lá dentro.
				_tapa_de_parry()

		if jumped == true:
			if not is_on_floor():
				jumped = false

		if Input.is_action_just_released("jump"):
			if velocity.y !=0:
				velocity.y = velocity.y * 0.5

		if right:
			if dowt == false and not duck:
				if not super2canflip:
					SpriteAnimated2D.flip_h = false
				if velocity.x == -speed:
					if velocity.y == 0:
						_girar()
				if not landsuper:
					velocity.x = speed
			if duck:
				if SpriteAnimated2D.flip_h == true:
					_girar()
				if not landsuper:
					SpriteAnimated2D.flip_h = false

		elif left:
			if dowt == false and not duck:
				if not super2canflip:
					SpriteAnimated2D.flip_h = true
				if velocity.x == speed:
					if velocity.y == 0:
						_girar()
				if not landsuper:
					velocity.x = -speed
			
				
			if duck:
				if SpriteAnimated2D.flip_h == false:
					_girar()
				if not landsuper:
					SpriteAnimated2D.flip_h = true


		if not left and not right and not landsuper:
			velocity.x = 0
		if player.dir == 2 or player.dir == 4:
			if player.dir == 4:
				SpriteAnimated2D.flip_h = true
				velocity.x = -speed
			if player.dir == 2:
				SpriteAnimated2D.flip_h = false
				velocity.x = speed

		if down:
			if aim == false:
				# Só inicia se ainda não está agachando: antes o _duck_start() era
				# recriado toda frame e o "run" das dir 2/4 interrompia o
				# "duck_start" => animação congelada e o crouch nunca completava.
				if not duck and not duck_start:
					_duck_start()
				# Como no original: agachado não anda — baixo+dir é só pra abaixar
				# (mantém velocity só no ar, onde a diagonal continua valendo).
				if is_on_floor():
					velocity.x = 0
		else:
			duck = false
			duck_start = false

		if up:
			if aim == false:
				uping = true
		else:
			uping = false

		if moving == true:
			if SpriteAnimated2D.animation != "turn" and SpriteAnimated2D.animation != "turn_duck" and SpriteAnimated2D.animation != "turn_shoot" and SpriteAnimated2D.animation != "turn_sdiagup":
				moving = false

		if Input.is_action_pressed("aim"):
			aim = true
		else:
			aim = false

		if velocity.x !=0:
			if $Runtimer.is_stopped():
				$Runtimer.start()

		if not shoot:
			shootdup = false
			$round_1.stop()
			$round_2.stop()
			$round_3.stop()
			$round_4.stop()
			$round_5.stop()
			$round_6.stop()
			$round_7.stop()
			$round_8.stop()
			$round_9.stop()
			$round_10.stop()
			$pea_loop1.stop()
			$pea_loop2.stop()
			$sped_4.stop()
			$sped_3.stop()
			$sped_2.stop()
			$sped_1.stop()
			# pea_start nunca era parado: ao apertar duas vezes rápido as duas
			# variantes ficavam tocando => finished delas chamava loopshoot() 2x
			# => 2 loops de pea tocando junto (som duplicado).
			$pea_start1.stop()
			$pea_start2.stop()

		# 🎯 O som de tiro é tocado UMA única vez, no bloco de "just_pressed" (mais abaixo),
		# para evitar que o mesmo tiro toque o som 2x / vire um loop duplicado.
		if player.actualshoot !=0:
			$pea_loop1.stop()
			$pea_loop2.stop()
			$pea_start1.stop()
			$pea_start2.stop()
		if player.actualshoot !=1:
			$sped_4.stop()
			$sped_3.stop()
			$sped_2.stop()
			$sped_1.stop()
		if player.actualshoot !=2:
			$round_1.stop()
			$round_2.stop()
			$round_3.stop()
			$round_4.stop()
			$round_5.stop()
			$round_6.stop()
			$round_7.stop()
			$round_8.stop()
			$round_9.stop()
			$round_10.stop()
		# 🔊 TROCA DE ARMA ENQUANTO ATIRA: o som de início só era dado no
		# just_pressed, então a arma nova saía MUDA até soltar e apertar de novo.
		# Aqui a gente toca o som da arma recém-escolhida (só se estiver atirando).
		if player.actualshoot != _arm_ante:
			_arm_ante = player.actualshoot
			if shoot:
				_som_inicio_tiro()
		if player.tiro_automatico:
			if Input.is_action_just_pressed("shoot"):
				if shoot:
					if is_instance_valid(shootf):
						shootf.chargex()
					shoot = false
					backsshoot = false
			elif not shoot:
				if not shootdup:
					creation()
				backsshoot = true
				shoot = true
				player.shooting = true
		else:
			if Input.is_action_pressed("shoot"):
				#shoot = true
				if not shootdup:
					if $BGtimre.is_stopped():
						shoot = true
						player.shooting = true
						$BGtimre.start()
						creation()
				backsshoot = true
			
			# 🎯 A MÁGICA ESTÁ AQUI: Só roda no frame exato em que o jogador SOLTAR o botão!
			elif Input.is_action_just_released("shoot"):# Descomentei para parar o timer quando soltar
				backsshoot = false
				shoot = false
				if is_instance_valid(shootf):
					shootf.chargex()
		if Input.is_action_just_pressed("shoot"):
			_som_inicio_tiro()
		# Como no original: no chão o dash tem cooldown de 0,4s;
		# no ar SÓ é permitido 1 dash, até tocar o chão de novo.
		if Input.is_action_just_pressed("dash") and $Dashtimer.is_stopped() and (is_on_floor() or not dash_ar_usado):
			if not is_on_floor():
				dash_ar_usado = true
			dash = true
			dashsound = randi_range(1,3)
			if dashsound == 1:
				$dash1.play()
			if dashsound == 2:
				$dash2.play()
			if dashsound == 3:
				$dash3.play()
			_dash()


		if aim:
			duck = false
			duck_start = false
			if is_on_floor():
				velocity.x = 0

		if not is_on_floor() and not stopall:
			if SpriteAnimated2D.animation == "parry" or SpriteAnimated2D.animation == "parry_axe":
				# Pose de parry (loop=true, sem animation_finished): só sai
				# depois de1 ciclo. Sem isto o else embaixo seria justamente o
				# que impede o "jump" de voltar, e a pose ficaria presa no ar.
				if _parry_pose_frames > 0:
					_parry_pose_frames -= 1
					if _parry_pose_frames == 0:
						SpriteAnimated2D.play("jump")
			elif SpriteAnimated2D.animation != "parred":
				SpriteAnimated2D.play("jump")

#ANIMAÇÕES ////////////////////////////////////////////////
		if is_on_floor() and jumped == false and not stopall:
			if velocity.x == 0:
				if player.actualshoot == 5 and shoot and not duck_start and not moving: SpriteAnimated2D.frame = 0
				if not duck and not duck_start and not up:
					if not shoot and not aim:
						SpriteAnimated2D.play("idle")
					if shoot and not aim:
						SpriteAnimated2D.play("idle_s")
				if duck and moving == false:
					if shoot == false:
						SpriteAnimated2D.play("duck")
					else:
						SpriteAnimated2D.play("duck_s")
				if up and not left and not right:
					if shoot == false:
						SpriteAnimated2D.play("up")
					if shoot:
						SpriteAnimated2D.play("up_s")
				if aim == true:
					if player.dir == 6 or player.dir == 8:
						if not shoot:
							SpriteAnimated2D.play("diagup")
						if shoot:
							SpriteAnimated2D.play("sdiagup")
					if player.dir == 0 or player.dir == 1 or player.dir == 5:
						if not shoot:
							SpriteAnimated2D.play("idle_aim")
						if shoot:
							SpriteAnimated2D.play("idle_s")
					if player.dir == 2 or player.dir == 4:
						if not shoot:
							SpriteAnimated2D.play("diagdown")
						if shoot:
							SpriteAnimated2D.play("sdiagdown")
					if player.dir == 3:
						if not shoot:
							SpriteAnimated2D.play("down")
						if shoot:
							SpriteAnimated2D.play("down_s")
			if velocity.x !=0 and not stopall:
				if moving == false:
					if not shoot:
						SpriteAnimated2D.play("run")
					if shoot:
						if player.dir !=6 and player.dir !=8:
							SpriteAnimated2D.play("run_s")
						else:
							SpriteAnimated2D.play("run_sdiagup")

		if velocity.x !=0:
			if is_on_floor():
				if player.dir == 1:
					$shootap.play("runr")
				if player.dir == 5:
					$shootap.play("runl")
				if player.dir == 6:
					$shootap.play("rundl")
				if player.dir == 8:
					$shootap.play("rundr")
		if velocity.x == 0 or not is_on_floor():
			if player.dir == 0:
				if SpriteAnimated2D.flip_h == false:
					$shootap.play("0")
				else:
					$shootap.play("5")
			if player.dir == 1:
				$shootap.play("1")
			if player.dir == 2:
				if not duck and not duck_start:
					$shootap.play("2")
				else:
					$shootap.play("duckr")
			if player.dir == 3:
				if not duck and not duck_start:
					if SpriteAnimated2D.flip_h:
						$shootap.play("3l")
					else:
						$shootap.play("3")
				else:
					if SpriteAnimated2D.flip_h:
						$shootap.play("duckl")
					else:
						$shootap.play("duckr")
			if player.dir == 4:
				if not duck and not duck_start:
					$shootap.play("4")
				else:
					$shootap.play("duckl")
			if player.dir == 5:
				$shootap.play("5")
			if player.dir == 6:
				$shootap.play("6")
			if player.dir == 7:
				if SpriteAnimated2D.flip_h:
					$shootap.play("7")
				else:
					$shootap.play("7r")
			if player.dir == 8:
				$shootap.play("8")
		if duck_start:
			if SpriteAnimated2D.flip_h:
				pass
			else:
				pass

	if SpriteAnimated2D.animation == "idle_aim":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 15
			SpriteAnimated2D.offset.y = -5
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -15
		SpriteAnimated2D.offset.y = -5
	if SpriteAnimated2D.animation == "idle_s":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 14
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -14
		SpriteAnimated2D.offset.y = -7
	if SpriteAnimated2D.animation == "idle":
		SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 0
	if SpriteAnimated2D.animation == "intro_a":
		SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = -8
	if SpriteAnimated2D.animation == "intro_b":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 9
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -9
		SpriteAnimated2D.offset.y = -47
	if SpriteAnimated2D.animation == "jump":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 3
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -3
		SpriteAnimated2D.offset.y = 10
	if SpriteAnimated2D.animation == "parred":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -3
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 3
		SpriteAnimated2D.offset.y = -4
	if SpriteAnimated2D.animation == "parry":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -4
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 4
		SpriteAnimated2D.offset.y = 11
	if SpriteAnimated2D.animation == "run":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 6
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -6
		SpriteAnimated2D.offset.y = -1
	if SpriteAnimated2D.animation == "run_s":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 10
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -10
		SpriteAnimated2D.offset.y = -1
	if SpriteAnimated2D.animation == "run_sdiagup":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 13
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -13
		SpriteAnimated2D.offset.y = 1
	if SpriteAnimated2D.animation == "scared":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -2
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 2
		SpriteAnimated2D.offset.y = -58
	if SpriteAnimated2D.animation == "sdiagdown":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 9
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -9
		SpriteAnimated2D.offset.y = -7
	if SpriteAnimated2D.animation == "sdiagup":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 6
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -6
		SpriteAnimated2D.offset.y = -1
	if SpriteAnimated2D.animation == "turn":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 6
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -6
		SpriteAnimated2D.offset.y = -1
	if SpriteAnimated2D.animation == "turn_sdiagup":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 20
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -20
		SpriteAnimated2D.offset.y = -8
	if SpriteAnimated2D.animation == "turn_shoot":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 18
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -18
		SpriteAnimated2D.offset.y = -8
	if SpriteAnimated2D.animation == "turn_duck":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 40
	if SpriteAnimated2D.animation == "up":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -10
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 10
		SpriteAnimated2D.offset.y = -14
	if SpriteAnimated2D.animation == "up_s":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -10
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 10
		SpriteAnimated2D.offset.y = -8
	if SpriteAnimated2D.animation == "ghost_revive":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 1
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -1
		SpriteAnimated2D.offset.y = -37
	if SpriteAnimated2D.animation == "ghost":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 3
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -3
		SpriteAnimated2D.offset.y = -31
	if SpriteAnimated2D.animation == "ex_upr":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 3
	if SpriteAnimated2D.animation == "ex_up":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -2
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 2
		SpriteAnimated2D.offset.y = 6
	if SpriteAnimated2D.animation == "ex_idler":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 3
	if SpriteAnimated2D.animation == "ex_idle":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -12
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 12
		SpriteAnimated2D.offset.y = -6
	if SpriteAnimated2D.animation == "ex_downr":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 3
	if SpriteAnimated2D.animation == "ex_down":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = -12
	if SpriteAnimated2D.animation == "ex_diagupr":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 3
	if SpriteAnimated2D.animation == "ex_diagup":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 10
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -10
		SpriteAnimated2D.offset.y = 7
	if SpriteAnimated2D.animation == "ex_diagdownr":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 3
	if SpriteAnimated2D.animation == "ex_diagdown":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 2
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -2
		SpriteAnimated2D.offset.y = 4
	if SpriteAnimated2D.animation == "duck_start":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 3
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -3
		SpriteAnimated2D.offset.y = 12
	if SpriteAnimated2D.animation == "duck_s":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 11
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -11
		SpriteAnimated2D.offset.y = 31
	if SpriteAnimated2D.animation == "duck":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 5
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -5
		SpriteAnimated2D.offset.y = 31
	if SpriteAnimated2D.animation == "down_s":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 1
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -1
		SpriteAnimated2D.offset.y = -5
	if SpriteAnimated2D.animation == "down":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 2
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -2
		SpriteAnimated2D.offset.y = -4
	if SpriteAnimated2D.animation == "diagup":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 6
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -6
		SpriteAnimated2D.offset.y = -1
	if SpriteAnimated2D.animation == "diagdown":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 12
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -12
		SpriteAnimated2D.offset.y = -6
	if SpriteAnimated2D.animation == "death":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 25
	if SpriteAnimated2D.animation == "dash_air":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 14
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -14
		SpriteAnimated2D.offset.y = 5
	if SpriteAnimated2D.animation == "dash":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 25
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -25
		SpriteAnimated2D.offset.y = -8
	if SpriteAnimated2D.animation == "super1":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -2
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 2
		SpriteAnimated2D.offset.y = -46
	if SpriteAnimated2D.animation == "super1_intro":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -2
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 2
		SpriteAnimated2D.offset.y = -46
	if SpriteAnimated2D.animation == "super1_intror":
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -2
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 2
		SpriteAnimated2D.offset.y = -46
	if SpriteAnimated2D.animation == "super2":
		SpriteAnimated2D.offset.y = -61
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -4
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 4
	if SpriteAnimated2D.animation == "super3":
		SpriteAnimated2D.offset.y = -47
		if SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = -1
		if not SpriteAnimated2D.flip_h:
			SpriteAnimated2D.offset.x = 1

		if SpriteAnimated2D.flip_h:
			$Bombam.play("floor_r")
		if not SpriteAnimated2D.flip_h:
			$Bombam.play("floor_l")


#/////////////////////////////////////////////////////////
	move_and_slide()

# Drena as 5 barras do Super I/III. Era um await dentro de _physics_process;
# agora é uma coroutine à parte chamada sem await (dispara e volta no 1º await),
# então _physics_process nunca mais suspende.
func _drena_cartas() -> void:
	exend()
	await $Cardtimer.timeout
	exend()
	await $Cardtimer.timeout
	exend()
	await $Cardtimer.timeout
	exend()
	await $Cardtimer.timeout
	exend()

func _girar():
	if is_on_floor():
		if moving == false:
			if velocity.y == 0:
				moving = true
				if not duck:
					if shoot == false:
						SpriteAnimated2D.play("turn")
					if shoot:
						if player.dir ==6 or player.dir ==8:
							SpriteAnimated2D.play("turn_sdiagup")
						else:
							SpriteAnimated2D.play("turn_shoot")
				else:
					SpriteAnimated2D.play("turn_duck")
				await SpriteAnimated2D.animation_finished
				turnduck.emit()
				moving = false

func _duck_start():
	# Precisa estar no chão E ainda não agachando (evita recriar o coroutine
	# toda frame, que era a causa do travamento da animação).
	if is_on_floor() and not duck and not duck_start:
		duck_start = true
		SpriteAnimated2D.play("duck_start")
		await SpriteAnimated2D.animation_finished
		# Só termina o crouch se ainda estiver segurando pra baixo:
		# se soltar no meio da animação, ele não pode agachar sozinho.
		if down and not aim:
			duck = true
		duck_start = false

func _intro():
	if player.boss: await gvar.abr
	stopall = true
	# CORREÇÃO: enquanto stopall/gvar.stopall estão ativos o bloco de movimento
	# inteiro (linha ~425) fica congelado, inclusive o "velocity.x = 0". Se o
	# jogador tivesse andado antes do iris abrir, a velocity.x residual ficava
	# presa e o Cuphead DESLIZAVA pela tela durante o intro/READY com a animação
	# de idle (parecia que "andava sozinho" ou "mexia travado"). Todos os outros
	# pontos que ligavam stopall já zeravam a velocidade; faltava aqui.
	velocity.x = 0
	SpriteAnimated2D.play("idle")
	if player.scared == false:
		if startboss == 1:
			await get_tree().create_timer(0.5).timeout
			SpriteAnimated2D.play("intro_a")
			$intro_a.play()
		if startboss == 2:
			await get_tree().create_timer(0.5).timeout
			SpriteAnimated2D.play("intro_b")
	else:
		SpriteAnimated2D.play("scared")
	await SpriteAnimated2D.animation_finished
	SpriteAnimated2D.play("idle")
	stopall = false

func _dash():
	moving = false
	stopall = true
	duck = false
	duck_start = false
	aim = false
	shoot = false
	velocity.y = 0
	var bomb = smokecreator.instantiate()
	if player.relic == 4:
		add_child(bomb)
		bomb.offset.y = -100
		bomb.scale.x = 0.5
		bomb.scale.y = 0.5
		bomb.offset.x = 3
		bomb.play("smoke" + str(randi_range(1,2)))
		bomb.global_position = $Bomb.global_position
	else:
		add_child(bomb)
		bomb.offset.y = -60
		bomb.play("dash")
		bomb.offset.x = 0
		bomb.global_position = $Bomb.global_position
	if SpriteAnimated2D.flip_h:
		$Bombam.play("floor_l")
	if not SpriteAnimated2D.flip_h:
		$Bombam.play("floor_r")
	if is_on_floor():
		SpriteAnimated2D.play("dash")
	if not is_on_floor():
		SpriteAnimated2D.play("dash_air")
	if SpriteAnimated2D.flip_h == false:
		velocity.x = 800
		bomb.flip_h = false
	else:
		velocity.x = -800
		bomb.flip_h = true
	if player.relic == 4:
		invencible = true
		SpriteAnimated2D.visible = false
	await SpriteAnimated2D.animation_finished
	invencible = false
	if player.relic == 4:
		bomb = smokecreator.instantiate()
		add_child(bomb)
		bomb.scale.x = 0.5
		bomb.scale.y = 0.5
		bomb.frame = 0
		bomb.offset.y = -100
		bomb.offset.x = 0
		bomb.play("smoke" + str(randi_range(1,2)))
		bomb.global_position = $Bomb.global_position
		SpriteAnimated2D.visible = true
	velocity.x = 0
	if not bex:
		stopall = false
	dash = false
	$Dashtimer.start()
	checkshoot()

func _bex():
	SpriteAnimated2D.stop()
	# Garante frame 0: se a animação anterior terminou no frame 14 e for
	# reutilizada (ex: dois EX seguidos), o gatilho "frame >= 7" dispararia
	# já na primeira frame do novo EX.
	SpriteAnimated2D.frame = 0
	SpriteAnimated2D.visible = true
	bex = true
	# Reinicia os gatilhos do EX (frame >= 7 é disparado uma única vez por uso).
	bex_spawn = false
	bex_gasto = false
	stopall = true
	dash = false
	shoot = false
	aim = false
	duck = false
	duck_start = false
	velocity.x = 0
	velocity.y = 0
	if player.supercarged:
		if player.special == 1:
			var super1sound = randi_range(1,4)
			super1sound = randi_range(1,4)
			invencible = true
			get_node("super1_intro" + str(super1sound)).play()
			if is_on_floor():
				SpriteAnimated2D.play("super1_intro")
			if not is_on_floor():
				SpriteAnimated2D.play("super1_intror")
			await SpriteAnimated2D.animation_finished
			SpriteAnimated2D.play("super1")
			await get_node("super1_intro" + str(super1sound)).finished
			$super1_loop.play()
		if player.special == 2:
			$super2.play()
			SpriteAnimated2D.play("super2")
			invencible = true
			super2ative = true
			# Cada Super II zera a trava para poder gastar as cartas de novo.
			super2_gastou_cartas = false
		if player.special == 3:
			$super3.play()
			SpriteAnimated2D.play("super3")
			invencible = true
	elif not player.supercarged:
		var fxe = preload("res://Scenes/Player/exfx.tscn")
		var fxex = fxe.instantiate()
		fxex.is_charge = 1
		add_child(fxex)
		fxex.global_position = SpriteAnimated2D.global_position
		if player.dir == 0 or player.dir == 1 or player.dir == 5:
			if is_on_floor():
				SpriteAnimated2D.play("ex_idle")
			else:
				SpriteAnimated2D.play("ex_idler")
		elif player.dir == 7:
			if is_on_floor():
				SpriteAnimated2D.play("ex_up")
			else:
				SpriteAnimated2D.play("ex_upr")
		elif player.dir == 3:
			if is_on_floor():
				SpriteAnimated2D.play("ex_down")
			else:
				SpriteAnimated2D.play("ex_downr")
		elif player.dir == 6 or player.dir == 8:
			if is_on_floor():
				SpriteAnimated2D.play("ex_diagup")
			else:
				SpriteAnimated2D.play("ex_diagupr")
		elif player.dir == 2 or player.dir == 4:
			if is_on_floor():
				SpriteAnimated2D.play("ex_diagdown")
			else:
				SpriteAnimated2D.play("ex_diagdownr")
	await SpriteAnimated2D.animation_finished
	invencible = false
	$Extimer.start()
	befx = false
	stopall = false
	bex = false
	if not super2ative:
		checkshoot()

# Como no original: o golpe/animação de parry SÓ acontece se houver um
# objeto rosa (ou o machado do Whetstone num inimigo) alcançável AGORA.
func _tem_alvo_de_parry() -> bool:
	for area in $parry.get_overlapping_areas():
		if not is_instance_valid(area):
			continue
		if $Parrytimer.is_stopped() and area.is_in_group("parryavel"):
			return true
		if player.relic == 5 and candashoraxe and $Parrytimer.is_stopped() and area.is_in_group("dano"):
			return true
	return false

# Duracao REAL (em segundos) de uma animacao do sprite.
# "parry" e "parry_axe" tem loop=true, entao NUNCA emitem "animation_finished"
# - nao da pra esperar o sinal, tem que esperar a duracao delas (8 quadros a
# 24fps = 0,333s = 20 frames de fisica a 60Hz).
func _dur_anim_seg(anim: StringName) -> float:
	var sf = SpriteAnimated2D.get_sprite_frames()
	if sf == null or not sf.has_animation(anim):
		return 0.34
	var fps := float(sf.get_animation_speed(anim))
	if fps <= 0.0:
		return 0.34
	return float(sf.get_frame_count(anim)) / fps

# A mesma duracao convertida em frames de FISICA (o contador que segura a pose
# e decrementado uma vez por _physics_process, nao por quadro de animacao).
func _dur_anim_fisica(anim: StringName) -> int:
	return int(ceil(_dur_anim_seg(anim) * float(Engine.physics_ticks_per_second)))

# A TAPA de parry: dá a animação ("parry", ou "parry_axe" com o Whetstone) e
# deixa o _checkparry() decidir se o parry roda de verdade — lá dentro ele só
# age em objeto rosa (ou machado, relic 5). Se o parry NÃO acontecer, a pose é
# segurada por UMA DURAÇÃO COMPLETA da animação e depois volta pro pulo:
# "parry" tem loop=true, nunca emite "animation_finished", e o guard de animação
# segura o "jump" — sem o contador a pose ficaria presa até pousar.
func _tapa_de_parry() -> void:
	if player.relic !=5:
		SpriteAnimated2D.play("parry")
	else:
		SpriteAnimated2D.play("parry_axe")
	parrysound = randi_range(1,2)
	_checkparry()
	if SpriteAnimated2D.animation == "parry_axe" or \
			(SpriteAnimated2D.animation == "parry" and not _parry_conseguido):
		_parry_pose_frames = _dur_anim_fisica(SpriteAnimated2D.animation)

func _checkparry():
	var areas = $parry.get_overlapping_areas()
	var slap = parryslap.instantiate()
	_parry_conseguido = false
	for area in areas:
		if is_instance_valid(area) and area.is_in_group("parryavel"):
			if $Parrytimer.is_stopped():
				_parry_conseguido = true
				parring = true
				parrysound = randi_range(1,2)
				get_node("parry" + str(parrysound)).play()
				get_node("parry_hit" + str(parrysound)).play()
				_parry(area)
				add_child(slap)
				slap.play("normal")
				slap.global_position = area.global_position
				slap.z_index = -2
				if player.relic !=5:
					SpriteAnimated2D.play("parred")
				Engine.time_scale = 0
				# IMPORTANTE: O timer precisa ignorar o time_scale, senão ele também fica lento!
				await get_tree().create_timer(0.07, true, false, true).timeout
				Engine.time_scale = 1.0
				parring = false
				await SpriteAnimated2D.animation_finished
				if player.relic !=5:
					SpriteAnimated2D.play("jump")
# === ADICIONE O IS_INSTANCE_VALID COLOCO LOGO NO INÍCIO DO IF ===
		if is_instance_valid(area) and area.is_in_group("dano") and candashoraxe:
			if player.relic == 5:
				if $Parrytimer.is_stopped():
					_parry_conseguido = true
					candashoraxe = false
					if area.has_method("dano"):
						area.dano(16)
					parring = true
					parrysound = randi_range(1,3)
					get_node("parry_axe_" + str(parrysound)).play()
					parrysound = randi_range(1,2)
					get_node("parry" + str(parrysound)).play()
					_parry(area)
					add_child(slap)
					slap.play("axe")
					slap.global_position = area.global_position
					slap.z_index = -2
					Engine.time_scale = 0
					# IMPORTANTE: O timer precisa ignorar o time_scale, senão ele também fica lento!
					await get_tree().create_timer(0.07, true, false, true).timeout
					Engine.time_scale = 1.0
					parring = false
func _parry(area):
	velocity.y = -1350
	$Parrytimer.start()
	if area.has_method("parry"):
		print("parry!")
		area.parry()
		if player.cardcont == 5:
			$card_max.play()
		if not stopall and not super2card:
			if player.cardcont >23:
				if player.special !=0:
					player.supercarged = true
			upcard = true
			addcard()
			await $Cardtimer.timeout
			if not bex:
				addcard()
			await $Cardtimer.timeout
			if not bex:
				addcard()
			await $Cardtimer.timeout
			if not bex:
				addcard()
			await $Cardtimer.timeout
			if not bex:
				addcard()
			await $Cardtimer.timeout
			if not bex:
				addcard()
			await $Cardtimer.timeout
			addingcard = false

func addcard():
	addingcard = true
	$Cardtimer.wait_time = 0.05
	$Cardtimer.start()
	player.card()
	player.carddiminuiu = false


func mncard():
	$Cardtimer.start()
	player._card()
	player.carddiminuiu = true
	await $Cardtimer.timeout
	player.carddiminuiu = false

func creation():
	# 1. Se o tiro antigo morreu (não é válido) ou nunca foi criado, instanciamos um NOVO!
	if not is_instance_valid(shootf):
		# RECOMENDADO: Substitua 'CENA_DO_SEU_SHOTCREATOR' pela variável do seu preload/export da cena .tscn
		# Exemplo se você tiver um preload: shootf = preload("res://caminho/shotcreator.tscn").instantiate()
		if has_node("shotcreator"): 
			shootf = get_node("shotcreator") # Tenta readquirir se ele já existir na árvore
		else:
			# Se você tiver a variável da cena guardada, use ela aqui para recriar:
			shootf = shotcreator.instantiate()
			#return # Remova esse return após colocar a sua variável de instância acima
	
	# 2. Agora que garantimos que o shootf existe e é válido, o código roda normalmente:
	if is_instance_valid(shootf):
		if not has_node("shotcreator"):
			add_child(shootf)
		shootf.global_position = $shootm.global_position
		shootdup = true

func checkshoot():
	if backsshoot == true:
		shoot = true
		backsshoot = false
		shootdup = false
		creation()
		# Mesmo caminho do just_pressed: para as variantes da mesma arma antes
		# de tocar a nova (senão o sped sorteado diferente duplicava o som, e o
		# "if not playing" engolia o pea_start que ainda estava tocando).
		_som_inicio_tiro()


# 🔊 Toca o som de INÍCIO da arma atual — UMA variante só por arma.
# Usado no just_pressed, na troca de arma e no checkshoot() (dash/EX/dano),
# pra os três casos tomarem exatamente a mesma decisão de som.
func _som_inicio_tiro() -> void:
	if player.actualshoot == 0:
		$pea_start1.stop()
		$pea_start2.stop()
		# O loop também: senão o start recomeçaria POR CIMA do loop que ainda
		# rodava (dois sons da mesma arma ao mesmo tempo = "duplicado").
		$pea_loop1.stop()
		$pea_loop2.stop()
		startshootsound = randi_range(1,2)
		get_node("pea_start" + str(startshootsound)).play()
	elif player.actualshoot == 1:
		# Para TODAS as variantes antes de sortear: senão a que já tocava e a
		# nova sorteada rodavam junto = som duplicado.
		$sped_1.stop()
		$sped_2.stop()
		$sped_3.stop()
		$sped_4.stop()
		startshootsound = randi_range(1,4)
		get_node("sped_" + str(startshootsound)).play()
	elif player.actualshoot == 2:
		# roundabout: mata qualquer corrente de await pendente e recomeça
		# do round_1 (um round_* parado no meio nunca emite "finished", então
		# a corrente velha fica suspensa e aborta quando acordar).
		_round_gen += 1
		var i = 1
		while i <= 10:
			get_node("round_" + str(i)).stop()
			i += 1
		$round_1.play()


func _ao_pousar():
	if landsuper:
		super2canflip = false
		velocity.x = 0
		landsuper = false
	landsound = randi_range(1,2)
	get_node("land" + str(landsound)).play()
	var bomb = smokecreator.instantiate()
	add_child(bomb)
	bomb.offset.y = -60
	if SpriteAnimated2D.flip_h:
		bomb.offset.x = -55
	if not SpriteAnimated2D.flip_h:
		bomb.offset.x = 55
	bomb.play("jump")
	bomb.global_position = $Bomb.global_position


func _on_runtimer_timeout() -> void:
	var bomb = smokecreator.instantiate()
	var walkanim = randi_range(1,6)
	if velocity.y == 0 and not stopall and not dash:
		if velocity.x !=0:
			add_child(bomb)
			if walkanim == 1:
				bomb.play("walk_1")
			if walkanim == 2:
				bomb.play("walk_2")
			if walkanim == 3:
				bomb.play("walk_3")
			if walkanim == 4:
				bomb.play("walk_4")
			if walkanim == 5:
				bomb.play("walk_5")
			if walkanim == 6:
				bomb.play("walk_6")
			bomb.offset.y = -60
			bomb.offset.x = 0
			bomb.global_position = $Bomb.global_position
			$Runtimer.start()

func loopshoot():
	if player.actualshoot == 0:
		# Para os DOIS loops antes de escolher: pea_start1 e pea_start2 podiam
		# terminar quase juntos e cada um chamar loopshoot() => dois pea_loop
		# tocando ao mesmo tempo (som duplicado).
		$pea_loop1.stop()
		$pea_loop2.stop()
		shootsound = randi_range(1,2)
		get_node("pea_loop" + str(shootsound)).play()


func _on_pea_loop_1_finished() -> void:
	$pea_loop2.play()


func _on_pea_loop_2_finished() -> void:
	$pea_loop1.play()


func _on_pea_start_1_finished() -> void:
	loopshoot()


func _on_pea_start_2_finished() -> void:
	loopshoot()

func _on_sped_4_finished() -> void:
	$sped_1.play()





func excreate(ex, fxex):
	player.dir = savedir
	if player.dir == 6:
		if ex !=null:
			ex.rotation_degrees = 210
		fxex.rotation_degrees = 210
	if player.dir == 1:
		if ex !=null:
			ex.rotation_degrees = 0
		fxex.rotation_degrees = 0
	if player.dir == 8:
		if ex !=null:
			ex.rotation_degrees = -30
		fxex.rotation_degrees = -30
	if player.dir == 7:
		if ex !=null:
			ex.rotation_degrees = -90
		fxex.rotation_degrees = -90
	if player.dir == 0:
		
		if player.mirror:
			if ex !=null:
				ex.rotation_degrees = 180
			fxex.rotation_degrees = 180
		else:
			if ex !=null:
				ex.rotation_degrees = 0
			fxex.rotation_degrees = 0
	if player.dir == 3:
		if not player.duck:
			if ex !=null:
				ex.rotation_degrees = 90
			fxex.rotation_degrees = 90
		else:
			if player.mirror:
				if ex !=null:
					ex.rotation_degrees = 180
				fxex.rotation_degrees = 180
			else:
				if ex !=null:
					ex.rotation_degrees = 0
				fxex.rotation_degrees = 0
	if player.dir == 5:
		if ex !=null:
			ex.rotation_degrees = 180
		fxex.rotation_degrees = 180
	if player.dir == 2:
		if not player.duck:
			if ex !=null:
				ex.rotation_degrees = 30
			fxex.rotation_degrees = 30
		else:
			if ex !=null:
				ex.rotation_degrees = 0
			fxex.rotation_degrees = 0
	if player.dir == 4:
		if not player.duck:
			if ex !=null:
				ex.rotation_degrees = 140
			fxex.rotation_degrees = 140
		else:
			if ex !=null:
				ex.rotation_degrees = 180
			fxex.rotation_degrees = 180

func exend():
	mncard()
	await $Cardtimer.timeout
	mncard()
	await $Cardtimer.timeout
	mncard()
	await $Cardtimer.timeout
	mncard()
	await $Cardtimer.timeout
	mncard()
	await $Cardtimer.timeout
	mncard()
	await $Cardtimer.timeout

func _on_super_1_loop_finished() -> void:
	var super1stop = randi_range(1,4)
	super1stop = randi_range(1,4)
	get_node("super1_stop" + str(super1stop)).play()

func super2jump(ex):
	await player.super2jump
	super2card = true
	shoot = false
	
	landsuper = true
	super2canflip = true
	velocity.x = 0
	ex.z_index = -1
	bex = false
	stopall = false
	superative = false
	super2ative = false
	if SpriteAnimated2D.flip_h:
		velocity.x = -400
	if not SpriteAnimated2D.flip_h:
		velocity.x = 400
	velocity.y = -1500
	SpriteAnimated2D.material.set_shader_parameter("ativo", true)
	$Cardtimer.wait_time = 0.2
	await get_tree().create_timer(0.5).timeout
	super2card = true
	player.super2card = true
	super2canflip = false
	velocity.x = 0
	landsuper = false
	checkshoot()
	# Super II: aqui o personagem fica DOURADO (shader "ativo"), então é a partir
	# de agora que as cartas começam a ser gastas — 1 barra (exend) por segundo,
	# durante os ~5s do estado dourado. Total: 5 barras (30 cartas), como nos
	# outros supers, mas nunca mais todas de uma vez no início.
	if super2_gastou_cartas:
		# Sinal duplicado: não cobra as cartas de novo, só espera o tempo normal.
		await get_tree().create_timer(5).timeout
	else:
		super2_gastou_cartas = true
		exend()
		await get_tree().create_timer(1).timeout
		exend()
		await get_tree().create_timer(1).timeout
		exend()
		await get_tree().create_timer(1).timeout
		exend()
		await get_tree().create_timer(1).timeout
		exend()
		await get_tree().create_timer(1).timeout
	super2card = false
	invencible = false
	player.super2card = false
	SpriteAnimated2D.material.set_shader_parameter("ativo", false)




func _on_sped_1_finished() -> void:
	$sped_2.play()



func _on_sped_2_finished() -> void:
	$sped_3.play()


func _on_sped_3_finished() -> void:
	$sped_4.play()



func _on_round_1_finished() -> void:
	# Corrente "viva": cada novo round_1.play() sobe _round_gen e faz as
	# correntes velhas abortarem. Sem isto, um stop() no meio do caminho
	# deixava a corrente antiga suspensa no await; quando o mesmo round_N
	# tocava de novo ela acordava e jogava o som em cima da corrente nova
	# = roundabout com som duplicado (dava depois de EX/dash/dano).
	_round_gen += 1
	var gen = _round_gen
	var n = 2
	while n <= 10:
		if gen != _round_gen:
			return # corrente mais nova assumiu: sai sem tocar nada
		var no := get_node("round_" + str(n)) as AudioStreamPlayer2D
		no.play()
		await no.finished
		n += 1
	if gen != _round_gen:
		return
	if shoot and player.actualshoot == 2:
		$round_1.play()
	return


func _on_dmgarea_area_entered(area: Area2D) -> void:
	if invencible == false and not super2card:
		if area.is_in_group("levar dano"):
			damg = true
			bex = false
			dash = false
			player.hp -=1
			print("dano")
			if player.hp <1:
				die()
				return
			stopall = true
			# i-frames IMEDIATOS ao levar dano: evita dano duplo durante o knockback (como no original)
			invencible = true
			if is_on_floor():
				SpriteAnimated2D.play("hit")
			if not is_on_floor():
				SpriteAnimated2D.play("hit_air")
			# 1. Escolhe o número aleatório de 1 a 5
			var numero_aleatorio = randi_range(1, 5)
			numero_aleatorio = randi_range(1, 5)
			# 2. Junta o texto com o número para achar o nó e dá Play!
			get_node("hit_" + str(numero_aleatorio)).play()
			velocity.y = -300
			if SpriteAnimated2D.flip_h:
				velocity.x = 250
			if not SpriteAnimated2D.flip_h:
				velocity.x = -250
			var numero_aleatori1o = randi_range(1, 4)
			numero_aleatori1o = randi_range(1, 4)
			# 2. Junta o texto com o número para achar o nó e dá Play!
			get_node("crack_" + str(numero_aleatori1o)).play()
			await SpriteAnimated2D.animation_finished
			stopall = false
			checkshoot()
			dano()
			damg = false

func die():
	var numero_aleatorio = randi_range(1, 5)
	numero_aleatorio = randi_range(1, 5)
	# 2. Junta o texto com o número para achar o nó e dá Play!
	get_node("hit_" + str(numero_aleatorio)).play()
	stopall = true
	dieg = true
	velocity.y = 0
	velocity.x = 0
	SpriteAnimated2D.play("death")
	await SpriteAnimated2D.animation_finished
	var numero = randi_range(1, 2)
	numero = randi_range(1, 2)
	# 2. Junta o texto com o número para achar o nó e dá Play!
	get_node("death_" + str(numero)).play()
	stopall = true
	velocity.y = -200
	velocity.x = 0
	SpriteAnimated2D.play("ghost")
	await  get_tree().create_timer(6).timeout
	# Revive: volta a vida MÁXIMA (base 3 + bônus da relíquia de coração).
	# Usa a mesma fonte do HUD (player.hp_max()) pra nunca divergir.
	player.hp = player.hp_max()
	player.cards = 0
	player.cardcont = 0
	get_tree().reload_current_scene()

func dano():
	indano = true
	if not super2card:
		# i-frames de ~2s: 4 piscadas de 0,5s (0,25s invisível + 0,25s visível).
		for i in range(4):
			SpriteAnimated2D.visible = false
			await  get_tree().create_timer(0.25).timeout
			SpriteAnimated2D.visible = true
			await  get_tree().create_timer(0.25).timeout
		if not super2card:
			invencible = false
	indano = false
