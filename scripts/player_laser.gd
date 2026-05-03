extends Area2D

const SPEED = 600.0
const DAMAGE = 25.0
const LIFETIME = 2.0

var direction: Vector2 = Vector2.RIGHT
var time_alive: float = 0.0

func _ready():
	# Collision
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4.0
	col.shape = shape
	add_child(col)
	
	# Glow light
	var light = PointLight2D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.2, 0.8, 1.0, 1.0))
	gradient.add_point(1.0, Color.TRANSPARENT)
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	light.texture = tex
	light.color = Color(0.3, 0.8, 1.0)
	light.energy = 1.5
	light.texture_scale = 0.5
	add_child(light)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Enable monitoring
	monitoring = true
	monitorable = false
	collision_layer = 4  # Bullet layer
	collision_mask = 2   # Enemy layer

func _physics_process(delta):
	time_alive += delta
	if time_alive >= LIFETIME:
		queue_free()
		return
	
	position += direction * SPEED * delta
	queue_redraw()

func _on_body_entered(body):
	# Hit a wall
	if body is StaticBody2D:
		_spawn_impact_effect()
		queue_free()

func _on_area_entered(area):
	pass

func hit_enemy(enemy):
	# Called by enemy when detecting collision
	_spawn_impact_effect()
	queue_free()

func _spawn_impact_effect():
	# Small flash at impact point
	var flash = PointLight2D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.5, 0.9, 1.0, 1.0))
	gradient.add_point(1.0, Color.TRANSPARENT)
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	flash.texture = tex
	flash.color = Color(0.3, 0.9, 1.0)
	flash.energy = 3.0
	flash.texture_scale = 0.8
	flash.global_position = global_position
	get_tree().current_scene.add_child(flash)
	
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "energy", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

func _draw():
	# Laser bolt — bright cyan trail
	draw_circle(Vector2.ZERO, 4, Color(0.3, 0.9, 1.0))
	draw_circle(Vector2.ZERO, 2, Color.WHITE)
	# Trail behind
	var trail_dir = -direction * 12.0
	draw_line(Vector2.ZERO, trail_dir, Color(0.2, 0.7, 1.0, 0.6), 3.0)
	draw_line(Vector2.ZERO, trail_dir * 0.5, Color(1, 1, 1, 0.4), 1.5)
