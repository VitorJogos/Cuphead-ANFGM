extends Area2D

# Direção atual do joystick (0 = solto, 1-8 = 8 direções)
# 1 = Direita, 2 = Baixo-Direita, 3 = Baixo, 4 = Baixo-Esquerda
# 5 = Esquerda, 6 = Cima-Esquerda, 7 = Cima, 8 = Cima-Direita
# Called when the node enters the scene tree for the first time.
@onready var SpriteAnimated2D = $AnimatedSprite2D
# Como no original, os Supers NÃO são afetados pelo nerf dos charms de coração.
@export var dano = 4 * player.hpnerf
var startt = false
# 🎮 1. CONFIGURAÇÕES DE MOVIMENTO DO CENTRO (O "Sol")
var velocidade: Vector2 = Vector2.ZERO
@export var velocidade_maxima: float = 750 
@export var aceleracao: float = 3200    

# 🌍 2. CONFIGURAÇÕES DA TRANSLAÇÃO (A "Terra")
@export var raio: float = 50          # A distância do fantasma até o centro (tamanho do círculo)
@export var velocidade_orbita: float = 5  # Quão rápido ele gira (valores maiores = gira mais rápido)
var angulo: float = 0.0

func _process(delta: float) -> void:
	if startt:
		$d.disabled = true
		# 🧭 MOVIMENTO DO CENTRO (Igual ao sistema de inércia anterior)
		var direcao_alvo = Vector2.ZERO
		match player.dir:
			1: direcao_alvo = Vector2(1, 0)       
			2: direcao_alvo = Vector2(1, 1)       
			3: direcao_alvo = Vector2(0, 1)       
			4: direcao_alvo = Vector2(-1, 1)      
			5: direcao_alvo = Vector2(-1, 0)      
			6: direcao_alvo = Vector2(-1, -1)     
			7: direcao_alvo = Vector2(0, -1)      
			8: direcao_alvo = Vector2(1, -1)      
			_: direcao_alvo = Vector2.ZERO        
			
		if direcao_alvo != Vector2.ZERO:
			direcao_alvo = direcao_alvo.normalized()
			
		velocidade = velocidade.move_toward(direcao_alvo * velocidade_maxima, aceleracao * delta)
		position += velocidade * delta # Isso move o nó principal (o centro invisível)

		# 🌀 CÁLCULO DA TRANSLAÇÃO (Mágica da Órbita)
		angulo += velocidade_orbita * delta # Atualiza o ângulo baseado no tempo
		
		# O Cosseno cuida do vai-e-vem no X, o Seno cuida do vai-e-vem no Y
		var offset_orbital = Vector2(cos(angulo), sin(angulo)) * raio
		
		# Move o Sprite e a Colisão ao redor do centro
		$AnimatedSprite2D.position = offset_orbital
		
		if has_node("CollisionShape2D"):
			$CollisionShape2D.position = offset_orbital
			$CollisionShape2D2.position = offset_orbital
			$d.position = offset_orbital
		
	# (Opcional) Se você quiser que o sprite também mude a própria rotação enquanto gira:
	# $AnimatedSprite2D.rotation = angulo
	if SpriteAnimated2D.frame == 27:
		SpriteAnimated2D.play("loop")
		startt = true
	if startt:
		var areas = get_overlapping_areas()
		var bodies = get_overlapping_bodies()
		if $Timer3.is_stopped():
			for area in areas:
				if area.is_in_group("dano"):
					$Timer3.start()
					print("dano")
					if area.has_method("dano"):
						area.dano(dano)
			for body in bodies :
				if body.is_in_group("dano"):
					$Timer3.start()
					print("dano")
					if body.has_method("dano"):
						body.dano(dano)

func _on_timer_2_timeout() -> void:
	startt = false
	$".".add_to_group("parryavel")
	$CollisionShape2D.disabled = true
	$d.disabled = false
	$CollisionShape2D2.disabled = true
	$AnimatedSprite2D.play("die")

func parry():
	queue_free()
