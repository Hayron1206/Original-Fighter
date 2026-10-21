extends CanvasLayer

const BAR_WIDTH := 420.0
const BAR_HEIGHT := 28.0
var _health_bars: Dictionary = {}
var _ai_status: Label
var _ai_toggle: CheckButton
var _view_width := 1280.0

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view_width = get_viewport().get_visible_rect().size.x
	add_child(root)
	_create_health_display(root, 1, "RAVEN — P1", Vector2(40.0, 18.0), false, Color("d9273e"))
	_create_health_display(root, 2, "VESPER — P2", Vector2(_view_width - BAR_WIDTH - 40.0, 18.0), true, Color("27c7d6"))
	_create_options_menu(root)
	_connect_fighters()

func _create_health_display(root: Control, player: int, fighter_name: String, position: Vector2, reverse: bool, fill_color: Color) -> void:
	var title := Label.new()
	title.text = fighter_name
	title.position = position
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("f4f1ec"))
	root.add_child(title)

	var bar := ProgressBar.new()
	bar.position = position + Vector2(0.0, 30.0)
	bar.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	if reverse:
		bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	var background := StyleBoxFlat.new()
	background.bg_color = Color("303544")
	background.corner_radius_top_left = 5
	background.corner_radius_top_right = 5
	background.corner_radius_bottom_left = 5
	background.corner_radius_bottom_right = 5
	bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 5
	fill.corner_radius_top_right = 5
	fill.corner_radius_bottom_left = 5
	fill.corner_radius_bottom_right = 5
	bar.add_theme_stylebox_override("fill", fill)
	root.add_child(bar)
	_health_bars[player] = bar

func _create_options_menu(root: Control) -> void:
	var options_button := Button.new()
	options_button.text = "OPÇÕES"
	options_button.position = Vector2((_view_width - 150.0) * 0.5, 18.0)
	options_button.custom_minimum_size = Vector2(150.0, 34.0)
	root.add_child(options_button)

	var panel := PanelContainer.new()
	panel.position = Vector2((_view_width - 300.0) * 0.5, 60.0)
	panel.custom_minimum_size = Vector2(300.0, 110.0)
	panel.visible = false
	root.add_child(panel)
	options_button.pressed.connect(func() -> void: panel.visible = not panel.visible)

	var content := VBoxContainer.new()
	panel.add_child(content)
	var heading := Label.new()
	heading.text = "CONTROLE DO OPONENTE"
	heading.add_theme_font_size_override("font_size", 16)
	content.add_child(heading)
	_ai_toggle = CheckButton.new()
	_ai_toggle.text = "Computador controla Vesper (P2)"
	_ai_toggle.button_pressed = false
	_ai_toggle.toggled.connect(_on_ai_toggled)
	content.add_child(_ai_toggle)
	_ai_status = Label.new()
	_ai_status.text = "P2 controlado por teclado ou controle"
	content.add_child(_ai_status)

func _connect_fighters() -> void:
	for fighter in get_tree().get_nodes_in_group("fighters"):
		var player := int(fighter.player_number)
		if _health_bars.has(player):
			fighter.health_changed.connect(_on_health_changed.bind(player))
			_on_health_changed(fighter.health, fighter.MAX_HEALTH, player)
		if player == 2:
			fighter.set_ai_controlled(_ai_toggle.button_pressed)

func _on_health_changed(current_health: float, max_health: float, player: int) -> void:
	var bar: ProgressBar = _health_bars[player]
	bar.max_value = max_health
	bar.value = current_health

func _on_ai_toggled(enabled: bool) -> void:
	for fighter in get_tree().get_nodes_in_group("fighters"):
		if int(fighter.player_number) == 2:
			fighter.set_ai_controlled(enabled)
	_ai_status.text = "Computador controlando P2" if enabled else "P2 controlado por teclado ou controle"


