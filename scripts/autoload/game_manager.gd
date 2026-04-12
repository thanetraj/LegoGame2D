extends Node

signal quota_updated(current, target)
signal battery_updated(percentage)
signal fear_updated(percentage)
signal health_updated(percentage)
signal player_damaged(amount)
signal level_completed
signal game_over

var quota_target: int = 150
var quota_current: int = 0
var battery_max: float = 100.0
var battery_current: float = 100.0
var fear_current: float = 0.0
var current_level: int = 1

# --- Health System ---
var health_max: float = 100.0
var health_current: float = 100.0
var death_cause: String = "unknown"  # "fear", "enemy", "unknown"

var is_game_active: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	if not is_game_active:
		return
	# When fear is very high, continuously drain health
	if fear_current >= 80.0:
		var drain_rate = remap(fear_current, 80.0, 100.0, 1.0, 8.0)
		damage_player(drain_rate * delta, "fear")

func start_game():
	current_level = 1
	_start_current_level()

func _start_current_level():
	if current_level > 5:
		current_level = 1
		
	quota_target = 100 + ((current_level - 1) * 50)
	quota_current = 0
	battery_current = battery_max
	fear_current = 0.0
	health_current = health_max
	death_cause = "unknown"
	is_game_active = true
	get_tree().call_deferred("change_scene_to_file", "res://scenes/game_level.tscn")
	
func next_level():
	current_level += 1
	_start_current_level()
	
func add_quota(amount: int):
	quota_current += amount
	quota_updated.emit(quota_current, quota_target)
	
	if quota_current >= quota_target and is_game_active:
		is_game_active = false
		level_completed.emit()
		get_tree().call_deferred("change_scene_to_file", "res://scenes/game_over.tscn")

func drain_battery(amount: float):
	battery_current = clamp(battery_current - amount, 0.0, battery_max)
	battery_updated.emit(battery_current / battery_max)

func add_fear(amount: float):
	fear_current = clamp(fear_current + amount, 0.0, 100.0)
	fear_updated.emit(fear_current / 100.0)
	# Fear no longer causes instant game over — it drains health via _process()

func recharge_battery(amount: float):
	battery_current = clamp(battery_current + amount, 0.0, battery_max)
	battery_updated.emit(battery_current / battery_max)

# --- Health Functions ---
func damage_player(amount: float, source: String = "enemy"):
	if not is_game_active:
		return
	health_current = clamp(health_current - amount, 0.0, health_max)
	health_updated.emit(health_current / health_max)
	if amount >= 5.0:
		player_damaged.emit(amount)
	
	if health_current <= 0.0:
		death_cause = source
		trigger_game_over()

func heal_player(amount: float):
	health_current = clamp(health_current + amount, 0.0, health_max)
	health_updated.emit(health_current / health_max)

func trigger_game_over():
	is_game_active = false
	game_over.emit()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/game_over.tscn")
