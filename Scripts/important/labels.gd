extends Label
@export var order = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if order == 1:
		self_modulate = Color.RED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func red():
	self_modulate = Color.RED

func black():
	self_modulate = Color.BLACK
