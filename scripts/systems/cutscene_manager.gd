## CutsceneSystem - Handles story cutscenes and scripted sequences
class_name CutsceneSystem
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal cutscene_started(cutscene_id: String)
signal cutscene_finished(cutscene_id: String)
signal cutscene_skipped(cutscene_id: String)

# =============================================================================
# PROPERTIES  
# =============================================================================

var is_playing: bool = false
var current_cutscene: String = ""
var cutscene_timer: Timer
var dialogue_box: Control = null
var fade_overlay: ColorRect = null

# Cutscene completion tracking
var completed_cutscenes: Array[String] = []

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Create timer for cutscene sequencing
	cutscene_timer = Timer.new()
	cutscene_timer.one_shot = true
	add_child(cutscene_timer)
	
	# Create fade overlay for transitions
	_create_fade_overlay()

func _input(event: InputEvent) -> void:
	# Allow skipping cutscenes with ESC
	if is_playing and event.is_action_pressed("ui_cancel"):
		skip_cutscene()

# =============================================================================
# CUTSCENE PLAYBACK
# =============================================================================

func play_cutscene(cutscene_id: String) -> void:
	if is_playing:
		push_warning("Already playing cutscene: " + current_cutscene)
		return
	
	is_playing = true
	current_cutscene = cutscene_id
	cutscene_started.emit(cutscene_id)
	
	# Disable player controls
	if GameManager.player:
		GameManager.player.set_cutscene_mode(true)
	
	# Play the appropriate cutscene
	match cutscene_id:
		"prologue_summoning_cutscene":
			_play_summoning_cutscene()
		"prologue_expulsion_cutscene":
			_play_expulsion_cutscene()
		"bob_teleportation_entrance":
			_play_bob_entrance_cutscene()
		"bob_creates_crystal":
			_play_crystal_creation_cutscene()
		_:
			push_warning("Unknown cutscene: " + cutscene_id)
			end_cutscene()

func end_cutscene() -> void:
	if not is_playing:
		return
	
	is_playing = false
	completed_cutscenes.append(current_cutscene)
	
	# Re-enable player controls
	if GameManager.player:
		GameManager.player.set_cutscene_mode(false)
	
	# Update quest objectives that watch for cutscenes
	_update_cutscene_objectives(current_cutscene)
	
	cutscene_finished.emit(current_cutscene)
	current_cutscene = ""

func skip_cutscene() -> void:
	if not is_playing:
		return
	
	cutscene_timer.stop()
	_fade_in(0.2)
	cutscene_skipped.emit(current_cutscene)
	end_cutscene()

# =============================================================================
# SPECIFIC CUTSCENES
# =============================================================================

func _play_summoning_cutscene() -> void:
	_fade_out(1.0)
	await cutscene_timer.timeout
	
	# Show dialogue
	_show_dialogue("Crazy Joe", "By the ancient pacts and desperate pleas, I summon champions from beyond the veil!")
	await cutscene_timer.timeout
	
	# Flash effect for summoning
	_flash_screen(Color.CYAN, 0.5)
	await cutscene_timer.timeout
	
	_show_dialogue("Narrator", "A blinding light fills the grand hall of the Mage Association...")
	await cutscene_timer.timeout
	
	_show_dialogue("Crazy Joe", "Yes! It worked! Welcome, mighty heroes! You must save our realm from—")
	await cutscene_timer.timeout
	
	_show_dialogue("Mage Elder", "Joe! What have you done?! These... these are mere weaklings!")
	await cutscene_timer.timeout
	
	_show_dialogue("Crazy Joe", "No, no! They have potential! They can grow stronger than any of us!")
	await cutscene_timer.timeout
	
	# Give starting items
	if GameManager.player:
		GameManager.player.inventory.add_gold(50)
		QuestManager.update_objective_progress("prologue_summoning", "witness_summoning", 1)
	
	_fade_in(1.0)
	await cutscene_timer.timeout
	
	end_cutscene()

func _play_expulsion_cutscene() -> void:
	_fade_out(0.5)
	await cutscene_timer.timeout
	
	_show_dialogue("Mage Elder", "Crazy Joe, your recklessness could have torn a new rift! You are hereby expelled from the Association!")
	await cutscene_timer.timeout
	
	_show_dialogue("Crazy Joe", "But... but the realm needs—")
	await cutscene_timer.timeout
	
	_show_dialogue("Mage Elder", "SILENCE! Guards, escort him out. Strip him of his robes and staff.")
	await cutscene_timer.timeout
	
	_show_dialogue("Mage Elder", "As for these... 'Summoned'... Give them the bare minimum. Some gold and that old tree no one wants.")
	await cutscene_timer.timeout
	
	_show_dialogue("Association Clerk", "Here. 50 gold coins and residency papers for the Old Oak. Try not to die.")
	await cutscene_timer.timeout
	
	# Update objectives
	QuestManager.update_objective_progress("prologue_expulsion", "witness_expulsion", 1)
	QuestManager.update_objective_progress("prologue_expulsion", "receive_amenities", 1)
	
	_fade_in(0.5)
	await cutscene_timer.timeout
	
	end_cutscene()

func _play_bob_entrance_cutscene() -> void:
	# Wait for night time effect
	_show_dialogue("Narrator", "That night, as you settle into the dusty interior of the Old Oak...")
	await cutscene_timer.timeout
	
	# Teleportation effect
	_flash_screen(Color.PURPLE, 0.3)
	
	# Spawn Bob NPC if not already present
	_spawn_bob_at_tree()
	
	_show_dialogue("???", "Well, well. Squatters in MY tree.")
	await cutscene_timer.timeout
	
	_show_dialogue("Bob", "Name's Bob. I've been living here for decades. Just made it LOOK abandoned.")
	await cutscene_timer.timeout
	
	_show_dialogue("Bob", "You're those Summoned everyone's talking about. Weak, they say. But I sense... potential.")
	await cutscene_timer.timeout
	
	_show_dialogue("Bob", "I've been investigating the Dungeon Fracture. Something's off about the landfill outside town.")
	await cutscene_timer.timeout
	
	_show_dialogue("Bob", "Prove yourselves. Clear out whatever's lurking there and bring back samples.")
	await cutscene_timer.timeout
	
	# Update objective
	QuestManager.update_objective_progress("chapter1_bob_arrival", "witness_bob_arrival", 1)
	
	end_cutscene()

func _play_crystal_creation_cutscene() -> void:
	_show_dialogue("Bob", "Interesting... Joe's trash contains fragments of spatial magic.")
	await cutscene_timer.timeout
	
	# Crafting effect
	_flash_screen(Color.BLUE, 0.5)
	
	_show_dialogue("Bob", "By fusing these fragments... There! A Fast Travel Crystal.")
	await cutscene_timer.timeout
	
	_show_dialogue("Bob", "This will let you teleport between attuned locations. Very useful for your journey.")
	await cutscene_timer.timeout
	
	_show_dialogue("Bob", "The real quest begins now. The Fracture's cause is out there somewhere.")
	await cutscene_timer.timeout
	
	_show_dialogue("Bob", "Explore, grow stronger, and find the truth. The realm's fate depends on it.")
	await cutscene_timer.timeout
	
	# Give fast travel crystal item
	if GameManager.player:
		# Add to inventory or unlock fast travel
		FastTravelManager.unlock_location("town_square")
		FastTravelManager.unlock_location("home_tree")
	
	# Update objective
	QuestManager.update_objective_progress("chapter1_fast_travel_crystal", "witness_crystal_creation", 1)
	
	end_cutscene()

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _create_fade_overlay() -> void:
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 0.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Add to UI layer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # On top of everything
	add_child(canvas_layer)
	canvas_layer.add_child(fade_overlay)

func _fade_out(duration: float) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, duration)
	cutscene_timer.wait_time = duration
	cutscene_timer.start()

func _fade_in(duration: float) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, duration)
	cutscene_timer.wait_time = duration
	cutscene_timer.start()

func _flash_screen(color: Color, duration: float) -> void:
	fade_overlay.color = color
	fade_overlay.modulate.a = 1.0
	var tween = get_tree().create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, duration)
	cutscene_timer.wait_time = duration
	cutscene_timer.start()

func _show_dialogue(speaker: String, text: String, duration: float = 3.0) -> void:
	# This would connect to the dialogue UI system
	if GameManager.dialogue_ui:
		GameManager.dialogue_ui.show_dialogue(speaker, text)
	else:
		print("[%s]: %s" % [speaker, text])
	
	cutscene_timer.wait_time = duration
	cutscene_timer.start()

func _spawn_bob_at_tree() -> void:
	# Spawn Bob NPC in the home tree if not already there
	var bob_scene = preload("res://scenes/npcs/bob.tscn")
	if bob_scene:
		var bob = bob_scene.instantiate()
		var home_tree = get_tree().get_nodes_in_group("home_tree_interior").front()
		if home_tree:
			home_tree.add_child(bob)
			bob.global_position = home_tree.global_position + Vector3(2, 0, 0)

func _update_cutscene_objectives(cutscene_id: String) -> void:
	# Find all active quests with CUSTOM objectives matching this cutscene
	for quest_id in QuestManager._active_quests:
		var quest = QuestManager._active_quests[quest_id]
		for obj in quest.get_objectives():
			if obj.objective_type == Enums.ObjectiveType.CUSTOM and obj.target_id == cutscene_id:
				QuestManager.update_objective_progress(quest_id, obj.objective_id, 1)

# =============================================================================
# SAVE/LOAD
# =============================================================================

func get_save_data() -> Dictionary:
	return {
		"completed_cutscenes": completed_cutscenes
	}

func load_save_data(data: Dictionary) -> void:
	completed_cutscenes = data.get("completed_cutscenes", [])