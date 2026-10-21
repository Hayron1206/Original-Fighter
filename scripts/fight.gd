extends Node2D

func _ready() -> void:
	var settings = get_node("/root/MatchSettings")
	var player_one = get_node("RavenPlaceholder")
	var player_two = get_node("VesperPlaceholder")
	_configure_fighter(player_one, 1, settings.player_one_character)
	_configure_fighter(player_two, 2, settings.player_two_character)
	select_stage(settings.stage_index)
	var fight_ui = get_node("FightUI")
	fight_ui.call("set_fighter_names", player_one.display_name, player_two.display_name)

func _configure_fighter(fighter, player_number: int, character_index: int) -> void:
	var settings = get_node("/root/MatchSettings")
	var character: Dictionary = settings.get_character_config(character_index)
	fighter.player_number = player_number
	fighter.display_name = "%s — P%d" % [character["name"], player_number]
	fighter.primary_color = Color(character["primary"])
	fighter.accent_color = Color(character["accent"])
	fighter.hair_color = Color(character["hair"])
	fighter.call("set_character_visual", character["sprite_key"])

func select_stage(stage_index: int) -> void:
	var settings = get_node("/root/MatchSettings")
	settings.stage_index = clampi(stage_index, 0, 1)
	var arena = get_node("Arena")
	arena.call("set_stage", settings.stage_index)
	var floor_y := float(arena.call("get_floor_y"))
	var p1_spawn: Marker2D = $FighterSpawns/P1Spawn
	var p2_spawn: Marker2D = $FighterSpawns/P2Spawn
	var player_one: CharacterBody2D = $RavenPlaceholder
	var player_two: CharacterBody2D = $VesperPlaceholder
	p1_spawn.position.y = floor_y
	p2_spawn.position.y = floor_y
	player_one.position.y = floor_y
	player_two.position.y = floor_y