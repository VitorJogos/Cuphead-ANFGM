extends CanvasLayer

# Espera (em s) com o painel da arma visível antes de esconder ("down").
# Cada clique novo sobe a geração e cancela a espera anterior, então apertar
# muito não deixa vários "down" atrasados brigando entre si.
var _hold_gen := 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Relíquias de coração dão +HP SEM reduzir o dano (como no original).
	if player.relic == 1 or player.relic == 2:
		player.hpnerf = 1
	# ATRIBUI a vida máxima, nunca soma. O revive da morte (player_1.gd) já deixa
	# 4/5 e recarrega a cena em seguida; com o "+=" de antes o bônus dobrava e as
	# relíquias viravam 5 e 7 vidas.
	player.hp = player.hp_max()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$Control/HP/Sprite2D/AnimatedSprite2D.frame = player.actualshoot
	# TROCAR ARMA — só dá play quando NADA está tocando e o painel ainda está
	# ESCONDIDO. O painel tem 3 estados:
	#   · tocando animação  -> deixa terminar, não cutuca (nem "up" nem "down")
	#   · parado e VISÍVEL  -> NÃO repete o "up": reiniciar do zero jogava o
	#     painel de 25.49 pra -13.665 e ele voltava a descer — era exatamente
	#     o "ir e voltar" que ficava feio ao apertar muito. O clique aqui só
	#     reinicia a espera de 1s antes de esconder
	#   · parado e ESCONDIDO -> aí sim sobe
	# O Sprite2D termina o "up" em y=25.49 e o "down" em y=-13.665 (início
	# da cena: -49.13); 0 fica no meio, então serve de giro.
	if player.arm == true:
		var _ap = $Control/HP/AnimationPlayer
		if _ap.is_playing():
			pass # animação rolando: a regra é não dar play por cima
		elif $Control/HP/Sprite2D.position.y < 0.0:
			_ap.play("up") # escondido: sobe
		else:
			player.arm = false # já visível: não tem o que subir de novo
			_segura_visivel()
	if player.hp !=1:
		$Control/HP.frame = player.hp
		$Control/HP.play("default")
	else:
		$Control/HP.play("1hp")
	$Control/Card.frame = player.cards


@warning_ignore("unused_parameter")
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if player.arm and anim_name == "up":
		player.arm = false
		_segura_visivel()


# Deixa o painel visível por 1 s e só então manda o "down".
func _segura_visivel() -> void:
	_hold_gen += 1
	var meu := _hold_gen
	await get_tree().create_timer(1).timeout
	if meu != _hold_gen:
		return # um clique novo reiniciou a espera; quem chegou depois cuida
	if $Control/HP/AnimationPlayer.is_playing():
		return
	$Control/HP/AnimationPlayer.play("down")
