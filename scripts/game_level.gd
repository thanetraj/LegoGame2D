extends Node2D

var ROOM_SIZE = 500
var GRID_W = 4
var GRID_H = 4

var map_grid = []
var walls_node: StaticBody2D

func _ready():
	GRID_W = 3 + GameManager.current_level
	GRID_H = 3 + GameManager.current_level
	_setup_level_nodes()
	_generate_maze()
	_spawn_entities()

func _setup_level_nodes():
	# Darkness
	var darkness = CanvasModulate.new()
	darkness.color = Color(0.05, 0.05, 0.08, 1.0)
	darkness.name = "Darkness"
	add_child(darkness)
	
	# Background
	var bg = Polygon2D.new()
	bg.color = Color(0.15, 0.15, 0.15)
	var w = GRID_W * ROOM_SIZE
	var h = GRID_H * ROOM_SIZE
	bg.polygon = PackedVector2Array([
		Vector2(-ROOM_SIZE, -ROOM_SIZE),
		Vector2(w + ROOM_SIZE, -ROOM_SIZE),
		Vector2(w + ROOM_SIZE, h + ROOM_SIZE),
		Vector2(-ROOM_SIZE, h + ROOM_SIZE)
	])
	bg.z_index = -10
	add_child(bg)
	
	walls_node = StaticBody2D.new()
	walls_node.name = "Walls"
	add_child(walls_node)
	
	# Spawn HUD
	var hud_script = load("res://scripts/hud.gd")
	if hud_script:
		var hud = hud_script.new()
		add_child(hud)

func _generate_maze():
	# Simple grid generation with random walls missing
	for x in range(GRID_W):
		map_grid.append([])
		for y in range(GRID_H):
			map_grid[x].append(true)
			_build_room_walls(x, y)
			
	# Border walls
	_build_wall(Vector2(-10, -10), Vector2(GRID_W * ROOM_SIZE + 10, -10))
	_build_wall(Vector2(-10, GRID_H * ROOM_SIZE + 10), Vector2(GRID_W * ROOM_SIZE + 10, GRID_H * ROOM_SIZE + 10))
	_build_wall(Vector2(-10, -10), Vector2(-10, GRID_H * ROOM_SIZE + 10))
	_build_wall(Vector2(GRID_W * ROOM_SIZE + 10, -10), Vector2(GRID_W * ROOM_SIZE + 10, GRID_H * ROOM_SIZE + 10))

func _build_room_walls(x: int, y: int):
	var px = x * ROOM_SIZE
	var py = y * ROOM_SIZE
	
	# Horizontal wall
	if y > 0 and randf() > 0.4:
		_build_wall(Vector2(px, py), Vector2(px + ROOM_SIZE / 2 - 50, py))
		_build_wall(Vector2(px + ROOM_SIZE / 2 + 50, py), Vector2(px + ROOM_SIZE, py))
		
	# Vertical wall
	if x > 0 and randf() > 0.4:
		_build_wall(Vector2(px, py), Vector2(px, py + ROOM_SIZE / 2 - 50))
		_build_wall(Vector2(px, py + ROOM_SIZE / 2 + 50), Vector2(px, py + ROOM_SIZE))

func _build_wall(start: Vector2, end: Vector2):
	var col = CollisionShape2D.new()
	var shape = SegmentShape2D.new()
	shape.a = start
	shape.b = end
	col.shape = shape
	walls_node.add_child(col)
	
	var line = Line2D.new()
	line.add_point(start)
	line.add_point(end)
	line.width = 10.0
	line.default_color = Color(0.2, 0.2, 0.2)
	# Light occluder for shadows
	var occ = LightOccluder2D.new()
	var poly = OccluderPolygon2D.new()
	var dir = (end - start).normalized().orthogonal() * 5.0
	poly.polygon = PackedVector2Array([
		start + dir, end + dir, end - dir, start - dir
	])
	occ.occluder = poly
	walls_node.add_child(line)
	walls_node.add_child(occ)

func _spawn_entities():
	var player_script = load("res://scripts/player.gd")
	if player_script:
		var player = player_script.new()
		player.position = Vector2(ROOM_SIZE / 2, ROOM_SIZE / 2)
		player.name = "Player"
		player.add_to_group("Player")
		add_child(player)
		
	var enemy_script = load("res://scripts/enemy.gd")
	var item_script = load("res://scripts/collectible_item.gd")
	
	var enemy_count = GameManager.current_level + 2
	for i in range(enemy_count):
		if enemy_script:
			var enemy = enemy_script.new()
			enemy.position = Vector2(randf_range(ROOM_SIZE, GRID_W * ROOM_SIZE - ROOM_SIZE), randf_range(ROOM_SIZE, GRID_H * ROOM_SIZE - ROOM_SIZE))
			enemy.name = "Enemy_" + str(i)
			add_child(enemy)
			
	var item_count = 10 + (GameManager.current_level * 5)
	for i in range(item_count):
		if item_script:
			var item = item_script.new()
			item.position = Vector2(randf_range(100, GRID_W * ROOM_SIZE - 100), randf_range(100, GRID_H * ROOM_SIZE - 100))
			add_child(item)
