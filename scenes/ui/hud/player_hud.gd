## PlayerHUD - In-game heads-up display
## Shows health, magika, stamina, spell info, and interaction prompts
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var health_bar: ProgressBar = $StatBars/HealthBar/ProgressBar
@onready var health_value: Label = $StatBars/HealthBar/Value
@onready var magika_bar: ProgressBar = $StatBars/MagikaBar/ProgressBar
@onready var magika_value: Label = $StatBars/MagikaBar/Value
@onready var stamina_bar: ProgressBar = $StatBars/StaminaBar/ProgressBar
@onready var stamina_value: Label = $StatBars/StaminaBar/Value

@onready var spell_name: Label = $SpellInfo/SpellName
@onready var cooldown_bar: ProgressBar = $SpellInfo/CooldownBar

@onready var interact_prompt: Label = $InteractPrompt
@onready var crosshair: CenterContainer = $Crosshair

# =============================================================================
# PROPERTIES
# =============================================================================

var player
var stats
var spell_caster

var _current_spell

# Gold and XP UI (created dynamically)
var _gold_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _level_label: Label
var _quest_tracker: VBoxContainer
var _active_ability_icon: TextureRect
var _active_ability_cooldown: ProgressBar

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Style the bars
	_setup_bar_colors()
	
	# Create additional HUD elements
	_create_gold_display()
	_create_xp_bar()
	_create_quest_tracker()
	_create_active_ability_display()
	
	# Connect to SaveManager signals
	SaveManager.gold_changed.connect(_on_gold_changed)
	SaveManager.level_up.connect(_on_level_up)
	
	# Connect to QuestManager for tracker
	QuestManager.objective_updated.connect(_on_quest_objective_updated)
	QuestManager.quest_completed.connect(_on_quest_tracker_changed)
	QuestManager.quest_started.connect(_on_quest_tracker_changed)


func _process(delta: float) -> void:
	if stats:
		_update_stat_bars()
	
	# Update spell from player's current weapon
	if player and player.current_weapon:
		var spell = player.get_current_spell()
		if spell != _current_spell:
			set_current_spell(spell)
	
	if spell_caster and _current_spell:
		_update_cooldown()
	
	# Update active ability cooldown
	_update_active_ability_cooldown()

# =============================================================================
# INITIALIZATION
# =============================================================================

func initialize(p) -> void:
	player = p
	stats = player.get_node_or_null("StatsComponent")
	spell_caster = player.get_node_or_null("SpellCaster")
	
	if stats:
		stats.health_changed.connect(_on_health_changed)
		stats.magika_changed.connect(_on_magika_changed)
		stats.stamina_changed.connect(_on_stamina_changed)
		_update_stat_bars()
	
	# Get current spell from player's weapon
	_update_spell_display()

# =============================================================================
# BAR UPDATES
# =============================================================================

func _setup_bar_colors() -> void:
	# Health bar - red
	var health_style = StyleBoxFlat.new()
	health_style.bg_color = Color.DARK_RED
	health_bar.add_theme_stylebox_override("fill", health_style)
	
	# Magika bar - blue
	var magika_style = StyleBoxFlat.new()
	magika_style.bg_color = Color.DARK_BLUE
	magika_bar.add_theme_stylebox_override("fill", magika_style)
	
	# Stamina bar - green
	var stamina_style = StyleBoxFlat.new()
	stamina_style.bg_color = Color.DARK_GREEN
	stamina_bar.add_theme_stylebox_override("fill", stamina_style)


func _update_stat_bars() -> void:
	if stats == null:
		return
	
	# Health
	health_bar.max_value = stats.max_health
	health_bar.value = stats.current_health
	health_value.text = "%d/%d" % [int(stats.current_health), int(stats.max_health)]
	
	# Magika
	magika_bar.max_value = stats.max_magika
	magika_bar.value = stats.current_magika
	magika_value.text = "%d/%d" % [int(stats.current_magika), int(stats.max_magika)]
	
	# Stamina
	stamina_bar.max_value = stats.max_stamina
	stamina_bar.value = stats.current_stamina
	stamina_value.text = "%d/%d" % [int(stats.current_stamina), int(stats.max_stamina)]


func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_value.text = "%d/%d" % [int(current), int(maximum)]
	
	# Flash on low health
	if current / maximum < 0.25:
		_flash_bar(health_bar, Color.RED)


func _on_magika_changed(current: float, maximum: float) -> void:
	magika_bar.max_value = maximum
	magika_bar.value = current
	magika_value.text = "%d/%d" % [int(current), int(maximum)]


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current
	stamina_value.text = "%d/%d" % [int(current), int(maximum)]


func _flash_bar(bar: ProgressBar, color: Color) -> void:
	var tween = create_tween()
	tween.tween_property(bar, "modulate", color, 0.1)
	tween.tween_property(bar, "modulate", Color.WHITE, 0.1)

# =============================================================================
# SPELL INFO
# =============================================================================

func set_current_spell(spell) -> void:
	_current_spell = spell
	if spell:
		spell_name.text = spell.spell_name
		# Show magika cost
		var cost_text = " (%d MP)" % int(spell.get_final_magika_cost())
		spell_name.text += cost_text
	else:
		spell_name.text = ""


func _update_spell_display() -> void:
	if player and player.has_method("get_current_spell"):
		var spell = player.get_current_spell()
		set_current_spell(spell)


func _update_cooldown() -> void:
	if spell_caster == null or _current_spell == null:
		cooldown_bar.value = 100
		return
	
	var remaining = spell_caster.get_cooldown_remaining(_current_spell)
	var total = _current_spell.get_final_cooldown()
	
	if remaining > 0:
		cooldown_bar.value = (1.0 - remaining / total) * 100
	else:
		cooldown_bar.value = 100

# =============================================================================
# INTERACTION
# =============================================================================

func show_interact_prompt(text: String = "[E] Interact") -> void:
	interact_prompt.text = text
	interact_prompt.visible = true


func hide_interact_prompt() -> void:
	interact_prompt.visible = false

# =============================================================================
# CROSSHAIR
# =============================================================================

func set_crosshair_color(color: Color) -> void:
	var dot = crosshair.get_node_or_null("CrosshairDot")
	if dot:
		dot.color = color


func expand_crosshair(amount: float = 1.5) -> void:
	var dot = crosshair.get_node_or_null("CrosshairDot")
	if dot:
		var tween = create_tween()
		tween.tween_property(dot, "custom_minimum_size", Vector2(6, 6), 0.05)
		tween.tween_property(dot, "custom_minimum_size", Vector2(4, 4), 0.1)

# =============================================================================
# GOLD DISPLAY
# =============================================================================

func _create_gold_display() -> void:
	var container = HBoxContainer.new()
	container.name = "GoldDisplay"
	container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	container.offset_left = -150
	container.offset_top = 10
	container.offset_right = -10
	container.add_theme_constant_override("separation", 8)
	add_child(container)
	
	var gold_icon = ColorRect.new()
	gold_icon.custom_minimum_size = Vector2(20, 20)
	gold_icon.color = Color.GOLD
	container.add_child(gold_icon)
	
	_gold_label = Label.new()
	_gold_label.text = "0"
	_gold_label.add_theme_font_size_override("font_size", 18)
	_gold_label.add_theme_color_override("font_color", Color.GOLD)
	_gold_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_gold_label.add_theme_constant_override("shadow_offset_x", 1)
	_gold_label.add_theme_constant_override("shadow_offset_y", 1)
	container.add_child(_gold_label)
	
	_update_gold_display()


func _update_gold_display() -> void:
	if _gold_label:
		_gold_label.text = str(SaveManager.get_gold())


func _on_gold_changed(new_amount: int, delta: int) -> void:
	_update_gold_display()
	
	# Flash gold color based on gain/loss
	if _gold_label:
		var flash_color = Color.GREEN if delta > 0 else Color.RED
		var tween = create_tween()
		tween.tween_property(_gold_label, "modulate", flash_color, 0.1)
		tween.tween_property(_gold_label, "modulate", Color.WHITE, 0.2)

# =============================================================================
# XP BAR
# =============================================================================

func _create_xp_bar() -> void:
	var container = HBoxContainer.new()
	container.name = "XPDisplay"
	container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	container.offset_left = 10
	container.offset_bottom = -10
	container.offset_top = -40
	container.offset_right = 300
	container.add_theme_constant_override("separation", 8)
	add_child(container)
	
	_level_label = Label.new()
	_level_label.text = "Lv.1"
	_level_label.add_theme_font_size_override("font_size", 16)
	_level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	_level_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_level_label.add_theme_constant_override("shadow_offset_x", 1)
	_level_label.add_theme_constant_override("shadow_offset_y", 1)
	container.add_child(_level_label)
	
	var bar_container = VBoxContainer.new()
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_container.add_theme_constant_override("separation", 2)
	container.add_child(bar_container)
	
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(200, 8)
	_xp_bar.show_percentage = false
	_xp_bar.max_value = 100
	_xp_bar.value = 0
	bar_container.add_child(_xp_bar)
	
	# Style XP bar
	var xp_style = StyleBoxFlat.new()
	xp_style.bg_color = Color(0.5, 0.3, 0.8)
	_xp_bar.add_theme_stylebox_override("fill", xp_style)
	
	var xp_bg = StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.15, 0.15, 0.2)
	_xp_bar.add_theme_stylebox_override("background", xp_bg)
	
	_xp_label = Label.new()
	_xp_label.add_theme_font_size_override("font_size", 10)
	_xp_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	bar_container.add_child(_xp_label)
	
	_update_xp_display()


func _update_xp_display() -> void:
	var exp_data = SaveManager.get_exp_progress()
	
	if _level_label:
		_level_label.text = "Lv.%d" % exp_data.level
	
	if _xp_bar:
		_xp_bar.value = exp_data.progress * 100
	
	if _xp_label:
		_xp_label.text = "%d / %d XP" % [exp_data.current, exp_data.needed]


func _on_level_up(new_level: int, skill_points: int) -> void:
	_update_xp_display()
	
	# Show level up notification
	_show_level_up_notification(new_level, skill_points)


func _show_level_up_notification(level: int, skill_points: int) -> void:
	var notification = Label.new()
	notification.text = "LEVEL UP! Level %d\n+%d Skill Points" % [level, skill_points]
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	notification.add_theme_font_size_override("font_size", 32)
	notification.add_theme_color_override("font_color", Color.GOLD)
	notification.add_theme_color_override("font_shadow_color", Color.BLACK)
	notification.add_theme_constant_override("shadow_offset_x", 2)
	notification.add_theme_constant_override("shadow_offset_y", 2)
	notification.modulate = Color(1, 1, 1, 0)
	add_child(notification)
	
	# Animate notification
	var tween = create_tween()
	tween.tween_property(notification, "modulate", Color.WHITE, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(notification, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(notification.queue_free)

# =============================================================================
# QUEST TRACKER
# =============================================================================

func _create_quest_tracker() -> void:
	_quest_tracker = VBoxContainer.new()
	_quest_tracker.name = "QuestTracker"
	_quest_tracker.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_quest_tracker.offset_left = -300
	_quest_tracker.offset_top = 50
	_quest_tracker.offset_right = -10
	_quest_tracker.add_theme_constant_override("separation", 4)
	add_child(_quest_tracker)
	
	_update_quest_tracker()


func _update_quest_tracker() -> void:
	if _quest_tracker == null:
		return
	
	# Clear existing
	for child in _quest_tracker.get_children():
		child.queue_free()
	
	var quest = QuestManager.get_tracked_quest()
	if quest == null:
		return
	
	# Quest name
	var name_label = Label.new()
	name_label.text = quest.quest_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.GOLD if quest.is_main_quest else Color.WHITE)
	name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_quest_tracker.add_child(name_label)
	
	# Show first 3 incomplete objectives
	var shown = 0
	for obj in quest.get_objectives():
		if shown >= 3:
			break
		if obj.is_completed or (obj.is_hidden and not obj.is_revealed):
			continue
		
		var obj_label = Label.new()
		obj_label.text = "- %s: %s" % [obj.description, obj.get_progress_text()]
		obj_label.add_theme_font_size_override("font_size", 12)
		obj_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		obj_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		obj_label.add_theme_constant_override("shadow_offset_x", 1)
		obj_label.add_theme_constant_override("shadow_offset_y", 1)
		obj_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_quest_tracker.add_child(obj_label)
		shown += 1


func _on_quest_objective_updated(_quest, _objective) -> void:
	_update_quest_tracker()


func _on_quest_tracker_changed(_quest) -> void:
	_update_quest_tracker()

# =============================================================================
# ACTIVE ABILITY
# =============================================================================

func _create_active_ability_display() -> void:
	var container = VBoxContainer.new()
	container.name = "ActiveAbility"
	container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	container.offset_left = -80
	container.offset_bottom = -10
	container.offset_top = -90
	container.offset_right = -10
	container.add_theme_constant_override("separation", 4)
	add_child(container)
	
	var label = Label.new()
	label.text = "Ability [F]"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(label)
	
	var icon_container = CenterContainer.new()
	container.add_child(icon_container)
	
	var icon_bg = ColorRect.new()
	icon_bg.custom_minimum_size = Vector2(48, 48)
	icon_bg.color = Color(0.15, 0.15, 0.2, 0.8)
	icon_container.add_child(icon_bg)
	
	_active_ability_icon = TextureRect.new()
	_active_ability_icon.custom_minimum_size = Vector2(40, 40)
	_active_ability_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_active_ability_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_active_ability_icon.position = Vector2(4, 4)
	icon_bg.add_child(_active_ability_icon)
	
	_active_ability_cooldown = ProgressBar.new()
	_active_ability_cooldown.custom_minimum_size = Vector2(48, 6)
	_active_ability_cooldown.show_percentage = false
	_active_ability_cooldown.max_value = 100
	_active_ability_cooldown.value = 100
	container.add_child(_active_ability_cooldown)
	
	# Style cooldown bar
	var cd_style = StyleBoxFlat.new()
	cd_style.bg_color = Color(1.0, 0.6, 0.3)
	_active_ability_cooldown.add_theme_stylebox_override("fill", cd_style)
	
	_update_active_ability_display()


func _update_active_ability_display() -> void:
	var ability = SkillManager.get_active_ability()
	
	if ability == null:
		if _active_ability_icon:
			_active_ability_icon.texture = null
			_active_ability_icon.modulate = Color(0.3, 0.3, 0.3)
		return
	
	if _active_ability_icon:
		_active_ability_icon.texture = ability.icon
		_active_ability_icon.modulate = Color.WHITE


func _update_active_ability_cooldown() -> void:
	if _active_ability_cooldown == null:
		return
	
	var cooldown_percent = SkillManager.get_active_ability_cooldown_percent()
	_active_ability_cooldown.value = (1.0 - cooldown_percent) * 100
	
	# Gray out icon while on cooldown
	if _active_ability_icon and cooldown_percent > 0:
		_active_ability_icon.modulate = Color(0.5, 0.5, 0.5)
	elif _active_ability_icon:
		_active_ability_icon.modulate = Color.WHITE
