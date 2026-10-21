extends Node2D

const STAGE_SIZE := Vector2(1280.0, 720.0)
const STAGE_NAMES := ["Vila do Vale das Lanternas", "Omni Layer"]
const STAGE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/stages/lantern_valley.jpg"),
	preload("res://assets/stages/omni_layer.png"),
]
const STAGE_FLOOR_Y := [526.0, 530.0]

var current_stage_index := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sync_floor()
	queue_redraw()

func set_stage(stage_index: int) -> void:
	current_stage_index = clampi(stage_index, 0, STAGE_TEXTURES.size() - 1)
	_sync_floor()
	queue_redraw()

func get_floor_y() -> float:
	return float(STAGE_FLOOR_Y[current_stage_index])

func get_stage_name() -> String:
	return STAGE_NAMES[current_stage_index]

func _sync_floor() -> void:
	var floor_body := get_node("Floor") as StaticBody2D
	floor_body.position.y = get_floor_y() + 10.0

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, STAGE_SIZE), Color("101522"))
	var stage_texture: Texture2D = STAGE_TEXTURES[current_stage_index]
	var texture_size := Vector2(stage_texture.get_width(), stage_texture.get_height())
	var scale_factor := maxf(STAGE_SIZE.x / texture_size.x, STAGE_SIZE.y / texture_size.y)
	var draw_size := texture_size * scale_factor
	var draw_position := (STAGE_SIZE - draw_size) * 0.5
	draw_texture_rect(stage_texture, Rect2(draw_position, draw_size), false)