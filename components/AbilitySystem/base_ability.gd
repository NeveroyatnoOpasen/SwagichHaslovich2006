# Base class for all abilities
# Extend this class to create custom abilities
extends Node
class_name BaseAbility

# Ability signals
signal ability_used(ability_name: String)
signal ability_cooldown_started(ability_name: String, cooldown: float)
signal ability_ready(ability_name: String)

# Ability properties
@export_group("Ability Info")
@export var ability_name: String = "Base Ability"
@export_multiline var description: String = "Base ability description"
@export var icon: Texture2D  # For UI display

@export_group("Ability Properties")
@export var cooldown: float = 1.0
@export var cost: float = 0.0  # Mana/Energy/Resource cost
@export var can_use_in_air: bool = true
@export var stops_movement: bool = false

# Internal state
var is_on_cooldown: bool = false
var cooldown_timer: float = 0.0
var owner_entity: CharacterBody3D  # Player or enemy using this ability

func _ready() -> void:
	# Abilities should not process by default
	set_process(false)

func _process(delta: float) -> void:
	# Handle cooldown
	if is_on_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			_cooldown_finished()

# ============================================================================
# PUBLIC API - Override these in child classes
# ============================================================================

# Called when ability is activated - OVERRIDE THIS
func activate(owner: CharacterBody3D) -> bool:
	if not can_use():
		return false

	owner_entity = owner
	_start_cooldown()
	ability_used.emit(ability_name)

	# Child classes should override and call super.activate() first
	return true

# Check if ability can be used - OVERRIDE to add custom conditions
func can_use() -> bool:
	if is_on_cooldown:
		print("  - Can't use: ON COOLDOWN (", cooldown_timer, "s remaining)")
		return false

	# Check if owner is on floor (if required)
	if not can_use_in_air and owner_entity and not owner_entity.is_on_floor():
		print("  - Can't use: NOT ON FLOOR (can_use_in_air=", can_use_in_air, ")")
		return false

	print("  - Can use: OK")
	return true

# Get current cooldown remaining (0.0 if ready)
func get_cooldown_remaining() -> float:
	return cooldown_timer if is_on_cooldown else 0.0

# Get cooldown percentage (0.0 = ready, 1.0 = just used)
func get_cooldown_percent() -> float:
	if not is_on_cooldown:
		return 0.0
	return cooldown_timer / cooldown

# ============================================================================
# INTERNAL METHODS
# ============================================================================

func _start_cooldown() -> void:
	is_on_cooldown = true
	cooldown_timer = cooldown
	ability_cooldown_started.emit(ability_name, cooldown)
	set_process(true)

func _cooldown_finished() -> void:
	is_on_cooldown = false
	cooldown_timer = 0.0
	ability_ready.emit(ability_name)
	set_process(false)

# Reset cooldown (useful for roguelike powerups)
func reset_cooldown() -> void:
	_cooldown_finished()

# Reduce cooldown by amount (useful for roguelike effects)
func reduce_cooldown(amount: float) -> void:
	if is_on_cooldown:
		cooldown_timer = max(0.0, cooldown_timer - amount)
		if cooldown_timer <= 0.0:
			_cooldown_finished()
