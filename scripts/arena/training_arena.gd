extends Node2D

const STAGE_SIZE := Vector2(1280, 720)
const FLOOR_Y := 520.0

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, STAGE_SIZE), Color("101522"))
	draw_rect(Rect2(0, 170, 1280, 350), Color("171c2a"))
	draw_rect(Rect2(0, FLOOR_Y, 1280, 200), Color("0c101a"))

	for i in range(9):
		var x := 70.0 + i * 145.0
		draw_rect(Rect2(x, 190, 4, 300), Color(0.25, 0.34, 0.48, 0.28))
		draw_line(Vector2(x - 35, 420), Vector2(x + 38, 420), Color(0.48, 0.12, 0.2, 0.25), 2.0)

	draw_rect(Rect2(0, FLOOR_Y - 5.0, 1280, 5), Color("d9dce4"))
	for i in range(11):
		var x := float(i) * 140.0 - 120.0
		draw_line(Vector2(640, FLOOR_Y), Vector2(x, 720), Color(0.3, 0.36, 0.48, 0.24), 1.0)
	for y in [570, 635, 710]:
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.3, 0.36, 0.48, 0.2), 1.0)
