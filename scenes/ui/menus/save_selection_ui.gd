## SaveSelectionUI - UI for selecting or creating save slots
extends Control

signal save_selected(slot_id: String)
signal new_save_requested()
signal cancelled()

@onready var save_list: ItemList = $Panel/VBox/SaveList
@onready var load_button: Button = $Panel/VBox/BtnHBox/LoadButton
@onready var new_button: Button = $Panel/VBox/BtnHBox/NewButton
@onready var delete_button: Button = $Panel/VBox/BtnHBox/DeleteButton
@onready var cancel_button: Button = $Panel/VBox/BtnHBox/CancelButton

var _slots: Array[Dictionary] = []

func _ready() -> void:
	load_button.pressed.connect(_on_load_pressed)
	new_button.pressed.connect(_on_new_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	save_list.item_selected.connect(_on_item_selected)
	
	load_button.disabled = true
	delete_button.disabled = true

func refresh() -> void:
	save_list.clear()
	_slots = SaveManager.get_save_slots()
	
	for slot in _slots:
		var time_str = Time.get_datetime_string_from_unix_time(slot.timestamp, true)
		var text = "%s (Lv.%d) - %s" % [slot.name, slot.level, time_str]
		save_list.add_item(text)
	
	load_button.disabled = true
	delete_button.disabled = true

func _on_item_selected(_index: int) -> void:
	load_button.disabled = false
	delete_button.disabled = false

func _on_load_pressed() -> void:
	var selected = save_list.get_selected_items()
	if selected.size() > 0:
		var slot_id = _slots[selected[0]].id
		save_selected.emit(slot_id)

func _on_new_pressed() -> void:
	new_save_requested.emit()

func _on_delete_pressed() -> void:
	var selected = save_list.get_selected_items()
	if selected.size() > 0:
		var slot_id = _slots[selected[0]].id
		SaveManager.delete_save(slot_id)
		refresh()

func _on_cancel_pressed() -> void:
	cancelled.emit()
