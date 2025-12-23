## MageAssociation - Interior of the Mage Association building
## Hub for quests, skill training, and magic-related services
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================

signal quest_board_accessed()
signal skill_trainer_accessed()
signal exit_triggered()

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Services")
@export var has_quest_board: bool = true
@export var has_skill_trainer: bool = true
@export var has_spell_vendor: bool = true

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var quest_board: Node3D = $QuestBoard
@onready var skill_trainer_npc: Node3D = $SkillTrainerNPC
@onready var spell_vendor_npc: Node3D = $SpellVendorNPC

# =============================================================================
# PROPERTIES
# =============================================================================

var _quest_board_ui: Control = null
var _skill_tree_ui: Control = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_setup_services()
	
	# Register spawn point (deferred to ensure valid transform)
	call_deferred("_register_spawn")


func _register_spawn() -> void:
	FastTravelManager.register_spawn_point("mage_association", get_player_spawn_position())

# =============================================================================
# SERVICES SETUP
# =============================================================================

func _setup_services() -> void:
	# Quest Board
	if has_quest_board and quest_board:
		if quest_board.has_signal("interacted"):
			quest_board.interacted.connect(_on_quest_board_interacted)
	
	# Skill Trainer
	if has_skill_trainer and skill_trainer_npc:
		if skill_trainer_npc.has_method("set_dialogue_callback"):
			skill_trainer_npc.set_dialogue_callback(_on_skill_trainer_dialogue_finished)
	
	# Spell Vendor
	if has_spell_vendor and spell_vendor_npc:
		_setup_spell_vendor()


func _setup_spell_vendor() -> void:
	if spell_vendor_npc == null:
		return
	
	# Configure as shop NPC
	if spell_vendor_npc.has_method("set_shop_id"):
		spell_vendor_npc.set_shop_id("spell_vendor")


# =============================================================================
# QUEST BOARD
# =============================================================================

func _on_quest_board_interacted(_player: Node) -> void:
	quest_board_accessed.emit()
	_open_quest_board()


func _open_quest_board() -> void:
	# Open quest log UI
	var quest_log_script = load("res://scenes/ui/menus/quest_log.gd")
	if quest_log_script:
		if _quest_board_ui == null:
			_quest_board_ui = Control.new()
			_quest_board_ui.set_script(quest_log_script)
			get_tree().root.add_child(_quest_board_ui)
		
		if _quest_board_ui.has_method("open"):
			_quest_board_ui.open()

# =============================================================================
# SKILL TRAINER
# =============================================================================

func _on_skill_trainer_dialogue_finished() -> void:
	skill_trainer_accessed.emit()
	_open_skill_tree()


func _open_skill_tree() -> void:
	var skill_tree_script = load("res://scenes/ui/menus/skill_tree_ui.gd")
	if skill_tree_script:
		if _skill_tree_ui == null:
			_skill_tree_ui = Control.new()
			_skill_tree_ui.set_script(skill_tree_script)
			get_tree().root.add_child(_skill_tree_ui)
		
		if _skill_tree_ui.has_method("open"):
			_skill_tree_ui.open()

# =============================================================================
# UTILITY
# =============================================================================

func get_player_spawn_position() -> Vector3:
	if player_spawn:
		return player_spawn.global_position
	return Vector3(0, 1, 0)
