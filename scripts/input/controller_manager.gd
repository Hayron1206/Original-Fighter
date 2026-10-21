extends Node

signal controllers_changed

const LEFT_STICK_DEADZONE := 0.2
var _player_devices: Dictionary = {1: -1, 2: -1}

func _ready() -> void:
	add_to_group("controller_manager")
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh_controllers()

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	call_deferred("_refresh_controllers")

func _refresh_controllers() -> void:
	var devices: Array[int] = Input.get_connected_joypads()
	devices.sort()
	for player in [1, 2]:
		var index: int = int(player) - 1
		var device_id: int = devices[index] if index < devices.size() else -1
		var old_device: int = _player_devices[player]
		_player_devices[player] = device_id
		if device_id != old_device:
			if device_id >= 0:
				print("[Original Fighter] P", player, " conectado: ", Input.get_joy_name(device_id))
			else:
				print("[Original Fighter] P", player, " sem controle; teclado continua disponivel.")
	controllers_changed.emit()

func get_horizontal_axis(player: int) -> float:
	var device_id := get_device_for_player(player)
	if device_id < 0:
		return 0.0
	var axis := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	if absf(axis) < LEFT_STICK_DEADZONE:
		axis = 0.0
	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_LEFT):
		axis = -1.0
	elif Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_RIGHT):
		axis = 1.0
	return axis

func is_button_pressed(player: int, button: int) -> bool:
	var device_id := get_device_for_player(player)
	return device_id >= 0 and Input.is_joy_button_pressed(device_id, button)

func get_device_for_player(player: int) -> int:
	return int(_player_devices.get(player, -1))


