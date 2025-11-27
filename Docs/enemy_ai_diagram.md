# Enemy AI System Diagram / Диаграмма AI системы врагов

## Подробная архитектура AI врага с State Machine

### 1. Complete Enemy AI State Machine

```mermaid
stateDiagram-v2
    [*] --> IDLE

    IDLE --> PATROL: has patrol_points.size > 0
    IDLE --> CHASE: Enemy detected (vision OR proximity)
    IDLE --> IDLE: Rotating, looking around

    PATROL --> PATROL: Moving to next patrol point
    PATROL --> IDLE: All points visited & !loop
    PATROL --> ALERT: Enemy detected
    PATROL --> CHASE: Enemy in vision range

    ALERT --> CHASE: Enemy spotted (vision)
    ALERT --> IDLE: Lost sight timeout expired
    ALERT --> ALERT: Moving to last_known_position

    CHASE --> ATTACK: distance <= attack_range
    CHASE --> ALERT: Lost sight (time_since_seen > lose_sight_time)
    CHASE --> RETREAT: health < (max_health * retreat_health_percent)
    CHASE --> CHASE: Following target via NavigationAgent3D

    ATTACK --> CHASE: distance > attack_range
    ATTACK --> RETREAT: health < (max_health * retreat_health_percent)
    ATTACK --> ATTACK: Maintaining distance & attacking

    RETREAT --> CHASE: health recovered (> retreat threshold)
    RETREAT --> RETREAT: Moving away from target

    note right of IDLE
        idle_speed = 0.0
        Looking around slowly
        Waiting for detection
    end note

    note right of PATROL
        patrol_speed = 2.0
        Following patrol_points array
        Wait patrol_wait_time at each point
        Cycle: 0 → 1 → 2 → ... → 0
    end note

    note right of ALERT
        chase_speed = 5.0
        Investigating last_known_position
        Actively searching for target
        Timeout: lose_sight_time (5s default)
    end note

    note right of CHASE
        chase_speed = 5.0
        Using NavigationAgent3D pathfinding
        Vision + DetectionArea active
        Transitions to ATTACK when close
    end note

    note right of ATTACK
        attack_speed = 1.0
        Maintaining min_attack_range - attack_range
        Performing attacks (cooldown managed)
        look_at_target() for accuracy
    end note

    note right of RETREAT
        chase_speed = 5.0 (running away)
        Moving opposite direction from target
        Health-based trigger
        Can return to CHASE if healed
    end note
```

---

### 2. Enemy AI Update Loop

```mermaid
flowchart TD
    Process[Enemy._process delta] --> UpdateTimers[Update various timers]

    UpdateTimers --> CheckHealth{health <<br/>retreat threshold?}
    CheckHealth -->|Yes| ForceRetreat[change_state RETREAT]
    CheckHealth -->|No| UpdateState[update_state delta]

    ForceRetreat --> UpdateState

    UpdateState --> MatchState{Match current_state}

    MatchState -->|IDLE| StateIdle[_state_idle]
    MatchState -->|PATROL| StatePatrol[_state_patrol]
    MatchState -->|ALERT| StateAlert[_state_alert]
    MatchState -->|CHASE| StateChase[_state_chase]
    MatchState -->|ATTACK| StateAttack[_state_attack]
    MatchState -->|RETREAT| StateRetreat[_state_retreat]

    StateIdle --> VisionCheck
    StatePatrol --> VisionCheck
    StateAlert --> VisionCheck
    StateChase --> VisionCheck
    StateAttack --> VisionCheck
    StateRetreat --> VisionCheck

    VisionCheck[Check Vision interval] --> VisionTime{vision_check_timer ><br/>vision_check_interval?}
    VisionTime -->|No| End
    VisionTime -->|Yes| ResetVisionTimer[Reset vision_check_timer]

    ResetVisionTimer --> CallVisionCheck[check_target_vision]
    CallVisionCheck --> End[Frame complete]

    style CheckHealth fill:#ff9999
    style MatchState fill:#99ccff
```

---

### 3. Vision System Detailed Flow

```mermaid
flowchart TD
    CheckVision[check_target_vision] --> HasTarget{current_target<br/>exists?}

    HasTarget -->|No| FindTarget[_find_closest_hostile_target]
    FindTarget --> FoundTarget{Target found?}
    FoundTarget -->|No| NoTarget[can_see_target = false<br/>Return]
    FoundTarget -->|Yes| SetTarget[current_target = found_target]

    HasTarget -->|Yes| CheckDistance
    SetTarget --> CheckDistance[Calculate distance to target]

    CheckDistance --> InRange{distance <=<br/>vision_range?}
    InRange -->|No| OutOfRange[can_see_target = false<br/>time_since_seen += delta]
    InRange -->|Yes| CheckAngle[Calculate angle to target]

    CheckAngle --> InAngle{angle <=<br/>vision_angle?}
    InAngle -->|No| OutOfAngle[can_see_target = false<br/>time_since_seen += delta]
    InAngle -->|Yes| SetupRaycast[Setup VisionRay]

    SetupRaycast --> SetRayTarget[VisionRay.target_position = to_target]
    SetRayTarget --> ForceUpdate[VisionRay.force_raycast_update]
    ForceUpdate --> IsColliding{VisionRay.<br/>is_colliding?}

    IsColliding -->|No| ClearVision[can_see_target = true<br/>time_since_seen = 0]
    IsColliding -->|Yes| GetCollider[collider = VisionRay.get_collider]

    GetCollider --> IsSameTarget{collider ==<br/>current_target?}
    IsSameTarget -->|Yes| ClearVision
    IsSameTarget -->|No| Blocked[Vision blocked by obstacle<br/>can_see_target = false]

    ClearVision --> UpdateLastKnown[last_known_target_pos = target.global_position]
    UpdateLastKnown --> End1[Vision check complete]

    OutOfRange --> End2[Vision check complete]
    OutOfAngle --> End2
    Blocked --> End2
    NoTarget --> End2

    style ClearVision fill:#99ff99
    style Blocked fill:#ff9999
    style NoTarget fill:#cccccc
```

**Параметры Vision:**
- `vision_range: float = 15.0` - дистанция зрения
- `vision_angle: float = 90.0` - угол обзора (degrees)
- `vision_check_interval: float = 0.1` - частота проверки

---

### 4. Target Detection System

```mermaid
flowchart TD
    FindTarget[_find_closest_hostile_target] --> CheckPotential{potential_targets<br/>empty?}

    CheckPotential -->|Yes| ReturnNull1[Return null]
    CheckPotential -->|No| InitVars[closest_target = null<br/>closest_distance = INF]

    InitVars --> LoopStart{For each<br/>potential_target}
    LoopStart -->|Done| ReturnClosest[Return closest_target]
    LoopStart -->|Next| CheckValid{target.is_valid?}

    CheckValid -->|No| LoopStart
    CheckValid -->|Yes| HasTeamComp{target has<br/>TeamComponent?}

    HasTeamComp -->|No| LoopStart
    HasTeamComp -->|Yes| GetTeam[target_team = target.TeamComponent]

    GetTeam --> CheckHostile{team_component.<br/>is_hostile_to<br/>target_team?}
    CheckHostile -->|No| LoopStart
    CheckHostile -->|Yes| CalcDistance[distance = global_position.distance_to target]

    CalcDistance --> IsCloser{distance <<br/>closest_distance?}
    IsCloser -->|No| LoopStart
    IsCloser -->|Yes| UpdateClosest[closest_target = target<br/>closest_distance = distance]

    UpdateClosest --> LoopStart
    ReturnNull1 --> End[End]
    ReturnClosest --> End

    style CheckHostile fill:#ff9999
    style UpdateClosest fill:#99ff99
```

---

### 5. Detection Area Integration

```mermaid
sequenceDiagram
    autonumber

    participant Player
    participant DetectArea as DetectionArea (Area3D)
    participant Enemy
    participant TeamComp as TeamComponent

    Player->>DetectArea: Enters detection sphere
    DetectArea->>DetectArea: body_entered(body)
    DetectArea->>DetectArea: Check: body is CharacterBody3D?

    alt Is CharacterBody3D
        DetectArea->>Player: Check has_node("TeamComponent")?

        alt Has TeamComponent
            DetectArea->>Player: Get TeamComponent
            DetectArea->>TeamComp: is_hostile_to(player.TeamComponent)

            alt Is Hostile
                DetectArea->>Enemy: Add to potential_targets
                Enemy->>Enemy: Check current_state

                alt State is IDLE
                    Enemy->>Enemy: change_state(ALERT)
                else State is PATROL
                    Enemy->>Enemy: change_state(ALERT)
                else Other States
                    Enemy->>Enemy: Stay in current state
                end
            else Not Hostile
                Note over DetectArea,Enemy: Ignore (friendly or neutral)
            end
        else No TeamComponent
            Note over DetectArea: Ignore (not a valid target)
        end
    else Not CharacterBody3D
        Note over DetectArea: Ignore (wrong type)
    end
```

**DetectionArea настройка:**
- Shape: SphereShape3D
- Radius: `detection_radius` (20.0 default)
- Monitoring: true
- Signals: `body_entered`, `body_exited`

---

### 6. Navigation System Flow

```mermaid
flowchart TD
    MoveToTarget[move_towards_target target_position] --> CheckNav{NavigationAgent3D<br/>ready?}

    CheckNav -->|No| DirectMove[Move directly towards target]
    CheckNav -->|Yes| UpdateInterval{navigation_update_timer ><br/>navigation_update_interval?}

    UpdateInterval -->|No| UseCache[Use cached_navigation_target]
    UpdateInterval -->|Yes| ResetTimer[Reset navigation_update_timer]

    ResetTimer --> SetTarget[navigation_agent.target_position = target_position]
    SetTarget --> CacheTarget[cached_navigation_target = target_position]
    CacheTarget --> GetNext

    UseCache --> GetNext[next_position = navigation_agent.get_next_path_position]

    GetNext --> CalcDirection[direction = next_position - global_position]
    CalcDirection --> Normalize[direction = direction.normalized]

    Normalize --> CheckState{Match current_state}
    CheckState -->|IDLE| SetSpeed1[speed = idle_speed]
    CheckState -->|PATROL| SetSpeed2[speed = patrol_speed]
    CheckState -->|CHASE| SetSpeed3[speed = chase_speed]
    CheckState -->|ATTACK| SetSpeed4[speed = attack_speed]
    CheckState -->|Other| SetSpeed3

    SetSpeed1 --> ApplyVelocity
    SetSpeed2 --> ApplyVelocity
    SetSpeed3 --> ApplyVelocity
    SetSpeed4 --> ApplyVelocity[velocity.x = direction.x * speed<br/>velocity.z = direction.z * speed]

    ApplyVelocity --> ApplyGravity[velocity.y -= gravity * delta]
    ApplyGravity --> MoveSlide[move_and_slide]

    DirectMove --> CalcDirection
    MoveSlide --> End[Movement complete]

    style GetNext fill:#99ccff
    style ApplyVelocity fill:#99ff99
```

**Оптимизация Navigation:**
- `navigation_update_interval: float = 0.2` - не пересчитываем путь каждый кадр
- `cached_navigation_target` - используем кеш между обновлениями

---

### 7. State-Specific Behaviors

#### IDLE State
```mermaid
flowchart TD
    Idle[_state_idle] --> StopMovement[velocity.x = 0<br/>velocity.z = 0]
    StopMovement --> Rotate[Slowly rotate looking around]
    Rotate --> CheckVision{can_see_target?}
    CheckVision -->|Yes| ToChase[change_state CHASE]
    CheckVision -->|No| End[Stay in IDLE]
```

#### PATROL State
```mermaid
flowchart TD
    Patrol[_state_patrol] --> HasPoints{patrol_points.<br/>size > 0?}
    HasPoints -->|No| ToIdle[change_state IDLE]
    HasPoints -->|Yes| GetPoint[current_point = patrol_points[patrol_index]]

    GetPoint --> CalcDist[distance = global_position.distance_to current_point]
    CalcDist --> Reached{distance < 1.0?}

    Reached -->|No| MoveToPoint[move_towards_target current_point]
    Reached -->|Yes| StartWait[patrol_wait_timer = patrol_wait_time]

    StartWait --> Waiting{patrol_wait_timer<br/>> 0?}
    Waiting -->|Yes| Decrement[patrol_wait_timer -= delta]
    Waiting -->|No| NextIndex[patrol_index = patrol_index + 1 % patrol_points.size]

    NextIndex --> GetPoint
    Decrement --> CheckVision
    MoveToPoint --> CheckVision{can_see_target?}

    CheckVision -->|Yes| ToChase[change_state CHASE]
    CheckVision -->|No| End[Continue PATROL]
```

#### CHASE State
```mermaid
flowchart TD
    Chase[_state_chase] --> HasTarget{current_target<br/>exists?}
    HasTarget -->|No| ToIdle[change_state IDLE]
    HasTarget -->|Yes| CalcDist[distance = global_position.distance_to target]

    CalcDist --> InAttackRange{distance <=<br/>attack_range?}
    InAttackRange -->|Yes| ToAttack[change_state ATTACK]
    InAttackRange -->|No| CheckSight{can_see_target?}

    CheckSight -->|Yes| Move[move_towards_target target.global_position]
    CheckSight -->|No| CheckTime{time_since_seen ><br/>lose_sight_time?}

    CheckTime -->|Yes| ToAlert[change_state ALERT]
    CheckTime -->|No| Move

    Move --> LookAt[look_at_target target.global_position]
    LookAt --> End[Continue CHASE]
```

#### ATTACK State
```mermaid
flowchart TD
    Attack[_state_attack] --> HasTarget{current_target<br/>exists?}
    HasTarget -->|No| ToIdle[change_state IDLE]
    HasTarget -->|Yes| CalcDist[distance = global_position.distance_to target]

    CalcDist --> OutOfRange{distance ><br/>attack_range?}
    OutOfRange -->|Yes| ToChase[change_state CHASE]
    OutOfRange -->|No| TooClose{distance <<br/>min_attack_range?}

    TooClose -->|Yes| MoveBack[move_away_from_target target, delta]
    TooClose -->|No| LookAt[look_at_target target.global_position]

    LookAt --> CheckCooldown{attack_cooldown_timer<br/><= 0?}
    CheckCooldown -->|No| DecrementCD[attack_cooldown_timer -= delta]
    CheckCooldown -->|Yes| PerformAttack[perform_attack]

    PerformAttack --> CallWeapon[melee_weapon.try_attack HEAVY]
    CallWeapon --> CheckSuccess{Attack<br/>successful?}

    CheckSuccess -->|Yes| ResetCD[attack_cooldown_timer = attack_cooldown]
    CheckSuccess -->|No| DecrementCD

    MoveBack --> End[Continue ATTACK]
    DecrementCD --> End
    ResetCD --> End
```

#### RETREAT State
```mermaid
flowchart TD
    Retreat[_state_retreat] --> HasTarget{current_target<br/>exists?}
    HasTarget -->|No| ToIdle[change_state IDLE]
    HasTarget -->|Yes| CheckHealth{health ><br/>retreat threshold?}

    CheckHealth -->|Yes| ToChase[change_state CHASE<br/>Health recovered!]
    CheckHealth -->|No| MoveAway[move_away_from_target target, delta]

    MoveAway --> LookAt[look_at_target target.global_position<br/>facing enemy while retreating]
    LookAt --> End[Continue RETREAT]
```

---

### 8. Damage Reaction Flow

```mermaid
sequenceDiagram
    autonumber

    participant Weapon as Enemy Weapon
    participant Hurtbox as Enemy HurtboxComponent
    participant Health as Enemy HealthComponent
    participant Enemy as Enemy AI
    participant MeleeWeapon as Enemy MeleeWeapon

    Weapon->>Hurtbox: Hit detected (from player)
    Hurtbox-->>Enemy: SIGNAL: hit_received(damage, knockback, pos)

    Enemy->>Enemy: _on_hit_received()
    Enemy->>Enemy: Calculate knockback direction
    Enemy->>Enemy: Apply knockback to velocity

    Enemy->>MeleeWeapon: Check is_attacking?

    alt Is Attacking
        Enemy->>MeleeWeapon: interrupt_attack()
        MeleeWeapon->>MeleeWeapon: Cancel current attack
        MeleeWeapon-->>Enemy: SIGNAL: attack_ended
    end

    Enemy->>Enemy: _play_hit_effect()
    Enemy->>Enemy: Set mesh modulate to WHITE
    Enemy->>Enemy: Start hit_effect_timer (0.1s)

    Hurtbox->>Health: apply_damage(damage)
    Health->>Health: health -= damage
    Health-->>Enemy: SIGNAL: health_changed(current, max, true)

    Enemy->>Enemy: _on_health_changed()

    alt Current State is IDLE or PATROL
        Enemy->>Enemy: change_state(CHASE)<br/>Aggro from damage
    else Other States
        Enemy->>Enemy: Stay in current state
    end

    alt health <= 0
        Health-->>Enemy: SIGNAL: health_depleted
        Enemy->>Enemy: queue_free()
    end
```

**Hit Effect:**
- Mesh modulate → Color.WHITE (flash)
- Duration: 0.1s
- Returns to normal color (RED)

---

### 9. Team-Based Target Selection

```mermaid
graph TB
    subgraph "Enemy (MOBS Team)"
        EnemyAI[Enemy AI]
        EnemyTeam[TeamComponent<br/>team = MOBS]
    end

    subgraph "Potential Targets"
        Player[Player<br/>team = REGULAR]
        Cultist[Cultist NPC<br/>team = CULT]
        OtherMob[Other Mob<br/>team = MOBS]
        Neutral[Neutral NPC<br/>team = NEUTRAL]
    end

    EnemyAI --> Check1{is_hostile_to<br/>Player.REGULAR?}
    Check1 -->|MOBS vs REGULAR = TRUE| Target1[✓ Attack Player]

    EnemyAI --> Check2{is_hostile_to<br/>Cultist.CULT?}
    Check2 -->|MOBS vs CULT = TRUE| Target2[✓ Attack Cultist]

    EnemyAI --> Check3{is_hostile_to<br/>OtherMob.MOBS?}
    Check3 -->|MOBS vs MOBS = FALSE| Ignore1[✗ Ignore Ally]

    EnemyAI --> Check4{is_hostile_to<br/>Neutral.NEUTRAL?}
    Check4 -->|MOBS vs NEUTRAL = FALSE| Ignore2[✗ Ignore Neutral]

    style Target1 fill:#ff9999
    style Target2 fill:#ff9999
    style Ignore1 fill:#99ff99
    style Ignore2 fill:#99ff99
```

**Hostility Matrix:**
```
        | CULT | REGULAR | MOBS | NEUTRAL |
--------|------|---------|------|---------|
CULT    | ✗    | ✓       | ✓    | ✗       |
REGULAR | ✓    | ✗       | ✓    | ✗       |
MOBS    | ✓    | ✓       | ✗    | ✗       |
NEUTRAL | ✗    | ✗       | ✗    | ✗       |
```

---

### 10. Performance Optimization

```mermaid
graph LR
    subgraph "Check Intervals"
        Vision[Vision Check<br/>0.1s interval]
        Navigation[Navigation Update<br/>0.2s interval]
        TargetSearch[Target Search<br/>0.5s interval]
    end

    subgraph "Caching"
        NavCache[Cached navigation_target]
        TargetCache[potential_targets array]
    end

    subgraph "Optimization Results"
        CPU[Reduced CPU usage<br/>~60-70%]
        FPS[Stable FPS with<br/>10+ enemies]
    end

    Vision --> CPU
    Navigation --> CPU
    TargetSearch --> CPU
    NavCache --> FPS
    TargetCache --> FPS

    style CPU fill:#99ff99
    style FPS fill:#99ff99
```

**Оптимизации:**
1. Vision check не каждый кадр (0.1s interval)
2. Navigation path не пересчитывается каждый кадр (0.2s interval)
3. Target search с интервалом (0.5s interval)
4. Кеширование navigation target
5. potential_targets обновляется только при входе/выходе из DetectionArea
6. Debug prints отключены по умолчанию (`enable_debug_prints = false`)

---

### 11. AI State Transition Triggers

```mermaid
graph TB
    subgraph "Detection Triggers"
        VisionDetect[Vision Detection<br/>can_see_target = true]
        ProximityDetect[Proximity Detection<br/>body_entered DetectionArea]
        DamageDetect[Damage Received<br/>hit_received signal]
    end

    subgraph "Distance Triggers"
        InAttackRange[Distance <= attack_range]
        OutAttackRange[Distance > attack_range]
        TooClose[Distance < min_attack_range]
    end

    subgraph "Time Triggers"
        LostSight[time_since_seen > lose_sight_time]
        WaitComplete[patrol_wait_timer <= 0]
        CooldownReady[attack_cooldown_timer <= 0]
    end

    subgraph "Health Triggers"
        LowHealth[health < max_health * retreat_percent]
        HealthRecovered[health > retreat threshold]
        Death[health <= 0]
    end

    VisionDetect --> Chase[→ CHASE]
    ProximityDetect --> Alert[→ ALERT]
    DamageDetect --> Chase

    InAttackRange --> Attack[→ ATTACK]
    OutAttackRange --> Chase
    TooClose --> MoveBack[Move Backward]

    LostSight --> Alert
    WaitComplete --> NextPatrol[Next Patrol Point]
    CooldownReady --> PerformAttack[Perform Attack]

    LowHealth --> Retreat[→ RETREAT]
    HealthRecovered --> Chase
    Death --> Destroy[queue_free]

    style Chase fill:#ff9999
    style Attack fill:#ff9999
    style Retreat fill:#ffcc99
    style Destroy fill:#666666
```

---

### 12. Complete AI Decision Tree

```mermaid
flowchart TD
    Start[Enemy AI Tick] --> HealthCheck{Health <<br/>retreat threshold?}

    HealthCheck -->|Yes| ForceRetreat[State = RETREAT]
    HealthCheck -->|No| StateSwitch{Current State?}

    StateSwitch -->|IDLE| IdleLogic
    StateSwitch -->|PATROL| PatrolLogic
    StateSwitch -->|ALERT| AlertLogic
    StateSwitch -->|CHASE| ChaseLogic
    StateSwitch -->|ATTACK| AttackLogic
    StateSwitch -->|RETREAT| RetreatLogic

    IdleLogic{Enemy detected?} -->|Yes| ToChase1[→ CHASE]
    IdleLogic -->|No| StayIdle[Rotate & Wait]

    PatrolLogic{Reached point?} -->|Yes| Wait[Wait at point]
    PatrolLogic -->|No| MovePatrol[Move to point]
    Wait --> NextPoint{Wait complete?}
    NextPoint -->|Yes| NextPatrol[Next patrol point]
    NextPoint -->|No| Wait
    MovePatrol --> PatrolVision{Enemy detected?}
    PatrolVision -->|Yes| ToChase2[→ CHASE]
    PatrolVision -->|No| MovePatrol

    AlertLogic{Found target?} -->|Yes| ToChase3[→ CHASE]
    AlertLogic -->|No| SearchTime{Search timeout?}
    SearchTime -->|Yes| ToIdle1[→ IDLE]
    SearchTime -->|No| Investigate[Move to last position]

    ChaseLogic{In attack range?} -->|Yes| ToAttack1[→ ATTACK]
    ChaseLogic -->|No| ChaseVision{Can see target?}
    ChaseVision -->|Yes| ChaseMove[Move towards target]
    ChaseVision -->|No| LostTime{Lost sight timeout?}
    LostTime -->|Yes| ToAlert1[→ ALERT]
    LostTime -->|No| ChaseMove

    AttackLogic{Out of range?} -->|Yes| ToChase4[→ CHASE]
    AttackLogic -->|No| AttackDistance{Too close?}
    AttackDistance -->|Yes| BackUp[Move backward]
    AttackDistance -->|No| AttackCD{Cooldown ready?}
    AttackCD -->|Yes| ExecuteAttack[Perform attack]
    AttackCD -->|No| WaitCD[Wait for cooldown]

    RetreatLogic{Health recovered?} -->|Yes| ToChase5[→ CHASE]
    RetreatLogic -->|No| Flee[Move away from target]

    ForceRetreat --> End
    ToChase1 --> End
    ToChase2 --> End
    ToChase3 --> End
    ToChase4 --> End
    ToChase5 --> End
    ToAttack1 --> End
    ToAlert1 --> End
    ToIdle1 --> End
    StayIdle --> End
    NextPatrol --> End
    Investigate --> End
    ChaseMove --> End
    BackUp --> End
    ExecuteAttack --> End
    WaitCD --> End
    Flee --> End

    End[End Tick]

    style HealthCheck fill:#ff9999
    style ToChase1 fill:#99ccff
    style ToChase2 fill:#99ccff
    style ToChase3 fill:#99ccff
    style ToChase4 fill:#99ccff
    style ToChase5 fill:#99ccff
    style ToAttack1 fill:#ffcc99
    style ForceRetreat fill:#ff6666
```

---

Эта диаграмма показывает полную логику AI врага с учетом всех состояний, переходов, оптимизаций и интеграций с другими системами.
