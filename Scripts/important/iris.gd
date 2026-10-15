extends AnimatedSprite2D

signal fechou
signal abriu
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	abrir()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if frame == 16:
		if animation == "reverse":
			gvar.fch.emit()
			print("fechou")
		if animation == "default":
			print("acabou")
			gvar.abr.emit()
			print("abriu")

func abrir():
	$".".play("default")

func fechar():
	$".".play("reverse")


func _on_animation_finished() -> void:
	if animation == "reverse":
		gvar.fch.emit()
		print("fechou")
	if animation == "default":
		print("acabou")
		gvar.abr.emit()
		print("abriu")
