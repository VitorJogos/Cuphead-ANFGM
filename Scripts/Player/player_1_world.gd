extends CharacterBody2D

# Velocidade do overworld original (MapPlayerMotor.SPEED = 2.5 unidades/s, 100 px por unidade)
const VELOCIDADE := 250.0

var mobile = false
var up = false
var down = false
var left = false
var right = false
@onready var SpriteAnimated2D = $AnimatedSprite2D
var dust = preload("res://Scenes/Player/dust_world.tscn")
var passo_direito = false
# Pe do jogador: o ponto de apoio testado contra a terra
const PES := Vector2(0.0, 16.0)
var _ilhas: Area2D

# Colisao fiel ao overworld: so anda em terra. A zona de terra fica na
# Area2D do grupo "ilhas" da cena do mapa (poligonos desenhados na ilha);
# testa o pe do jogador por eixo, entao ele desliza pela beira em vez de grudar.
func _em_terra_ok(p: Vector2) -> bool:
	if _ilhas == null or not is_instance_valid(_ilhas):
		_ilhas = get_tree().get_first_node_in_group("ilhas")
	if _ilhas == null:
		return true
	var q := PhysicsPointQueryParameters2D.new()
	q.position = p
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = 0xFFFFFFFF
	return not get_world_2d().direct_space_state.intersect_point(q).is_empty()

func _physics_process(delta: float) -> void:
	if mobile == false:
		if not Input.is_action_pressed("right") and not Input.is_action_pressed("left") and not Input.is_action_pressed("up") and not Input.is_action_pressed("down"):
			player.dir = 0
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
	if left == true:
		velocity.x = -VELOCIDADE
		SpriteAnimated2D.flip_h = true
		if not up and not down:
			SpriteAnimated2D.play("side_walk")
		if up and not down:
			SpriteAnimated2D.play("diagup_walk")
		if not up and down:
			SpriteAnimated2D.play("diagdown_walk")
	if right == true:
		velocity.x = VELOCIDADE
		SpriteAnimated2D.flip_h = false
		if not up and not down:
			SpriteAnimated2D.play("side_walk")
		if up and not down:
			SpriteAnimated2D.play("diagup_walk")
		if not up and down:
			SpriteAnimated2D.play("diagdown_walk")
	if up == true:
		velocity.y = -VELOCIDADE
		if not left and not right:
			SpriteAnimated2D.play("up_walk")
	if down == true:
		velocity.y = VELOCIDADE
		if not left and not right:
			SpriteAnimated2D.play("down_walk")
	if not left and not right:
		velocity.x = 0
	if not up and not down:
		velocity.y = 0
	# No original o input e normalizado: diagonal anda na mesma velocidade do reto
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized() * VELOCIDADE
	# Poeira nasce nos passos como no original (2 por ciclo de caminhada, em qualquer direcao)
	if velocity != Vector2.ZERO and $Timer.is_stopped():
		$Timer.start()
	if SpriteAnimated2D.animation == "side_walk":
		$dust.play("side")
		if velocity.x == 0:
			SpriteAnimated2D.play("side_idle")
		SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 0
	if SpriteAnimated2D.animation == "side_idle":
		SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 0
	if SpriteAnimated2D.animation == "down_walk":
		$dust.play("down")
		if velocity.y == 0:
			SpriteAnimated2D.play("down_idle")
		SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 0
	if SpriteAnimated2D.animation == "down_idle":
		SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 0
	if SpriteAnimated2D.animation == "up_walk":
		$dust.play("up")
		if velocity.y == 0:
			SpriteAnimated2D.play("up_idle")
		SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 0
	if SpriteAnimated2D.animation == "up_idle":
		SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 0
	if SpriteAnimated2D.animation == "diagup_walk":
		$dust.play("diagup")
		if velocity.y == 0 and velocity.x == 0:
			SpriteAnimated2D.play("diagup_idle")
		SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 0
	if SpriteAnimated2D.animation == "diagup_idle":
		SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 0
	if SpriteAnimated2D.animation == "diagdown_walk":
		$dust.play("diagown")
		if velocity.y == 0 and velocity.x == 0:
			SpriteAnimated2D.play("diagdown_idle")
		SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 0
	if SpriteAnimated2D.animation == "diagdown_idle":
		SpriteAnimated2D.offset.x = 0
		SpriteAnimated2D.offset.y = 0
	
	var passo := velocity * delta
	if passo.x != 0.0 and _em_terra_ok(global_position + PES + Vector2(passo.x, 0.0)):
		global_position.x += passo.x
	if passo.y != 0.0 and _em_terra_ok(global_position + PES + Vector2(0.0, passo.y)):
		global_position.y += passo.y

func _on_timer_timeout() -> void:
	if velocity == Vector2.ZERO:
		# parou no meio do passo: o proximo passeio recomeca com o 1o passo (0,2 s, igual o original)
		$Timer.wait_time = 0.2
		return
	var dustx = dust.instantiate()
	add_child(dustx)
	passo_direito = not passo_direito
	var marca = $dustmark.global_position
	if passo_direito:
		# espelha a marca no outro lado do jogador (pé direito)
		dustx.global_position = Vector2(2.0 * global_position.x - marca.x, marca.y)
	else:
		dustx.global_position = marca
	# proximos passos: 0,2667 s (0,4667 - 0,2 dos eventos originais)
	$Timer.wait_time = 0.26666667
