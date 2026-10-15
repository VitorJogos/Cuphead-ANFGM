extends AnimatedSprite2D

var peashooter = preload("res://Scenes/Player/shoots/peashooter.tscn")
var spreadshot = preload("res://Scenes/Player/shoots/spreadshoot.tscn")
var roundabount = preload("res://Scenes/Player/shoots/roundabount.tscn")
var homing = preload("res://Scenes/Player/shoots/homing.tscn")
var obus = preload("res://Scenes/Player/shoots/obus.tscn")
var charge = preload("res://Scenes/Player/shoots/charge.tscn")
var super2cards = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if player.actualshoot == 5:
		var numero_aleatorio = randi_range(1, 5)
		# 🛠️ Monta o nome do nó dinamicamente (ex: "Som" + "3" vira "Som3")
		var nome_do_no = "Start_" + str(numero_aleatorio)
		# 🎵 Busca o nó pelo nome criado e dá Play
		get_node(nome_do_no).play()
		play("charge_1")
		$charge.start()
	rotation_degrees = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player.actualshoot == 5:
		if not animation == "charge_2" and not animation == "charge_1":
		# 🎲 Escolhe um número de 1 a 5
			var numero_aleatorio = randi_range(1, 5)
			# 🛠️ Monta o nome do nó dinamicamente (ex: "Som" + "3" vira "Som3")
			var nome_do_no = "Start_" + str(numero_aleatorio)
			# 🎵 Busca o nó pelo nome criado e dá Play
			get_node(nome_do_no).play()
			$".".play("charge_1")
			$charge.start()
	
	if player.atualizashot:
		print("eu existo viu!")
		atualizaranim()
	#if $shoottimer.is_stopped()
	if player.actualshoot == 0:
		$".".play("peashooter")
		$shoottimer.wait_time = 0.125
	if player.actualshoot == 1:
		$".".play("spreadshot")
		$shoottimer.wait_time = 0.15
	if player.actualshoot == 2:
		$".".play("roundabount")
		$shoottimer.wait_time = 0.27
	if player.actualshoot == 3:
		$".".play("homing")
		$shoottimer.wait_time = 0.167
	if player.actualshoot == 4:
		$".".play("obus")
		$shoottimer.wait_time = 0.45
	if player.dir == 6:
		rotation_degrees = 210
	if player.dir == 1:
		rotation_degrees = 0
	if player.dir == 8:
		rotation_degrees = -30
	if player.dir == 7:
		rotation_degrees = -90
	if player.dir == 0:
		if player.mirror:
			rotation_degrees = 180
		else:
			rotation_degrees = 0
	if player.dir == 3:
		if not player.duck:
			rotation_degrees = 90
		else:
			if player.mirror:
				rotation_degrees = 180
			else:
				rotation_degrees = 0
	if player.dir == 5:
		rotation_degrees = 180
	if player.dir == 2:
		if not player.duck:
			rotation_degrees = 30
		else:
			rotation_degrees = 0
	if player.dir == 4:
		if not player.duck:
			rotation_degrees = 140
		else:
			rotation_degrees = 180
	if not player.shooting:
		if $Timer.is_stopped():
			$Timer.start()
			await  $Timer.timeout
			if not player.shooting:
				queue_free()
	if player.stopall:
		chargex()
		queue_free()
	position = player.shootfposition

func morrer():
	queue_free()


func _on_shoottimer_timeout() -> void:
	if player.actualshoot == 0:
		var shoot = peashooter.instantiate()
		get_parent().add_child(shoot)
		shoot.global_position = $peashooter.global_position
		shoot.global_rotation_degrees = $".".global_rotation_degrees
		if super2cards:
			shoot.super2cards = true
		if not super2cards:
			shoot.super2cards = false
	if player.actualshoot == 2:
		var shoot = roundabount.instantiate()
		get_parent().add_child(shoot)
		shoot.global_position = $peashooter.global_position
		shoot.global_rotation_degrees = $".".global_rotation_degrees
		if super2cards:
			shoot.super2cards = true
		if not super2cards:
			shoot.super2cards = false
	if player.actualshoot == 3:
		var shoot = homing.instantiate()
		get_parent().add_child(shoot)
		shoot.global_position = $peashooter.global_position
		shoot.global_rotation_degrees = $".".global_rotation_degrees
		if super2cards:
			shoot.super2cards = true
		if not super2cards:
			shoot.super2cards = false
	if player.actualshoot == 4:
		var shoot = obus.instantiate()
		get_parent().add_child(shoot)
		shoot.global_position = $peashooter.global_position
		shoot.global_rotation_degrees = $".".global_rotation_degrees
		if super2cards:
			shoot.super2cards = true
		if not super2cards:
			shoot.super2cards = false
	if player.actualshoot == 1:
		# Criamos uma lista com os ângulos que queremos (o leque do Bacamarte)
		var angulos = [-30, -15, 0, 15, 30]
		@warning_ignore("shadowed_variable_base_class")
		for offset in angulos:
			# ✨ ESSENCIAL: Instanciar um NOVO tiro para cada ângulo do leque
			var shoot = spreadshot.instantiate()
			get_parent().add_child(shoot)
			
			shoot.global_position = $peashooter.global_position
			
			# Define a rotação base da arma + o desvio do leque
			shoot.global_rotation_degrees = global_rotation_degrees + offset
			
			# Configura se é um tiro forte ou fraco (os das pontas e o do meio são fortes)
			if offset == -30 or offset == 0 or offset == 30:
				shoot.forte = true # Se você tiver essa variável no script do tiro
				#shoot.scale = Vector2(1.2, 1.2)
			else:
				shoot.forte = false
				shoot.scale = Vector2(0.8, 0.8)
				
			# Aplica a carta do Super 2
			if super2cards:
				shoot.super2cards = true
			if not super2cards:
				shoot.super2cards = false


func chargex():
	if player.actualshoot == 5 and is_inside_tree():
		if $".".animation == "charge_1":
			var shoot = charge.instantiate()
			shoot.forte = false
			get_parent().add_child(shoot)
			shoot.global_position = $peashooter.global_position
			shoot.global_rotation_degrees = $".".global_rotation_degrees
			
			if super2cards:
				shoot.super2cards = true
			if not super2cards:
				shoot.super2cards = false
		elif $".".animation == "charge_2":
			var shoot = charge.instantiate()
			get_parent().add_child(shoot)
			shoot.global_position = $peashooter.global_position
			shoot.global_rotation_degrees = $".".global_rotation_degrees
			shoot.forte = true
			if super2cards:
				shoot.super2cards = true
			if not super2cards:
				shoot.super2cards = false
	return


func _on_charge_timeout() -> void:
	if $".".animation == "charge_1":
		$Ready.play()
		$".".play("charge_2")


func atualizaranim():
	if player.actualshoot == 0:
		$".".play("peashooter")
		$shoottimer.wait_time = 0.125
	if player.actualshoot == 1:
		$".".play("spreadshot")
		$shoottimer.wait_time = 0.15
	if player.actualshoot == 2:
		$".".play("roundabount")
		$shoottimer.wait_time = 0.27
	if player.actualshoot == 3:
		$".".play("homing")
		$shoottimer.wait_time = 0.167
	if player.actualshoot == 4:
		$".".play("obus")
		$shoottimer.wait_time = 0.45
	if player.actualshoot == 5:
		if animation == "charge_2":
			print("AAAAAAAAAA")
		$".".play("charge_1")
		$charge.start()
