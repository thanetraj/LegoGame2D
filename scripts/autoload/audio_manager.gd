extends Node

# --- Audio Players ---
var ambience_player: AudioStreamPlayer
var heartbeat_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer  # For short one-shot sounds

# --- Procedural Audio State ---
var ambience_phase: float = 0.0
var heartbeat_phase: float = 0.0
var heartbeat_bpm: float = 60.0  # Beats per minute, increases with fear
var heartbeat_time: float = 0.0
var is_heartbeat_active: bool = false

# Footstep
var footstep_cooldown: float = 0.0

# Ambience
const AMBIENCE_MIX_RATE = 22050.0
const SFX_MIX_RATE = 22050.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ambience()
	_setup_heartbeat()
	_setup_sfx()

func _process(delta):
	if not GameManager.is_game_active:
		if ambience_player.playing:
			ambience_player.stop()
		if heartbeat_player.playing:
			heartbeat_player.stop()
		return
	
	# Start ambience if not playing
	if not ambience_player.playing:
		ambience_player.play()
	
	_fill_ambience_buffer()
	_update_heartbeat(delta)
	
	# Footstep cooldown
	if footstep_cooldown > 0:
		footstep_cooldown -= delta

# ===== SETUP =====

func _setup_ambience():
	ambience_player = AudioStreamPlayer.new()
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = AMBIENCE_MIX_RATE
	stream.buffer_length = 0.5
	ambience_player.stream = stream
	ambience_player.volume_db = -18.0
	ambience_player.bus = "Master"
	add_child(ambience_player)

func _setup_heartbeat():
	heartbeat_player = AudioStreamPlayer.new()
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = AMBIENCE_MIX_RATE
	stream.buffer_length = 0.3
	heartbeat_player.stream = stream
	heartbeat_player.volume_db = -10.0
	heartbeat_player.bus = "Master"
	add_child(heartbeat_player)

func _setup_sfx():
	sfx_player = AudioStreamPlayer.new()
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = SFX_MIX_RATE
	stream.buffer_length = 0.5
	sfx_player.stream = stream
	sfx_player.volume_db = -6.0
	sfx_player.bus = "Master"
	add_child(sfx_player)

# ===== AMBIENCE — Eerie low drone =====

func _fill_ambience_buffer():
	var playback: AudioStreamGeneratorPlayback = ambience_player.get_stream_playback()
	if playback == null:
		return
	var frames_available = playback.get_frames_available()
	for i in range(frames_available):
		ambience_phase += 1.0 / AMBIENCE_MIX_RATE
		# Layered low-frequency drones for eerie atmosphere
		var sample = 0.0
		# Base drone (45 Hz)
		sample += sin(ambience_phase * 45.0 * TAU) * 0.3
		# Slow wobble (50 Hz with modulation)
		sample += sin(ambience_phase * 50.0 * TAU + sin(ambience_phase * 0.3 * TAU) * 2.0) * 0.2
		# Very low sub-bass rumble (30 Hz)
		sample += sin(ambience_phase * 30.0 * TAU) * 0.15
		# Creepy high whisper tone (very quiet)
		sample += sin(ambience_phase * 800.0 * TAU + sin(ambience_phase * 2.0 * TAU) * 5.0) * 0.03
		
		sample = clamp(sample, -1.0, 1.0)
		playback.push_frame(Vector2(sample, sample))

# ===== HEARTBEAT — Increases with fear =====

func _update_heartbeat(delta):
	var fear = GameManager.fear_current
	
	# Heartbeat activates when fear > 30%
	if fear > 30.0:
		if not is_heartbeat_active:
			is_heartbeat_active = true
			heartbeat_player.play()
		
		# BPM increases with fear: 60 BPM at 30% fear -> 160 BPM at 100% fear
		heartbeat_bpm = remap(fear, 30.0, 100.0, 60.0, 160.0)
		heartbeat_player.volume_db = remap(fear, 30.0, 100.0, -15.0, -3.0)
		
		_fill_heartbeat_buffer()
	else:
		if is_heartbeat_active:
			is_heartbeat_active = false
			heartbeat_player.stop()

func _fill_heartbeat_buffer():
	var playback: AudioStreamGeneratorPlayback = heartbeat_player.get_stream_playback()
	if playback == null:
		return
	var frames_available = playback.get_frames_available()
	var beat_duration = 60.0 / heartbeat_bpm  # seconds per beat
	
	for i in range(frames_available):
		heartbeat_time += 1.0 / AMBIENCE_MIX_RATE
		
		# Position within the current beat cycle (0.0 to 1.0)
		var beat_pos = fmod(heartbeat_time, beat_duration) / beat_duration
		
		var sample = 0.0
		# "Lub" - first thump (at 0.0 of beat)
		if beat_pos < 0.08:
			var env = 1.0 - (beat_pos / 0.08)
			sample = sin(beat_pos * 55.0 * TAU) * env * env * 0.8
		# "Dub" - second thump (at 0.15 of beat)  
		elif beat_pos > 0.12 and beat_pos < 0.20:
			var local_pos = (beat_pos - 0.12) / 0.08
			var env = 1.0 - local_pos
			sample = sin(local_pos * 45.0 * TAU) * env * env * 0.6
		
		sample = clamp(sample, -1.0, 1.0)
		playback.push_frame(Vector2(sample, sample))

# ===== SFX — One-shot sound effects =====

func play_footstep(is_sprinting: bool = false):
	if footstep_cooldown > 0:
		return
	# Sprint = faster footsteps
	footstep_cooldown = 0.25 if is_sprinting else 0.4
	_generate_and_play_sfx("footstep")

func play_flashlight_click():
	_generate_and_play_sfx("click")

func play_item_pickup():
	_generate_and_play_sfx("pickup")

func play_enemy_growl():
	_generate_and_play_sfx("growl")

func play_damage_hit():
	_generate_and_play_sfx("hit")

func _generate_and_play_sfx(sound_type: String):
	# Create a temporary player for each SFX so they can overlap
	var player = AudioStreamPlayer.new()
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = SFX_MIX_RATE
	stream.buffer_length = 0.5
	player.stream = stream
	player.bus = "Master"
	add_child(player)
	
	match sound_type:
		"footstep":
			player.volume_db = -20.0
		"click":
			player.volume_db = -10.0
		"pickup":
			player.volume_db = -8.0
		"growl":
			player.volume_db = -6.0
		"hit":
			player.volume_db = -4.0
	
	player.play()
	
	# Fill buffer with generated sound
	# Need to wait one frame for playback to be available
	await get_tree().process_frame
	
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	if playback == null:
		player.queue_free()
		return
	
	var samples = []
	match sound_type:
		"footstep":
			samples = _gen_footstep()
		"click":
			samples = _gen_click()
		"pickup":
			samples = _gen_pickup()
		"growl":
			samples = _gen_growl()
		"hit":
			samples = _gen_hit()
	
	for s in samples:
		playback.push_frame(Vector2(s, s))
	
	# Auto-free after playback
	var duration = samples.size() / SFX_MIX_RATE
	await get_tree().create_timer(duration + 0.1).timeout
	player.queue_free()

# --- Sound Generators ---

func _gen_footstep() -> Array:
	var samples = []
	var duration = 0.06  # Very short thud
	var total = int(duration * SFX_MIX_RATE)
	for i in range(total):
		var t = float(i) / SFX_MIX_RATE
		var env = 1.0 - (t / duration)
		# Low thud noise
		var sample = (randf() * 2.0 - 1.0) * env * env * 0.4
		# Add a low tone
		sample += sin(t * 120.0 * TAU) * env * env * 0.3
		samples.append(clamp(sample, -1.0, 1.0))
	return samples

func _gen_click() -> Array:
	var samples = []
	var duration = 0.04
	var total = int(duration * SFX_MIX_RATE)
	for i in range(total):
		var t = float(i) / SFX_MIX_RATE
		var env = 1.0 - (t / duration)
		# Sharp click — high frequency burst
		var sample = sin(t * 2500.0 * TAU) * env * env * 0.6
		sample += sin(t * 1800.0 * TAU) * env * 0.3
		samples.append(clamp(sample, -1.0, 1.0))
	return samples

func _gen_pickup() -> Array:
	var samples = []
	var duration = 0.25
	var total = int(duration * SFX_MIX_RATE)
	for i in range(total):
		var t = float(i) / SFX_MIX_RATE
		var env = 1.0 - (t / duration)
		# Ascending tone: 440Hz -> 880Hz (pleasant ding)
		var freq = lerp(440.0, 880.0, t / duration)
		var sample = sin(t * freq * TAU) * env * 0.5
		# Add harmonic sparkle
		sample += sin(t * freq * 2.0 * TAU) * env * env * 0.2
		samples.append(clamp(sample, -1.0, 1.0))
	return samples

func _gen_growl() -> Array:
	var samples = []
	var duration = 0.4
	var total = int(duration * SFX_MIX_RATE)
	for i in range(total):
		var t = float(i) / SFX_MIX_RATE
		var env_in = min(t / 0.05, 1.0)  # Fade in
		var env_out = 1.0 - max((t - 0.3) / 0.1, 0.0)  # Fade out
		var env = env_in * env_out
		# Distorted low growl
		var sample = sin(t * 80.0 * TAU + sin(t * 30.0 * TAU) * 3.0) * env * 0.7
		# Add rumble noise
		sample += (randf() * 2.0 - 1.0) * env * 0.2
		samples.append(clamp(sample, -1.0, 1.0))
	return samples

func _gen_hit() -> Array:
	var samples = []
	var duration = 0.15
	var total = int(duration * SFX_MIX_RATE)
	for i in range(total):
		var t = float(i) / SFX_MIX_RATE
		var env = 1.0 - (t / duration)
		# Harsh impact — noise + low thump
		var sample = (randf() * 2.0 - 1.0) * env * env * 0.5
		sample += sin(t * 60.0 * TAU) * env * 0.6
		# Distortion crunch
		sample += sin(t * 200.0 * TAU) * env * env * env * 0.3
		samples.append(clamp(sample, -1.0, 1.0))
	return samples
