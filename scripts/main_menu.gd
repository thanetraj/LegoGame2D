extends Control

func _ready():
	_setup_ui()

func _setup_ui():
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 50)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "REPO 2D"
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Retrieve the items. Avoid the shadows."
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.custom_minimum_size = Vector2(300, 0)
	btn_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_vbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_vbox)
	
	var start_btn = Button.new()
	start_btn.text = "START SHIFT"
	start_btn.add_theme_font_size_override("font_size", 32)
	start_btn.custom_minimum_size = Vector2(0, 60)
	start_btn.pressed.connect(_on_start_pressed)
	btn_vbox.add_child(start_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "QUIT"
	quit_btn.add_theme_font_size_override("font_size", 32)
	quit_btn.custom_minimum_size = Vector2(0, 60)
	quit_btn.pressed.connect(_on_quit_pressed)
	btn_vbox.add_child(quit_btn)

func _on_start_pressed():
	GameManager.start_game()

func _on_quit_pressed():
	get_tree().quit()
