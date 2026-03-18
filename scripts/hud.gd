extends CanvasLayer

var quota_label: Label
var battery_bar: ProgressBar
var time_label: Label
var fear_overlay: ColorRect

func _ready():
	_setup_ui()
	GameManager.quota_updated.connect(_on_quota_updated)
	GameManager.battery_updated.connect(_on_battery_updated)
	GameManager.fear_updated.connect(_on_fear_updated)
	
func _setup_ui():
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	quota_label = Label.new()
	quota_label.text = "Quota: 0 / " + str(GameManager.quota_target)
	quota_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(quota_label)
	
	battery_bar = ProgressBar.new()
	battery_bar.custom_minimum_size = Vector2(200, 20)
	battery_bar.max_value = 1.0
	battery_bar.value = 1.0
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.9, 0)
	battery_bar.add_theme_stylebox_override("fill", sb)
	vbox.add_child(battery_bar)
	
	time_label = Label.new()
	time_label.text = "Time Alive: 0s"
	time_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(time_label)
	
	_setup_shaders()

func _setup_shaders():
	# Vignette
	var vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.material = ShaderMaterial.new()
	vignette.material.shader = load("res://shaders/vignette.gdshader")
	add_child(vignette)
	
	# Fear Overlay
	fear_overlay = ColorRect.new()
	fear_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fear_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fear_overlay.material = ShaderMaterial.new()
	fear_overlay.material.shader = load("res://shaders/fear_overlay.gdshader")
	
	# Create noise texture for fear shader
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	var noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	fear_overlay.material.set_shader_parameter("noise_texture", noise_tex)
	fear_overlay.material.set_shader_parameter("fear_level", 0.0)
	add_child(fear_overlay)

func _process(delta):
	if GameManager.is_game_active:
		var time = Time.get_ticks_msec() / 1000
		time_label.text = "Time Alive: " + str(time) + "s"

func _on_quota_updated(current, target):
	quota_label.text = "Quota: " + str(current) + " / " + str(target)

func _on_battery_updated(percentage):
	battery_bar.value = percentage

func _on_fear_updated(percentage):
	if fear_overlay and fear_overlay.material:
		fear_overlay.material.set_shader_parameter("fear_level", percentage)
