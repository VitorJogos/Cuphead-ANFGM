extends AnimatedSprite2D

## Topo da frente da ponte (Toppers4).
## Fica escondido e só aparece quando o jogador está em cima
## da colisão da ponte (pé do jogador dentro do polígono "Ponte").

@onready var ponte: CollisionPolygon2D = get_node("../../Colisao/Ponte")
@onready var jogador: Node2D = get_node("../../Player1_World")

func _ready() -> void:
	visible = false

func _physics_process(_delta: float) -> void:
	var pes: Vector2 = jogador.global_position + Vector2(0.0, 16.0)
	visible = Geometry2D.is_point_in_polygon(ponte.to_local(pes), ponte.polygon)
