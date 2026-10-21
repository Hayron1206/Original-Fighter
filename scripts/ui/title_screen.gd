extends Control
const FIGHT_SCENE := "res://scenes/fight/fight.tscn"
const CHARACTER_NAMES := ["RAVEN", "VESPER", "HAYASHI KUROGANE"]
const STAGE_NAMES := ["Vila do Vale das Lanternas", "Omni Layer"]
var _player_one_selector: OptionButton
var _player_two_selector: OptionButton
var _stage_selector: OptionButton
func _ready() -> void:
	_build_screen()
func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("101522")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var accent_band := ColorRect.new()
	accent_band.color = Color("d9273e")
	accent_band.anchor_top = 0.82
	accent_band.anchor_bottom = 1.0
	accent_band.color.a = 0.16
	background.add_child(accent_band)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(780.0, 0.0)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	center.add_child(content)
	var title := Label.new()
	title.text = "ORIGINAL FIGHTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("f4f1ec"))
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "ESCOLHA OS LUTADORES E O CENÁRIO"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("d9273e"))
	content.add_child(subtitle)
	var character_row := HBoxContainer.new()
	character_row.alignment = BoxContainer.ALIGNMENT_CENTER
	character_row.add_theme_constant_override("separation", 18)
	content.add_child(character_row)
	_player_one_selector = _create_character_panel(character_row, "JOGADOR 1")
	_player_two_selector = _create_character_panel(character_row, "JOGADOR 2")
	_player_one_selector.select(0)
	_player_two_selector.select(1)
	var stage_panel := PanelContainer.new()
	stage_panel.custom_minimum_size = Vector2(680.0, 92.0)
	stage_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(stage_panel)
	var stage_content := VBoxContainer.new()
	stage_content.add_theme_constant_override("separation", 5)
	stage_panel.add_child(stage_content)
	var stage_label := Label.new()
	stage_label.text = "CENÁRIO"
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.add_theme_font_size_override("font_size", 16)
	stage_content.add_child(stage_label)
	_stage_selector = OptionButton.new()
	_stage_selector.custom_minimum_size = Vector2(420.0, 38.0)
	_stage_selector.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for stage_name in STAGE_NAMES:
		_stage_selector.add_item(stage_name)
	stage_content.add_child(_stage_selector)
	_stage_selector.select(0)
	var play_button := Button.new()
	play_button.text = "COMEÇAR LUTA"
	play_button.custom_minimum_size = Vector2(240.0, 52.0)
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_button.add_theme_font_size_override("font_size", 20)
	play_button.pressed.connect(_start_fight)
	content.add_child(play_button)
	var footer := Label.new()
	footer.text = "P1: WASD / Xbox ou PlayStation     P2: Setas / segundo controle"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color("aeb5c7"))
	content.add_child(footer)
func _create_character_panel(parent: HBoxContainer, player_label: String) -> OptionButton:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360.0, 105.0)
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)
	var label := Label.new()
	label.text = player_label
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	content.add_child(label)
	var selector := OptionButton.new()
	selector.custom_minimum_size = Vector2(320.0, 40.0)
	selector.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for character_name in CHARACTER_NAMES:
		selector.add_item(character_name)
	content.add_child(selector)
	return selector
func _start_fight() -> void:
	var settings = get_node("/root/MatchSettings")
	settings.player_one_character = _player_one_selector.selected
	settings.player_two_character = _player_two_selector.selected
	settings.stage_index = _stage_selector.selected
	var error := get_tree().change_scene_to_file(FIGHT_SCENE)
	if error != OK:
		push_error("Nao foi possivel abrir a cena de luta.")