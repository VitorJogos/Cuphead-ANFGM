extends AnimatedSprite2D
@export var super2 = 0
var heposition = position
@export var exfx = 0
var is_charge = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if exfx == 1:
		if is_charge == 1:
			$".".play("charge_up")
		else:
			$".".play("a")
	if super2 == 1:
		$".".frame = 0
		$".".play("default")

		if $".".frame == 19:
			player.super2jump.emit()
		if $".".flip_h:
			$".".offset.x = 42
			#$AnimationPlayer.play("L")
		if not $".".flip_h:
			$".".offset.x = -42
			#$AnimationPlayer.play("R")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if super2 == 1:
		if $".".frame == 19:
			player.super2jump.emit()
		if $".".frame == 7:
			Engine.time_scale = 0.0 # Congela o tempo do jogo
			# Usamos um timer que ignora o tempo de jogo (process_always)
			await get_tree().create_timer(0.1, true, false, true).timeout
			Engine.time_scale = 1.0 # Volta ao normal
		if $".".flip_h:
			$".".offset.x = 42
			#$AnimationPlayer.play("L")
		if not $".".flip_h:
			$".".offset.x = -42
			#$AnimationPlayer.play("R")
	await $".".animation_finished
	queue_free()

func position():
	pass
