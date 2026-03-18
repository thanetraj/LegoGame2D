extends CharacterBody2D

const SPEED = 150.0
const SPRINT_SPEED = 250.0
const STAMINA_DRAIN = 20.0
const STAMINA_REGEN = 15.0
const BATTERY_DRAIN_RATE = 1.0

var current_stamina: float = 100.0
var max_stamina: float = 100.0
var flashlight_on: bool = true
var is_sprinting: bool = false
var has_flashlight: PointLight2D = null

func _ready():
	_setup_nodes()
	
func _setup_nodes():
	# Procedurally create collision if missing
	if get_node_or_null("CollisionShape2D") == null:
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 12.0
		col.shape = shape
		add_child(col)
		col.name = "CollisionShape2D"
		
	# Setup Camera
	if get_node_or_null("Camera2D") == null:
		var cam = Camera2D.new()
		cam.zoom = Vector2(1.5, 1.5)
		cam.position_smoothing_enabled = true
		cam.add_child(CanvasLayer.new()) # For vignette later
		add_child(cam)
		cam.name = "Camera2D"
		
	# Setup Flashlight (PointLight2D with custom gradient texture)
	has_flashlight = get_node_or_null("Flashlight")
	if has_flashlight == null:
		has_flashlight = PointLight2D.new()
		has_flashlight.name = "Flashlight"
		
		# Create a flashlight cone texture programmatically
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color.WHITE)
		gradient.add_point(0.8, Color(1, 1, 1, 0.4))
		gradient.add_point(1.0, Color.TRANSPARENT)
		
		var tex = GradientTexture2D.new()
		tex.gradient = gradient
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 512
		tex.height = 512
		
		has_flashlight.texture = tex
		has_flashlight.texture_scale = 1.5
		has_flashlight.shadow_enabled = true
		has_flashlight.position = Vector2(10, 0)
		has_flashlight.energy = 1.2
		add_child(has_flashlight)

func _physics_process(delta):
	if not GameManager.is_game_active:
		return
		
	_handle_movement(delta)
	_handle_flashlight(delta)
	
	# Rotate towards mouse
	var mouse_pos = get_global_mouse_position()
	rotation = lerp_angle(rotation, global_position.direction_to(mouse_pos).angle(), 15.0 * delta)
	
	queue_redraw()

func _handle_movement(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	is_sprinting = Input.is_action_pressed("sprint") and current_stamina > 0 and direction != Vector2.ZERO
	
	if is_sprinting:
		current_stamina = clamp(current_stamina - STAMINA_DRAIN * delta, 0.0, max_stamina)
		velocity = direction * SPRINT_SPEED
	else:
		current_stamina = clamp(current_stamina + STAMINA_REGEN * delta, 0.0, max_stamina)
		velocity = direction * SPEED
		
	move_and_slide()

func _handle_flashlight(delta):
	if Input.is_action_just_pressed("switch_light"):
		flashlight_on = not flashlight_on
		has_flashlight.enabled = flashlight_on
		
	if flashlight_on and GameManager.battery_current > 0:
		GameManager.drain_battery(BATTERY_DRAIN_RATE * delta)
		has_flashlight.energy = lerp(0.2, 1.2, GameManager.battery_current / GameManager.battery_max)
	elif GameManager.battery_current <= 0:
		flashlight_on = false
		has_flashlight.enabled = false

func _draw():
	# Draw player hazard suit (Orange circle with a backpack)
	draw_circle(Vector2.ZERO, 12, Color(0.9, 0.4, 0.0))
	draw_circle(Vector2(5, 0), 8, Color(0.8, 0.8, 0.8)) # Helmet/visor facing forward
	draw_rect(Rect2(-12, -8, 8, 16), Color(0.3, 0.3, 0.3)) # Backpack
