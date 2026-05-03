extends CharacterBody2D

enum State { PATROL, INVESTIGATE, CHASE, ATTACK }

const PATROL_SPEED = 30.0
const CHASE_SPEED = 95.0
const DETECTION_RADIUS = 200.0
const ATTACK_DAMAGE = 25.0
const ATTACK_COOLDOWN = 1.5

var current_state: State = State.PATROL
var target_pos: Vector2 = Vector2.ZERO
var player_ref: Node2D = null
var time_in_state: float = 0.0

var patrol_timer: float = 0.0
var chase_timer: float = 0.0
var attack_cooldown_timer: float = 0.0

# Health system
var health: float = 50.0
var max_health: float = 50.0

@onready var raycast = RayCast2D.new()

func _ready():
	_setup_nodes()
	_pick_new_patrol_point()

func _setup_nodes():
	# Procedurally create collision
	if get_node_or_null("CollisionShape2D") == null:
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 16.0
		col.shape = shape
		add_child(col)
		col.name = "CollisionShape2D"
		
	# Red glowing light
	var light = PointLight2D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0, 0, 0.8))
	gradient.add_point(1.0, Color.TRANSPARENT)
	
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	
	light.texture = tex
	light.color = Color.RED
	light.energy = 0.8
	light.shadow_enabled = true
	add_child(light)
	
	# Raycast for line of sight
	add_child(raycast)
	raycast.enabled = true
	
	# Set collision layers
	collision_layer = 2  # Enemy
	collision_mask = 1   # Walls
	
	# Detection area for player bullets
	var detect_area = Area2D.new()
	detect_area.name = "HitArea"
	var area_col = CollisionShape2D.new()
	var area_shape = CircleShape2D.new()
	area_shape.radius = 18.0
	area_col.shape = area_shape
	detect_area.add_child(area_col)
	detect_area.collision_layer = 2  # Enemy
	detect_area.collision_mask = 4   # Bullet layer
	detect_area.area_entered.connect(_on_bullet_hit)
	add_child(detect_area)

func _physics_process(delta):
	if not GameManager.is_game_active:
		return
		
	if player_ref == null:
		var group = get_tree().get_nodes_in_group("Player")
		if group.size() > 0:
			player_ref = group[0]
	
	# Tick attack cooldown
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
			
	time_in_state += delta
	queue_redraw()
	
	match current_state:
		State.PATROL:
			_state_patrol(delta)
		State.INVESTIGATE:
			_state_investigate(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)

func _state_patrol(delta):
	patrol_timer -= delta
	if patrol_timer <= 0 or global_position.distance_to(target_pos) < 10.0:
		_pick_new_patrol_point()
		
	var dir = global_position.direction_to(target_pos)
	velocity = dir * PATROL_SPEED
	move_and_slide()
	
	_check_for_player()

func _state_investigate(delta):
	var dir = global_position.direction_to(target_pos)
	velocity = dir * (PATROL_SPEED * 1.5)
	move_and_slide()
	
	if global_position.distance_to(target_pos) < 20.0:
		current_state = State.PATROL
		_pick_new_patrol_point()
		
	_check_for_player()

func _state_chase(delta):
	if player_ref == null:
		current_state = State.PATROL
		return
		
	chase_timer += delta
	var dist_to_player = global_position.distance_to(player_ref.global_position)
	
	if dist_to_player > DETECTION_RADIUS * 1.5 and chase_timer > 5.0:
		current_state = State.INVESTIGATE
		target_pos = player_ref.global_position
		return
		
	target_pos = player_ref.global_position
	var dir = global_position.direction_to(target_pos)
	velocity = dir * CHASE_SPEED
	move_and_slide()
	
	# Increase player fear based on proximity
	if dist_to_player < 150.0:
		GameManager.add_fear(delta * 20.0 * (150.0 / max(1.0, dist_to_player)))
		
	# Attack when close enough (instead of instant game over)
	if dist_to_player < 30.0 and attack_cooldown_timer <= 0:
		current_state = State.ATTACK
		time_in_state = 0.0

func _state_attack(delta):
	# Deal damage once at start of attack
	if time_in_state < delta * 2:  # First frame of attack
		GameManager.damage_player(ATTACK_DAMAGE, "enemy")
		GameManager.add_fear(15.0)  # Fear burst on hit
		attack_cooldown_timer = ATTACK_COOLDOWN
	
	# Back off after attacking (give player escape chance)
	if player_ref != null:
		var away_dir = player_ref.global_position.direction_to(global_position)
		velocity = away_dir * CHASE_SPEED * 0.8
		move_and_slide()
	
	# After backing off, resume chase
	if time_in_state > 0.8:
		current_state = State.CHASE
		chase_timer = 0.0

func _check_for_player():
	if player_ref == null:
		return
		
	var dist = global_position.distance_to(player_ref.global_position)
	if dist < DETECTION_RADIUS:
		raycast.target_position = to_local(player_ref.global_position)
		raycast.force_raycast_update()
		
		var col = raycast.get_collider()
		if col == player_ref:
			current_state = State.CHASE
			chase_timer = 0.0
			GameManager.add_fear(10.0) # Jump scare burst
			AudioManager.play_enemy_growl()

func _pick_new_patrol_point():
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var random_dist = randf_range(100, 300)
	target_pos = global_position + (random_dir * random_dist)
	patrol_timer = randf_range(3.0, 7.0)

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		_die()

func _on_bullet_hit(area):
	if area.get_parent().has_method("hit_enemy"):
		take_damage(GameManager.laser_damage)
		area.get_parent().hit_enemy(self)

func _die():
	# Death burst
	var flash = PointLight2D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.8, 0.0, 0.0, 1.0))
	gradient.add_point(1.0, Color.TRANSPARENT)
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	flash.texture = tex
	flash.color = Color(0.8, 0.0, 0.0)
	flash.energy = 3.0
	flash.texture_scale = 1.2
	flash.global_position = global_position
	get_tree().current_scene.add_child(flash)
	
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "energy", 0.0, 0.4)
	tween.tween_callback(flash.queue_free)
	
	GameManager.add_quota(10)
	queue_free()

func _draw():
	var time_val = float(Time.get_ticks_msec()) / 1000.0
	var core_color = Color(0.1, 0.0, 0.0)
	
	# Draw writhing shadow body using overlapping circles
	for i in range(8):
		var offset = Vector2(
			sin(time_val * 3.0 + i) * 8.0,
			cos(time_val * 2.5 + i * 1.5) * 8.0
		)
		draw_circle(offset, 12, core_color)
		
	# Red glowing eyes
	var eye_offset = Vector2.ZERO
	if target_pos != Vector2.ZERO and global_position.distance_to(target_pos) > 0:
		eye_offset = global_position.direction_to(target_pos) * 6.0
		
	var eye_color = Color(1.0, 0.0, 0.0, 0.5 + 0.5 * sin(time_val * 5.0))
	if current_state == State.CHASE:
		eye_color = Color(1.0, 0.2, 0.2)
		eye_offset *= 1.5
		# Alert icon !
		draw_line(Vector2(0, -30), Vector2(0, -18), Color.RED, 3.0)
		draw_circle(Vector2(0, -12), 2.0, Color.RED)
	elif current_state == State.ATTACK:
		# Attack flash — bright white eyes
		eye_color = Color(1.0, 1.0, 1.0)
		eye_offset *= 2.0
		# Draw attack slash marks
		draw_line(Vector2(-15, -15), Vector2(15, 15), Color(1, 0.3, 0.3, 0.8), 2.0)
		draw_line(Vector2(15, -15), Vector2(-15, 15), Color(1, 0.3, 0.3, 0.8), 2.0)
		
	draw_circle(eye_offset + Vector2(-5, -4), 3, eye_color)
	draw_circle(eye_offset + Vector2(5, -4), 3, eye_color)
	
	# Health bar (only if damaged)
	if health < max_health:
		var bar_width = 24.0
		var bar_height = 3.0
		var bar_y = -22.0
		var health_ratio = health / max_health
		draw_rect(Rect2(-bar_width/2, bar_y, bar_width, bar_height), Color(0.2, 0.0, 0.0))
		draw_rect(Rect2(-bar_width/2, bar_y, bar_width * health_ratio, bar_height), Color(0.9, 0.1, 0.1))
