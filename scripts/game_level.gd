extends Node2D

var ROOM_SIZE = 500
var GRID_W = 4
var GRID_H = 4

var map_grid = []
var walls_node: StaticBody2D

# --- Room Visibility / Fog of War ---
var visited_rooms: Dictionary = {}  # Key: Vector2i(room_x, room_y), Value: true
var player_ref: Node2D = null
var enemies_list: Array = []
var items_list: Array = []

func _ready():
	GRID_W = 3 + GameManager.current_level
	GRID_H = 3 + GameManager.current_level
	_setup_level_nodes()
	_generate_maze()
	_spawn_entities()
	# Mark starting room (0,0) as visited
	visited_rooms[Vector2i(0, 0)] = true

func _process(_delta):
	if player_ref == null:
		return
	# Determine which room the player is currently in
	var player_room = _get_room_from_position(player_ref.global_position)
	
	# Mark current room as visited
	if not visited_rooms.has(player_room):
		visited_rooms[player_room] = true
	
	var space_state = get_world_2d().direct_space_state
	
	# Update visibility: Must be within distance AND have line-of-sight (no walls in between)
	for enemy in enemies_list:
		if is_instance_valid(enemy):
			var dist = enemy.global_position.distance_to(player_ref.global_position)
			var is_vis = false
			if dist < 900.0:
				var query = PhysicsRayQueryParameters2D.create(player_ref.global_position, enemy.global_position)
				query.exclude = [player_ref.get_rid(), enemy.get_rid()]
				is_vis = space_state.intersect_ray(query).is_empty()
			enemy.visible = is_vis
	
	for item in items_list:
		if is_instance_valid(item):
			var dist = item.global_position.distance_to(player_ref.global_position)
			var is_vis = false
			if dist < 900.0:
				var query = PhysicsRayQueryParameters2D.create(player_ref.global_position, item.global_position)
				query.exclude = [player_ref.get_rid(), item.get_rid()]
				is_vis = space_state.intersect_ray(query).is_empty()
			item.visible = is_vis

# Convert a world position to a room grid coordinate
func _get_room_from_position(pos: Vector2) -> Vector2i:
	var rx = clampi(int(pos.x / ROOM_SIZE), 0, GRID_W - 1)
	var ry = clampi(int(pos.y / ROOM_SIZE), 0, GRID_H - 1)
	return Vector2i(rx, ry)

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
		player_ref = player_script.new()
		player_ref.position = Vector2(ROOM_SIZE / 2, ROOM_SIZE / 2)
		player_ref.name = "Player"
		player_ref.add_to_group("Player")
		add_child(player_ref)
		
	var enemy_script = load("res://scripts/enemy.gd")
	var item_script = load("res://scripts/collectible_item.gd")
	
	var enemy_count = GameManager.current_level + 2
	for i in range(enemy_count):
		if enemy_script:
			var enemy = enemy_script.new()
			enemy.position = Vector2(randf_range(ROOM_SIZE, GRID_W * ROOM_SIZE - ROOM_SIZE), randf_range(ROOM_SIZE, GRID_H * ROOM_SIZE - ROOM_SIZE))
			enemy.name = "Enemy_" + str(i)
			enemy.visible = false  # Hidden until room is visited
			add_child(enemy)
			enemies_list.append(enemy)
			
	var item_count = 10 + (GameManager.current_level * 5)
	for i in range(item_count):
		if item_script:
			var item = item_script.new()
			item.position = Vector2(randf_range(100, GRID_W * ROOM_SIZE - 100), randf_range(100, GRID_H * ROOM_SIZE - 100))
			item.visible = false  # Hidden until room is visited
			add_child(item)
			items_list.append(item)
