# Combat System Flow / Детальный поток боевой системы

## Полный цикл атаки от ввода до нанесения урона

### 1. Combat Flow - Complete Attack Cycle

```mermaid
flowchart TD
    Start([Player Presses LMB/RMB]) --> Input[Player._input event]

    Input --> CheckAttack{Attack button<br/>pressed?}
    CheckAttack -->|LMB| LightAttack[attack_type = LIGHT]
    CheckAttack -->|RMB| HeavyAttack[attack_type = HEAVY]

    LightAttack --> CombatInput[CombatComponent.handle_attack_input]
    HeavyAttack --> CombatInput

    CombatInput --> CheckMovementEnabled{movement_enabled<br/>== true?}
    CheckMovementEnabled -->|No| Blocked[Input Blocked]
    CheckMovementEnabled -->|Yes| CheckGround

    CheckGround{On Ground or<br/>allow_air_attack?} -->|No| Blocked
    CheckGround -->|Yes| CheckCombo{enable_combo?}

    CheckCombo -->|No| DirectAttack[Perform Attack]
    CheckCombo -->|Yes| CheckComboWindow{Within combo<br/>window?}

    CheckComboWindow -->|Yes| IncrementCombo[current_combo++]
    CheckComboWindow -->|No| ResetCombo[current_combo = 0]

    IncrementCombo --> CheckMaxCombo{combo ><br/>max_combo_count?}
    CheckMaxCombo -->|Yes| ResetCombo
    CheckMaxCombo -->|No| DirectAttack
    ResetCombo --> DirectAttack

    DirectAttack --> TryAttack[MeleeWeaponComponent.try_attack]

    TryAttack --> CheckCooldown{Weapon on<br/>cooldown?}
    CheckCooldown -->|Yes| AttackFailed[Attack Failed]
    CheckCooldown -->|No| CheckAlreadyAttacking{Already<br/>attacking?}

    CheckAlreadyAttacking -->|Yes| QueueAttack[Queue attack for combo]
    CheckAlreadyAttacking -->|No| StartAttack[_start_attack]

    StartAttack --> SetParams[Set damage & knockback<br/>based on attack_type]
    SetParams --> EmitSignal1[SIGNAL: attack_started]
    EmitSignal1 --> StartTimer[Start attack_timer]

    StartTimer --> TimerLoop{attack_timer<br/>in range?}
    TimerLoop -->|active_start to active_end| ActivateHitbox[HitboxComponent.activate]
    TimerLoop -->|> active_end| DeactivateHitbox[HitboxComponent.deactivate]

    ActivateHitbox --> EnableCollision[Enable hitbox monitoring]
    EnableCollision --> WaitCollision{Collision with<br/>Area3D?}

    WaitCollision -->|Yes| CheckHurtbox{Is HurtboxComponent?}
    CheckHurtbox -->|No| WaitCollision
    CheckHurtbox -->|Yes| CheckAlreadyHit{Already hit<br/>this target?}

    CheckAlreadyHit -->|Yes| WaitCollision
    CheckAlreadyHit -->|No| RecordHit[Add to hit_targets]

    RecordHit --> ApplyDamage[HurtboxComponent.take_hit]
    ApplyDamage --> CheckEnabled{hurtbox.enabled?}
    CheckEnabled -->|No| End1[End]
    CheckEnabled -->|Yes| ApplyMultiplier[damage *= damage_multiplier]

    ApplyMultiplier --> EmitHitReceived[SIGNAL: hit_received]
    EmitHitReceived --> CheckHealthComp{Has HealthComponent?}

    CheckHealthComp -->|Yes| DamageHealth[HealthComponent.apply_damage]
    CheckHealthComp -->|No| End2[End]

    DamageHealth --> SubtractHP[health -= damage]
    SubtractHP --> EmitHealthChanged[SIGNAL: health_changed]

    EmitHealthChanged --> CheckDeath{health <= 0?}
    CheckDeath -->|No| ApplyKnockback[Apply knockback to enemy]
    CheckDeath -->|Yes| EmitDepleted[SIGNAL: health_depleted]

    EmitDepleted --> DestroyEntity[get_parent.queue_free]

    ApplyKnockback --> InterruptEnemyAttack[Interrupt enemy attack if attacking]
    InterruptEnemyAttack --> PlayHitEffect[Play hit visual effect]

    DeactivateHitbox --> CheckTimerEnd{attack_timer ><br/>attack_duration?}
    CheckTimerEnd -->|No| TimerLoop
    CheckTimerEnd -->|Yes| EndAttack[End attack state]

    EndAttack --> EmitAttackEnded[SIGNAL: attack_ended]
    EmitAttackEnded --> StartCooldown[Start cooldown_timer]

    StartCooldown --> CheckQueuedAttack{Attack queued<br/>for combo?}
    CheckQueuedAttack -->|Yes| ProcessQueue[Process queued attack]
    CheckQueuedAttack -->|No| Idle[Return to Idle]

    ProcessQueue --> TryAttack

    PlayHitEffect --> End3[Combat cycle complete]
    AttackFailed --> End4[End]
    Blocked --> End5[End]
    DestroyEntity --> End6[Entity destroyed]

    style Start fill:#99ccff
    style DestroyEntity fill:#ff6666
    style EmitDepleted fill:#ff9999
    style ActivateHitbox fill:#ffcc99
    style DamageHealth fill:#ff9999
```

---

### 2. Combo System Flow

```mermaid
stateDiagram-v2
    [*] --> Idle

    Idle --> FirstAttack: Player presses attack
    FirstAttack --> ComboWindow1: Attack completes

    ComboWindow1 --> SecondAttack: Attack pressed within combo_window
    ComboWindow1 --> Idle: combo_window expires

    SecondAttack --> ComboWindow2: Attack completes
    ComboWindow2 --> ThirdAttack: Attack pressed within combo_window
    ComboWindow2 --> Idle: combo_window expires

    ThirdAttack --> MaxCombo: combo_count >= max_combo_count
    MaxCombo --> Idle: Combo reset

    note right of ComboWindow1
        combo_window = 0.5s
        current_combo = 1
    end note

    note right of ComboWindow2
        combo_window = 0.5s
        current_combo = 2
    end note

    note right of MaxCombo
        max_combo_count = 3
        SIGNAL: combo_reset()
    end note
```

---

### 3. Attack Timing Diagram

```mermaid
gantt
    title Attack Timing (Light Attack Example: 0.3s duration)
    dateFormat X
    axisFormat %L ms

    section Weapon State
    Cooldown (previous)    :done, cooldown, 0, 100
    Attack Input           :active, input, 100, 110
    Attack Start           :crit, start, 110, 110

    section Attack Phase
    Startup (no damage)    :startup, 110, 210
    Active (damage)        :active, active, 210, 360
    Recovery               :recovery, 360, 410

    section Hitbox State
    Disabled               :done, h1, 0, 210
    ACTIVE (can hit)       :crit, h2, 210, 360
    Disabled               :done, h3, 360, 500

    section Cooldown
    New Cooldown           :cooldown2, 410, 710
```

**Параметры из примера:**
- `light_attack_duration = 0.3s` (300ms)
- `light_active_start = 0.1s` (100ms)
- `light_active_end = 0.25s` (250ms)
- `light_cooldown = 0.4s` (400ms)

**Фазы:**
1. **Startup (0 - 100ms)**: Анимация начинается, урон не наносится
2. **Active (100 - 250ms)**: Хитбокс активен, может нанести урон
3. **Recovery (250 - 300ms)**: Анимация завершается, урон не наносится
4. **Cooldown (300 - 700ms)**: Невозможно атаковать снова

---

### 4. Signal Propagation in Combat

```mermaid
sequenceDiagram
    autonumber

    participant Player
    participant CombatComp as CombatComponent
    participant MeleeWeapon as MeleeWeaponComponent
    participant Hitbox as HitboxComponent
    participant Enemy
    participant Hurtbox as HurtboxComponent
    participant Health as HealthComponent

    Player->>CombatComp: Input (LMB pressed)
    CombatComp->>CombatComp: Validate (combo, ground check)
    CombatComp->>MeleeWeapon: try_attack(LIGHT)

    MeleeWeapon->>MeleeWeapon: Check cooldown
    MeleeWeapon-->>CombatComp: SIGNAL: attack_started(LIGHT)
    CombatComp-->>Player: SIGNAL: attack_performed(LIGHT)

    Note over MeleeWeapon: Timer: 0.1s

    MeleeWeapon->>Hitbox: activate()
    Hitbox->>Hitbox: Enable monitoring

    Note over Hitbox,Hurtbox: Collision Detection

    Hitbox->>Hurtbox: area_entered signal
    Hurtbox->>Hurtbox: Check if already hit
    Hurtbox-->>Enemy: SIGNAL: hit_received(damage, knockback, pos)

    Hurtbox->>Health: apply_damage(damage)
    Health->>Health: health -= damage
    Health-->>Enemy: SIGNAL: health_changed(current, max, true)

    alt health <= 0
        Health-->>Enemy: SIGNAL: health_depleted()
        Enemy->>Enemy: queue_free()
    else health > 0
        Enemy->>Enemy: Apply knockback
        Enemy->>Enemy: Interrupt attack
        Enemy->>Enemy: Play hit effect
    end

    Hitbox-->>MeleeWeapon: SIGNAL: hit_detected(hurtbox)
    MeleeWeapon-->>CombatComp: SIGNAL: hit_landed(target)

    Note over MeleeWeapon: Timer: 0.25s

    MeleeWeapon->>Hitbox: deactivate()

    Note over MeleeWeapon: Timer: 0.3s (attack ends)

    MeleeWeapon-->>CombatComp: SIGNAL: attack_ended()
    MeleeWeapon->>MeleeWeapon: Start cooldown timer
```

---

### 5. Hit Detection Logic

```mermaid
flowchart TD
    HitboxActive[Hitbox Activated] --> CollisionCheck{Area3D enters<br/>hitbox?}

    CollisionCheck -->|Yes| TypeCheck{Is area a<br/>HurtboxComponent?}
    TypeCheck -->|No| Ignore1[Ignore collision]
    TypeCheck -->|Yes| AlreadyHit{Target in<br/>hit_targets list?}

    AlreadyHit -->|Yes| Ignore2[Ignore - already hit this attack]
    AlreadyHit -->|No| AddToList[Add to hit_targets]

    AddToList --> GetDamage[Get damage from weapon]
    GetDamage --> GetKnockback[Get knockback from weapon]
    GetKnockback --> CallTakeHit[hurtbox.take_hit damage, knockback, global_position]

    CallTakeHit --> CheckEnabled{hurtbox.enabled?}
    CheckEnabled -->|No| End1[End - hurtbox disabled]
    CheckEnabled -->|Yes| ApplyMultiplier[actual_damage = damage × damage_multiplier]

    ApplyMultiplier --> EmitSignal[EMIT: hit_received signal]
    EmitSignal --> HasHealth{hurtbox has<br/>health_component?}

    HasHealth -->|No| End2[End - no health to damage]
    HasHealth -->|Yes| ApplyDamage[health_component.apply_damage actual_damage]

    ApplyDamage --> RecordHit[Record hit in hit_targets]
    RecordHit --> EmitHitDetected[EMIT: hit_detected signal from hitbox]
    EmitHitDetected --> End3[Hit registered successfully]

    style AddToList fill:#99ff99
    style RecordHit fill:#99ff99
    style Ignore1 fill:#cccccc
    style Ignore2 fill:#cccccc
```

---

### 6. Damage Multiplier System

```mermaid
graph LR
    subgraph "Attack Source"
        Weapon[MeleeWeaponComponent<br/>base_damage = 25.0]
    end

    subgraph "Target Hurtbox"
        Hurtbox1[Head Hurtbox<br/>damage_multiplier = 2.0]
        Hurtbox2[Body Hurtbox<br/>damage_multiplier = 1.0]
        Hurtbox3[Leg Hurtbox<br/>damage_multiplier = 0.5]
    end

    subgraph "Final Damage"
        Damage1[25.0 × 2.0 = 50.0<br/>Critical Hit!]
        Damage2[25.0 × 1.0 = 25.0<br/>Normal]
        Damage3[25.0 × 0.5 = 12.5<br/>Weak Hit]
    end

    Weapon -->|Hits| Hurtbox1 --> Damage1
    Weapon -->|Hits| Hurtbox2 --> Damage2
    Weapon -->|Hits| Hurtbox3 --> Damage3

    style Hurtbox1 fill:#ff6666
    style Hurtbox2 fill:#ffcc99
    style Hurtbox3 fill:#99ff99
```

---

### 7. Attack Interruption Flow

```mermaid
flowchart TD
    EnemyAttacking[Enemy is Attacking] --> TakesHit{Enemy hit_received<br/>signal?}

    TakesHit -->|Yes| CheckAttacking{melee_weapon.<br/>is_attacking?}
    CheckAttacking -->|No| ApplyKnockback[Apply knockback only]
    CheckAttacking -->|Yes| InterruptAttack[melee_weapon.interrupt_attack]

    InterruptAttack --> StopAttack[Set is_attacking = false]
    StopAttack --> ResetTimer[Reset attack_timer]
    ResetTimer --> DeactivateHitbox[Deactivate hitbox]
    DeactivateHitbox --> EmitEnded[EMIT: attack_ended signal]

    EmitEnded --> ApplyKnockback
    ApplyKnockback --> CalculateDirection[direction = position - attacker_position]
    CalculateDirection --> ApplyVelocity[velocity += direction.normalized × knockback_force]

    ApplyVelocity --> PlayEffect[Play hit visual effect<br/>white flash, 0.1s]
    PlayEffect --> UpdateAI{Enemy AI state?}

    UpdateAI -->|IDLE/PATROL| ChangeToChase[Change state to CHASE<br/>aggro from damage]
    UpdateAI -->|CHASE/ATTACK| StayInState[Stay in current state]

    ChangeToChase --> RecoverControl[Resume AI control]
    StayInState --> RecoverControl
    RecoverControl --> End[Enemy can attack again]

    style InterruptAttack fill:#ff9999
    style ChangeToChase fill:#ffcc99
```

---

### 8. Combat Component State Management

```mermaid
stateDiagram-v2
    [*] --> Idle

    Idle --> Attacking: handle_attack_input() called<br/>& can_attack() == true

    Attacking --> Attacking: Queued attack exists<br/>& combo enabled
    Attacking --> Cooldown: Attack animation complete

    Cooldown --> Idle: Cooldown timer expires

    Attacking --> Interrupted: melee_weapon.interrupt_attack()<br/>(from damage)
    Interrupted --> Cooldown

    note right of Idle
        movement_enabled = true
        is_attacking() = false
        Can accept new input
    end note

    note right of Attacking
        movement_enabled = false<br/>(if stop_movement_on_attack)
        is_attacking() = true
        Processing attack
    end note

    note right of Cooldown
        movement_enabled = true
        is_attacking() = false
        Waiting for cooldown
    end note
```

---

### 9. Collision Layer Interaction

```mermaid
graph TB
    subgraph "Player Attack"
        PlayerWeapon[MeleeWeaponComponent]
        PlayerHitbox[HitboxComponent<br/>Layer: 2<br/>Mask: 4]
    end

    subgraph "Enemy Defense"
        EnemyBody[Enemy]
        EnemyHurtbox[HurtboxComponent<br/>Layer: 4<br/>Mask: 2]
    end

    subgraph "Enemy Attack"
        EnemyWeapon[MeleeWeaponComponent]
        EnemyHitbox[HitboxComponent<br/>Layer: 2<br/>Mask: 4]
    end

    subgraph "Player Defense"
        PlayerBody[Player]
        PlayerHurtbox[HurtboxComponent<br/>Layer: 4<br/>Mask: 2]
    end

    PlayerWeapon --> PlayerHitbox
    PlayerHitbox -.->|Can detect| EnemyHurtbox
    EnemyHurtbox --> EnemyBody

    EnemyWeapon --> EnemyHitbox
    EnemyHitbox -.->|Can detect| PlayerHurtbox
    PlayerHurtbox --> PlayerBody

    style PlayerHitbox fill:#ff9999
    style EnemyHurtbox fill:#99ccff
    style EnemyHitbox fill:#ff9999
    style PlayerHurtbox fill:#99ccff
```

**Правила:**
- **Layer 2 (Hitbox)** может обнаружить **Layer 4 (Hurtbox)**
- **Layer 4 (Hurtbox)** может обнаружить **Layer 2 (Hitbox)**
- Hitbox игрока НЕ видит Hitbox врага (нет столкновения оружия)
- Hurtbox игрока НЕ видит Hurtbox врага (нет столкновения тел)

---

### 10. Performance Optimization Notes

**Оптимизации в боевой системе:**

1. **Hit Prevention**:
   - `hit_targets: Array` предотвращает множественные попадания
   - Очищается при каждой новой атаке

2. **Hitbox Activation**:
   - Hitbox активен только во время active window (100-150ms обычно)
   - Отключен в остальное время

3. **Cooldown System**:
   - Предотвращает spam атак
   - Балансировка геймплея

4. **Signal-based**:
   - Слабая связанность компонентов
   - Легко добавлять новые реакции (VFX, SFX, анимации)

5. **Component Separation**:
   - CombatComponent = логика ввода/комбо
   - MeleeWeaponComponent = логика оружия
   - Легко менять оружие без изменения боевой системы
