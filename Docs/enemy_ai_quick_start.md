# Enemy AI Quick Start Guide

## What Changed

Your enemy now has a **smart AI system** instead of blindly chasing the player!

## New Behaviors

### 1. **Vision-Based Detection** 👁️
- Enemy can only see you if you're in their field of view (90° cone)
- They need direct line-of-sight (you can hide behind walls!)
- Vision range: 15 units

### 2. **State Machine** 🤖
The enemy now has different "moods":

- **IDLE**: Standing around, slowly turning
- **PATROL**: Walking between patrol points (if set up)
- **ALERT**: "I heard something!" - investigating
- **CHASE**: Actively hunting you down
- **ATTACK**: In combat range, attacking
- **RETREAT**: "I'm dying!" - running away

### 3. **Smart Combat** ⚔️
- Maintains distance (won't get too close or too far)
- Attack cooldown (2 seconds between attacks)
- Can be interrupted if hit

## Testing the AI

### Test 1: Stealth Approach
1. Run the game
2. Approach enemy from behind slowly
3. **Expected**: Enemy stays in IDLE/PATROL, doesn't notice you
4. Walk into their vision cone
5. **Expected**: Enemy spots you, transitions to CHASE

### Test 2: Line of Sight
1. Get enemy to chase you
2. Run behind a wall/object
3. **Expected**: After 5 seconds, enemy goes to ALERT state
4. Goes to your last known position and looks around
5. Eventually returns to IDLE

### Test 3: Combat
1. Let enemy spot you
2. Let them get close
3. **Expected**:
   - Enemy switches to ATTACK state
   - Maintains 1.5-2.5 unit distance
   - Attacks every 2 seconds
   - Animation plays with each attack

### Test 4: Retreat
1. Attack the enemy until low HP (below 25%)
2. **Expected**: Enemy runs away (RETREAT state)

### Test 5: Patrol (Optional Setup Required)
1. Select Enemy node in Godot
2. In Inspector → Patrol section:
   - Set `patrol_points` array size to 3
   - Add three Vector3 positions (e.g., (0,0,0), (10,0,0), (10,0,10))
3. Run game
4. **Expected**: Enemy walks between points, waits 2 seconds at each

## Adjusting AI Parameters

All parameters are in the Inspector when you select the Enemy node:

### Make Enemy More Aggressive
- `vision_range`: 20.0 (default: 15.0)
- `vision_angle`: 120.0 (default: 90.0)
- `attack_cooldown`: 1.0 (default: 2.0)
- `chase_speed`: 7.0 (default: 5.0)

### Make Enemy Less Aggressive
- `vision_range`: 10.0
- `vision_angle`: 60.0
- `attack_cooldown`: 3.0
- `retreat_health_percent`: 0.5 (retreats at 50% HP)

### Adjust Combat Feel
- `attack_range`: 3.0 (how close to start attacking)
- `min_attack_range`: 2.0 (minimum distance enemy maintains)
- `attack_speed`: 0.5 (slower movement during attack)

## Debugging

Open Godot console to see state transitions:
```
Enemy state: IDLE -> ALERT
Enemy state: ALERT -> CHASE
Enemy state: CHASE -> ATTACK
Enemy attacking!
```

Enable collision shapes (Debug → Visible Collision Shapes) to see:
- **Red sphere**: Detection area (20 unit radius)
- **Blue line**: Vision ray (15 units forward)

## Troubleshooting

### Enemy doesn't see player
- Check that player is in global group "Player"
- Ensure VisionRay node exists under Enemy
- Check vision_range and vision_angle values
- Make sure NavigationAgent3D path is valid

### Enemy walks through walls
- Bake Navigation Mesh in your level scene
- In Godot: Navigation → Bake NavigationMesh

### Attacks aren't working
- Verify MeleeWeaponComponent has HitboxComponent child (NOT HurtboxComponent!)
- Check collision layers: Hitbox (layer 2, mask 4)
- Ensure AnimationPlayer has "Melee_atack" animation

### Enemy never retreats
- Check that enemy has HealthComponent
- Verify `retreat_health_percent` (default 0.25 = 25% HP)
- Damage the enemy below this threshold

## Next Steps

1. **Test basic detection**: Walk in front of enemy
2. **Test hiding**: Use walls to break line-of-sight
3. **Test combat**: Let enemy attack you
4. **Add patrol routes**: Set up patrol points for more interesting behavior
5. **Tune parameters**: Adjust speeds, ranges, cooldowns to your liking

For complete documentation, see `Docs/enemy_ai_system.md`
