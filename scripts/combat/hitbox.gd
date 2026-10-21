extends Area2D

signal hit_landed(hurtbox: Area2D)

const ACTIVE_DURATION := 0.12
var _active := false
var _hit_targets: Dictionary = {}

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func activate() -> void:
	if _active:
		return
	_active = true
	_hit_targets.clear()
	set_deferred("monitoring", true)
	await get_tree().create_timer(ACTIVE_DURATION).timeout
	set_deferred("monitoring", false)
	_active = false

func _on_area_entered(area: Area2D) -> void:
	if not _active or not area.is_in_group("hurtboxes"):
		return
	var target := area.get_parent()
	if target == get_parent() or _hit_targets.has(target.get_instance_id()):
		return
	_hit_targets[target.get_instance_id()] = true
	hit_landed.emit(area)
