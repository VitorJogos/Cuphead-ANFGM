extends Node
# Direção atual do joystick (0 = solto, 1-8 = 8 direções)
# 1 = Direita, 2 = Baixo-Direita, 3 = Baixo, 4 = Baixo-Esquerda
# 5 = Esquerda, 6 = Cima-Esquerda, 7 = Cima, 8 = Cima-Direita
var dir = gvar.dir
var playerdir = 0
# Called when the node enters the scene tree for the first time.
var boss = true
var scared = false
var hp = 3
# Vida máxima: base 3 + bônus da relíquia de coração (Heart +1 => 4,
# Twin Heart +2 => 5), SEM reduzir o dano (hpnerf fica 1, como no original).
# É a ÚNICA fonte da conta: antes o HUD somava "+= 1/2" ao carregar a fase e o
# revive da morte já tinha atribuído 4/5 — na recarga da cena virava 5 e 7.
func hp_max() -> int:
	if relic == 1:
		return 4
	if relic == 2:
		return 5
	return 3
var uscharge = false
var chalice = false
var relic = 0 # 0 =none 1 =1hp 2=2hp 3=coffe 4=smokebomb #5=axe 6=sugar
var special = 0
var cardsadd = 0
var pc = false
var heposition = 0
var super2card = false
var location = 1 # 0 = normal 1 = menu/map
var cardcont = 0:
	set(novo_valor):
			# SÓ FAZ ALGO SE O VALOR FOR DIFERENTE DO ATUAL
			if novo_valor != cardcont: 
				cardcont = novo_valor
				cardaudio = true
				#print("Global diz: cardcont mudou para ", cardcont)
			else:
				cardaudio = false
var cardaudio = false
var carddiminuiu = false
var cards = 0
var tiro_automatico = false
var coins = 0
var duck = false
var mirror = false
var shooting = false
var stopall = false
var shootfposition = 0
var actualshoot = 5
var shoot1 = 0
var shoot2 = 3
var playshoot = false
var lessdmg = 1
var hpnerf = 1
var supercarged = false
signal super2jump
var atualizashot = false
var arm = false
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("arm"):
		arm = true
	if atualizashot:
		atualizashot = false
	# Como no original: Heart (relic 1) dá -5% de dano e Twin Heart (relic 2)
	# dá -10%. Afeta apenas tiros e EX; os Supers são ISENTOS
	# (ver super_1.gd e super_iii.gd, e o wiki: "Super Arts are unaffected").
	if relic == 1:
		lessdmg = 0.95
	elif relic == 2:
		lessdmg = 0.90
	else:
		lessdmg = 1
	player.dir = gvar.dir
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
	if cards >=30:
		cards = 30
	if cardsadd >= 1:
		cardsadd = 0
		cards +=1
	# Super fica 'carregado' (B vira Super em vez de EX) somente com as 5 cartas cheias E com super equipado.
	supercarged = (cards >= 30 and special != 0)
	if cards >= 6 and cards <=11:
		cardcont = 1
	if cards >= 12 and cards <=17:
		cardcont = 2
	if cards >= 18 and cards <=23:
		cardcont = 3
	if cards >= 24 and cards <=29:
		cardcont = 4
	if cards == 30:
		cardcont = 5
	if cards <6:
		cardcont = 0
func _ready() -> void:
	pass

func card():
	cards +=1

func _card():
	cards -=1
# Called every frame. 'delta' is the elapsed time since the previous frame.
