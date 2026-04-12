extends Area2D

var value: int = 25
var time_offset: float = randf() * 100.0
var base_y: float = 0.0

func _ready():
	monitoring = true
	body_entered.connect(_on_body_entered)
	base_y = position.y
	_setup_nodes()

func _setup_nodes():
	if get_node_or_null("CollisionShape2D") == null:
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 16.0
		col.shape = shape
		add_child(col)
		col.name = "CollisionShape2D"
		
	var light = PointLight2D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.8, 0.2, 0.9))
	gradient.add_point(1.0, Color.TRANSPARENT)
	
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	
	light.texture = tex
	light.color = Color(1.0, 0.8, 0.2)
	light.energy = 1.2
	add_child(light)

func _process(delta):
	# Bobbing up and down
	var time = Time.get_ticks_msec() / 1000.0 + time_offset
	position.y = base_y + sin(time * 3.0) * 5.0
	queue_redraw()

func _on_body_entered(body):
	if body.name == "Player":
		GameManager.add_quota(value)
		AudioManager.play_item_pickup()
		
		# Create light burst effect
		var burst = PointLight2D.new()
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color.WHITE)
		gradient.add_point(1.0, Color.TRANSPARENT)
		var tex = GradientTexture2D.new()
		tex.gradient = gradient
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 256
		tex.height = 256
		burst.texture = tex
		burst.energy = 3.0
		burst.shadow_enabled = true
		burst.global_position = global_position
		
		# Add to parent so it outlives the item
		get_tree().current_scene.add_child(burst)
		
		var tween = get_tree().create_tween()
		tween.tween_property(burst, "texture_scale", 4.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(burst, "energy", 0.0, 0.5)
		tween.tween_callback(burst.queue_free)
		
		queue_free()

func _draw():
	var time = Time.get_ticks_msec() / 1000.0 + time_offset
	var angle = time * 2.0
	
	draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
	
	# Draw glowing crystal shape
	var points = PackedVector2Array([
		Vector2(0, -10),
		Vector2(6, 0),
		Vector2(0, 10),
		Vector2(-6, 0)
	])
	
	draw_polygon(points, [Color(1.0, 0.8, 0.2, 0.9)])
	draw_polyline(points, Color(1.0, 1.0, 0.5, 1.0), 1.0)
