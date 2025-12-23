## ShopUI - Shop interface for buying and selling items
## Displays shop stock, player inventory, and buyback
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal closed()

# =============================================================================
# PROPERTIES
# =============================================================================

var _shop: ShopData = null
var _is_open: bool = false
var _current_tab: int = 0  ## 0 = Buy, 1 = Sell, 2 = Buyback
var _selected_index: int = -1
var _inventory_system: Node = null

# UI Components
var _main_panel: PanelContainer
var _shop_name_label: Label
var _gold_label: Label
var _tab_container: TabContainer
var _buy_grid: GridContainer
var _sell_grid: GridContainer
var _buyback_grid: GridContainer
var _item_slots: Dictionary = {}  ## tab_index -> Array[ItemSlot]
var _tooltip: ItemTooltip
var _details_panel: PanelContainer
var _item_name_label: Label
var _item_price_label: Label
var _item_description: RichTextLabel
var _quantity_spinbox: SpinBox
var _action_button: Button

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_create_ui()
	_create_tooltip()
	hide()
	
	SaveManager.gold_changed.connect(_on_gold_changed)


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	
	if event.is_action_pressed("pause") or event.is_action_pressed("inventory"):
		close()
		get_viewport().set_input_as_handled()

# =============================================================================
# UI CREATION
# =============================================================================

func _create_ui() -> void:
	# Background dimmer
	var dimmer = ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	
	# Main container
	var main_container = HBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_container.add_theme_constant_override("separation", 16)
	add_child(main_container)
	
	# Shop panel (left)
	_create_shop_panel(main_container)
	
	# Details panel (right)
	_create_details_panel(main_container)


func _create_shop_panel(parent: Control) -> void:
	_main_panel = PanelContainer.new()
	_main_panel.name = "ShopPanel"
	_main_panel.custom_minimum_size = Vector2(500, 500)
	_apply_panel_style(_main_panel)
	parent.add_child(_main_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_main_panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	_shop_name_label = Label.new()
	_shop_name_label.text = "Shop"
	_shop_name_label.add_theme_font_size_override("font_size", 20)
	header.add_child(_shop_name_label)
	
	header.add_child(Control.new())
	header.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 16)
	_gold_label.add_theme_color_override("font_color", Color.GOLD)
	header.add_child(_gold_label)
	
	var close_button = Button.new()
	close_button.text = "X"
	close_button.pressed.connect(close)
	header.add_child(close_button)
	
	# Tab container
	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.tab_changed.connect(_on_tab_changed)
	vbox.add_child(_tab_container)
	
	# Buy tab
	var buy_scroll = ScrollContainer.new()
	buy_scroll.name = "Buy"
	_tab_container.add_child(buy_scroll)
	
	_buy_grid = GridContainer.new()
	_buy_grid.columns = 6
	_buy_grid.add_theme_constant_override("h_separation", 4)
	_buy_grid.add_theme_constant_override("v_separation", 4)
	buy_scroll.add_child(_buy_grid)
	
	# Sell tab (player inventory)
	var sell_scroll = ScrollContainer.new()
	sell_scroll.name = "Sell"
	_tab_container.add_child(sell_scroll)
	
	_sell_grid = GridContainer.new()
	_sell_grid.columns = 6
	_sell_grid.add_theme_constant_override("h_separation", 4)
	_sell_grid.add_theme_constant_override("v_separation", 4)
	sell_scroll.add_child(_sell_grid)
	
	# Buyback tab
	var buyback_scroll = ScrollContainer.new()
	buyback_scroll.name = "Buyback"
	_tab_container.add_child(buyback_scroll)
	
	_buyback_grid = GridContainer.new()
	_buyback_grid.columns = 6
	_buyback_grid.add_theme_constant_override("h_separation", 4)
	_buyback_grid.add_theme_constant_override("v_separation", 4)
	buyback_scroll.add_child(_buyback_grid)
	
	_item_slots = {0: [], 1: [], 2: []}


func _create_details_panel(parent: Control) -> void:
	_details_panel = PanelContainer.new()
	_details_panel.name = "DetailsPanel"
	_details_panel.custom_minimum_size = Vector2(250, 500)
	_apply_panel_style(_details_panel)
	parent.add_child(_details_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_details_panel.add_child(vbox)
	
	# Item name
	_item_name_label = Label.new()
	_item_name_label.add_theme_font_size_override("font_size", 18)
	_item_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_item_name_label)
	
	# Price
	_item_price_label = Label.new()
	_item_price_label.add_theme_font_size_override("font_size", 16)
	_item_price_label.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(_item_price_label)
	
	vbox.add_child(HSeparator.new())
	
	# Description
	_item_description = RichTextLabel.new()
	_item_description.bbcode_enabled = true
	_item_description.fit_content = true
	_item_description.scroll_active = false
	_item_description.custom_minimum_size = Vector2(0, 100)
	vbox.add_child(_item_description)
	
	# Spacer
	vbox.add_child(Control.new())
	vbox.get_child(vbox.get_child_count() - 1).size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Quantity
	var qty_row = HBoxContainer.new()
	qty_row.add_theme_constant_override("separation", 8)
	vbox.add_child(qty_row)
	
	var qty_label = Label.new()
	qty_label.text = "Quantity:"
	qty_row.add_child(qty_label)
	
	_quantity_spinbox = SpinBox.new()
	_quantity_spinbox.min_value = 1
	_quantity_spinbox.max_value = 99
	_quantity_spinbox.value = 1
	_quantity_spinbox.value_changed.connect(_on_quantity_changed)
	qty_row.add_child(_quantity_spinbox)
	
	# Action button
	_action_button = Button.new()
	_action_button.text = "Buy"
	_action_button.custom_minimum_size = Vector2(0, 40)
	_action_button.pressed.connect(_on_action_pressed)
	vbox.add_child(_action_button)


func _create_tooltip() -> void:
	_tooltip = ItemTooltip.new()
	_tooltip.name = "ItemTooltip"
	add_child(_tooltip)


func _apply_panel_style(panel: PanelContainer) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.35)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

# =============================================================================
# PUBLIC METHODS
# =============================================================================

func open(shop: ShopData) -> void:
	_shop = shop
	_is_open = true
	_selected_index = -1
	
	# Try to get inventory system from player
	var player = _get_local_player()
	if player:
		_inventory_system = player.get_node_or_null("InventorySystem")
	
	_refresh_display()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	_is_open = false
	_shop = null
	_tooltip.hide_tooltip()
	hide()
	closed.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_open() -> bool:
	return _is_open


func _exit_tree() -> void:
	"""Disconnect all signals before tree exit to prevent memory leaks"""
	_disconnect_all_signals()


func _disconnect_all_signals() -> void:
	"""Disconnect all ItemSlot signals and SaveManager signals to prevent memory leaks"""
	# Disconnect SaveManager signals
	if SaveManager.gold_changed.is_connected(_on_gold_changed):
		SaveManager.gold_changed.disconnect(_on_gold_changed)
	
	# Disconnect item slots from all tabs
	for tab_slots in _item_slots.values():
		if tab_slots is Array:
			for slot in tab_slots:
				pass  # TODO: Implement slot disconnection logic

	
	_item_slots.clear()

# =============================================================================
# DISPLAY REFRESH
# =============================================================================

func _refresh_display() -> void:
	if _shop == null:
		return
	
	_shop_name_label.text = _shop.shop_name
	_gold_label.text = "%d Gold" % SaveManager.get_gold()
	
	_refresh_buy_tab()
	_refresh_sell_tab()
	_refresh_buyback_tab()
	_clear_details()


func _refresh_buy_tab() -> void:
	_clear_grid(_buy_grid, 0)
	
	var stock = _shop.get_stock()
	for i in range(stock.size()):
		var entry = stock[i]
		var slot = _create_slot(entry.item, entry.quantity, i, 0)
		_buy_grid.add_child(slot)
		_item_slots[0].append(slot)


func _refresh_sell_tab() -> void:
	_clear_grid(_sell_grid, 1)
	
	if _inventory_system == null:
		return
	
	for i in range(Constants.INVENTORY_SIZE):
		var item_entry = _inventory_system.get_item(i)
		if item_entry and item_entry.has("item"):
			var slot = _create_slot(item_entry.item, item_entry.get("quantity", 1), i, 1)
			_sell_grid.add_child(slot)
			_item_slots[1].append(slot)


func _refresh_buyback_tab() -> void:
	_clear_grid(_buyback_grid, 2)
	
	var buyback = _shop.get_buyback()
	for i in range(buyback.size()):
		var entry = buyback[i]
		var slot = _create_slot(entry.item, entry.quantity, i, 2)
		_buyback_grid.add_child(slot)
		_item_slots[2].append(slot)


func _clear_grid(grid: GridContainer, tab_index: int) -> void:
	for child in grid.get_children():
		child.queue_free()
	_item_slots[tab_index].clear()


func _create_slot(item: ItemData, quantity: int, index: int, tab: int) -> ItemSlot:
	var slot = ItemSlot.new()
	slot.slot_index = index
	slot.set_item(item, quantity)
	slot.slot_clicked.connect(_on_slot_clicked.bind(tab))
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	return slot

# =============================================================================
# DETAILS PANEL
# =============================================================================

func _update_details() -> void:
	if _selected_index < 0:
		_clear_details()
		return
	
	# Safety check - ensure UI is initialized
	if not _item_name_label:
		return
	
	var item: ItemData = null
	var price: int = 0
	var max_qty: int = 1
	
	match _current_tab:
		0:  # Buy
			var stock = _shop.get_stock()
			if _selected_index < stock.size():
				var entry = stock[_selected_index]
				item = entry.item
				price = entry.price
				max_qty = entry.quantity
		1:  # Sell
			if _inventory_system:
				var entry = _inventory_system.get_item(_selected_index)
				if entry and entry.has("item"):
					item = entry.item
					price = _shop.get_sell_price(item)
					max_qty = entry.get("quantity", 1)
		2:  # Buyback
			var buyback = _shop.get_buyback()
			if _selected_index < buyback.size():
				var entry = buyback[_selected_index]
				item = entry.item
				price = entry.price
				max_qty = entry.quantity
	
	if item == null:
		_clear_details()
		return
	
	# Update display
	_item_name_label.text = item.item_name
	_item_name_label.add_theme_color_override("font_color", item.get_rarity_color())
	
	var action_text = "Sell" if _current_tab == 1 else "Buy"
	if _item_price_label:
		_item_price_label.text = "%s: %d Gold" % [action_text, price]
	
	# Check affordability for buy tabs
	if _current_tab != 1:
		var can_afford = SaveManager.has_gold(price)
		if _item_price_label:
			_item_price_label.add_theme_color_override("font_color", Color.GOLD if can_afford else Color.RED)
		if _action_button:
			_action_button.disabled = not can_afford
	else:
		if _item_price_label:
			_item_price_label.add_theme_color_override("font_color", Color.GOLD)
		if _action_button:
			_action_button.disabled = false
	
	if _item_description:
		_item_description.text = item.get_tooltip()
	
	if _quantity_spinbox:
		_quantity_spinbox.max_value = max_qty
		_quantity_spinbox.value = min(_quantity_spinbox.value, max_qty)
	
	if _action_button:
		_action_button.text = action_text


func _clear_details() -> void:
	if not _item_name_label:
		return
	_item_name_label.text = "Select an item"
	_item_name_label.add_theme_color_override("font_color", Color.WHITE)
	if _item_price_label:
		_item_price_label.text = ""
	if _item_description:
		_item_description.text = ""
	if _quantity_spinbox:
		_quantity_spinbox.value = 1
	if _action_button:
		_action_button.disabled = true

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_tab_changed(tab: int) -> void:
	_current_tab = tab
	_selected_index = -1
	_clear_details()


func _on_slot_clicked(slot: ItemSlot, _button: int, tab: int) -> void:
	_current_tab = tab
	_selected_index = slot.slot_index
	_update_details()


func _on_slot_hovered(slot: ItemSlot) -> void:
	if slot.item:
		_tooltip.show_item(slot.item)


func _on_slot_unhovered(_slot: ItemSlot) -> void:
	_tooltip.hide_tooltip()


func _on_quantity_changed(_value: float) -> void:
	_update_details()


func _on_action_pressed() -> void:
	if _selected_index < 0:
		return
	
	var quantity = int(_quantity_spinbox.value)
	var success = false
	
	match _current_tab:
		0:  # Buy
			success = ShopManager.buy_item(_selected_index, quantity)
			if success:
				# Add to player inventory
				var stock = _shop.get_stock()
				if _selected_index < stock.size():
					var item = stock[_selected_index].item
					if _inventory_system:
						for i in range(quantity):
							_inventory_system.add_item(item)
		1:  # Sell
			if _inventory_system:
				var entry = _inventory_system.get_item(_selected_index)
				if entry and entry.has("item"):
					success = ShopManager.sell_item(entry.item, quantity)
					if success:
						_inventory_system.remove_item(_selected_index, quantity)
		2:  # Buyback
			success = ShopManager.buyback_item(_selected_index, quantity)
			if success:
				var buyback = _shop.get_buyback()
				if _selected_index < buyback.size():
					var item = buyback[_selected_index].item
					if _inventory_system:
						for i in range(quantity):
							_inventory_system.add_item(item)
	
	if success:
		_refresh_display()
		_selected_index = -1


func _on_gold_changed(_new_amount: int, _delta: int) -> void:
	if _is_open:
		_gold_label.text = "%d Gold" % SaveManager.get_gold()
		_update_details()

# =============================================================================
# HELPERS
# =============================================================================

func _get_local_player() -> Node:
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("is_local_player") and player.is_local_player:
			return player
	return null
