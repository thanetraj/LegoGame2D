extends Area2D

# Enemy bullet — fired by ShooterEnemy, deals damage to player

const SPEED = 300.0
const LIFETIME = 3.0

var direction: Vector2 = Vector2.RIGHT
var damage: float = 5.0
var time_alive: float = 0.0

func _ready():
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 3.0
	col.shape = shape
	add_child(col)
	
	# Red glow
	var light = PointLight2D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.2, 0.2, 1.0))
	gradient.add_point(1.0, Color.TRANSPARENT)
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 32
	tex.height = 32
	light.texture = tex
	light.color = Color(1, 0.2, 0.2)
	light.energy = 1.0
	light.texture_scale = 0.4
	add_child(light)
	
	monitoring = true
	monitorable = false
	collision_layer = 8   # Enemy bullet layer
	collision_mask = 1    # Player layer
	
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	time_alive += delta
	if time_alive >= LIFETIME:
		queue_free()
		return
	
	position += direction * SPEED * delta
	queue_redraw()

func _on_body_entered(body):
	if body is StaticBody2D:
		queue_free()
		return
	
	# Check if we hit the player
	if body.is_in_group("Player"):
		GameManager.damage_player(damage, "enemy")
		queue_free()

func _draw():
	# Red bullet
	draw_circle(Vector2.ZERO, 3, Color(1, 0.2, 0.2))
	draw_circle(Vector2.ZERO, 1.5, Color(1, 0.8, 0.5))
	# Trail
	var trail_dir = -direction * 8.0
	draw_line(Vector2.ZERO, trail_dir, Color(1, 0.2, 0.2, 0.5), 2.0)
