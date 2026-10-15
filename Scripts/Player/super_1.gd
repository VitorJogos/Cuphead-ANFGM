extends Area2D

# Como no original, os Supers NÃO são afetados pelo nerf dos charms de coração.
var dano = 27.15 * player.hpnerf
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CollisionShape2D.rotation_degrees = $".".rotation_degrees
	if player.mirror:
		$".".rotation_degrees = 180
	if not player.mirror:
		$".".rotation_degrees = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$CollisionShape2D.rotation_degrees = $".".rotation_degrees
	if player.mirror:
		$".".rotation_degrees = 180
	if not player.mirror:
		$".".rotation_degrees = 0
	var areas = $".".get_overlapping_areas()
	var bodies = $".".get_overlapping_bodies()
	if $Timer.is_stopped():
		for area in areas:
			print("areas encontradas ", area.name)
			if area.is_in_group("dano"):
				$Timer.start()
				if area.has_method("dano"):
					area.dano(dano)
		for body in bodies:
			if body.is_in_group("dano"):
				$Timer.start()
				if body.has_method("dano"):
					body.dano(dano)


func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()
