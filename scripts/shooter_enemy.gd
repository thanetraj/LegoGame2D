extends CharacterBody2D

# Shooter Enemy — spawns from Level 6 onward
# Patrols, detects player, and shoots red laser bullets (5 damage each)

enum State { PATROL, ALERT, SHOOT, RETREAT }

const PATROL_SPEED = 35.0
const RETREAT_SPEED = 60.0
const DETECTION_RADIUS = 350.0
const SHOOT_RANGE = 280.0
const BULLET_DAMAGE = 5.0
const SHOOT_COOLDOWN = 1.8
const BURST_COUNT = 3
const BURST_INTERVAL = 0.25

var current_state: State = State.PATROL
var target_pos: Vector2 = Vector2.ZERO
var player_ref: Node2D = null
var patrol_timer: float = 0.0
var shoot_cooldown_timer: float = 0.0
var burst_remaining: int = 0
var burst_timer: float = 0.0
var time_in_state: float = 0.0

# Health system for shooter enemy
var health: float = 75.0
var max_health: float = 75.0

@onready var raycast = RayCast2D.new()

func _ready():
	_setup_nodes()
	_pick_new_patrol_point()
	add_to_group("ShooterEnemy")
	# Collision layer: enemy = 2
	collision_layer = 2
	collision_mask = 1  # Collide with walls

func _setup_nodes():
	if get_node_or_null("CollisionShape2D") == null:
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 14.0
		col.shape = shape
		add_child(col)
		col.name = "CollisionShape2D"
	
	# Purple-red glowing light
	var light = PointLight2D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.8, 0.0, 0.5, 0.8))
	gradient.add_point(1.0, Color.TRANSPARENT)
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	light.texture = tex
	light.color = Color(0.8, 0.1, 0.4)
	light.energy = 0.6
	light.shadow_enabled = true
	add_child(light)
	
	add_child(raycast)
	raycast.enabled = true

	# Detection area for player bullets
	var detect_area = Area2D.new()
	detect_area.name = "HitArea"
	var area_col = CollisionShape2D.new()
	var area_shape = CircleShape2D.new()
	area_shape.radius = 16.0
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
	
	shoot_cooldown_timer -= delta
	time_in_state += delta
	queue_redraw()
	
	match current_state:
		State.PATROL:
			_state_patrol(delta)
		State.ALERT:
			_state_alert(delta)
		State.SHOOT:
			_state_shoot(delta)
		State.RETREAT:
			_state_retreat(delta)

func _state_patrol(delta):
	patrol_timer -= delta
	if patrol_timer <= 0 or global_position.distance_to(target_pos) < 10.0:
		_pick_new_patrol_point()
	
	var dir = global_position.direction_to(target_pos)
	velocity = dir * PATROL_SPEED
	move_and_slide()
	_check_for_player()

func _state_alert(delta):
	# Face the player and prepare to shoot
	if player_ref == null:
		current_state = State.PATROL
		return
	
	velocity = Vector2.ZERO
	move_and_slide()
	
	if time_in_state > 0.5:
		current_state = State.SHOOT
		burst_remaining = BURST_COUNT
		burst_timer = 0.0
		time_in_state = 0.0

func _state_shoot(delta):
	if player_ref == null:
		current_state = State.PATROL
		return
	
	velocity = Vector2.ZERO
	move_and_slide()
	
	burst_timer -= delta
	if burst_timer <= 0 and burst_remaining > 0:
		_fire_bullet()
		burst_remaining -= 1
		burst_timer = BURST_INTERVAL
	
	if burst_remaining <= 0:
		shoot_cooldown_timer = SHOOT_COOLDOWN
		current_state = State.RETREAT
		time_in_state = 0.0

func _state_retreat(delta):
	if player_ref == null:
		current_state = State.PATROL
		return
	
	# Move away from player after shooting
	var away_dir = player_ref.global_position.direction_to(global_position)
	velocity = away_dir * RETREAT_SPEED
	move_and_slide()
	
	if time_in_state > 1.5:
		current_state = State.PATROL
		_pick_new_patrol_point()

func _fire_bullet():
	if player_ref == null:
		return
	
	var bullet_script = load("res://scripts/enemy_bullet.gd")
	if bullet_script:
		var bullet = bullet_script.new()
		bullet.global_position = global_position
		bullet.direction = global_position.direction_to(player_ref.global_position)
		bullet.damage = BULLET_DAMAGE
		get_tree().current_scene.add_child(bullet)

func _check_for_player():
	if player_ref == null:
		return
	
	var dist = global_position.distance_to(player_ref.global_position)
	if dist < DETECTION_RADIUS and shoot_cooldown_timer <= 0:
		raycast.target_position = to_local(player_ref.global_position)
		raycast.force_raycast_update()
		
		var col = raycast.get_collider()
		if col == player_ref:
			current_state = State.ALERT
			time_in_state = 0.0

func _pick_new_patrol_point():
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var random_dist = randf_range(100, 250)
	target_pos = global_position + (random_dir * random_dist)
	patrol_timer = randf_range(3.0, 6.0)

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		_die()

func _on_bullet_hit(area):
	# Check if it's a player bullet
	if area.get_parent().has_method("hit_enemy"):
		take_damage(GameManager.laser_damage)
		area.get_parent().hit_enemy(self)

func _die():
	# Death flash
	var flash = PointLight2D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.3, 0.6, 1.0))
	gradient.add_point(1.0, Color.TRANSPARENT)
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	flash.texture = tex
	flash.color = Color(1, 0.2, 0.5)
	flash.energy = 4.0
	flash.texture_scale = 1.5
	flash.global_position = global_position
	get_tree().current_scene.add_child(flash)
	
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "energy", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)
	
	# Drop bonus item on death
	GameManager.add_quota(15)
	queue_free()

func _draw():
	var time_val = float(Time.get_ticks_msec()) / 1000.0
	
	# Armored body — hexagonal shape with pulsing glow
	var body_color = Color(0.3, 0.0, 0.2)
	var armor_color = Color(0.6, 0.1, 0.3, 0.5 + 0.3 * sin(time_val * 3.0))
	
	# Outer armor plates
	for i in range(6):
		var angle = i * (PI / 3.0) + time_val * 0.5
		var offset = Vector2(cos(angle), sin(angle)) * 10.0
		draw_circle(offset, 8, body_color)
	
	# Core body
	draw_circle(Vector2.ZERO, 10, body_color)
	draw_circle(Vector2.ZERO, 6, armor_color)
	
	# Targeting eye (single, larger)
	var eye_color = Color(1.0, 0.2, 0.4, 0.7 + 0.3 * sin(time_val * 6.0))
	if current_state == State.SHOOT:
		eye_color = Color(1.0, 1.0, 0.0)  # Yellow when shooting
	elif current_state == State.ALERT:
		eye_color = Color(1.0, 0.5, 0.0)  # Orange when alerted
		# Alert indicator
		draw_line(Vector2(0, -25), Vector2(0, -16), Color(1, 0.5, 0), 2.5)
		draw_circle(Vector2(0, -12), 1.5, Color(1, 0.5, 0))
	
	draw_circle(Vector2.ZERO, 4, eye_color)
	
	# Gun barrel indicator (facing target)
	if player_ref and (current_state == State.SHOOT or current_state == State.ALERT):
		var aim_dir = global_position.direction_to(player_ref.global_position)
		var local_aim = aim_dir.rotated(-rotation) * 16.0
		draw_line(Vector2.ZERO, local_aim, Color(1, 0.3, 0.3, 0.8), 2.0)
	
	# Health bar above enemy
	var bar_width = 24.0
	var bar_height = 3.0
	var bar_y = -22.0
	var health_ratio = health / max_health
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width, bar_height), Color(0.2, 0.0, 0.0))
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width * health_ratio, bar_height), Color(0.8, 0.1, 0.3))
