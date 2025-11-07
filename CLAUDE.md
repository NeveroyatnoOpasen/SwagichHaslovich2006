# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a 3D first-person game project built in **Godot 4.5** using GDScript. The game combines elements of roguelike, souls-like, and immersive sim genres with a narrative focus. The project name is "Hasl" (internally called "swag" in project.godot).

**Main scene**: `levels/World.tscn`
**Engine version**: Godot 4.5

## Running and Testing

This is a Godot Engine project. Development is done through the Godot Editor:
- Open the project in Godot 4.5 or later
- Press F5 to run the game
- Press F6 to run the current scene

**Git integration**: The project uses the GitPlugin addon for version control within Godot.

## Project Architecture

### Folder Structure

The project uses a color-coded folder organization system (defined in project.godot):
- **`components/`** (blue) - Reusable component systems
- **`entity/`** (red) - Game entities (player, enemies, interactive objects)
- **`levels/`** (green) - Game levels and scenes
- **`miscelanius/`** (pink) - Miscellaneous scripts and utilities
- **`addons/`** - Godot plugins (proto-csgs for prototyping, godot-git-plugin)

### Component-Based Architecture

The project uses a component-based architecture where functionality is modular and reusable:

#### Health System (`components/HealthComponent/`)
- **`HealthComponent`** - Node-based component that manages health, damage, and healing
- Signals: `health_changed(current_health, max_health, damaged)`, `health_depleted()`
- Automatically destroys parent entity when health depletes (calls `queue_free()`)

#### Combat System (`components/CombatComponents/`)

A comprehensive melee combat system with 4 main components (documented in Russian in `components/CombatComponents/README.md`):

1. **`HitboxComponent`** (Area3D) - Active attack detection
   - Collision layer: 2, Mask: 4
   - Prevents multiple hits on same target
   - Attached to weapons

2. **`HurtboxComponent`** (Area3D) - Passive damage reception
   - Collision layer: 4, Mask: 2
   - Integrates with HealthComponent
   - Supports damage multipliers
   - Signal: `hit_received(damage, knockback_force, attacker_position)`

3. **`MeleeWeaponComponent`** (Node3D) - Weapon management
   - Two attack types: LIGHT and HEAVY
   - Configurable damage, knockback, duration, and cooldowns
   - Controls hitbox activation/deactivation timing
   - Signals: `hit_landed(target)`, `attack_ended()`

4. **`CombatComponent`** (Node) - Combat coordination
   - Handles attack input processing
   - Combo system (configurable max combo count and window)
   - Attack restrictions (air attacks, movement stopping)
   - Integrates with CharacterBody3D
   - Signals: `attack_performed(attack_type)`, `combo_started(combo_index)`, `combo_reset()`

**Attack workflow**: Player/Enemy input → CombatComponent → MeleeWeaponComponent → HitboxComponent detects collision → HurtboxComponent receives hit → HealthComponent applies damage

#### Interaction System (`components/Interaction Array/`)
- **`interact_ray`** (RayCast3D) - Raycasting system for world interaction
- Detects objects implementing the `Interactable` class
- Displays prompt messages via attached Label
- See `interaction_system.md` for details

### Entity Structure

#### Player (`entity/player/player.gd`)
- Extends CharacterBody3D
- First-person controller with mouse look (captured cursor)
- Features:
  - WASD movement with configurable speed
  - Jump mechanics
  - Camera tilt on strafe movement
  - Pitch/yaw rotation system (Pivot node for camera)
  - Integrated combat system (CombatComponent)
  - Health system (HealthComponent)
  - Interaction system (InteractRay)
- Movement can be blocked during attacks if `stop_movement_on_attack` is enabled
- Node hierarchy: Player → Pivot → Camera3D
- Combat integrated via player.gd lines 52-59

#### Enemy (`entity/enemy/enemy.gd`)
- Extends CharacterBody3D
- **Advanced AI State Machine** with 6 states: IDLE, PATROL, ALERT, CHASE, ATTACK, RETREAT
- **Vision System**: Line-of-sight detection using RayCast3D with configurable range and angle
- **Detection Area**: Sphere collision for proximity detection ("hearing")
- NavigationAgent3D-based pathfinding
- Integrates HealthComponent, HurtboxComponent, and MeleeWeaponComponent
- Key Features:
  - **Smart Chase**: Only pursues player when detected via vision or proximity
  - **Patrol Routes**: Configurable patrol points with wait times
  - **Combat AI**: Maintains optimal attack distance, manages cooldowns
  - **Retreat Behavior**: Flees when health is low
  - **Alert State**: Investigates last known player position
  - Visual feedback: white flash on hit, red normal color
  - Knockback physics and attack interruption on damage
- Required child nodes: VisionRay (RayCast3D), DetectionArea (Area3D with SphereShape3D)
- **Detailed documentation**: See `Docs/enemy_ai_system.md` for full AI behavior explanation
- Uses global group "Player" to find player reference

### Global Groups
Defined in project.godot:
- **`DynamicObject`** - For physics-based interactive objects
- **`Player`** - For player identification (enemy AI uses this)

### Input Actions
Configured in project.godot:
- `move_forward` - W
- `move_backward` - S
- `move_left` - A
- `move_right` - D
- `jump` - Space
- `use` - E (interaction)
- `attack` - Left Mouse Button (light attack)
- `heavy_attack` - Right Mouse Button (heavy attack)

## Coding Patterns

### Component Integration Pattern
Components are typically added as child nodes and referenced via `@onready`:
```gdscript
@onready var health_component: HealthComponent = $health_component
@onready var combat_component: CombatComponent = $CombatComponent
```

Components communicate via signals. Connect in `_ready()`:
```gdscript
if health_component:
    health_component.health_depleted.connect(_on_health_depleted)
```

**For comprehensive signals documentation**, see `Docs/godot_signals_cheatsheet.md`

### Signal-Based Communication
The codebase heavily uses Godot signals for decoupled communication between components. All major components emit signals for state changes.

### Attack System Usage
```gdscript
# Light attack
combat_component.handle_attack_input(MeleeWeaponComponent.AttackType.LIGHT)

# Heavy attack
combat_component.handle_attack_input(MeleeWeaponComponent.AttackType.HEAVY)
```

### Interaction System Pattern
Interactive objects should extend the `Interactable` class and implement:
- `prompt_message` property (displayed to player)
- `use()` method (called when player presses 'use')

## Important Notes

- **Collision layers**: Combat system uses specific layers (Hitbox: layer 2/mask 4, Hurtbox: layer 4/mask 2)
- **Combat system documentation**: Primary documentation is in Russian in `components/CombatComponents/README.md`
- **Enemy AI documentation**: Full state machine and behavior documentation in `Docs/enemy_ai_system.md`
- **Camera structure**: Player camera is child of Pivot node to separate pitch (Pivot.rotation.x) from yaw (Player.rotation.y)
- **Navigation**: Enemy AI uses NavigationAgent3D - ensure navigation meshes are baked in levels
- **Physics**: Default gravity from ProjectSettings is used throughout
- **Component references**: Many components attempt auto-discovery of dependencies in `_ready()` if not manually assigned
- **AI State Machine**: Enemy behavior is controlled via state enum - state transitions are logged to console for debugging
- **Vision System**: Enemy vision requires direct line-of-sight (RayCast3D) and respects field-of-view angle
- **Patrol Routes**: Set patrol points in Inspector as Array[Vector3] - enemy will cycle through them automatically

## Recent Changes (from git log)
- Folders reorganization
- Combat system implementation (melee weapons, hitboxes, hurtboxes)
- World level creation
- Proto-CSG addon added for prototyping
