extends CanvasLayer

const BAR_WIDTH := 420.0
const BAR_HEIGHT := 28.0
const ROUND_DURATION := 99.0
var _health_bars: Dictionary = {}
var _fighter_name_labels: Dictionary = {}
var _fighters: Dictionary = {}
var _ai_status: Label
var _ai_toggle: CheckButton
var _stage_selector: OptionButton
var _timer_label: Label
var _view_width := 1280.0
var _time_left := ROUND_DURATION
var _round_over := false

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view_width = get_viewport().get_visible_rect().size.x
	add_child(root)
	_create_health_display(root, 1, "RAVEN — P1", Vector2(40.0, 18.0), false, Color("d9273e"))
	_create_health_display(root, 2, "VESPER — P2", Vector2(_view_width - BAR_WIDTH - 40.0, 18.0), true, Color("27c7d6"))
	_create_round_timer(root)
	_create_options_menu(root)
	_connect_fighters()

func _process(delta: float) -> void:
	if _round_over:
		return
	var fighter_one = _fighters.get(1)
	var fighter_two = _fighters.get(2)
	if fighter_one == null or fighter_two == null:
		return
	if fighter_one.health <= 0.0:
		_finish_round(2, "NOCAUTE")
		return
	if fighter_two.health <= 0.0:
		_finish_round(1, "NOCAUTE")
		return
	_time_left = maxf(0.0, _time_left - delta)
	_update_timer_label()
	if _time_left <= 0.0:
		if is_equal_approx(fighter_one.health, fighter_two.health):
			_finish_round(0, "TEMPO ESGOTADO")
		else:
			_finish_round(1 if fighter_one.health > fighter_two.health else 2, "TEMPO ESGOTADO")

func _create_health_display(root: Control, player: int, fighter_name: String, position: Vector2, reverse: bool, fill_color: Color) -> void:
	var title := Label.new()
	title.text = fighter_name
	title.position = position
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("f4f1ec"))
	root.add_child(title)

	_fighter_name_labels[player] = title

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

func _create_round_timer(root: Control) -> void:
	_timer_label = Label.new()
	_timer_label.position = Vector2((_view_width - 120.0) * 0.5, 44.0)
	_timer_label.custom_minimum_size = Vector2(120.0, 36.0)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 28)
	_timer_label.add_theme_color_override("font_color", Color("fff1c7"))
	root.add_child(_timer_label)
	_update_timer_label()

func _update_timer_label() -> void:
	var total_seconds := ceili(_time_left)
	var minutes := floori(float(total_seconds) / 60.0)
	var seconds := total_seconds % 60
	_timer_label.text = "%02d:%02d" % [minutes, seconds]

func _create_options_menu(root: Control) -> void:
	var options_button := Button.new()
	options_button.text = "OPÇÕES"
	options_button.position = Vector2((_view_width - 150.0) * 0.5, 88.0)
	options_button.custom_minimum_size = Vector2(150.0, 34.0)
	root.add_child(options_button)

	var panel := PanelContainer.new()
	panel.position = Vector2((_view_width - 360.0) * 0.5, 128.0)
	panel.custom_minimum_size = Vector2(360.0, 190.0)
	panel.visible = false
	root.add_child(panel)
	options_button.pressed.connect(func() -> void: panel.visible = not panel.visible)

	var content := VBoxContainer.new()
	panel.add_child(content)
	var stage_heading := Label.new()
	stage_heading.text = "CENÁRIO"
	stage_heading.add_theme_font_size_override("font_size", 16)
	content.add_child(stage_heading)
	_stage_selector = OptionButton.new()
	_stage_selector.add_item("Vila do Vale das Lanternas", 0)
	_stage_selector.add_item("Omni Layer", 1)
	_stage_selector.item_selected.connect(_on_stage_selected)
	var match_settings = get_node("/root/MatchSettings")
	_stage_selector.select(match_settings.stage_index)
	content.add_child(_stage_selector)
	var opponent_heading := Label.new()
	opponent_heading.text = "CONTROLE DO OPONENTE"
	opponent_heading.add_theme_font_size_override("font_size", 16)
	content.add_child(opponent_heading)
	_ai_toggle = CheckButton.new()
	_ai_toggle.text = "Computador controla Jogador 2 (P2)"
	_ai_toggle.button_pressed = false
	_ai_toggle.toggled.connect(_on_ai_toggled)
	content.add_child(_ai_toggle)
	_ai_status = Label.new()
	_ai_status.text = "P2 controlado por teclado ou controle"
	content.add_child(_ai_status)

func _connect_fighters() -> void:
	for fighter in get_tree().get_nodes_in_group("fighters"):
		var player := int(fighter.player_number)
		_fighters[player] = fighter
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

func _finish_round(winner: int, reason: String) -> void:
	if _round_over:
		return
	_round_over = true
	var result_text := "EMPATE!"
	if winner == 1:
		result_text = "VOCÊ VENCEU!" if _ai_toggle.button_pressed else "%s VENCEU!" % str(_fighters[1].display_name)
	elif winner == 2:
		result_text = "VOCÊ PERDEU!" if _ai_toggle.button_pressed else "%s VENCEU!" % str(_fighters[2].display_name)
	_show_result_overlay(result_text, reason)

func _show_result_overlay(result_text: String, reason: String) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.03, 0.06, 0.78)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420.0, 230.0)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(content)
	var result_label := Label.new()
	result_label.text = result_text
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 34)
	content.add_child(result_label)
	var reason_label := Label.new()
	reason_label.text = reason
	reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason_label.add_theme_font_size_override("font_size", 18)
	content.add_child(reason_label)
	var rematch_button := Button.new()
	rematch_button.text = "JOGAR NOVAMENTE"
	rematch_button.custom_minimum_size = Vector2(220.0, 42.0)
	rematch_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rematch_button.pressed.connect(func() -> void: get_tree().reload_current_scene())
	content.add_child(rematch_button)

func _on_stage_selected(stage_index: int) -> void:
	get_tree().current_scene.call("select_stage", stage_index)

func set_fighter_names(player_one_name: String, player_two_name: String) -> void:
	if _fighter_name_labels.has(1):
		_fighter_name_labels[1].text = player_one_name
	if _fighter_name_labels.has(2):
		_fighter_name_labels[2].text = player_two_name