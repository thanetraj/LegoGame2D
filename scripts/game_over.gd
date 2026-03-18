extends Control

func _ready():
	_setup_ui()

func _setup_ui():
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.05, 0.05) if GameManager.fear_current >= 100.0 else Color(0.05, 0.2, 0.05)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 40)
	add_child(vbox)
	
	var won = GameManager.quota_current >= GameManager.quota_target
	var title = Label.new()
	title.text = "LEVEL " + str(GameManager.current_level) + " CLEARED!" if won else "DIED IN THE DARK"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var stats = Label.new()
	stats.text = "Items Retrieved: " + str(GameManager.quota_current) + "\nTarget: " + str(GameManager.quota_target)
	stats.add_theme_font_size_override("font_size", 32)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats)
	
	var action_btn = Button.new()
	action_btn.text = "NEXT LEVEL" if won else "RETURN TO MENU"
	action_btn.add_theme_font_size_override("font_size", 32)
	action_btn.custom_minimum_size = Vector2(300, 60)
	action_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	if won:
		action_btn.pressed.connect(GameManager.next_level)
	else:
		action_btn.pressed.connect(_on_menu_pressed)
		
	vbox.add_child(action_btn)

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
