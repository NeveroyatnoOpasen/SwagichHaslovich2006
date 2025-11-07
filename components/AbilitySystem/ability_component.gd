# Component for managing character abilities
# Attach to Player or Enemy to give them abilities
extends Node
class_name AbilityComponent

# Signals
signal ability_activated(ability_name: String)
signal ability_failed(ability_name: String, reason: String)

# Ability slots - bind these to input actions
# Can be NodePath (from scene) or BaseAbility instance (added at runtime)
@export_group("Ability Slots")
@export var ability_1 = null  # Primary ability (e.g., Shift)
@export var ability_2 = null  # Secondary ability (e.g., R)
@export var ability_3 = null  # Ultimate ability (e.g., Q)
@export var ability_4 = null  # Special ability (e.g., E)

# Input action names
@export_group("Input Bindings")
@export var ability_1_action: String = "ability_1"
@export var ability_2_action: String = "ability_2"
@export var ability_3_action: String = "ability_3"
@export var ability_4_action: String = "ability_4"

# Owner reference
var owner_entity: CharacterBody3D

# All abilities in a dictionary for easy access
var abilities: Dictionary = {}

func _ready() -> void:
	# Get owner entity (parent should be CharacterBody3D)
	owner_entity = get_parent() as CharacterBody3D
	if not owner_entity:
		push_error("AbilityComponent must be child of CharacterBody3D")
		return

	# Resolve NodePaths to actual ability nodes
	if ability_1 is NodePath:
		ability_1 = get_node_or_null(ability_1)
	if ability_2 is NodePath:
		ability_2 = get_node_or_null(ability_2)
	if ability_3 is NodePath:
		ability_3 = get_node_or_null(ability_3)
	if ability_4 is NodePath:
		ability_4 = get_node_or_null(ability_4)

	# Register all assigned abilities
	_register_ability("ability_1", ability_1)
	_register_ability("ability_2", ability_2)
	_register_ability("ability_3", ability_3)
	_register_ability("ability_4", ability_4)

func _process(_delta: float) -> void:
	if not owner_entity:
		return

	# Check input for each ability
	if Input.is_action_just_pressed(ability_1_action):
		print(">>> ABILITY 1 KEY PRESSED (", ability_1_action, ")")
		use_ability("ability_1")

	if Input.is_action_just_pressed(ability_2_action):
		print(">>> ABILITY 2 KEY PRESSED (", ability_2_action, ")")
		use_ability("ability_2")

	if Input.is_action_just_pressed(ability_3_action):
		print(">>> ABILITY 3 KEY PRESSED (", ability_3_action, ")")
		use_ability("ability_3")

	if Input.is_action_just_pressed(ability_4_action):
		print(">>> ABILITY 4 KEY PRESSED (", ability_4_action, ")")
		use_ability("ability_4")

# ============================================================================
# PUBLIC API
# ============================================================================

# Use ability by slot name
func use_ability(slot: String) -> bool:
	if not abilities.has(slot):
		return false

	var ability: BaseAbility = abilities[slot]
	if not ability:
		return false

	if ability.activate(owner_entity):
		ability_activated.emit(ability.ability_name)
		return true
	else:
		ability_failed.emit(ability.ability_name, "Cannot use ability")
		return false

# Add or replace ability in a slot at runtime
func set_ability(slot: String, new_ability: BaseAbility) -> void:
	# Remove old ability if exists
	if abilities.has(slot) and abilities[slot]:
		var old_ability = abilities[slot]
		remove_child(old_ability)
		old_ability.queue_free()

	# Add new ability
	if new_ability:
		add_child(new_ability)
		abilities[slot] = new_ability
		new_ability.owner_entity = owner_entity

		# Connect signals
		if not new_ability.ability_used.is_connected(_on_ability_used):
			new_ability.ability_used.connect(_on_ability_used)

		print("Ability equipped: ", new_ability.ability_name, " in slot ", slot)

# Remove ability from slot
func remove_ability(slot: String) -> void:
	if abilities.has(slot) and abilities[slot]:
		var ability = abilities[slot]
		abilities.erase(slot)
		remove_child(ability)
		ability.queue_free()
		print("Ability removed from slot: ", slot)

# Get ability from slot
func get_ability(slot: String) -> BaseAbility:
	return abilities.get(slot, null)

# Check if ability is ready
func is_ability_ready(slot: String) -> bool:
	if not abilities.has(slot):
		return false
	var ability = abilities[slot]
	return ability and ability.can_use()

# Get cooldown remaining for ability
func get_ability_cooldown(slot: String) -> float:
	if not abilities.has(slot) or not abilities[slot]:
		return 0.0
	return abilities[slot].get_cooldown_remaining()

# Reset all cooldowns (useful for roguelike events)
func reset_all_cooldowns() -> void:
	for ability in abilities.values():
		if ability:
			ability.reset_cooldown()

# ============================================================================
# INTERNAL METHODS
# ============================================================================

func _register_ability(slot: String, ability: BaseAbility) -> void:
	if not ability:
		return

	abilities[slot] = ability
	ability.owner_entity = owner_entity

	# Connect signals
	if not ability.ability_used.is_connected(_on_ability_used):
		ability.ability_used.connect(_on_ability_used)

func _on_ability_used(ability_name: String) -> void:
	print("Used ability: ", ability_name)
