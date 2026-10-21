extends CharacterBody2D

signal health_changed(current_health: float, max_health: float)

@export var player_number := 1
@export var display_name := "FIGHTER"
@export var primary_color := Color("20232d")
@export var accent_color := Color("d9273e")
@export var hair_color := Color("11131a")

const MOVE_SPEED := 320.0
const GRAVITY := 1600.0
const JUMP_SPEED := -620.0
const LEFT_BOUND := 100.0
const RIGHT_BOUND := 1180.0
const ATTACK_COOLDOWN := 0.38
const MAX_HEALTH := 100.0
const DAMAGE_PER_HIT := 10.0
const AI_ATTACK_RANGE := 105.0
const AI_ATTACK_COOLDOWN := 0.82
const HITSTUN_DURATION := 0.16

@onready var hitbox: Area2D = $Hitbox
var controller_manager: Node
var health := MAX_HEALTH
var ai_controlled := false
var facing_left := false
var is_blocking := false
var _attack_cooldown := 0.0
var _attack_visual_timer := 0.0
var _ai_attack_timer := 0.0
var _hitstun_timer := 0.0
var _knockback_velocity := 0.0
var _jump_was_down := false
var _attack_was_down := false

func _ready() -> void:
	controller_manager = get_tree().get_first_node_in_group("controller_manager")
	hitbox.hit_landed.connect(_on_hitbox_hit_landed)
	_update_facing()
	queue_redraw()

func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_ai_attack_timer = maxf(0.0, _ai_attack_timer - delta)
	var was_attacking := _attack_visual_timer > 0.0
	_attack_visual_timer = maxf(0.0, _attack_visual_timer - delta)

	var direction := 0.0
	var jump_down := false
	var block_pressed := false
	var attack_down := false
	if player_number == 2 and ai_controlled:
		var opponent := _get_opponent()
		if opponent != null:
			var distance_to_opponent := opponent.global_position.x - global_position.x
			direction = signf(distance_to_opponent) if absf(distance_to_opponent) > AI_ATTACK_RANGE else 0.0
			attack_down = absf(distance_to_opponent) <= AI_ATTACK_RANGE and _ai_attack_timer <= 0.0 and is_on_floor()
			if attack_down:
				_ai_attack_timer = AI_ATTACK_COOLDOWN
	elif player_number == 1:
		if Input.is_key_pressed(KEY_A):
			direction -= 1.0
		if Input.is_key_pressed(KEY_D):
			direction += 1.0
		jump_down = Input.is_key_pressed(KEY_W)
		block_pressed = Input.is_key_pressed(KEY_F)
		attack_down = Input.is_key_pressed(KEY_G)
	else:
		if Input.is_key_pressed(KEY_LEFT):
			direction -= 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			direction += 1.0
		jump_down = Input.is_key_pressed(KEY_UP)
		block_pressed = Input.is_key_pressed(KEY_K)
		attack_down = Input.is_key_pressed(KEY_COMMA)

	if controller_manager != null and not (player_number == 2 and ai_controlled):
		direction += controller_manager.get_horizontal_axis(player_number)
		jump_down = jump_down or controller_manager.is_button_pressed(player_number, JOY_BUTTON_A)
		block_pressed = block_pressed or controller_manager.is_button_pressed(player_number, JOY_BUTTON_LEFT_SHOULDER)
		attack_down = attack_down or controller_manager.is_button_pressed(player_number, JOY_BUTTON_X)
		direction = clampf(direction, -1.0, 1.0)

	var jump_pressed := jump_down and not _jump_was_down
	var attack_pressed := attack_down and not _attack_was_down
	_jump_was_down = jump_down
	_attack_was_down = attack_down

	var was_blocking := is_blocking
	if _hitstun_timer > 0.0:
		_hitstun_timer = maxf(0.0, _hitstun_timer - delta)
		direction = 0.0
		block_pressed = false
	is_blocking = block_pressed and is_on_floor()
	if is_blocking:
		direction = 0.0

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	if jump_pressed and is_on_floor() and not is_blocking and _hitstun_timer <= 0.0:
		velocity.y = JUMP_SPEED

	if _hitstun_timer > 0.0:
		velocity.x = _knockback_velocity
		_knockback_velocity = move_toward(_knockback_velocity, 0.0, 1600.0 * delta)
	else:
		velocity.x = direction * MOVE_SPEED
	move_and_slide()
	global_position.x = clampf(global_position.x, LEFT_BOUND, RIGHT_BOUND)
	_update_facing()

	if attack_pressed and _attack_cooldown <= 0.0 and is_on_floor() and not is_blocking and _hitstun_timer <= 0.0:
		_attack_cooldown = ATTACK_COOLDOWN
		_attack_visual_timer = 0.14
		hitbox.position.x = -48.0 if facing_left else 48.0
		hitbox.activate()

	if was_blocking != is_blocking or was_attacking != (_attack_visual_timer > 0.0):
		queue_redraw()

func set_ai_controlled(enabled: bool) -> void:
	ai_controlled = enabled
	_jump_was_down = false
	_attack_was_down = false

func apply_damage(amount: float, attacker: Node2D) -> void:
	if health <= 0.0 or is_blocking or attacker == null:
		return
	health = maxf(0.0, health - amount)
	var away_direction := signf(global_position.x - attacker.global_position.x)
	if is_zero_approx(away_direction):
		away_direction = 1.0 if facing_left else -1.0
	_knockback_velocity = away_direction * 260.0
	_hitstun_timer = HITSTUN_DURATION
	health_changed.emit(health, MAX_HEALTH)
	print(display_name, " recebeu dano. Vida: ", int(health), "/", int(MAX_HEALTH))

func _on_hitbox_hit_landed(hurtbox: Area2D) -> void:
	var target := hurtbox.get_parent()
	if target != self and target.has_method("apply_damage"):
		target.apply_damage(DAMAGE_PER_HIT, self)

func _get_opponent() -> Node2D:
	for fighter in get_tree().get_nodes_in_group("fighters"):
		if fighter != self and fighter is Node2D:
			return fighter
	return null

func _update_facing() -> void:
	for fighter in get_tree().get_nodes_in_group("fighters"):
		if fighter != self and fighter is Node2D:
			var should_face_left: bool = fighter.global_position.x < global_position.x
			if facing_left != should_face_left:
				facing_left = should_face_left
				queue_redraw()
			return

func _draw() -> void:
	var direction := -1.0 if facing_left else 1.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22 * direction, -66), Vector2(-2 * direction, -66),
		Vector2(-8 * direction, -12), Vector2(-32 * direction, -8), Vector2(-38 * direction, -20)
	]), primary_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(3 * direction, -66), Vector2(25 * direction, -70),
		Vector2(39 * direction, -15), Vector2(16 * direction, -8), Vector2(4 * direction, -22)
	]), primary_color)
	draw_rect(Rect2(-37 * direction, -12, 32, 9), accent_color)
	draw_rect(Rect2(12 * direction, -12, 34, 9), accent_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-29 * direction, -126), Vector2(17 * direction, -130),
		Vector2(34 * direction, -108), Vector2(27 * direction, -67),
		Vector2(-28 * direction, -64), Vector2(-41 * direction, -103)
	]), primary_color)
	draw_line(Vector2(-18 * direction, -119), Vector2(-22 * direction, -75), accent_color, 4.0)
	draw_circle(Vector2(0, -146), 17.0, Color("d7ad91"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-17 * direction, -148), Vector2(-21 * direction, -166),
		Vector2(-7 * direction, -161), Vector2(0, -175),
		Vector2(9 * direction, -160), Vector2(21 * direction, -164),
		Vector2(17 * direction, -143), Vector2(4 * direction, -151), Vector2(-7 * direction, -141)
	]), hair_color)

	if is_blocking:
		draw_line(Vector2(10 * direction, -112), Vector2(45 * direction, -132), accent_color, 10.0)
		draw_arc(Vector2(42 * direction, -112), 29.0, -1.15, 1.15, 16, Color(accent_color, 0.7), 3.0)
	elif _attack_visual_timer > 0.0:
		draw_line(Vector2(32 * direction, -100), Vector2(92 * direction, -130), Color(accent_color, 0.9), 6.0)
		draw_line(Vector2(40 * direction, -91), Vector2(83 * direction, -91), Color(accent_color, 0.45), 3.0)

	draw_string(ThemeDB.fallback_font, Vector2(-75, 30), display_name, HORIZONTAL_ALIGNMENT_CENTER, 150, 16, Color("f4f1ec"))
