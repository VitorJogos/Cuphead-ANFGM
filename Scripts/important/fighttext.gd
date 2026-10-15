extends AnimatedSprite2D

var announcer = randi_range(1,5)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if player.boss:
		await gvar.abr
		gvar.stopall = true
		$".".play("new_animation")
		$Timer.start()
		announcer = randi_range(1,5)
		get_node("annoucer1_" + str(announcer)).play()
		await $Timer.timeout
		$".".play("ready")
		await $".".animation_finished
		$".".play("wallop")
		await $".".animation_finished
		gvar.stopall = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if $".".animation == "wallop":
		if $".".frame == 7:
			announcer = randi_range(1,5)
			get_node("annoucer2_" + str(announcer)).play()
	if $".".animation == "knockout":
		if $".".frame == 7:
			$knockout_bell.play()
			$knockout.play()
			await $knockout.finished
			$knockout_boom.play()
	await gvar.knockout
	knockout()

func knockout():
	$".".play("knockout")
	gvar.canpause = false


func _on_animation_finished() -> void:
	if $".".animation == "knockout":
		gvar.bossexplode.emit()
		await get_tree().create_timer(4.0).timeout
		$"../../Iris/Iris".fechar()
		await get_tree().create_timer(1.0).timeout
		$"../../Iris/Iris".abrir()
