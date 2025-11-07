# Godot Signals Cheatsheet

## What Are Signals?

Signals are Godot's implementation of the **observer pattern**. They allow objects to communicate without tight coupling. When something happens in one object, it can "emit" a signal, and any number of other objects can "listen" for that signal and react.

**Think of it like a radio broadcast**: One transmitter (emitter) sends a signal, and multiple receivers (listeners) can tune in and respond.

## Why Use Signals?

✅ **Decoupling**: Objects don't need to know about each other
✅ **Flexibility**: Easy to add/remove listeners
✅ **Clean Code**: Avoids messy parent/child dependencies
✅ **Maintainability**: Changes in one system don't break others

---

## Basic Syntax

### 1. Declaring Signals

```gdscript
# Basic signal (no parameters)
signal button_pressed

# Signal with parameters
signal health_changed(current: float, max: float)

# Signal with typed parameters (Godot 4+)
signal hit_received(damage: float, knockback: float, attacker_pos: Vector3)

# Multiple signals
signal opened
signal closed
signal locked
```

### 2. Emitting Signals

```gdscript
# Emit signal with no parameters
button_pressed.emit()

# Emit signal with parameters
health_changed.emit(50.0, 100.0)

# Emit with all parameters
hit_received.emit(25.0, 5.0, Vector3(10, 0, 5))
```

### 3. Connecting to Signals

#### Method A: In Code (_ready function)

```gdscript
func _ready() -> void:
    # Connect signal to a function
    health_component.health_changed.connect(_on_health_changed)

    # Connect with lambda (inline function)
    button.pressed.connect(func(): print("Button clicked!"))

    # Connect to function in another node
    player.died.connect(game_manager._on_player_died)

# Handler function
func _on_health_changed(current: float, max: float) -> void:
    print("Health: ", current, "/", max)
```

#### Method B: In Godot Editor

1. Select the node with the signal
2. Go to "Node" tab (next to Inspector)
3. Double-click the signal
4. Select target node and method
5. Click "Connect"

---

## Real Examples from This Project

### Example 1: Health System

```gdscript
# In HealthComponent (components/HealthComponent/health_component.gd)

# 1. Declare signals
signal health_changed(current_health: float, max_health: float, damaged: bool)
signal health_depleted()

# 2. Emit signals when something happens
func apply_damage(damage: float) -> void:
    health -= damage
    health_changed.emit(health, max_health, true)  # damaged = true

    if health <= 0:
        health_depleted.emit()

func heal(amount: float) -> void:
    health = min(health + amount, max_health)
    health_changed.emit(health, max_health, false)  # damaged = false
```

```gdscript
# In Enemy (entity/enemy/enemy.gd)

# 3. Connect to signals in _ready()
func _ready() -> void:
    if health_component:
        health_component.health_changed.connect(_on_health_changed)
        health_component.health_depleted.connect(_on_health_depleted)

# 4. Handle the signals
func _on_health_changed(current_health: float, max_health: float, damaged: bool) -> void:
    print("Enemy health: ", current_health, "/", max_health)

    if damaged:
        play_hit_effect()
        # Become aggressive if idle
        if current_state == State.IDLE:
            change_state(State.CHASE)

func _on_health_depleted() -> void:
    print("Enemy died!")
    queue_free()
```

### Example 2: Combat System

```gdscript
# In MeleeWeaponComponent (components/CombatComponents/melee_weapon_component.gd)

signal attack_started(attack_type: AttackType)
signal attack_ended()
signal hit_landed(target: HurtboxComponent)

func _start_attack(attack_type: AttackType) -> void:
    is_attacking = true
	attack_started.emit(attack_type)  # Tell everyone we're attacking

func _end_attack() -> void:
	is_attacking = false
	attack_ended.emit()

func _on_hit_detected(hurtbox: HurtboxComponent) -> void:
	hit_landed.emit(hurtbox)  # Tell everyone we hit something
```

```gdscript
# In Player (entity/player/player.gd)

func _ready() -> void:
	if combat_component:
		combat_component.attack_performed.connect(_on_attack_performed)
		combat_component.combo_started.connect(_on_combo_started)
		combat_component.combo_reset.connect(_on_combo_reset)

func _on_attack_performed(attack_type: MeleeWeaponComponent.AttackType) -> void:
	print("Attack type: ", attack_type)
	# Play animation, sound effects, camera shake, etc.

func _on_combo_started(combo_index: int) -> void:
	print("Combo #", combo_index)
	# Change animation based on combo number
```

### Example 3: Area Detection

```gdscript
# Area3D has built-in signals

func _ready() -> void:
	# DetectionArea signals
	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)

	# HitboxComponent signals
	hitbox.area_entered.connect(_on_area_entered)

func _on_detection_area_entered(body: Node3D) -> void:
	if body == player:
		print("Player detected!")
		change_state(State.ALERT)

func _on_area_entered(area: Area3D) -> void:
	if area is HurtboxComponent:
		print("Hit something!")
```

---

## Common Patterns

### Pattern 1: Chain Reactions

Signals can trigger other signals, creating chains:

```gdscript
# HitboxComponent detects collision
hitbox.area_entered → _on_area_entered()
				   ↓
# Emit custom signal
hit_detected.emit(hurtbox)
				   ↓
# MeleeWeaponComponent forwards it
hit_landed.emit(target)
				   ↓
# CombatComponent does something
_on_hit_landed(target)
```

### Pattern 2: One-to-Many

One signal can notify multiple listeners:

```gdscript
# In player
player.died.emit()
	↓
	├→ UI updates (shows death screen)
	├→ Camera shakes
	├→ Sound plays
	└→ GameManager respawns player
```

### Pattern 3: Component Communication

Components talk through signals without knowing about each other:

```gdscript
# HurtboxComponent
hit_received.emit(damage, knockback, attacker_pos)
	↓
# Enemy script listens and reacts
_on_hit_received(damage, knockback, attacker_pos)
	velocity += knockback_direction * knockback
```

---

## Advanced Techniques

### 1. Disconnecting Signals

```gdscript
# Disconnect when no longer needed
func cleanup() -> void:
	if health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.disconnect(_on_health_changed)
```

### 2. One-Shot Connections

```gdscript
# Godot 4.0+: CONNECT_ONE_SHOT flag
signal_name.connect(handler, CONNECT_ONE_SHOT)

# Alternative: disconnect in handler
func _on_one_time_event() -> void:
	print("This runs once")
	some_signal.disconnect(_on_one_time_event)
```

### 3. Connect with Parameters (Callable.bind)

```gdscript
# Pass extra data to handler
button_1.pressed.connect(_on_button_pressed.bind("Button 1"))
button_2.pressed.connect(_on_button_pressed.bind("Button 2"))

func _on_button_pressed(button_name: String) -> void:
	print(button_name, " was pressed")
```

### 4. Group Signals

```gdscript
# Emit to all nodes in a group
get_tree().call_group("enemies", "take_damage", 50)

# Better: Use signals for flexibility
signal player_ability_used(ability_type: String)

func use_fireball() -> void:
	player_ability_used.emit("fireball")
	# All enemies listening can react differently
```

---

## Best Practices

### ✅ DO

```gdscript
# Use descriptive names
signal health_depleted()  # Good
signal event1()           # Bad

# Type your parameters (Godot 4+)
signal hit(damage: float, position: Vector3)

# Document what signals do
## Emitted when the player completes a level
signal level_completed(level_number: int, score: int)

# Check before emitting if needed
if some_signal.get_connections().size() > 0:
	some_signal.emit()
```

### ❌ DON'T

```gdscript
# Don't emit in _process() every frame
func _process(delta):
	health_changed.emit(health, max_health)  # BAD! Too many emissions

# Don't create circular dependencies
# Node A emits → Node B changes state → emits → Node A changes state → infinite loop

# Don't use signals for everything
# Simple parent-child relationships: just call functions directly
```

---

## Built-in Godot Signals

### Node Signals
- `ready` - Node is ready
- `tree_entered` - Node enters scene tree
- `tree_exiting` - Node is about to exit tree

### Physics Signals
- `body_entered(body)` - Area3D/Area2D
- `body_exited(body)` - Area3D/Area2D
- `area_entered(area)` - Area3D/Area2D
- `area_exited(area)` - Area3D/Area2D

### Input Signals
- `pressed` - Button
- `toggled(button_pressed)` - CheckBox/CheckButton
- `value_changed(value)` - Slider/SpinBox
- `text_changed(new_text)` - LineEdit/TextEdit

### Animation Signals
- `animation_finished(anim_name)` - AnimationPlayer
- `animation_started(anim_name)` - AnimationPlayer

---

## Debugging Signals

### Check Connections

```gdscript
# See what's connected to a signal
var connections = my_signal.get_connections()
for conn in connections:
    print("Connected to: ", conn["callable"])

# Check if specific function is connected
if my_signal.is_connected(_on_my_signal):
    print("Handler is connected")
```

### Debug Prints

```gdscript
func _on_some_signal(param: int) -> void:
    print_debug("Signal received with param: ", param)
    # print_debug shows file and line number
```

### Godot Debugger

- Set breakpoint in signal handler
- Check "Debugger" → "Monitors" to see signal emissions
- Use "Remote" tab to inspect scene tree connections

---

## Quick Reference

| Task | Code |
|------|------|
| **Declare** | `signal my_signal` |
| **Declare with params** | `signal my_signal(param: Type)` |
| **Emit** | `my_signal.emit()` |
| **Emit with params** | `my_signal.emit(value)` |
| **Connect** | `my_signal.connect(_handler)` |
| **Disconnect** | `my_signal.disconnect(_handler)` |
| **Check connection** | `my_signal.is_connected(_handler)` |
| **Get connections** | `my_signal.get_connections()` |
| **One-shot** | `my_signal.connect(_handler, CONNECT_ONE_SHOT)` |

---

## Common Errors & Solutions

### Error: "Signal already connected"
```gdscript
# Check before connecting
if not my_signal.is_connected(_handler):
    my_signal.connect(_handler)
```

### Error: "Invalid call. Nonexistent function"
```gdscript
# Make sure handler function exists and matches parameters
signal my_signal(value: int)
func _on_my_signal(value: int):  # Signature must match!
    pass
```

### Error: Signal never fires
```gdscript
# 1. Check you're actually emitting it
# 2. Check the emitter node exists
# 3. Check connection happened before emission
# 4. Use print() to debug:
print("About to emit signal")
my_signal.emit()
```

---

## Summary

**Signals are powerful for:**
- Component-based architecture ✓
- UI events ✓
- Game events ✓
- State changes ✓
- Decoupled systems ✓

**Remember:**
1. Declare with `signal`
2. Emit with `.emit()`
3. Connect with `.connect()`
4. Handle in a function

Signals make your code flexible, maintainable, and easy to extend!
