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
const LIGHT_ATTACK_COOLDOWN := 0.38
const HEAVY_ATTACK_COOLDOWN := 0.72
const MAX_HEALTH := 100.0
const LIGHT_DAMAGE := 10.0
const HEAVY_DAMAGE := 20.0
const AI_ATTACK_RANGE := 105.0
const AI_ATTACK_COOLDOWN := 0.82
const HITSTUN_DURATION := 0.16
const CHARACTER_FRAME_COUNTS := {"raven": 6, "vesper": 6, "hayashi": 5}
const CHARACTER_SCALES := {"raven": 1.22, "vesper": 1.14, "hayashi": 1.08}
const CHARACTER_FOOT_PIXELS := {"raven": 143.0, "vesper": 152.0, "hayashi": 160.0}

@onready var hitbox: Area2D = $Hitbox
@onready var character_sprite: AnimatedSprite2D = $CharacterSprite
var controller_manager: Node
var health := MAX_HEALTH
var _is_ko := false
var ai_controlled := false
var facing_left := false
var is_blocking := false
var _attack_cooldown := 0.0
var _current_attack_damage := LIGHT_DAMAGE
var _attack_visual_timer := 0.0
var _sprite_attack_timer := 0.0
var _heavy_attack_visual := false
var _ai_attack_timer := 0.0
var _hitstun_timer := 0.0
var _knockback_velocity := 0.0
var _jump_was_down := false
var _light_attack_was_down := false
var _heavy_attack_was_down := false

func _ready() -> void:
	controller_manager = get_tree().get_first_node_in_group("controller_manager")
	hitbox.hit_landed.connect(_on_hitbox_hit_landed)
	_update_facing()
	queue_redraw()

func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_ai_attack_timer = maxf(0.0, _ai_attack_timer - delta)
	var was_attacking := _attack_visual_timer > 0.0
	_sprite_attack_timer = maxf(0.0, _sprite_attack_timer - delta)
	var was_heavy_visual := _heavy_attack_visual
	_attack_visual_timer = maxf(0.0, _attack_visual_timer - delta)
	if _attack_visual_timer <= 0.0:
		_heavy_attack_visual = false

	var direction := 0.0
	var jump_down := false
	var block_pressed := false
	var light_attack_down := false
	var heavy_attack_down := false
	if player_number == 2 and ai_controlled:
		var opponent := _get_opponent()
		if opponent != null:
			var distance_to_opponent := opponent.global_position.x - global_position.x
			direction = signf(distance_to_opponent) if absf(distance_to_opponent) > AI_ATTACK_RANGE else 0.0
			light_attack_down = absf(distance_to_opponent) <= AI_ATTACK_RANGE and _ai_attack_timer <= 0.0 and is_on_floor()
			if light_attack_down:
				_ai_attack_timer = AI_ATTACK_COOLDOWN
	elif player_number == 1:
		if Input.is_key_pressed(KEY_A):
			direction -= 1.0
		if Input.is_key_pressed(KEY_D):
			direction += 1.0
		jump_down = Input.is_key_pressed(KEY_W)
		block_pressed = Input.is_key_pressed(KEY_F)
		light_attack_down = Input.is_key_pressed(KEY_G)
		heavy_attack_down = Input.is_key_pressed(KEY_H)
	else:
		if Input.is_key_pressed(KEY_LEFT):
			direction -= 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			direction += 1.0
		jump_down = Input.is_key_pressed(KEY_UP)
		block_pressed = Input.is_key_pressed(KEY_K)
		light_attack_down = Input.is_key_pressed(KEY_COMMA)
		heavy_attack_down = Input.is_key_pressed(KEY_PERIOD)

	if controller_manager != null and not (player_number == 2 and ai_controlled):
		direction += controller_manager.get_horizontal_axis(player_number)
		jump_down = jump_down or controller_manager.is_button_pressed(player_number, JOY_BUTTON_A)
		block_pressed = block_pressed or controller_manager.is_button_pressed(player_number, JOY_BUTTON_B)
		light_attack_down = light_attack_down or controller_manager.is_button_pressed(player_number, JOY_BUTTON_X)
		heavy_attack_down = heavy_attack_down or controller_manager.is_button_pressed(player_number, JOY_BUTTON_Y)
		direction = clampf(direction, -1.0, 1.0)

	var jump_pressed := jump_down and not _jump_was_down
	var light_attack_pressed := light_attack_down and not _light_attack_was_down
	var heavy_attack_pressed := heavy_attack_down and not _heavy_attack_was_down
	_jump_was_down = jump_down
	_light_attack_was_down = light_attack_down
	_heavy_attack_was_down = heavy_attack_down

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

	if (light_attack_pressed or heavy_attack_pressed) and _attack_cooldown <= 0.0 and is_on_floor() and not is_blocking and _hitstun_timer <= 0.0:
		_heavy_attack_visual = heavy_attack_pressed
		if heavy_attack_pressed:
			_current_attack_damage = HEAVY_DAMAGE
			_attack_cooldown = HEAVY_ATTACK_COOLDOWN
		else:
			_current_attack_damage = LIGHT_DAMAGE
			_attack_cooldown = LIGHT_ATTACK_COOLDOWN
		_attack_visual_timer = 0.22 if _heavy_attack_visual else 0.14
		_sprite_attack_timer = 0.49 if _heavy_attack_visual else 0.43
		hitbox.position.x = -48.0 if facing_left else 48.0
		hitbox.activate()

	_update_sprite_animation(direction)
	if was_blocking != is_blocking or was_attacking != (_attack_visual_timer > 0.0) or was_heavy_visual != _heavy_attack_visual:
		queue_redraw()

func set_character_visual(character_key: String) -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 7.0)
	frames.set_animation_loop("idle", true)
	_add_animation_frames(frames, character_key, "idle", int(CHARACTER_FRAME_COUNTS.get(character_key, 0)), 7.0)
	var animation_counts: Dictionary = {
		"raven": {"walk": 8, "crouch": 4, "jump": 6, "guard": 4, "light_attack": 6, "heavy_attack": 6},
		"vesper": {"walk": 8, "crouch": 4, "jump": 6, "guard": 4, "light_attack": 6, "heavy_attack": 6},
		"hayashi": {"walk": 6, "crouch": 4, "jump": 5, "guard": 4, "light_attack": 3, "heavy_attack": 5},
	}
	var character_actions: Dictionary = animation_counts.get(character_key, {})
	for action_variant in character_actions.keys():
		var action_name := String(action_variant)
		var action_fps := 10.0
		if action_name == "jump":
			action_fps = 8.0
		elif action_name == "crouch" or action_name == "guard":
			action_fps = 6.0
		elif action_name == "light_attack":
			action_fps = 14.0
		elif action_name == "heavy_attack":
			action_fps = 12.0
		var action_loops: bool = action_name in ["walk", "crouch", "guard"]
		_add_animation_frames(frames, character_key, action_name, int(character_actions[action_variant]), action_fps, action_loops)
	if frames.get_frame_count("idle") == 0:
		push_warning("Nenhum quadro de idle encontrado para: " + character_key)
		return
	character_sprite.sprite_frames = frames
	character_sprite.animation = "idle"
	var scale_factor := float(CHARACTER_SCALES.get(character_key, 1.0))
	var foot_pixel := float(CHARACTER_FOOT_PIXELS.get(character_key, 150.0))
	var frame_height := float(frames.get_frame_texture("idle", 0).get_height())
	character_sprite.scale = Vector2.ONE * scale_factor
	character_sprite.position.y = -(foot_pixel - frame_height * 0.5) * scale_factor
	character_sprite.flip_h = facing_left
	character_sprite.play("idle")

func _add_animation_frames(frames: SpriteFrames, character_key: String, animation_name: String, frame_count: int, fps: float, loops: bool = true) -> void:
	for frame_index in range(frame_count):
		var frame_path := "res://assets/sprites/characters/%s/%s_%d.png" % [character_key, animation_name, frame_index]
		var frame_texture := load(frame_path) as Texture2D
		if frame_texture != null:
			if not frames.has_animation(animation_name):
				frames.add_animation(animation_name)
				frames.set_animation_speed(animation_name, fps)
				frames.set_animation_loop(animation_name, loops)
			frames.add_frame(animation_name, frame_texture)

func _update_sprite_animation(direction: float) -> void:
	var next_animation := "idle"
	if not is_on_floor():
		next_animation = "jump"
	elif _hitstun_timer > 0.0:
		next_animation = "hit"
	elif is_blocking:
		next_animation = "guard"
	elif _sprite_attack_timer > 0.0:
		next_animation = "heavy_attack" if _heavy_attack_visual else "light_attack"
	elif absf(direction) > 0.1:
		next_animation = "walk"
	if not character_sprite.sprite_frames.has_animation(next_animation):
		next_animation = "idle"
	if character_sprite.animation != next_animation or not character_sprite.is_playing():
		character_sprite.play(next_animation)
func set_ai_controlled(enabled: bool) -> void:
	ai_controlled = enabled
	_jump_was_down = false
	_light_attack_was_down = false
	_heavy_attack_was_down = false

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
	if health <= 0.0:
		_knock_out()

func _knock_out() -> void:
	if _is_ko:
		return
	_is_ko = true
	velocity = Vector2.ZERO
	is_blocking = false
	_attack_visual_timer = 0.0
	queue_redraw()
	var fall_angle := deg_to_rad(-90.0 if facing_left else 90.0)
	var death_tween := create_tween().set_parallel(true)
	death_tween.tween_property(self, "rotation", fall_angle, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	death_tween.tween_property(self, "modulate", Color(0.58, 0.58, 0.64, 1.0), 0.65)
func _on_hitbox_hit_landed(hurtbox: Area2D) -> void:
	var target := hurtbox.get_parent()
	if target != self and target.has_method("apply_damage"):
		target.apply_damage(_current_attack_damage, self)

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
				character_sprite.flip_h = facing_left
				queue_redraw()
			return
func _draw() -> void:
	var direction := -1.0 if facing_left else 1.0
	if is_blocking:
		draw_line(Vector2(10 * direction, -112), Vector2(45 * direction, -132), accent_color, 10.0)
		draw_arc(Vector2(42 * direction, -112), 29.0, -1.15, 1.15, 16, Color(accent_color, 0.7), 3.0)
	elif _attack_visual_timer > 0.0:
		var swing_width := 10.0 if _heavy_attack_visual else 6.0
		var swing_length := 112.0 if _heavy_attack_visual else 92.0
		draw_line(Vector2(32 * direction, -100), Vector2(swing_length * direction, -130), Color(accent_color, 0.9), swing_width)
		draw_line(Vector2(40 * direction, -91), Vector2(83 * direction, -91), Color(accent_color, 0.45), 3.0)
