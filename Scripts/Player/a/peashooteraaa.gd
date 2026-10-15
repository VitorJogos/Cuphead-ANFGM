extends Area2D
var stop = false
var dmg = 4
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if stop == false:
		position += transform.x * 2100 * delta


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free() # Replace with function body.


func _on_shoot_animation_finished() -> void:
	if $shoot.animation == "intro":
		$shoot.play("main")
	else:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("atiravel"):
		stop = true
		print("tome")
		$shoot.play("death")


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("atiravel"):
		stop = true
		$shoot.play("death")
	if area.is_in_group("dano"):
		gvar.cardsadd += 0.2
		stop = true
		$shoot.play("death")
		if area.has_method("dano"):
			area.dano()
			area.vida -=4
