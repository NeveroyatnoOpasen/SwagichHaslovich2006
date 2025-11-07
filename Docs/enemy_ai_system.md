# Enemy AI System Documentation

## Overview

The enemy AI uses a state machine architecture with vision detection, navigation, and smart combat behavior.

## AI States

### 1. **IDLE**
- Enemy stands in place, slowly rotating
- Transitions to CHASE if player is spotted
- Transitions to PATROL if patrol points are configured

### 2. **PATROL**
- Moves between predefined patrol points
- Waits at each point for `patrol_wait_time` seconds
- Transitions to CHASE when player is spotted
- Falls back to IDLE if no patrol points exist

### 3. **ALERT**
- Moves to last known player position
- Looks around for player
- Transitions to CHASE if player is spotted again
- Returns to IDLE after `lose_sight_time` seconds

### 4. **CHASE**
- Actively pursues the player using NavigationAgent3D
- Requires line-of-sight to continue
- Transitions to ATTACK when within `attack_range`
- Transitions to ALERT if player is lost for `lose_sight_time` seconds

### 5. **ATTACK**
- Maintains optimal distance between `min_attack_range` and `attack_range`
- Backs away if too close, approaches if too far
- Attacks every `attack_cooldown` seconds
- Returns to CHASE if player moves too far away

### 6. **RETREAT**
- Enemy runs away from player
- Activated when health drops below `retreat_health_percent`
- Returns to CHASE when health recovers slightly

## Vision System

The enemy uses a three-part detection system:

### 1. Distance Check
- `vision_range` (default: 15.0) - Maximum distance enemy can see

### 2. Angle Check
- `vision_angle` (default: 90°) - Field of view cone
- Enemy can only see targets in front of them

### 3. Line of Sight (Raycast)
- Uses `VisionRay` RayCast3D node
- Checks for obstacles between enemy and player
- Player can hide behind walls/objects

### 4. Detection Area
- Sphere collision area (`detection_radius`: 20.0)
- Alerts enemy when player enters, even if not visible
- Represents "hearing" or sensing player nearby

## Parameters

All parameters are exported and can be adjusted in the Godot Inspector:

### Movement Speed
- `idle_speed`: 0.0 - Speed when idle (stationary)
- `patrol_speed`: 2.0 - Speed during patrol
- `chase_speed`: 5.0 - Speed when chasing player
- `attack_speed`: 1.0 - Speed during combat

### AI Behavior
- `vision_range`: 15.0 - How far enemy can see
- `vision_angle`: 90.0 - Field of view in degrees
- `detection_radius`: 20.0 - Radius of detection sphere
- `attack_range`: 2.5 - Distance to start attacking
- `min_attack_range`: 1.5 - Minimum distance (enemy backs away if closer)
- `retreat_health_percent`: 0.25 (25%) - HP threshold for retreat
- `lose_sight_time`: 5.0 - Seconds before giving up on player
- `attack_cooldown`: 2.0 - Seconds between attacks

### Patrol
- `patrol_points`: Array[Vector3] - List of patrol waypoints
- `patrol_wait_time`: 2.0 - Seconds to wait at each point

## Scene Structure

Enemy scene must include:

```
Enemy (CharacterBody3D)
├── CollisionShape3D
├── MeshInstance3D
├── health_component (HealthComponent)
├── HurtboxComponent (Area3D)
├── NavigationAgent3D
├── AnimationPlayer
├── MeleeWeaponComponent (Node3D)
│   └── HitboxComponent (Area3D)
├── VisionRay (RayCast3D)           # Required for vision
└── DetectionArea (Area3D)          # Required for detection
    └── CollisionShape3D (Sphere)
```

## Setting Up Patrol Routes

In the Godot Inspector:

1. Select the Enemy node
2. Expand "Patrol" section
3. Set `patrol_points` array size (e.g., 3)
4. For each element, enter a Vector3 position:
   - Vector3(10, 0, 0)
   - Vector3(10, 0, 10)
   - Vector3(0, 0, 10)

The enemy will cycle through these points continuously.

## Combat Behavior

1. **Approach Phase**: Enemy chases until within `attack_range`
2. **Distance Management**:
   - Too close (< `min_attack_range`): backs away
   - Too far (> `attack_range`): approaches
   - Optimal range: stays in place
3. **Attack Execution**:
   - Plays "Melee_atack" animation
   - Triggers MeleeWeaponComponent heavy attack
   - Waits for `attack_cooldown` before next attack

## Reaction to Damage

When enemy takes damage:
- **In IDLE/PATROL**: Immediately switches to CHASE (becomes aggressive)
- **In ATTACK**: Attack is interrupted
- **Below retreat threshold**: Switches to RETREAT state
- Visual feedback: white flash effect

## Tips for Balancing

### Making Enemy More Aggressive
- Increase `vision_range` and `vision_angle`
- Increase `detection_radius`
- Decrease `lose_sight_time`
- Decrease `attack_cooldown`

### Making Enemy Less Aggressive
- Decrease `vision_range` and `vision_angle`
- Increase `attack_cooldown`
- Increase `retreat_health_percent`

### Smarter Patrol
- Add more patrol points
- Increase `patrol_wait_time` for cautious behavior
- Place patrol points near choke points

### Better Combat
- Adjust `min_attack_range` and `attack_range` for weapon reach
- Match `attack_cooldown` to animation duration
- Tune `attack_speed` for smooth positioning

## Debugging

Enable debug output in console:
- State transitions are printed: "Enemy state: IDLE -> CHASE"
- Attack execution: "Enemy attacking!"
- Health changes: "Здоровье врага: 50/50"

To visualize detection areas in editor:
- Debug → Visible Collision Shapes
- You'll see the DetectionArea sphere and VisionRay direction

## Advanced: Custom States

To add new states:

1. Add to enum in enemy.gd:
```gdscript
enum State {
    IDLE,
    PATROL,
    ALERT,
    CHASE,
    ATTACK,
    RETREAT,
    YOUR_NEW_STATE  # Add here
}
```

2. Add state handler function:
```gdscript
func _state_your_new_state(delta: float) -> void:
    # Your logic here
    pass
```

3. Add to state machine in `update_state()`:
```gdscript
State.YOUR_NEW_STATE:
    _state_your_new_state(delta)
```

4. Add transition logic in appropriate states
