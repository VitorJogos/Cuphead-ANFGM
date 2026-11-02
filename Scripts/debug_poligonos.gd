extends Node2D

const CORES: Array[Color] = [
	Color(1.0, 0.2, 0.2, 0.3),
	Color(0.2, 1.0, 0.2, 0.3),
	Color(0.35, 0.65, 1.0, 0.3),
	Color(1.0, 1.0, 0.25, 0.3),
	Color(1.0, 0.4, 1.0, 0.3),
	Color(0.25, 1.0, 1.0, 0.3),
	Color(1.0, 0.65, 0.25, 0.3),
]

var _formas: Array[Dictionary] = []

func _ready() -> void:
	z_index = 100
	var colisao := get_node_or_null(^"../Colisao")
	if colisao == null:
		return
	var i := 0
	for filho in colisao.get_children():
		if not (filho is CollisionPolygon2D):
			continue
		var pol := filho as CollisionPolygon2D
		var cor := CORES[i % CORES.size()]
		i += 1
		_formas.append({"pontos": pol.polygon, "desloc": pol.position, "cor": cor})
	queue_redraw()

func _draw() -> void:
	for forma in _formas:
		var pontos: PackedVector2Array = forma["pontos"]
		var desloc: Vector2 = forma["desloc"]
		var cor: Color = forma["cor"]
		if pontos.size() < 3:
			continue
		var mundiais := PackedVector2Array()
		for p in pontos:
			mundiais.append(p + desloc)
		var indices := Geometry2D.triangulate_polygon(mundiais)
		if indices.size() >= 3:
			var k := 0
			while k < indices.size():
				var triangulo := PackedVector2Array([
					mundiais[indices[k]],
					mundiais[indices[k + 1]],
					mundiais[indices[k + 2]],
				])
				draw_colored_polygon(triangulo, cor)
				k += 3
		else:
			draw_colored_polygon(mundiais, cor)
		var contorno := Color(cor.r, cor.g, cor.b, 1.0)
		var total := mundiais.size()
		for j in total:
			draw_line(mundiais[j], mundiais[(j + 1) % total], contorno, 2.0, true)
