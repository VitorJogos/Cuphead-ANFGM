extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func parry():
	$AnimatedSprite2D.frame = 1
	$Timer.start()
	await $Timer.timeout
	$AnimatedSprite2D.frame = 0
