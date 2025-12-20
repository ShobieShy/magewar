## InventorySystem - Manages player inventory and equipment
class_name InventorySystem
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal inventory_changed()
signal item_added(item: ItemData, slot: int)
signal item_removed(item: ItemData, slot: int)
signal item_used(item: ItemData)
signal equipment_changed(slot: Enums.EquipmentSlot)
signal inventory_full()

# =============================================================================
# PROPERTIES
# =============================================================================

var owner_node: Node
var stats_component: StatsComponent

var inventory: Array = []  # Array of ItemData or null
var equipment: Dictionary = {}  # EquipmentSlot -> ItemData

var inventory_size: int = Constants.INVENTORY_SIZE

# Transaction system for preventing duplication during drag-drop
var _transaction_counter: int = 0
var _pending_transactions: Dictionary = {}  # transaction_id -> {source_slot, target_slot, item_id}

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Initialize inventory slots
	inventory.resize(inventory_size)
	
	# Initialize equipment slots
	for slot in Enums.EquipmentSlot.values():
		if slot != Enums.EquipmentSlot.NONE:
			equipment[slot] = null

# =============================================================================
# INITIALIZATION
# =============================================================================

func initialize(owner: Node) -> void:
	owner_node = owner
	stats_component = owner.get_node_or_null("StatsComponent")

# =============================================================================
# INVENTORY OPERATIONS
# =============================================================================

func add_item(item: ItemData) -> int:
	## Adds an item to inventory. Returns slot index or -1 if full.
	
	# Validate item
	if not item or not is_instance_valid(item):
		push_warning("add_item: Attempted to add invalid item")
		return -1
	
	# Try to stack if stackable
	if item.stackable:
		for i in range(inventory_size):
			if inventory[i] and is_instance_valid(inventory[i]) and inventory[i].item_id == item.item_id:
				if inventory[i].stack_count < inventory[i].max_stack:
					inventory[i].stack_count += item.stack_count if item.stack_count > 0 else 1
					# Ensure we don't exceed max stack
					if inventory[i].stack_count > inventory[i].max_stack:
						inventory[i].stack_count = inventory[i].max_stack
					item_added.emit(inventory[i], i)
					inventory_changed.emit()
					return i
	
	# Find empty slot
	for i in range(inventory_size):
		if inventory[i] == null:
			# Create a new instance to avoid reference issues
			if item.has_method("duplicate"):
				inventory[i] = item.duplicate()
			else:
				inventory[i] = item
			item_added.emit(inventory[i], i)
			inventory_changed.emit()
			return i
	
	inventory_full.emit()
	return -1


func remove_item(slot: int) -> ItemData:
	## Removes and returns item at slot
	if slot < 0 or slot >= inventory_size:
		return null
	
	var item = inventory[slot]
	if item == null:
		return null
	
	inventory[slot] = null
	item_removed.emit(item, slot)
	inventory_changed.emit()
	return item


func remove_item_by_id(item_id: String, count: int = 1) -> int:
	## Removes items by ID. Returns number actually removed.
	var removed = 0
	
	for i in range(inventory_size):
		if removed >= count:
			break
		
		if inventory[i] and inventory[i].item_id == item_id:
			if inventory[i].stackable and inventory[i].stack_count > 1:
				var to_remove = mini(inventory[i].stack_count, count - removed)
				inventory[i].stack_count -= to_remove
				removed += to_remove
				if inventory[i].stack_count <= 0:
					inventory[i] = null
			else:
				inventory[i] = null
				removed += 1
	
	if removed > 0:
		inventory_changed.emit()
	
	return removed


func get_item(slot: int) -> ItemData:
	if slot < 0 or slot >= inventory_size:
		return null
	return inventory[slot]


func move_item(from_slot: int, to_slot: int) -> int:
	"""Atomically move an item from one slot to another.
	
	This is safer than swap for drag-drop operations because it moves
	rather than swaps, reducing the chance of duplication.
	Returns transaction ID or -1 if failed.
	"""
	if from_slot < 0 or from_slot >= inventory_size:
		push_warning("move_item: Invalid from_slot %d" % from_slot)
		return -1
	if to_slot < 0 or to_slot >= inventory_size:
		push_warning("move_item: Invalid to_slot %d" % to_slot)
		return -1
	
	if from_slot == to_slot:
		return -1
	
	# Get and validate source item
	var item = inventory[from_slot]
	if item == null:
		push_warning("move_item: No item at from_slot %d" % from_slot)
		return -1
	
	if not is_instance_valid(item):
		push_warning("move_item: Item at from_slot %d is invalid" % from_slot)
		inventory[from_slot] = null  # Clean up stale reference
		return -1
	
	# Validate target is empty
	if inventory[to_slot] != null:
		push_warning("move_item: Target slot %d is not empty" % to_slot)
		return -1
	
	# Atomic move operation
	inventory[to_slot] = item
	inventory[from_slot] = null
	inventory_changed.emit()
	_transaction_counter += 1
	return _transaction_counter


func swap_items(slot_a: int, slot_b: int) -> int:
	"""Atomically swap two inventory items. Returns transaction ID.
	
	This operation is atomic to prevent duplication in drag-drop scenarios.
	Returns -1 if swap failed.
	"""
	if slot_a < 0 or slot_a >= inventory_size:
		push_warning("swap_items: Invalid slot_a %d" % slot_a)
		return -1
	if slot_b < 0 or slot_b >= inventory_size:
		push_warning("swap_items: Invalid slot_b %d" % slot_b)
		return -1
	
	# Don't swap if same slot
	if slot_a == slot_b:
		return -1
	
	# Validate items before swap
	var item_a = inventory[slot_a]
	var item_b = inventory[slot_b]
	
	# Validate instances
	if item_a and not is_instance_valid(item_a):
		push_warning("swap_items: Item at slot_a %d is invalid" % slot_a)
		return -1
	if item_b and not is_instance_valid(item_b):
		push_warning("swap_items: Item at slot_b %d is invalid" % slot_b)
		return -1
	
	# Check for stacking if both items exist and are the same
	if item_a and item_b:
		if item_a.item_id == item_b.item_id and item_a.stackable:
			# Try to stack instead of swapping
			var total_count = item_a.stack_count + item_b.stack_count
			if total_count <= item_a.max_stack:
				# Combine into slot_b
				item_b.stack_count = total_count
				inventory[slot_a] = null
				inventory_changed.emit()
				_transaction_counter += 1
				return _transaction_counter
			else:
				# Fill slot_b to max and keep remainder in slot_a
				item_a.stack_count = total_count - item_a.max_stack
				item_b.stack_count = item_a.max_stack
				inventory_changed.emit()
				_transaction_counter += 1
				return _transaction_counter
	
	# Regular swap - atomic operation
	var temp = inventory[slot_a]
	inventory[slot_a] = inventory[slot_b]
	inventory[slot_b] = temp
	inventory_changed.emit()
	_transaction_counter += 1
	return _transaction_counter


func has_item(item_id: String, count: int = 1) -> bool:
	var found = 0
	for item in inventory:
		if item and item.item_id == item_id:
			if item.stackable:
				found += item.stack_count
			else:
				found += 1
		if found >= count:
			return true
	return false


func get_item_count(item_id: String) -> int:
	var count = 0
	for item in inventory:
		if item and item.item_id == item_id:
			if item.stackable:
				count += item.stack_count
			else:
				count += 1
	return count


func get_free_slots() -> int:
	var free = 0
	for item in inventory:
		if item == null:
			free += 1
	return free


func is_full() -> bool:
	return get_free_slots() == 0

# =============================================================================
# EQUIPMENT OPERATIONS
# =============================================================================

func equip_item(item: ItemData, from_inventory_slot: int = -1) -> ItemData:
	## Equips an item and returns the previously equipped item (if any)
	
	if item == null:
		push_warning("Cannot equip null item")
		return null
	
	if not is_instance_valid(item):
		push_warning("Cannot equip invalid item")
		return null
	
	if not item is EquipmentData:
		push_warning("Cannot equip non-equipment item")
		return null
	
	var equip_data: EquipmentData = item
	var slot = equip_data.slot
	
	if slot == Enums.EquipmentSlot.NONE:
		push_warning("Item has no equipment slot")
		return null
	
	# Remove from inventory if specified, with bounds check
	if from_inventory_slot >= 0:
		if from_inventory_slot < 0 or from_inventory_slot >= inventory_size:
			push_warning("equip_item: Invalid inventory slot %d" % from_inventory_slot)
		else:
			remove_item(from_inventory_slot)
	
	# Unequip current item
	var old_item = unequip_slot(slot)
	
	# Equip new item
	equipment[slot] = equip_data
	
	# Apply stats
	if stats_component:
		equip_data.apply_to_stats(stats_component)
	
	equipment_changed.emit(slot)
	return old_item


func unequip_slot(slot: Enums.EquipmentSlot) -> ItemData:
	## Unequips item from slot and returns it
	var item = equipment.get(slot)
	if item == null:
		return null
	
	# Remove stats
	if stats_component and item is EquipmentData:
		item.remove_from_stats(stats_component)
	
	equipment[slot] = null
	equipment_changed.emit(slot)
	return item


func unequip_to_inventory(slot: Enums.EquipmentSlot) -> bool:
	## Unequips to inventory. Returns false if inventory is full.
	if is_full():
		return false
	
	var item = unequip_slot(slot)
	if item:
		add_item(item)
		return true
	return false


func get_equipped(slot: Enums.EquipmentSlot) -> ItemData:
	return equipment.get(slot)


func is_slot_equipped(slot: Enums.EquipmentSlot) -> bool:
	return equipment.get(slot) != null

# =============================================================================
# ITEM USE
# =============================================================================

func use_item(slot: int) -> bool:
	# Validate slot bounds
	if slot < 0 or slot >= inventory_size:
		push_warning("use_item: Invalid slot %d (inventory size: %d)" % [slot, inventory_size])
		return false
	
	var item = get_item(slot)
	if item == null:
		return false
	
	# Validate item state
	if not is_instance_valid(item):
		push_warning("use_item: Item at slot %d is no longer valid" % slot)
		inventory[slot] = null  # Clean up stale reference
		return false
	
	if not item.can_use():
		return false
	
	if item.use(owner_node):
		item_used.emit(item)
		
		# Remove consumable with bounds check
		if item.stackable and item.stack_count > 1:
			item.stack_count -= 1
			inventory_changed.emit()
		else:
			remove_item(slot)
		
		return true
	
	return false

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	var inv_data = []
	for item in inventory:
		if item:
			inv_data.append({
				"id": item.item_id,
				"stack": item.stack_count if item.stackable else 1
			})
		else:
			inv_data.append(null)
	
	var equip_data = {}
	for slot in equipment.keys():
		if equipment[slot]:
			equip_data[slot] = equipment[slot].item_id
	
	return {
		"inventory": inv_data,
		"equipment": equip_data
	}


func load_save_data(data: Dictionary, item_database: Dictionary) -> void:
	## item_database maps item_id to ItemData resource
	
	# Load inventory
	if data.has("inventory"):
		for i in range(mini(data.inventory.size(), inventory_size)):
			if data.inventory[i]:
				var item_id = data.inventory[i].id
				if item_database.has(item_id):
					var item = item_database[item_id].duplicate_item()
					if item.stackable:
						item.stack_count = data.inventory[i].get("stack", 1)
					inventory[i] = item
	
	# Load equipment
	if data.has("equipment"):
		for slot_str in data.equipment.keys():
			var slot = int(slot_str)
			var item_id = data.equipment[slot_str]
			if item_database.has(item_id):
				var item = item_database[item_id].duplicate_item()
				equip_item(item)
