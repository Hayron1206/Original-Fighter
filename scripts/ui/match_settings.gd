extends Node
const CHARACTERS: Array[Dictionary] = [
	{"name":"RAVEN","sprite_key":"raven","primary":"20232d","accent":"d9273e","hair":"11131a"},
	{"name":"VESPER","sprite_key":"vesper","primary":"20293b","accent":"27c7d6","hair":"d1d9e5"},
	{"name":"HAYASHI KUROGANE","sprite_key":"hayashi","primary":"20232d","accent":"d9273e","hair":"e8e8ee"},
]
var player_one_character := 0
var player_two_character := 1
var stage_index := 0
func get_character_config(character_index: int) -> Dictionary:
	return CHARACTERS[clampi(character_index, 0, CHARACTERS.size() - 1)]