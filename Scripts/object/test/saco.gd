extends Area2D
@export var saco = false
@export var hp = 1000
@export var savehp = 0
var died = false
var explodie = false
var explosion = preload("res://Scenes/objects/test/bossexplosion.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	savehp = hp
	print(savehp)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not died and saco:
		$Label.text = "HP - " + "%.1f" % hp
	if explodie:
		if hp == 0:
			if $explodetiemr.is_stopped():
				var explode = explosion.instantiate()
				add_child(explode)
				explode.global_position = $Marker2D.global_position
				$explodetiemr.start()
	if hp <0 and hp !=0:
		die()
		hp = 0
	if died and saco:
		if $Timer.is_stopped():
			$Timer.start()
			Tradutor.definir($Label, "Recuperando HP...")
			await $Timer.timeout
			explodie = false
			gvar.desatshots = false
			hp += savehp
			died = false

@warning_ignore("shadowed_variable")
func dano(dano):
	if not died:
		piscar_dano()
		hp -= dano

func die():
	died = true
	gvar.knockout.emit()
	gvar.desatshots = true
	print(hp)
	await gvar.bossexplode
	explodie = true

func piscar_dano():
	# Muda a cor para um tom avermelhado ou branco
	$AnimatedSprite2D.modulate = Color(5, 4, 5, 1) # Multiplica a cor (fica brilhante)
	await get_tree().create_timer(0.1).timeout # Espera um décimo de segundo
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 1) # Volta ao normal
