extends CanvasLayer

var quota_label: Label
var battery_bar: ProgressBar
var health_bar: ProgressBar
var health_label: Label
var battery_label_node: Label
var time_label: Label
var fear_overlay: ColorRect

# Health bar pulse
var health_pulse_timer: float = 0.0

func _ready():
	_setup_ui()
	GameManager.quota_updated.connect(_on_quota_updated)
	GameManager.battery_updated.connect(_on_battery_updated)
	GameManager.fear_updated.connect(_on_fear_updated)
	GameManager.health_updated.connect(_on_health_updated)
	
func _setup_ui():
	# ===== TOP BAR — Health & Battery (centered at top) =====
	var top_panel = PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.custom_minimum_size = Vector2(0, 50)
	# Dark semi-transparent background
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 0
	top_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(top_panel)
	
	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_theme_constant_override("separation", 40)
	top_panel.add_child(top_hbox)
	
	# --- Health Section ---
	var health_section = HBoxContainer.new()
	health_section.add_theme_constant_override("separation", 8)
	top_hbox.add_child(health_section)
	
	health_label = Label.new()
	health_label.text = "❤"
	health_label.add_theme_font_size_override("font_size", 22)
	health_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	health_section.add_child(health_label)
	
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(220, 14)
	health_bar.max_value = 1.0
	health_bar.value = 1.0
	health_bar.show_percentage = false
	health_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var health_sb = StyleBoxFlat.new()
	health_sb.bg_color = Color(0.9, 0.15, 0.15)
	health_sb.corner_radius_top_left = 7
	health_sb.corner_radius_top_right = 7
	health_sb.corner_radius_bottom_left = 7
	health_sb.corner_radius_bottom_right = 7
	health_bar.add_theme_stylebox_override("fill", health_sb)
	var health_bg = StyleBoxFlat.new()
	health_bg.bg_color = Color(0.25, 0.05, 0.05)
	health_bg.corner_radius_top_left = 7
	health_bg.corner_radius_top_right = 7
	health_bg.corner_radius_bottom_left = 7
	health_bg.corner_radius_bottom_right = 7
	health_bar.add_theme_stylebox_override("background", health_bg)
	health_section.add_child(health_bar)
	
	# --- Separator ---
	var sep = VSeparator.new()
	sep.custom_minimum_size = Vector2(2, 0)
	sep.modulate = Color(1, 1, 1, 0.2)
	top_hbox.add_child(sep)
	
	# --- Battery Section ---
	var battery_section = HBoxContainer.new()
	battery_section.add_theme_constant_override("separation", 8)
	top_hbox.add_child(battery_section)
	
	battery_label_node = Label.new()
	battery_label_node.text = "⚡"
	battery_label_node.add_theme_font_size_override("font_size", 22)
	battery_label_node.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	battery_section.add_child(battery_label_node)
	
	battery_bar = ProgressBar.new()
	battery_bar.custom_minimum_size = Vector2(220, 14)
	battery_bar.max_value = 1.0
	battery_bar.value = 1.0
	battery_bar.show_percentage = false
	battery_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.85, 0)
	sb.corner_radius_top_left = 7
	sb.corner_radius_top_right = 7
	sb.corner_radius_bottom_left = 7
	sb.corner_radius_bottom_right = 7
	battery_bar.add_theme_stylebox_override("fill", sb)
	var bat_bg = StyleBoxFlat.new()
	bat_bg.bg_color = Color(0.18, 0.14, 0.0)
	bat_bg.corner_radius_top_left = 7
	bat_bg.corner_radius_top_right = 7
	bat_bg.corner_radius_bottom_left = 7
	bat_bg.corner_radius_bottom_right = 7
	battery_bar.add_theme_stylebox_override("background", bat_bg)
	battery_section.add_child(battery_bar)
	
	# ===== LEFT INFO — Level, Quota, Time (top-left below bar) =====
	var info_margin = MarginContainer.new()
	info_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info_margin.add_theme_constant_override("margin_left", 20)
	info_margin.add_theme_constant_override("margin_top", 60)
	info_margin.add_theme_constant_override("margin_right", 20)
	info_margin.add_theme_constant_override("margin_bottom", 20)
	add_child(info_margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	info_margin.add_child(vbox)
	
	var level_label = Label.new()
	level_label.text = "- LEVEL " + str(GameManager.current_level) + " -"
	level_label.add_theme_font_size_override("font_size", 40)
	level_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	vbox.add_child(level_label)
	
	quota_label = Label.new()
	quota_label.text = "Quota: 0 / " + str(GameManager.quota_target)
	quota_label.add_theme_font_size_override("font_size", 26)
	vbox.add_child(quota_label)
	
	time_label = Label.new()
	time_label.text = "Time: 0s"
	time_label.add_theme_font_size_override("font_size", 20)
	time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
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
		time_label.text = "Time: " + str(time) + "s"
		
		# Health bar pulse when low
		if health_bar.value < 0.3 and health_bar.value > 0:
			health_pulse_timer += delta * 5.0
			var pulse_alpha = 0.5 + 0.5 * sin(health_pulse_timer)
			health_label.add_theme_color_override("font_color", Color(1, 0.1, 0.1, pulse_alpha))
			health_bar.modulate.a = 0.6 + 0.4 * sin(health_pulse_timer)
		else:
			health_bar.modulate.a = 1.0

func _on_quota_updated(current, target):
	quota_label.text = "Quota: " + str(current) + " / " + str(target)

func _on_battery_updated(percentage):
	battery_bar.value = percentage

func _on_health_updated(percentage):
	health_bar.value = percentage

func _on_fear_updated(percentage):
	if fear_overlay and fear_overlay.material:
		fear_overlay.material.set_shader_parameter("fear_level", percentage)

