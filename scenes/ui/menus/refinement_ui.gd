## RefinementUI - Weapon refinement interface
## Allows players to refine weapons from +0 to +10
class_name RefinementUI
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal refinement_attempted(weapon: ItemData, success: bool)
signal refinement_cancelled()

# =============================================================================
# REFERENCES
# =============================================================================

@onready var title_label = $VBoxContainer/TitleLabel
@onready var tier_label = $VBoxContainer/TierLabel
@onready var tier_progress = $VBoxContainer/TierProgress
@onready var success_label = $VBoxContainer/SuccessLabel
@onready var downgrade_warning = $VBoxContainer/DowngradeWarning
@onready var cost_panel = $VBoxContainer/CostPanel
@onready var materials_list = $VBoxContainer/CostPanel/MaterialsList
@onready var gold_cost_label = $VBoxContainer/CostPanel/GoldCostLabel
@onready var refine_button = $VBoxContainer/ButtonContainer/RefineButton
@onready var cancel_button = $VBoxContainer/ButtonContainer/CancelButton
@onready var recovery_checkbox = $VBoxContainer/RecoveryCheckbox
@onready var recovery_cost_label = $VBoxContainer/RecoveryCostLabel

# =============================================================================
# PROPERTIES
# =============================================================================

var current_weapon: ItemData = null
var player_inventory: InventorySystem = null
var player_gold: int = 0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Hide by default
	hide()
	
	# Connect buttons
	refine_button.pressed.connect(_on_refine_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	recovery_checkbox.toggled.connect(_on_recovery_toggled)

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

## Open refinement UI for a weapon
func open_refinement(weapon: ItemData, inventory: InventorySystem, gold: int) -> void:
	current_weapon = weapon
	player_inventory = inventory
	player_gold = gold
	
	show()
	_update_display()

## Close refinement UI
func close_refinement() -> void:
	hide()
	current_weapon = null
	recovery_checkbox.button_pressed = false

# =============================================================================
# DISPLAY UPDATES
# =============================================================================

func _update_display() -> void:
	if not current_weapon or not current_weapon.has_meta("refinement_system"):
		_display_no_weapon()
		return
	
	var refinement_system = current_weapon.get_meta("refinement_system")
	var current_tier = refinement_system.refinement_level
	var next_tier = current_tier + 1
	
	# Update title
	if current_weapon.has_meta("weapon_name"):
		title_label.text = "Refining: %s" % current_weapon.get_meta("weapon_name")
	else:
		title_label.text = "Refining Weapon"
	
	# Update tier display
	tier_label.text = "Current Tier: +%d/+10" % current_tier
	tier_progress.value = current_tier * 10  # 0-100
	
	# Check if max refinement
	if refinement_system.is_max_refinement():
		title_label.text += " (MAX)"
		refine_button.disabled = true
		success_label.text = "This weapon is fully refined!"
		materials_list.clear()
		gold_cost_label.text = "N/A"
		downgrade_warning.hide()
		recovery_checkbox.hide()
		recovery_cost_label.hide()
		return
	
	# Update success chance
	var success_chance = refinement_system.get_success_chance()
	success_label.text = "Success Rate: %.0f%%" % (success_chance * 100)
	
	# Update downgrade warning
	var downgrade_risk = refinement_system.get_downgrade_risk()
	if downgrade_risk > 0:
		downgrade_warning.show()
		downgrade_warning.text = "⚠️ Failure Risk: Weapon may downgrade to +%d (%.0f%% chance)" % [
			current_tier - 1, downgrade_risk * 100
		]
	else:
		downgrade_warning.hide()
	
	# Update costs
	var cost = refinement_system.get_next_refinement_cost()
	var gold_cost = cost.get("gold", 0)
	
	gold_cost_label.text = "Gold Cost: %d" % gold_cost
	
	# Display material requirements
	_display_materials(cost)
	
	# Calculate recovery cost
	var material_requirements = cost.duplicate()
	material_requirements.erase("gold")
	var recovery_cost = _calculate_recovery_cost(material_requirements)
	recovery_cost_label.text = "Insurance Cost: %d gold" % recovery_cost
	
	# Update button state
	_update_button_state(refinement_system, cost, gold_cost)

func _display_materials(cost: Dictionary) -> void:
	materials_list.clear()
	
	for material_id in cost:
		if material_id == "gold":
			continue
		
		var needed = cost[material_id]
		var have = player_inventory.get_material_quantity(material_id)
		
		# Load material for display name
		var material_path = "res://resources/items/materials/%s.tres" % material_id
		var material_name = material_id
		if ResourceLoader.exists(material_path):
			var material = load(material_path)
			material_name = material.get_display_name()
		
		var status = "✓" if have >= needed else "✗"
		var text = "%s %s: %d / %d" % [status, material_name, have, needed]
		materials_list.add_item(text)
		
		# Color items based on whether we have enough
		if have < needed:
			materials_list.set_item_custom_fg_color(materials_list.item_count - 1, Color.RED)

func _display_no_weapon() -> void:
	title_label.text = "No weapon selected"
	tier_label.text = "Please equip a weapon to refine"
	success_label.text = ""
	materials_list.clear()
	gold_cost_label.text = ""
	downgrade_warning.hide()
	refine_button.disabled = true

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_refine_pressed() -> void:
	if not current_weapon or not current_weapon.has_meta("refinement_system"):
		return
	
	var refinement_system = current_weapon.get_meta("refinement_system")
	var cost = refinement_system.get_next_refinement_cost()
	var gold_cost = cost.get("gold", 0)
	
	# Check resources
	if player_gold < gold_cost:
		_show_error("Not enough gold! Need %d, have %d" % [gold_cost, player_gold])
		return
	
	var material_requirements = cost.duplicate()
	material_requirements.erase("gold")
	
	if not player_inventory.has_materials(material_requirements):
		_show_error("Not enough materials!")
		return
	
	# Consume resources
	player_gold -= gold_cost
	if not player_inventory.consume_materials(material_requirements):
		_show_error("Failed to consume materials!")
		player_gold += gold_cost  # Refund gold if material consumption fails
		return
	
	# Attempt refinement
	var success = refinement_system.attempt_refinement()
	
	if success:
		_show_success("Refinement successful! Weapon now +%d" % refinement_system.refinement_level)
		refinement_attempted.emit(current_weapon, true)
	else:
		# Check for downgrade
		var downgrade_risk = refinement_system.get_downgrade_risk()
		if downgrade_risk > 0 and refinement_system.refinement_level < cost.get("gold", 0) / 100:
			_show_error("Refinement failed! Weapon downgraded to +%d" % refinement_system.refinement_level)
		else:
			_show_error("Refinement failed! Your materials were consumed.")
		refinement_attempted.emit(current_weapon, false)
	
	_update_display()

func _on_cancel_pressed() -> void:
	refinement_cancelled.emit()
	close_refinement()

func _on_recovery_toggled(_enabled: bool) -> void:
	_update_display()

# =============================================================================
# UTILITY
# =============================================================================

func _update_button_state(_refinement_system: RefinementSystem, cost: Dictionary, gold_cost: int) -> void:
	var can_afford_gold = player_gold >= gold_cost
	var can_afford_materials = true
	
	var material_requirements = cost.duplicate()
	material_requirements.erase("gold")
	
	for material_id in material_requirements:
		var needed = material_requirements[material_id]
		var have = player_inventory.get_material_quantity(material_id)
		if have < needed:
			can_afford_materials = false
			break
	
	refine_button.disabled = not (can_afford_gold and can_afford_materials)

func _calculate_recovery_cost(material_requirements: Dictionary) -> int:
	var material_count = 0
	for material_id in material_requirements:
		material_count += material_requirements[material_id]
	return material_count * 50

func _show_success(message: String) -> void:
	success_label.text = message
	success_label.add_theme_color_override("font_color", Color.GREEN)

func _show_error(message: String) -> void:
	success_label.text = message
	success_label.add_theme_color_override("font_color", Color.RED)
