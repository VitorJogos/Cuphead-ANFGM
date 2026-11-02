extends Camera2D
## Camera do mapa fiel ao original (CupheadMapCamera.cs).
##
## O original usa orthographicSize 3.6 com 100 px por unidade = 720 px de
## altura de mundo na tela, segue o jogador com Lerp(posicao, alvo,
## delta * 6) e prende a imagem dentro dos limites do mapa (Map.Camera).
##
## Aqui: a suavizacao e o proprio position_smoothing_speed = 6.0 (mesma
## matematica do Lerp do Unity) e o zoom enquadra SEMPRE 720 px de mundo
## de altura — a largura acompanha o aspecto, entao nada de imagem
## esticada. O enquadramento nao muda com a RESOLUÇÃO nem com o OVERSCAN:
## igual ao original, o que muda e so o tamanho da imagem na janela.
##
## Os limites do mapa (limit_left/top/right/bottom) sao informados por
## cada cena de mapa (ile i, etc.), igual ao Map.Camera do original.

const ALTURA_MUNDO := 720.0

var _tam_anterior := Vector2.ZERO

func _process(_delta: float) -> void:
	# Poll simples: resolve zoom na primeira frame e se a RESOLUÇÃO /
	# OVERSCAN / janela mudarem no meio do jogo.
	var tam := get_viewport().get_visible_rect().size
	if tam != _tam_anterior:
		_tam_anterior = tam
		if tam.y > 0.0:
			var z := tam.y / ALTURA_MUNDO
			zoom = Vector2(z, z)
