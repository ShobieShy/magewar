## SaveValidator - Validates player save data to prevent corruption
## Ensures all save data meets expected schema and constraints
class_name SaveValidator
extends Node

# =============================================================================
# VALIDATION SCHEMAS
# =============================================================================

## Schema for player data
const PLAYER_SCHEMA = {
	"id": {"type": "string", "required": true},
	"name": {"type": "string", "required": true},
	"level": {"type": "int", "required": true, "min": 1, "max": 100},
	"experience": {"type": "int", "required": true, "min": 0},
	"position": {"type": "Vector3", "required": true},
	"rotation": {"type": "float", "required": true},
	"gold": {"type": "int", "required": true, "min": 0},
	"skill_points": {"type": "int", "required": false, "min": 0},
	"unlocked_skills": {"type": "Array", "required": false},
	"active_ability": {"type": "string", "required": false},
	"stats": {"type": "Dictionary", "required": false},
	"allocated_stats": {"type": "Dictionary", "required": false},
	"unallocated_stat_points": {"type": "int", "required": false, "min": 0},
	"stat_points_per_level": {"type": "int", "required": false, "min": 0},
	"health": {"type": "float", "required": false, "min": 0},
	"mana": {"type": "float", "required": false, "min": 0},
	"inventory": {"type": "Array", "required": true},
	"equipment": {"type": "Dictionary", "required": true},
	"storage": {"type": "Array", "required": false},
	"unlocks": {"type": "Array", "required": false},
	"achievements": {"type": "Array", "required": false},
	"statistics": {"type": "Dictionary", "required": false},
	"skills": {"type": "Array", "required": false},
}

## Schema for inventory items
const ITEM_SCHEMA = {
	"id": {"type": "string", "required": true},
	"item_id": {"type": "string", "required": true},
	"stack_count": {"type": "int", "required": true, "min": 1, "max": 9999},
	"quality": {"type": "int", "required": false, "min": 0, "max": 5},
	"durability": {"type": "float", "required": false, "min": 0.0, "max": 100.0},
}

## Schema for equipment slot
const EQUIPMENT_SCHEMA = {
	"item_id": {"type": "string", "required": true},
	"enchantments": {"type": "Array", "required": false},
}

# =============================================================================
# PUBLIC METHODS
# =============================================================================

func validate_player_data(data: Dictionary) -> Dictionary:
	"""Validate player save data. Returns validation result dictionary."""
	var result = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"fixed": false
	}
	
	# Check required top-level fields
	for field_name in PLAYER_SCHEMA.keys():
		var schema = PLAYER_SCHEMA[field_name]

		if schema.get("required", false) and not data.has(field_name):
			# For sanitizable fields, this is not a validation error
			# The sanitization will provide defaults
			result.warnings.append("Missing required field will be defaulted: %s" % field_name)
			continue
		
		if data.has(field_name):
			var validation = _validate_field(field_name, data[field_name], schema)
			if not validation.valid:
				result.valid = false
				result.errors.append("Field '%s': %s" % [field_name, validation.error])
	
	# Validate inventory items
	if data.has("inventory"):
		var inv_validation = _validate_inventory(data.inventory)
		if not inv_validation.valid:
			result.valid = false
			result.errors += inv_validation.errors
	
	# Validate equipment
	if data.has("equipment"):
		var equip_validation = _validate_equipment(data.equipment)
		if not equip_validation.valid:
			result.valid = false
			result.errors += equip_validation.errors
	
	# Log results
	if not result.valid:
		push_error("Save data validation failed: ", result.errors)
	elif result.warnings.size() > 0:
		for warning in result.warnings:
			push_warning("Save data warning: %s" % warning)
	
	return result


func sanitize_player_data(data: Dictionary) -> Dictionary:
	"""Sanitize player data by removing unknown fields and clamping values."""
	var sanitized = {}

	for field_name in PLAYER_SCHEMA.keys():
		var schema = PLAYER_SCHEMA[field_name]
		var value = null

		if data.has(field_name):
			value = data[field_name]
		elif schema.get("required", false):
			# Add default values for missing required fields
			match field_name:
				"id": value = "player_1"
				"name": value = "Mage"
				"level": value = 1
				"experience": value = 0
				"gold": value = 0
				"position": value = Vector3(0, 0, 0)
				"rotation": value = 0.0
				"inventory": value = []
				"equipment": value = {
					"head": null,
					"body": null,
					"belt": null,
					"feet": null,
					"weapon_primary": null,
					"weapon_secondary": null,
					"grimoire": null,
					"potion": null
				}
			# For default values, skip further processing
			if value != null:
				sanitized[field_name] = value
				continue
		
		if value == null:
			continue
		
		# Type conversion if needed
		if schema.has("type"):
			var original_type = typeof(value)
			value = _coerce_type(value, schema.type)
			# Ensure conversion happened (especially for float->int)
			if original_type != typeof(value) and schema.type == "int" and value is float:
				value = int(round(value))
		
		# Clamp numeric values
		if schema.has("min"):
			value = max(value, schema.min)
		if schema.has("max"):
			value = min(value, schema.max)
		
		sanitized[field_name] = value
	
	# Clean inventory
	if data.has("inventory"):
		sanitized.inventory = _sanitize_inventory(data.inventory)
	
	# Clean equipment
	if data.has("equipment"):
		sanitized.equipment = _sanitize_equipment(data.equipment)
	
	return sanitized


func compare_saves(save1: Dictionary, save2: Dictionary) -> Dictionary:
	"""Compare two saves and return differences."""
	var result = {
		"equal": true,
		"player_level_changed": false,
		"inventory_changed": false,
		"position_changed": false,
		"differences": []
	}
	
	# Compare player level
	if save1.get("level", 0) != save2.get("level", 0):
		result.player_level_changed = true
		result.equal = false
		result.differences.append("Level: %d -> %d" % [save1.get("level", 0), save2.get("level", 0)])
	
	# Compare position
	if save1.get("position", Vector3.ZERO) != save2.get("position", Vector3.ZERO):
		result.position_changed = true
		result.equal = false
		result.differences.append("Position changed")
	
	# Compare inventory
	if save1.get("inventory", []) != save2.get("inventory", []):
		result.inventory_changed = true
		result.equal = false
		result.differences.append("Inventory changed")
	
	return result

# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _validate_field(_field_name: String, value: Variant, schema: Dictionary) -> Dictionary:
	"""Validate a single field against its schema."""
	var result = {"valid": true, "error": ""}
	
	# Type check
	if schema.has("type"):
		var expected_type = schema.type
		var actual_type = typeof(value)
		
		if not _is_type_match(value, expected_type):
			result.valid = false
			result.error = "Expected type %s, got %s" % [expected_type, _type_name(actual_type)]
			return result
	
	# Value range check
	if schema.has("min") and value < schema.min:
		result.valid = false
		result.error = "Value %s is below minimum %s" % [value, schema.min]
		return result
	
	if schema.has("max") and value > schema.max:
		result.valid = false
		result.error = "Value %s exceeds maximum %s" % [value, schema.max]
		return result
	
	return result


func _validate_inventory(inventory: Array) -> Dictionary:
	"""Validate inventory array."""
	var result = {"valid": true, "errors": []}
	
	if not inventory is Array:
		result.valid = false
		result.errors.append("Inventory is not an array")
		return result
	
	if inventory.size() > Constants.INVENTORY_SIZE:
		result.valid = false
		result.errors.append("Inventory exceeds maximum size (%d items)" % Constants.INVENTORY_SIZE)
	
	for i in range(inventory.size()):
		var item = inventory[i]
		if item == null:
			continue  # Null items are valid (empty slots)
		
		if item is Dictionary:
			for required_field in ITEM_SCHEMA.keys():
				if ITEM_SCHEMA[required_field].required and not item.has(required_field):
					result.valid = false
					result.errors.append("Inventory item %d missing field: %s" % [i, required_field])
	
	return result


func _validate_equipment(equipment: Dictionary) -> Dictionary:
	"""Validate equipment dictionary."""
	var result = {"valid": true, "errors": []}
	
	if not equipment is Dictionary:
		result.valid = false
		result.errors.append("Equipment is not a dictionary")
		return result
	
	for slot in equipment.keys():
		var item = equipment[slot]
		if item == null:
			continue  # Empty equipment slots are valid
		
		if item is Dictionary:
			if not item.has("item_id"):
				result.valid = false
				result.errors.append("Equipment slot %s missing item_id" % slot)
	
	return result


func _sanitize_inventory(inventory: Array) -> Array:
	"""Remove invalid items from inventory."""
	var sanitized = []
	
	for item in inventory:
		if item == null:
			sanitized.append(null)  # Keep null slots
		elif item is Dictionary and item.has("item_id"):
			# Clamp stack count
			if item.has("stack_count"):
				item.stack_count = clampi(item.stack_count, 1, 9999)
			sanitized.append(item)
		# Skip invalid items
	
	return sanitized


func _sanitize_equipment(equipment: Dictionary) -> Dictionary:
	"""Clean up equipment dictionary."""
	var sanitized = {}
	
	for slot in equipment.keys():
		var item = equipment[slot]
		if item == null:
			sanitized[slot] = null
		elif item is Dictionary and item.has("item_id"):
			sanitized[slot] = item
		# Skip invalid items
	
	return sanitized


func _is_type_match(value: Variant, expected_type: String) -> bool:
	"""Check if value matches expected type or can be coerced."""
	match expected_type:
		"string": return value is String
		"int": 
			# Allow float->int coercion
			return value is int or value is float
		"float": return value is float or value is int
		"bool": return value is bool
		"Vector3": return value is Vector3 or value is String
		"Dictionary": return value is Dictionary
		"Array": return value is Array
		_: return true


func _coerce_type(value: Variant, expected_type: String) -> Variant:
	"""Attempt to coerce value to expected type."""
	if _is_type_match(value, expected_type):
		return value
	
	match expected_type:
		"string": return str(value)
		"int": 
			if value is float:
				return int(round(value))
			return int(value)
		"float": return float(value)
		"bool": return bool(value)
		"Vector3": 
			if value is String:
				# Try to parse "x,y,z" format
				var parts = value.split(",")
				if parts.size() == 3:
					return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
			return Vector3.ZERO
		_: return value


func _type_name(type_int: int) -> String:
	"""Get human-readable type name."""
	match type_int:
		TYPE_NIL: return "nil"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "string"
		TYPE_VECTOR3: return "Vector3"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
		_: return "unknown"
