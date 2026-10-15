extends OptionButton
@export var idk = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if idk == 0:
		selected = player.special
	if idk == 1:
		selected = player.relic
	if idk ==2:
		selected = player.shoot1
	if idk ==3:
		selected = player.shoot2
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_item_selected(index: int) -> void:
	if idk == 0:
		var bid  = get_item_id(index)
		player.special = bid
	if idk == 1:
		var bid  = get_item_id(index)
		player.relic = bid
	if idk == 2:
		var bid  = get_item_id(index)
		await get_tree().create_timer(0.125).timeout
		player.shoot1 = bid
		player.atualizashot = true
		await get_tree().create_timer(0.5).timeout
		player.playshoot = true
		await get_tree().create_timer(0.01).timeout
		player.playshoot = false
	if idk == 3:
		var bid  = get_item_id(index)
		await get_tree().create_timer(0.125).timeout
		player.shoot2 = bid
		player.atualizashot = true
		await get_tree().create_timer(0.5).timeout
		player.playshoot = true
		await get_tree().create_timer(0.01).timeout
		player.playshoot = false
