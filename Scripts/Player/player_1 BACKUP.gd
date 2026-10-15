extends CharacterBody2D
# Direção atual do joystick (0 = solto, 1-8 = 8 direções)
# 1 = Direita, 2 = Baixo-Direita, 3 = Baixo, 4 = Baixo-Esquerda
# 5 = Esquerda, 6 = Cima-Esquerda, 7 = Cima, 8 = Cima-Direita
var duck = false
var duck_start = false
var up = false
var down = false
var updo = false
var left = false
var right = false
var leri = false
var shoot = false
var aim = false
var mobile = false
var moving = false
var gravity = 5000
var jump_str = -1350
var speed = 400
var mov_up = false
var jumped = false
var jumpcor = false
var dowt = false
var uping = false
var stopspamjump = false
var startboss = randi_range(1, 2)
var stopall = false
var dash = false
var bex = false
var superart = 0 #0 = none 1= I 2=II 3=III
var hit = false
var was_in_air = false # Coloque no topo do script
var reliq = 0 # 0 =none 1 =1hp 2=2hp 3=coffe 4=smokebomb
var parryslap = preload("res://Scenes/objects/test/parryslap.tscn")
var shotcreator = preload("res://Scenes/Player/shoots/shotcreator.tscn")
var peashotex = preload("res://Scenes/Player/shoots/peashooter_ex.tscn")
var smokecreator = preload ("res://Scenes/Player/smoke.tscn")
var super1 = preload("res://Scenes/Player/super_1.tscn")
var jumpsound = randi_range(1,3)
var parrysound = randi_range(1,2)
var cardsound = randi_range(1,2)
var dashsound = randi_range(1,3)
var landsound = randi_range(1,2)
var startshootsound = randi_range(1,2)
var shootsound = randi_range(1,2)
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
var invencible = false
var parring = false
@onready var SpriteAnimated2D = $AnimatedSprite2D
func _ready() -> void:
	if player.boss == true:
		_intro()
@onready var player_sprite = $AnimatedSprite2D
@onready var glow = 0

func _physics_process(delta: float) -> void:
	
	#low.animation = player_sprite.animation
	#glow.frame = player_sprite.frame
	#glow.flip_h = player_sprite.flip_h
	#glow.offset = player_sprite.offset
	if super2ative:
		stopall = true
	if bex:
		if not superative and not super2ative:
			if $AnimatedSprite2D.frame == 7:
				if player.actualshoot == 0:
					var ex = peashotex.instantiate()
					get_parent().add_child(ex)
					ex.global_position = $Ex.global_position
					excreate(ex)
		else:
			if $AnimatedSprite2D.frame == 7:
				var ex = super2.instantiate()
				if ex.frame == 19:
					if player.special == 2 and superative:
						super2jump(ex)
						ex.z_index = -1
						velocity.y = -1500
				if player.special == 1:
					ex = super1.instantiate()
					get_parent().add_child(ex)
					ex.global_position = $Super1.global_position
				if player.special == 3:
					ex = super3.instantiate()
					get_parent().add_child(ex)
					ex.global_position = SpriteAnimated2D.global_position
				if player.special == 2 and $AnimatedSprite2D.animation == "super2":
					ex.position()
					ex = super2.instantiate()
					get_parent().add_child(ex)
					ex.z_index = 1
					ex.global_position = $AnimatedSprite2D.global_position
					ex.global_position.y += -70
					playerpos = $AnimatedSprite2D.global_position
					player.heposition = ex.heposition
					ex.flip_h = $AnimatedSprite2D.flip_h
					super2jump(ex)
					$AnimatedSprite2D.play("jump")
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
	if stopall:
		$pea_loop1.stop()
		$pea_loop2.stop()
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
	if $AnimatedSprite2D.flip_h == true:
		$Super2.play("L")
		player.mirror = true
	else:
		$Super2.play("R")
		player.mirror = false
	if player.cards == 30 and player.special !=0:
		superative = true
	else:
		superative = false
	if Input.is_action_just_pressed("B move") and $Extimer.is_stopped() and not bex and not gvar.desatshots and not super2card:
		if player.cards >5:
			_bex()  
			if player.special == 0 or player.cards <30:
				savedir = player.dir
				if savedir != 0:
					$Exam.play(str(savedir))
					befx = true
				if savedir == 0:
					if $AnimatedSprite2D.flip_h:
						$Exam.play("5")
					else:
						$Exam.play("0")
				
	if $AnimatedSprite2D.frame == 7 and bex:
		if not superative:
			$Cardtimer.wait_time = 0.05
			exend() 
		else:
			if player.special == 1 :
				$Cardtimer.wait_time = 0.1
			if player.special !=2:
				exend()
				await $Cardtimer.timeout
				exend()
				await $Cardtimer.timeout
				exend()
				await $Cardtimer.timeout
				exend()
				await $Cardtimer.timeout
				exend()
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



	if not stopall and not gvar.stopall:
		gravity = 5000 * delta
		if not is_on_floor():
			velocity.y += gravity
			duck = false
			duck_start = false
		else:
			if not landsuper:
				velocity.y = 0
				stopspamjump = false




		if Input.is_action_just_pressed("jump") and jumped == false:
			if is_on_floor():
				jumpsound = randi_range(1,3)
				jumped = true
				velocity.y = jump_str
				if velocity.y !=0:
					$AnimatedSprite2D.play("jump")
				if jumpsound == 1:
					$jump1.play()
				if jumpsound == 2:
					$jump2.play()
				if jumpsound == 3:
					$jump3.play()
			if not is_on_floor():
				$AnimatedSprite2D.play("parry")
				parrysound = randi_range(1,2)
				_checkparry()

		if jumped == true:
			if not is_on_floor():
				jumped = false

		if Input.is_action_just_released("jump"):
			if velocity.y !=0:
				velocity.y = velocity.y * 0.5

		if right:
			if dowt == false and not duck:
				if not super2canflip:
					$AnimatedSprite2D.flip_h = false
				if velocity.x == -speed:
					if velocity.y == 0:
						_girar()
				if not landsuper:
					velocity.x = speed
			if duck:
				if $AnimatedSprite2D.flip_h == true:
					_girar()
				if not landsuper:
					$AnimatedSprite2D.flip_h = false

		if left:
			if dowt == false and not duck:
				if not super2canflip:
					$AnimatedSprite2D.flip_h = true
				if velocity.x == speed:
					if velocity.y == 0:
						_girar()
				if not landsuper:
					velocity.x = -speed
			
				
			if duck:
				if $AnimatedSprite2D.flip_h == false:
					_girar()
				if not landsuper:
					$AnimatedSprite2D.flip_h = true


		if not left and not right and not landsuper:
			velocity.x = 0
		if player.dir == 2 or player.dir == 4:
			if is_on_floor():
				velocity.x = 0
			else:
				if player.dir == 4:
					velocity.x = -speed
				if player.dir == 2:
					velocity.x = speed

		if down:
			if aim == false:
				if not duck:
					_duck_start()
		else:
			duck = false
			duck_start = false

		if up:
			if aim == false:
				uping = true
		else:
			uping = false

		if moving == true:
			if $AnimatedSprite2D.animation != "turn" and $AnimatedSprite2D.animation != "turn_duck" and $AnimatedSprite2D.animation != "turn_shoot" and $AnimatedSprite2D.animation != "turn_sdiagup":
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
			$pea_loop1.stop()
			$pea_loop2.stop()

		if Input.is_action_just_pressed("shoot") and not gvar.desatshots:
			if shoot:
				shoot = false
				backsshoot = false
			else:
				backsshoot = true
				shoot = true
				if not shootdup:
					creation()
				if player.actualshoot == 0:
					startshootsound = randi_range(1,2)
					if startshootsound == 1:
						$pea_start1.play()
						
					if startshootsound == 2:
						$pea_start2.play()
						

		if Input.is_action_just_pressed("dash") and $Dashtimer.is_stopped():
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
			if $AnimatedSprite2D.animation != "parry" and $AnimatedSprite2D.animation != "parred":
				$AnimatedSprite2D.play("jump")

#ANIMAÇÕES ////////////////////////////////////////////////
		if is_on_floor() and jumped == false and not stopall:
			if velocity.x == 0:
				if not duck and not duck_start and not up:
					if not shoot and not aim:
						$AnimatedSprite2D.play("idle")
					if shoot and not aim:
						$AnimatedSprite2D.play("idle_s")
				if duck and moving == false:
					if shoot == false:
						$AnimatedSprite2D.play("duck")
					else:
						$AnimatedSprite2D.play("duck_s")
				if up and not left and not right:
					if shoot == false:
						$AnimatedSprite2D.play("up")
					if shoot:
						$AnimatedSprite2D.play("up_s")
				if aim == true:
					if player.dir == 6 or player.dir == 8:
						if not shoot:
							$AnimatedSprite2D.play("diagup")
						if shoot:
							$AnimatedSprite2D.play("sdiagup")
					if player.dir == 0 or player.dir == 1 or player.dir == 5:
						if not shoot:
							$AnimatedSprite2D.play("idle_aim")
						if shoot:
							$AnimatedSprite2D.play("idle_s")
					if player.dir == 2 or player.dir == 4:
						if not shoot:
							$AnimatedSprite2D.play("diagdown")
						if shoot:
							$AnimatedSprite2D.play("sdiagdown")
					if player.dir == 3:
						if not shoot:
							$AnimatedSprite2D.play("down")
						if shoot:
							$AnimatedSprite2D.play("down_s")
			if velocity.x !=0 and not stopall:
				if moving == false:
					if not shoot:
						$AnimatedSprite2D.play("run")
					if shoot:
						if player.dir !=6 and player.dir !=8:
							$AnimatedSprite2D.play("run_s")
						else:
							$AnimatedSprite2D.play("run_sdiagup")

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
				if $AnimatedSprite2D.flip_h == false:
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
					if $AnimatedSprite2D.flip_h:
						$shootap.play("3l")
					else:
						$shootap.play("3")
				else:
					if $AnimatedSprite2D.flip_h:
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
				if $AnimatedSprite2D.flip_h:
					$shootap.play("7")
				else:
					$shootap.play("7r")
			if player.dir == 8:
				$shootap.play("8")
		if duck_start:
			if $AnimatedSprite2D.flip_h:
				pass
			else:
				pass

	if $AnimatedSprite2D.animation == "idle_aim":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 15
			$AnimatedSprite2D.offset.y = -5
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -15
		$AnimatedSprite2D.offset.y = -5
	if $AnimatedSprite2D.animation == "idle_s":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 14
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -14
		$AnimatedSprite2D.offset.y = -7
	if $AnimatedSprite2D.animation == "idle":
		$AnimatedSprite2D.offset.x = 0
		$AnimatedSprite2D.offset.y = 0
	if $AnimatedSprite2D.animation == "intro_a":
		$AnimatedSprite2D.offset.x = 0
		$AnimatedSprite2D.offset.y = -8
	if $AnimatedSprite2D.animation == "intro_b":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 9
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -9
		$AnimatedSprite2D.offset.y = -47
	if $AnimatedSprite2D.animation == "jump":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 3
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -3
		$AnimatedSprite2D.offset.y = 10
	if $AnimatedSprite2D.animation == "parred":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -3
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 3
		$AnimatedSprite2D.offset.y = -4
	if $AnimatedSprite2D.animation == "parry":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -4
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 4
		$AnimatedSprite2D.offset.y = 11
	if $AnimatedSprite2D.animation == "run":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 6
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -6
		$AnimatedSprite2D.offset.y = -1
	if $AnimatedSprite2D.animation == "run_s":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 10
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -10
		$AnimatedSprite2D.offset.y = -1
	if $AnimatedSprite2D.animation == "run_sdiagup":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 13
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -13
		$AnimatedSprite2D.offset.y = 1
	if $AnimatedSprite2D.animation == "scared":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -2
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 2
		$AnimatedSprite2D.offset.y = -58
	if $AnimatedSprite2D.animation == "sdiagdown":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 9
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -9
		$AnimatedSprite2D.offset.y = -7
	if $AnimatedSprite2D.animation == "sdiagup":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 6
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -6
		$AnimatedSprite2D.offset.y = -1
	if $AnimatedSprite2D.animation == "turn":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 6
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -6
		$AnimatedSprite2D.offset.y = -1
	if $AnimatedSprite2D.animation == "turn_sdiagup":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 20
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -20
		$AnimatedSprite2D.offset.y = -8
	if $AnimatedSprite2D.animation == "turn_shoot":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 18
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -18
		$AnimatedSprite2D.offset.y = -8
	if $AnimatedSprite2D.animation == "turn_duck":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		$AnimatedSprite2D.offset.y = 40
	if $AnimatedSprite2D.animation == "up":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -10
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 10
		$AnimatedSprite2D.offset.y = -14
	if $AnimatedSprite2D.animation == "up_s":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -10
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 10
		$AnimatedSprite2D.offset.y = -8
	if $AnimatedSprite2D.animation == "ghost_revive":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 1
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -1
		$AnimatedSprite2D.offset.y = -37
	if $AnimatedSprite2D.animation == "ghost":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 3
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -3
		$AnimatedSprite2D.offset.y = -31
	if $AnimatedSprite2D.animation == "ex_upr":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		$AnimatedSprite2D.offset.y = 3
	if $AnimatedSprite2D.animation == "ex_up":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -2
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 2
		$AnimatedSprite2D.offset.y = 6
	if $AnimatedSprite2D.animation == "ex_idler":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		$AnimatedSprite2D.offset.y = 3
	if $AnimatedSprite2D.animation == "ex_idle":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -12
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 12
		$AnimatedSprite2D.offset.y = -6
	if $AnimatedSprite2D.animation == "ex_downr":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		$AnimatedSprite2D.offset.y = 3
	if $AnimatedSprite2D.animation == "ex_down":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		$AnimatedSprite2D.offset.y = -12
	if $AnimatedSprite2D.animation == "ex_diagupr":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		$AnimatedSprite2D.offset.y = 3
	if $AnimatedSprite2D.animation == "ex_diagup":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 10
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -10
		$AnimatedSprite2D.offset.y = 7
	if $AnimatedSprite2D.animation == "ex_diagdownr":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		$AnimatedSprite2D.offset.y = 3
	if $AnimatedSprite2D.animation == "ex_diagdown":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 2
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -2
		$AnimatedSprite2D.offset.y = 4
	if $AnimatedSprite2D.animation == "duck_start":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 3
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -3
		$AnimatedSprite2D.offset.y = 12
	if $AnimatedSprite2D.animation == "duck_s":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 11
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -11
		$AnimatedSprite2D.offset.y = 31
	if $AnimatedSprite2D.animation == "duck":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 5
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -5
		$AnimatedSprite2D.offset.y = 31
	if $AnimatedSprite2D.animation == "down_s":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 1
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -1
		$AnimatedSprite2D.offset.y = -5
	if $AnimatedSprite2D.animation == "down":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 2
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -2
		$AnimatedSprite2D.offset.y = -4
	if $AnimatedSprite2D.animation == "diagup":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 6
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -6
		$AnimatedSprite2D.offset.y = -1
	if $AnimatedSprite2D.animation == "diagdown":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 12
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -12
		$AnimatedSprite2D.offset.y = -6
	if $AnimatedSprite2D.animation == "death":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 0
		$AnimatedSprite2D.offset.y = 25
	if $AnimatedSprite2D.animation == "dash_air":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 14
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -14
		$AnimatedSprite2D.offset.y = 5
	if $AnimatedSprite2D.animation == "dash":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 25
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -25
		$AnimatedSprite2D.offset.y = -8
	if $AnimatedSprite2D.animation == "super1":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -2
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 2
		$AnimatedSprite2D.offset.y = -46
	if $AnimatedSprite2D.animation == "super1_intro":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -2
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 2
		$AnimatedSprite2D.offset.y = -46
	if $AnimatedSprite2D.animation == "super1_intror":
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -2
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 2
		$AnimatedSprite2D.offset.y = -46
	if $AnimatedSprite2D.animation == "super2":
		$AnimatedSprite2D.offset.y = -61
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -4
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 4
	if $AnimatedSprite2D.animation == "super3":
		$AnimatedSprite2D.offset.y = -47
		if $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = -1
		if not $AnimatedSprite2D.flip_h:
			$AnimatedSprite2D.offset.x = 1

		if $AnimatedSprite2D.flip_h:
			$Bombam.play("floor_r")
		if not $AnimatedSprite2D.flip_h:
			$Bombam.play("floor_l")


#/////////////////////////////////////////////////////////
	move_and_slide()

func _girar():
	if is_on_floor():
		if moving == false:
			if velocity.y == 0:
				moving = true
				if not duck:
					if shoot == false:
						$AnimatedSprite2D.play("turn")
					if shoot:
						if player.dir ==6 or player.dir ==8:
							$AnimatedSprite2D.play("turn_sdiagup")
						else:
							$AnimatedSprite2D.play("turn_shoot")
				else:
					$AnimatedSprite2D.play("turn_duck")
				await $AnimatedSprite2D.animation_finished
				turnduck.emit()
				moving = false

func _duck_start():
	if velocity.y == 0:
		duck_start = true
		$AnimatedSprite2D.play("duck_start")
		await $AnimatedSprite2D.animation_finished
		duck = true
		duck_start = false

func _intro():
	stopall = true
	$AnimatedSprite2D.play("idle")
	if player.scared == false:
		if startboss == 1:
			await get_tree().create_timer(0.5).timeout
			$AnimatedSprite2D.play("intro_a")
			$intro_a.play()
		if startboss == 2:
			await get_tree().create_timer(0.5).timeout
			$AnimatedSprite2D.play("intro_b")
	else:
		$AnimatedSprite2D.play("scared")
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("idle")
	stopall = false

func _dash():
	duck = false
	duck_start = false
	aim = false
	shoot = false
	stopall = true
	velocity.y = 0
	var bomb = smokecreator.instantiate()
	if player.relic == 4:
		add_child(bomb)
		bomb.offset.y = -100
		bomb.scale.x = 0.5
		bomb.scale.y = 0.5
		bomb.offset.x = 0
		bomb.play("smoke" + str(randi_range(1,2)))
		bomb.global_position = $Bomb.global_position
	else:
		add_child(bomb)
		bomb.offset.y = -60
		bomb.play("dash")
		if not $AnimatedSprite2D.flip_h:
			bomb.offset.x = -150
		if $AnimatedSprite2D.flip_h:
			bomb.offset.x = 150
		bomb.global_position = $Bomb.global_position
	if $AnimatedSprite2D.flip_h:
		$Bombam.play("floor_l")
	if not $AnimatedSprite2D.flip_h:
		$Bombam.play("floor_r")
	if is_on_floor():
		$AnimatedSprite2D.play("dash")
	if not is_on_floor():
		$AnimatedSprite2D.play("dash_air")
	if $AnimatedSprite2D.flip_h == false:
		velocity.x = 800
		bomb.flip_h = false
	else:
		velocity.x = -800
		bomb.flip_h = true
	$Dashtimer.start()
	if player.relic == 4:
		invencible = true
		SpriteAnimated2D.visible = false
	await $AnimatedSprite2D.animation_finished
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
	stopall = false
	dash = false
	checkshoot()

func _bex():
	SpriteAnimated2D.visible = true
	bex = true
	stopall = true
	dash = false
	shoot = false
	aim = false
	duck = false
	duck_start = false
	velocity.x = 0
	velocity.y = 0
	if player.special == 0 or player.cards !=30:
		if player.dir == 0 or player.dir == 1 or player.dir == 5:
			if is_on_floor():
				$AnimatedSprite2D.play("ex_idle")
			else:
				$AnimatedSprite2D.play("ex_idler")
		elif player.dir == 7:
			if is_on_floor():
				$AnimatedSprite2D.play("ex_up")
			else:
				$AnimatedSprite2D.play("ex_upr")
		elif player.dir == 3:
			if is_on_floor():
				$AnimatedSprite2D.play("ex_down")
			else:
				$AnimatedSprite2D.play("ex_downr")
		elif player.dir == 6 or player.dir == 8:
			if is_on_floor():
				$AnimatedSprite2D.play("ex_diagup")
			else:
				$AnimatedSprite2D.play("ex_diagupr")
		elif player.dir == 2 or player.dir == 4:
			if is_on_floor():
				$AnimatedSprite2D.play("ex_diagdown")
			else:
				$AnimatedSprite2D.play("ex_diagdownr")
	if player.special !=0 and player.cards == 30:
		if player.special == 1:
			var super1sound = randi_range(1,4)
			super1sound = randi_range(1,4)
			invencible = true
			get_node("super1_intro" + str(super1sound)).play()
			if is_on_floor():
				$AnimatedSprite2D.play("super1_intro")
			if not is_on_floor():
				$AnimatedSprite2D.play("super1_intror")
			await $AnimatedSprite2D.animation_finished
			$AnimatedSprite2D.play("super1")
			await get_node("super1_intro" + str(super1sound)).finished
			$super1_loop.play()
		if player.special == 2:
			$super2.play()
			$AnimatedSprite2D.play("super2")
			invencible = true
			super2ative = true
		if player.special == 3:
			$AnimatedSprite2D.play("super3")
			invencible = true
	await $AnimatedSprite2D.animation_finished
	invencible = false
	$Extimer.start()
	befx = false
	stopall = false
	bex = false
	if not super2ative:
		checkshoot()

func _checkparry():
	var areas = $parry.get_overlapping_areas()
	var slap = parryslap.instantiate()
	for area in areas:
		if is_instance_valid(area) and area.is_in_group("parryavel"):
			if $Parrytimer.is_stopped():
				parring = true
				parrysound = randi_range(1,2)
				get_node("parry" + str(parrysound)).play()
				get_node("parry_hit" + str(parrysound)).play()
				_parry(area)
				add_child(slap)
				slap.global_position = area.global_position
				slap.z_index = -2
				$AnimatedSprite2D.play("parred")
				await $AnimatedSprite2D.animation_finished
				$AnimatedSprite2D.play("jump")
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
			addcard()
			await $Cardtimer.timeout
			if bex:
				await $AnimatedSprite2D.animation_finished
				addcard()
			else:
				addcard()
			await $Cardtimer.timeout
			if bex:
				await $AnimatedSprite2D.animation_finished
				addcard()
			else:
				addcard()
			await $Cardtimer.timeout
			if bex:
				await $AnimatedSprite2D.animation_finished
				addcard()
			else:
				addcard()
			await $Cardtimer.timeout
			if bex:
				await $AnimatedSprite2D.animation_finished
				addcard()
			else:
				addcard()
			await $Cardtimer.timeout
			if stopall:
				await $AnimatedSprite2D.animation_finished
				addcard()
			else:
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
	if not has_node("shotcreator"):
		var shootf = shotcreator.instantiate()
		add_child(shootf)
		shootf.global_position = $shootm.global_position
		shootdup = true
		print(shootf)

func checkshoot():
	if backsshoot == true:
		shoot = true
		backsshoot = false
		shootdup = false
		creation()
		if player.actualshoot == 0:
			get_node("pea_start" + str(startshootsound)).play()



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
	if $AnimatedSprite2D.flip_h:
		bomb.offset.x = -55
	if not $AnimatedSprite2D.flip_h:
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

func excreate(ex):
	player.dir = savedir
	if player.dir == 6:
		ex.rotation_degrees = 210
	if player.dir == 1:
		ex.rotation_degrees = 0
	if player.dir == 8:
		ex.rotation_degrees = -30
	if player.dir == 7:
		ex.rotation_degrees = -90
	if player.dir == 0:
		if player.mirror:
			ex.rotation_degrees = 180
		else:
			ex.rotation_degrees = 0
	if player.dir == 3:
		if not player.duck:
			ex.rotation_degrees = 90
		else:
			if player.mirror:
				ex.rotation_degrees = 180
			else:
				ex.rotation_degrees = 0
	if player.dir == 5:
		ex.rotation_degrees = 180
	if player.dir == 2:
		if not player.duck:
			ex.rotation_degrees = 30
		else:
			ex.rotation_degrees = 0
	if player.dir == 4:
		if not player.duck:
			ex.rotation_degrees = 140
		else:
			ex.rotation_degrees = 180

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
	if $AnimatedSprite2D.flip_h:
		velocity.x = -400
	if not $AnimatedSprite2D.flip_h:
		velocity.x = 400
	velocity.y = -1500
	$AnimatedSprite2D.material.set_shader_parameter("ativo", true)
	$Cardtimer.wait_time = 0.2
	await get_tree().create_timer(0.5).timeout
	super2card = true
	player.super2card = true
	super2canflip = false
	velocity.x = 0
	landsuper = false
	checkshoot()
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
	$AnimatedSprite2D.material.set_shader_parameter("ativo", false)
