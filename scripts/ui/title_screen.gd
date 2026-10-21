extends Control

const FIGHT_SCENE := "res://scenes/fight/fight.tscn"

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("101522")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var accent_band := ColorRect.new()
	accent_band.color = Color("d9273e")
	accent_band.anchor_top = 0.72
	accent_band.anchor_bottom = 1.0
	accent_band.offset_top = 0.0
	accent_band.offset_bottom = 0.0
	accent_band.color.a = 0.18
	background.add_child(accent_band)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(560.0, 300.0)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	center.add_child(content)

	var title := Label.new()
	title.text = "ORIGINAL FIGHTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("f4f1ec"))
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "DEMO DE COMBATE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("d9273e"))
	content.add_child(subtitle)

	var play_button := Button.new()
	play_button.text = "JOGAR"
	play_button.custom_minimum_size = Vector2(220.0, 54.0)
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_button.add_theme_font_size_override("font_size", 22)
	play_button.pressed.connect(_start_fight)
	content.add_child(play_button)

	var footer := Label.new()
	footer.text = "RAVEN  VS  VESPER"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 16)
	footer.add_theme_color_override("font_color", Color("aeb5c7"))
	content.add_child(footer)

func _start_fight() -> void:
	var error := get_tree().change_scene_to_file(FIGHT_SCENE)
	if error != OK:
		push_error("Nao foi possivel abrir a cena de luta.")
