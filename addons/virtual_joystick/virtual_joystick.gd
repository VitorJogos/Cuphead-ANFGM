class_name VirtualJoystickAddon

extends Control

## A simple virtual joystick for touchscreens, with useful options.
## Github: https://github.com/MarcoFazioRandom/Virtual-Joystick-Godot

# EXPORTED VARIABLE

## The color of the button when the joystick is pressed.
@export var pressed_color := Color.GRAY

## If the input is inside this range, the output is zero.
@export_range(0, 200, 1) var deadzone_size : float = 10

## The max distance the tip can reach.
@export_range(0, 500, 1) var clampzone_size : float = 75

enum Joystick_mode {
	FIXED, ## The joystick doesn't move.
	DYNAMIC, ## Every time the joystick area is pressed, the joystick position is set on the touched position.
	FOLLOWING ## When the finger moves outside the joystick area, the joystick will follow it.
}

## If the joystick stays in the same position or appears on the touched position when touch is started
@export var joystick_mode := Joystick_mode.FIXED

enum Visibility_mode {
	ALWAYS, ## Always visible
	TOUCHSCREEN_ONLY, ## Visible on touch screens only
	WHEN_TOUCHED ## Visible only when touched
}

## If the joystick is always visible, or is shown only if there is a touchscreen
@export var visibility_mode := Visibility_mode.ALWAYS

## If true, the joystick uses Input Actions (Project -> Project Settings -> Input Map)
@export var use_input_actions := true

@export var action_left := "ui_left"
@export var action_right := "ui_right"
@export var action_up := "ui_up"
@export var action_down := "ui_down"

# PUBLIC VARIABLES

## If the joystick is receiving inputs.
var is_pressed := false

# The joystick output.
var output := Vector2.ZERO

# Direção atual do joystick (0 = solto, 1-8 = 8 direções)
# 1 = Direita, 2 = Baixo-Direita, 3 = Baixo, 4 = Baixo-Esquerda
# 5 = Esquerda, 6 = Cima-Esquerda, 7 = Cima, 8 = Cima-Direita
var dir := 0

# PRIVATE VARIABLES

var _touch_index : int = -1

@onready var _base := $Base
@onready var _tip := $Base/Tip

@onready var _base_default_position : Vector2 = _base.position
@onready var _tip_default_position : Vector2 = _tip.position

@onready var _default_color : Color = _tip.modulate

# FUNCTIONS

func _ready() -> void:
	if ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"):
		printerr("The Project Setting 'emulate_mouse_from_touch' should be set to False")
	if not ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"):
		printerr("The Project Setting 'emulate_touch_from_mouse' should be set to True")
	
	if not DisplayServer.is_touchscreen_available() and visibility_mode == Visibility_mode.TOUCHSCREEN_ONLY :
		hide()
	
	if visibility_mode == Visibility_mode.WHEN_TOUCHED:
		hide()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_inside_joystick_area(event.position) and _touch_index == -1:
				if joystick_mode == Joystick_mode.DYNAMIC or joystick_mode == Joystick_mode.FOLLOWING or (joystick_mode == Joystick_mode.FIXED and _is_point_inside_base(event.position)):
					if joystick_mode == Joystick_mode.DYNAMIC or joystick_mode == Joystick_mode.FOLLOWING:
						_move_base(event.position)
					if visibility_mode == Visibility_mode.WHEN_TOUCHED:
						show()
					_touch_index = event.index
					_tip.modulate = pressed_color
					_update_joystick(event.position)
					get_viewport().set_input_as_handled()
		elif event.index == _touch_index:
			_reset()
			if visibility_mode == Visibility_mode.WHEN_TOUCHED:
				hide()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_joystick(event.position)
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if gvar.stopfix == true:
		_reset()
		joystick_mode = Joystick_mode.FIXED # Garante frame a frame que ele não volta para DYNAMIC
	if not gvar.stopfix == true:
		joystick_mode = Joystick_mode.DYNAMIC # Garante frame a frame que ele não volta para DYNAMIC
func _move_base(new_position: Vector2) -> void:
	_base.global_position = new_position - _base.pivot_offset * get_global_transform_with_canvas().get_scale()

func _move_tip(new_position: Vector2) -> void:
	_tip.global_position = new_position - _tip.pivot_offset * _base.get_global_transform_with_canvas().get_scale()

func _is_point_inside_joystick_area(point: Vector2) -> bool:
	var x: bool = point.x >= global_position.x and point.x <= global_position.x + (size.x * get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= global_position.y and point.y <= global_position.y + (size.y * get_global_transform_with_canvas().get_scale().y)
	return x and y

func _get_base_radius() -> Vector2:
	return _base.size * _base.get_global_transform_with_canvas().get_scale() / 2

func _is_point_inside_base(point: Vector2) -> bool:
	var _base_radius = _get_base_radius()
	var center : Vector2 = _base.global_position + _base_radius
	var vector : Vector2 = point - center
	if vector.length_squared() <= _base_radius.x * _base_radius.x:
		return true
	else:
		return false

func _get_direction_8way(vector: Vector2) -> int:
	# Se o vetor está na deadzone, retorna 0
	if vector.length() <= deadzone_size:
		return 0
	
	# Calcula o ângulo em radianos
	var angle = vector.angle()
	
	# Converte para graus e normaliza para 0-360
	var degrees = rad_to_deg(angle)
	if degrees < 0:
		degrees += 360
	
	# Divide em 8 setores de 45 graus cada
	# Adiciona 22.5 graus para centralizar os setores
	var sector = int((degrees + 22.5) / 45.0) % 8
	
	# Mapeia os setores para as direções:
	# 0: Direita, 1: Baixo-Direita, 2: Baixo, 3: Baixo-Esquerda
	# 4: Esquerda, 5: Cima-Esquerda, 6: Cima, 7: Cima-Direita
	return sector + 1

func _update_joystick(touch_position: Vector2) -> void:
	var _base_radius = _get_base_radius()
	var center : Vector2 = _base.global_position + _base_radius
	var vector : Vector2 = touch_position - center
	vector = vector.limit_length(clampzone_size)
	
	if joystick_mode == Joystick_mode.FOLLOWING and touch_position.distance_to(center) > clampzone_size:
		_move_base(touch_position - vector)
	
	_move_tip(center + vector)
	
	# === ALTERAÇÃO PARA REMOVER SISTEMA DE PRESSÃO ===
	if vector.length() > deadzone_size: # Verifica se está fora da deadzone
		is_pressed = true
		output = vector.normalized() # Sempre retorna direção normalizada (magnitude 1)
		dir = _get_direction_8way(vector) # Calcula a direção de 1-8
		gvar.dir =  _get_direction_8way(vector)
	else:
		is_pressed = false
		output = Vector2.ZERO
		dir = 0 # Joystick solto
		gvar.dir = 0
	# === FIM DA ALTERAÇÃO ===
	
	if use_input_actions:
		# Release actions
		if output.x >= 0 and Input.is_action_pressed(action_left):
			Input.action_release(action_left)
		if output.x <= 0 and Input.is_action_pressed(action_right):
			Input.action_release(action_right)
		if output.y >= 0 and Input.is_action_pressed(action_up):
			Input.action_release(action_up)
		if output.y <= 0 and Input.is_action_pressed(action_down):
			Input.action_release(action_down)
		# Press actions - agora sempre com força máxima (1.0)
		if output.x < 0:
			Input.action_press(action_left, 1.0)
		if output.x > 0:
			Input.action_press(action_right, 1.0)
		if output.y < 0:
			Input.action_press(action_up, 1.0)
		if output.y > 0:
			Input.action_press(action_down, 1.0)

func _reset():
	is_pressed = false
	output = Vector2.ZERO
	dir = 0 # Reset da direção para joystick solto
	gvar.dir = 0
	_touch_index = -1
	_tip.modulate = _default_color
	_base.position = _base_default_position
	_tip.position = _tip_default_position
	# Release actions
	if use_input_actions:
		for action in [action_left, action_right, action_down, action_up]:
			if Input.is_action_pressed(action):
				Input.action_release(action)


func _on_touch_screen_button_pressed() -> void:
	pass # Replace with function body.
