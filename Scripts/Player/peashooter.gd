extends Area2D

@export var intro = randi_range(1,2)
var stopall = false
@warning_ignore("integer_division")
@export var dano = 4 * player.lessdmg * player.hpnerf
var notdmg = false
var colidedsound = randi_range(1,16)
var startsound = randi_range(1,4)
var obus_iniciado = false
var direcao_volta : Vector2 = Vector2.ZERO
var angulo_fixado : bool = false
@export var shoot = 0
@export var ex = false
var atingidos = 0 # limite 4
var tempo_entre_hits = 0.0 # Controla o intervalo do multi-hit
var tempo_vida = 0.0 # Quanto tempo o tiro já existe (usado para o EX do roundabout não morrer ao nascer)
@export var speed = 2100
var oneex = false
var super2cards = false
@export var forte = true
var back = false
var altura_maxima = 0.0 
@export var gravidade : float = 2800.0
var velocity_y = -100

# 🎯 VARIÁVEIS DO CHASER NORMAL E EX (CHAOS ORBIT)
var alvo: Node2D = null
@export var velocidade_curva: float = 6.5 
var bounce_count = 0
var posicao_inicial : Vector2

var angulo_orbita: float = 0.0 
var raio_atual: float = 0.0 
@export var raio_maximo: float = 100
@export var velocidade_orbita: float = 15 # ⚡ BEM MAIS RÁPIDO AGORA!
var is_clone: bool = false

# 🛠️ VARIÁVEIS DE CONFIGURAÇÃO DO EX (ROUNDABOUT)
@export var aceleracao_ex: float = 1400.0 # Força de arranque
@export var freio_ex: float = 3500.0 # Força do travão no ar
@export var velocidade_maxima_ex: float = 1150.0 # Limite de velocidade nas retas
var ex_estado: int = 0 # 0: Voando em linha reta | 1: Travando | 2: Girando/Restaura
var ex_timer: float = 0.0 # O cronómetro interno que controla as fases do voo

func _ready() -> void:
	posicao_inicial = global_position # Salva onde o tiro nasceu
	altura_maxima = global_position.y
	
	if shoot == 1:
		if not ex:
			if not forte:
				dano = 0.75 * player.lessdmg * player.hpnerf
			else:
				dano = 1.25 * player.lessdmg * player.hpnerf
			speed = 1100
		else:
			dano = 11 * player.lessdmg * player.hpnerf
			speed = 500
			
	# ========================================================
	# CONFIGURAÇÃO DO VAI E VEM / ROUNDABOUT (SHOOT 2)
	# ========================================================
	if shoot == 2:
		if not ex:
			dano = 8.5 * player.lessdmg * player.hpnerf
			speed = 1100
		else:
			dano = 4.5 * player.lessdmg * player.hpnerf
			speed = velocidade_maxima_ex 
			ex_estado = 0 
			ex_timer = 0.2 


	# ========================================================
	# 🟢 CONFIGURAÇÃO DO CHASER (SHOOT 3) + CHAOS ORBIT
	# ========================================================
	if shoot == 3:
		if not ex:
			dano = 2.6 * player.lessdmg * player.hpnerf
			speed = 770
		else:
			# Dano oficial do Chaos Orbit
			dano = 8.0 * player.lessdmg * player.hpnerf 
			speed = 0 # Desliga a velocidade normal para ele não fugir
			
			# 🛑 MÁGICA 1: O escudo não tem tempo de vida! Ele só some se bater.
			if has_node("Timer"):
				$Timer.stop()
				
			# 🪄 MÁGICA 2: Clona a si mesmo 3 vezes para formar as 4 estrelas!
			if not is_clone:
				for i in range(1, 4):
					var clone = load(scene_file_path).instantiate()
					clone.shoot = 3
					clone.ex = true
					clone.is_clone = true
					clone.forte = forte
					clone.angulo_orbita = i * (PI / 2.0) 
					get_parent().call_deferred("add_child", clone)

	# 🟣 CONFIGURAÇÃO DO OBUS / LOBBER (SHOOT 4)
	if shoot == 4:
		dano = 11.6 * player.lessdmg * player.hpnerf
		if not ex:
			speed = 600
		else:
			dano = 28 * player.lessdmg * player.hpnerf
			speed = 2000
			
	if not ex:
		if shoot != 4:
			$AnimatedSprite2D.offset.x = 29
		else:
			$AnimatedSprite2D.offset = Vector2.ZERO 
			
		if shoot !=5:
			if intro == 1:
				$AnimatedSprite2D.play("intro_a")
			if intro == 2:
				$AnimatedSprite2D.play("intro_b")
		else:
			if forte:
				var numero_aleatorio = randi_range(1, 3)
				# 🛠️ Monta o nome do nó dinamicamente (ex: "Som" + "3" vira "Som3")
				var nome_do_no = "huge_" + str(numero_aleatorio)
				# 🎵 Busca o nó pelo nome criado e dá Play
				get_node(nome_do_no).play()
				$AnimationPlayer.play("normal")
				dano = 38 * player.lessdmg * player.hpnerf
				$AnimatedSprite2D.play("intro_a")
			else:
				$AnimationPlayer.play("small")
				dano = 6 * player.lessdmg * player.hpnerf
				$AnimatedSprite2D.play("intro_l")
	if ex:
		get_node("Start" + str(startsound)).play()
		$AnimatedSprite2D.play("intro")
		if shoot != 4 and shoot !=1 and shoot !=5:
			$AnimatedSprite2D.offset.x = 77
		else:
			$AnimatedSprite2D.offset = Vector2.ZERO
			
	await $AnimatedSprite2D.animation_finished
	if stopall: return
	# EX da Charge: fica parado no lugar com o ângulo fixo definido no disparo
	# (fiel ao original), e não morre na hora.
	if shoot == 5 and ex:
		dano = 27 * player.lessdmg * player.hpnerf
		speed = 1200
		forte = true
		# 🛑 CORRIGE a hitbox gigante: para a animação que escala a colisão 2x e
		# deixa o EX com um tamanho razoável (não uma hitbox enorme invisível).
		if has_node("AnimationPlayer"):
			$AnimationPlayer.stop()
		if has_node("CollisionShape2D"):
			$CollisionShape2D.scale = Vector2(1, 1)
	if shoot != 4:
		$AnimatedSprite2D.offset.x = 0
	if forte:
		$AnimatedSprite2D.play("main")
	else:
		$AnimatedSprite2D.play("main_l")
	#if $AnimatedSprite2D/FX.is_valid():
		#$AnimatedSprite2D/FX.top_level = true
	

func _process(delta: float) -> void:
	tempo_vida += delta
	if shoot == 5 and not ex:
		if forte:
			$AnimationPlayer.play("normal")
		else:
			$AnimationPlayer.play("small")
	if shoot == 5 and ex:
		rotation_degrees = 0
	if tempo_entre_hits > 0:
		tempo_entre_hits -= delta

	if atingidos >= 3 and not stopall and shoot !=2 and shoot !=5:
		die(false)

	if not stopall:
		if not ex:
			if shoot == 2:
				if back:
					speed = int(lerp(float(speed), -1200.0, 6.0 * delta))
				elif $AnimatedSprite2D.animation == "turn":
					speed = int(lerp(float(speed), 0.0, 8.0 * delta))
				position += transform.x * speed * delta
			elif shoot == 3:
				procurar_alvo_mais_proximo()
				if alvo and is_instance_valid(alvo):
					var angulo_alvo = (alvo.global_position - global_position).angle()
					global_rotation = lerp_angle(global_rotation, angulo_alvo, velocidade_curva * delta)
				position += Vector2.RIGHT.rotated(global_rotation) * speed * delta
			elif shoot == 5:
				position += transform.x * speed * delta
			elif shoot == 4:
				if not obus_iniciado:
					var angulo_graus = round(rad_to_deg(transform.x.angle()))
					var dir_x = -1.0 if abs(angulo_graus) > 90 else 1.0
					global_rotation = 0.0
					
					if angulo_graus < -80 and angulo_graus > -100:
						velocity_y = -900.0        
						speed = 0.0                
					elif angulo_graus < -10 and angulo_graus > -170:
						velocity_y = -820.0        
						speed = 460.0 * dir_x      
					elif angulo_graus > 80 and angulo_graus < 100:
						velocity_y = 400.0         
						speed = 0.0                
					elif angulo_graus > 10 and angulo_graus < 170:
						velocity_y = -150.0        
						speed = 520.0 * dir_x
					else:
						velocity_y = -550.0        
						speed = 620.0 * dir_x        
					altura_maxima = global_position.y
					obus_iniciado = true
				
				if global_position.y < altura_maxima:
					altura_maxima = global_position.y
				
				velocity_y += gravidade * delta
				position.y += velocity_y * delta
				position.x += speed * delta
			else:
				position += transform.x * speed * delta
				
		# ========================================================
		# 🔥 LÓGICA DE MOVIMENTAÇÃO DOS EX
		# ========================================================
		if ex:
			if shoot == 0 or shoot == 1:
				position += transform.x * speed * delta
			elif shoot == 4:
				if not obus_iniciado:
					var angulo_graus = round(rad_to_deg(transform.x.angle()))
					var dir_x = -1.0 if abs(angulo_graus) > 90 else 1.0
					global_rotation = 0.0
					
					if angulo_graus < -80 and angulo_graus > -100:
						velocity_y = -1100 
						speed = 0.0                
					elif angulo_graus < -10 and angulo_graus > -170:
						velocity_y = -550      
						speed = 850 * dir_x      
					elif angulo_graus > 80 and angulo_graus < 100:
						velocity_y = 400.0         
						speed = 0.0                
					elif angulo_graus > 10 and angulo_graus < 170:
						velocity_y = 0     
						speed = 850 * dir_x
					else:
						velocity_y = -550.0        
						speed = 850 * dir_x        
					obus_iniciado = true
				position += transform.x * speed * delta
				velocity_y += gravidade * delta
				position.y += velocity_y * delta
				
			# 🪚 JUMBO REBOUND (EX DO ROUNDABOUT)
			elif shoot == 2:
				if direcao_volta == Vector2.ZERO:
					direcao_volta = transform.x

				if $AnimatedSprite2D.animation == "intro":
					position += direcao_volta * speed * delta
				else:
					if ex_estado == 0:
						speed = move_toward(float(speed), velocidade_maxima_ex, aceleracao_ex * delta)
						position += direcao_volta * speed * delta
						
						ex_timer -= delta
						if ex_timer <= 0.0:
							ex_estado = 1 
							
					elif ex_estado == 1:
						speed = move_toward(float(speed), 0.0, freio_ex * delta)
						position += direcao_volta * speed * delta
						
						if speed <= 0.0:
							ex_estado = 2 
							executar_turn_ex()
							
			# 🟢 CHAOS ORBIT (EX DO CHASER)
# 🟢 CHAOS ORBIT (EX DO CHASER) - SEGUINDO A COLISÃO ATIVA DO PLAYER
			elif shoot == 3:
				var player_node = get_tree().get_first_node_in_group("player")
				if player_node and is_instance_valid(player_node):
					angulo_orbita += velocidade_orbita * delta
					raio_atual = lerp(raio_atual, raio_maximo, 12.0 * delta)
					
					var offset_x = cos(angulo_orbita) * raio_atual
					var offset_y = sin(angulo_orbita) * raio_atual
					
					# 🎯 VARIÁVEL PARA GUARDAR O CENTRO DA ORBITA
					var posicao_centro : Vector2 = player_node.global_position
					
					# Pegamos os dois shapes de colisão do seu player (ajuste os nomes se forem diferentes)
					var colisao_em_pe = player_node.get_node_or_null("CollisionShape2D")
					var colisao_agachado = player_node.get_node_or_null("CollisionShape2D2")
					
					# Verifica qual colisão está ativa no momento e segue a posição global dela
					if colisao_agachado and not colisao_agachado.disabled:
						posicao_centro = colisao_agachado.global_position
					elif colisao_em_pe and not colisao_em_pe.disabled:
						posicao_centro = colisao_em_pe.global_position
					
					global_position = posicao_centro + Vector2(offset_x, offset_y)
					global_rotation = angulo_orbita + (PI / 2.0)
				else:
					die(false)
	else:
		return

	var areas = get_overlapping_areas()
	var bodies = get_overlapping_bodies()

	if ex:
		if tempo_entre_hits <= 0:
			colidedsound = randi_range(1, 3)
			for area in areas:
				if stopall: return
				if area.is_in_group("dano") and area.has_method("dano"):
					area.dano(dano)
					# 🌟 SE FOR O ESCUDO DO CHASER, BATEU, MORREU NA HORA!
					if shoot == 3:
						colided()
						die(false)
						return
						
					if shoot !=5:
						tempo_entre_hits = 0.05
					else:
						tempo_entre_hits = 1
					if area.is_in_group("boss"):
						if shoot == 0:
							atingidos += 1
						else:
							atingidos += 3
						colided()
						if atingidos >= 3:
							if shoot !=2 and shoot !=5:
								die(false)
							return
					return
			for body in bodies:
				if stopall: return
				if body.is_in_group("dano") and body.has_method("dano"):
					body.dano(dano)
					# 🌟 MESMA COISA PARA INIMIGOS COMUNS!
					if shoot == 3:
						colided()
						die(false)
						return
					if shoot !=5:
						tempo_entre_hits = 0.05
					else:
						tempo_entre_hits = 1
					if body.is_in_group("boss"):
						atingidos += 1
						if shoot == 5:
							atingidos += 67
						colided()
						if atingidos >= 3:
							if shoot !=2 and shoot !=5:
								die(false)
							return
					return

func procurar_alvo_mais_proximo() -> void:
	var inimigos = get_tree().get_nodes_in_group("dano")
	var menor_distancia = INF
	var alvo_temporario: Node2D = null

	for inimigo in inimigos:
		if inimigo == self: continue

		if inimigo is Area2D or inimigo is CharacterBody2D:
			var distancia = global_position.distance_to(inimigo.global_position)
			if distancia < menor_distancia:
				menor_distancia = distancia
				alvo_temporario = inimigo

	alvo = alvo_temporario

func _on_timer_timeout() -> void:
	die(true)

func _on_area_entered(area: Area2D) -> void:
	# 🛡️ SE FOR O CHÃO: Trata o Lobber e faz todos os outros ignorarem!
	if area.is_in_group("chao"):
		if shoot == 4 and not stopall and not ex:
			executar_quique()
		notdmg = true
		return # Alerta de segurança: impede o Charge e outros de morrerem no chão!

	# 🌀 EX DO ROUNDABOUT: quando ele volta e encosta no player, ele morre
	# (toca a animação de morte e some), como no original.
	# O tempo_vida protege contra o nascimento: em algumas direções de tiro
	# a hitbox do EX já nasce sobre o player, e ele não pode morrer na hora.
	if ex and shoot == 2 and not stopall and tempo_vida > 0.3:
		var dono = area.get_parent()
		if area.is_in_group("player") or (dono != null and dono.is_in_group("player")):
			die(false)
			return

	if not ex and not stopall:
		if area.is_in_group("dano") and not area.is_in_group("player") and not area.get_parent().is_in_group("player"):
			if area.has_method("dano"):
				area.dano(dano)
				die(false)
				
	if area.is_in_group("atiravel") and not stopall:
		# O EX da Charge nasce PARADO na altura do player. No chão a hitbox dele
		# (220x241) encosta na zona "atiravel" do cenário já na frame do
		# nascimento e ele morria instantaneamente — dava a impressão de que o EX
		# não saía. Como ele nunca se move, só o Timer encerra a vida dele.
		if ex and (shoot == 2 or shoot == 3 or shoot == 5):
			return
		notdmg = true
		die(false)

func _on_body_entered(body: Node2D) -> void:
	# 🛡️ SE FOR O CHÃO: Trata o Lobber e faz todos os outros ignorarem!
	if body.is_in_group("chao"):
		if shoot == 4 and not stopall and not ex:
			executar_quique()
		notdmg = true
		return # Alerta de segurança: impede o Charge e outros de morrerem no chão!
	if not ex and not stopall:
		if body.is_in_group("dano") and not body.is_in_group("player"):
			if body.has_method("dano"):
				body.dano(dano)
			die(false)
			
	if body.is_in_group("atiravel") and not stopall:
		# Mesma proteção do caminho de áreas: o EX da Charge não pode morrer ao
		# nascer em pé no chão (a hitbox grande encosta no cenário de imediato).
		if ex and (shoot == 2 or shoot == 3 or shoot == 5):
			return
		notdmg = true
		die(false)
func die(foi_por_tempo: bool = false):
	if stopall: return
	stopall = true

	if not ex:
		colidedsound = randi_range(1,16)
	else:
		colidedsound = randi_range(1,3)

	if not foi_por_tempo and not notdmg and not ex and not super2cards and not player.super2card:
		if shoot == 0:
			player.cardsadd += 0.17
		if shoot == 2:
			player.cardsadd += 0.25
		if shoot == 1:
			if forte:
				player.cardsadd += 0.071
			else:
				player.cardsadd += 0.02
		if shoot == 3:
			player.cardsadd += 0.07
		if shoot == 4:
			player.cardsadd += 0.2
		if shoot == 5:
			if forte:
				player.cardsadd += 0.5
			else:
				player.cardsadd += 0.085
	if shoot == 1:
		if not ex:
			if foi_por_tempo:
				if forte:
					$AnimatedSprite2D.play("death")
				else:
					$AnimatedSprite2D.play("death_l")
			else:
				colided()
				if forte:
					$AnimatedSprite2D.play("death_2")
				else:
					$AnimatedSprite2D.play("death_l_2")
		else:
			$AnimatedSprite2D.play("death")
	elif shoot == 5:
		if not ex:
			colided()
			if forte:
				var numero_aleatorio = randi_range(1, 3)
				
				# 🛠️ Monta o nome do nó dinamicamente (ex: "Som" + "3" vira "Som3")
				var nome_do_no = "impacth_" + str(numero_aleatorio)
				
				# 🎵 Busca o nó pelo nome criado e dá Play
				get_node(nome_do_no).play()
				$AnimatedSprite2D.play("death")
			else:
				$AnimatedSprite2D.play("death_l")
		else:
			$AnimatedSprite2D.play("death")
	else:
		colided()
		$AnimatedSprite2D.play("death")
	if ex:
		if shoot !=4 and shoot !=1 and shoot !=5  :
			$AnimatedSprite2D.offset.x = 160
	await $AnimatedSprite2D.animation_finished
	if is_instance_valid(self):
		queue_free()

func colided():
	get_node("Colided" + str(colidedsound)).play()

func executar_turn_ex() -> void:
	if stopall: return
	speed = 0.0 
	$AnimatedSprite2D.play("turn")
	
	await $AnimatedSprite2D.animation_finished
	if stopall: return
	
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and is_instance_valid(player_node):
		direcao_volta = (player_node.global_position - global_position).normalized()
		global_rotation = direcao_volta.angle()
	else:
		direcao_volta = -direcao_volta
		global_rotation = direcao_volta.angle()
		
	$AnimatedSprite2D.play("main")
	speed = 200.0 
	ex_timer = 0.85 
	ex_estado = 0 

func _on_timer_2_timeout() -> void:
	if shoot == 2 and not stopall:
		if $AnimatedSprite2D.animation == "intro":
			if has_node("Timer2"): $Timer2.start(0.2)
			return
		if not ex:
			$AnimatedSprite2D.play("turn")
			await $AnimatedSprite2D.animation_finished
			if stopall: return
			back = true
			$AnimatedSprite2D.play("main")
		else:
			pass

func executar_quique() -> void:
	if ex: return
	var queda_total = global_position.y - altura_maxima
	bounce_count += 1
	
	if bounce_count > 2:
		die(false)
		return
		
	var pulo_perfeito = sqrt(2.0 * gravidade * (queda_total * 0.5)) * 1.2
	
	if bounce_count == 1:
		var direcao_atual = sign(speed)
		speed = 450 * direcao_atual
		velocity_y = -max(pulo_perfeito, 800)
	elif bounce_count == 2:
		var direcao_atual = sign(speed)
		speed = 250 * direcao_atual
		velocity_y = -max(pulo_perfeito * 0.5, 380)
		
	match randi_range(0, 1):
		0:
			$AnimatedSprite2D.play("bounce_1")
		1:
			$AnimatedSprite2D.play("bounce_2")
			
	await $AnimatedSprite2D.animation_finished
	if stopall:
		return
	$AnimatedSprite2D.play("main")


func _on_animated_sprite_2d_animation_finished() -> void:
	if shoot == 5 and ex and $AnimatedSprite2D.animation == "main":
		queue_free()
