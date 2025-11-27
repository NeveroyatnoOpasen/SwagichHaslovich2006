# Game Architecture Diagram / Диаграмма архитектуры игры

## Полная архитектура системы "Hasl" (Godot 4.5)

### 1. Общая архитектура компонентов

```mermaid
graph TB
	subgraph "AUTOLOAD SYSTEMS"
		GameState["GameState<br/>(Character Selection,<br/>Spawn System)"]
		DialogManager["DialogManager<br/>(Dialog Database,<br/>Event System)"]
	end

	subgraph "COMPONENT SYSTEMS"
		HealthComp["HealthComponent<br/>(HP Management)"]
		TeamComp["TeamComponent<br/>(Faction System)"]

		subgraph "Combat System"
			CombatComp["CombatComponent<br/>(Input, Combo)"]
			MeleeWeapon["MeleeWeaponComponent<br/>(Weapon Logic)"]
			Hitbox["HitboxComponent<br/>(Attack Detection)"]
			Hurtbox["HurtboxComponent<br/>(Damage Reception)"]
		end

		subgraph "Dialog System"
			DialogUI["DialogUI<br/>(Visual Interface)"]
			NPCDialog["NPCDialogComponent<br/>(NPC Handler)"]
		end

		subgraph "Interaction System"
			InteractRay["InteractRay<br/>(RayCast3D)"]
			Interactable["Interactable<br/>(Base Class)"]
		end

		subgraph "Ability System"
			AbilityComp["AbilityComponent<br/>(Ability Manager)"]
			BaseAbility["BaseAbility<br/>(Base Class)"]
			DashAbility["DashAbility"]
			FireballAbility["FireballAbility"]
		end
	end

	subgraph "ENTITIES"
		Player["Player<br/>(CharacterBody3D)"]
		Enemy["Enemy<br/>(CharacterBody3D,<br/>AI State Machine)"]
		NPCBase["NPCBase<br/>(Interactable)"]
	end

	%% Connections
	Player --> HealthComp
	Player --> TeamComp
	Player --> CombatComp
	Player --> InteractRay
	Player --> AbilityComp

	Enemy --> HealthComp
	Enemy --> TeamComp
	Enemy --> MeleeWeapon
	Enemy --> Hurtbox

	NPCBase --> NPCDialog
	NPCBase --> Interactable

	CombatComp --> MeleeWeapon
	MeleeWeapon --> Hitbox
	Hurtbox --> HealthComp

	InteractRay --> Interactable
	Interactable --> NPCBase

	NPCDialog --> DialogManager
	DialogManager --> DialogUI

	AbilityComp --> BaseAbility
	BaseAbility --> DashAbility
	BaseAbility --> FireballAbility

	Player -.->|uses| GameState
	Enemy -.->|uses| TeamComp

	style GameState fill:#ff9999
	style DialogManager fill:#ff9999
	style Player fill:#99ccff
	style Enemy fill:#ffcc99
	style NPCBase fill:#99ff99
```

---

### 2. Иерархия наследования классов

```mermaid
classDiagram
	class Node {
		+_ready()
		+_process(delta)
	}

	class Node3D {
		+position: Vector3
		+rotation: Vector3
	}

	class CharacterBody3D {
		+velocity: Vector3
		+move_and_slide()
	}

	class Area3D {
		+monitoring: bool
		+area_entered
	}

	class RayCast3D {
		+is_colliding() bool
		+get_collider()
	}

	%% Components
	class HealthComponent {
		+max_health: float
		+health: float
		+apply_damage(damage)
		+heal(amount)
		Signal: health_changed
		Signal: health_depleted
	}

	class TeamComponent {
		+team: Team
		+is_hostile_to(other) bool
		+is_friendly_to(other) bool
	}

	class CombatComponent {
		+enable_combo: bool
		+max_combo_count: int
		+handle_attack_input(type)
		Signal: attack_performed
		Signal: combo_started
	}

	class MeleeWeaponComponent {
		+light_damage: float
		+heavy_damage: float
		+try_attack(type) bool
		Signal: attack_started
		Signal: hit_landed
	}

	class HitboxComponent {
		+damage: float
		+knockback_force: float
		+activate()
		+deactivate()
		Signal: hit_detected
	}

	class HurtboxComponent {
		+damage_multiplier: float
		+take_hit(damage, knockback, pos)
		Signal: hit_received
	}

	class Interactable {
		+prompt_message: String
		+use()
	}

	class InteractRay {
		+Collider: Interactable
		+use()
	}

	class BaseAbility {
		+cooldown: float
		+activate(owner) bool
		+can_use() bool
		Signal: ability_used
	}

	class AbilityComponent {
		+ability_1: BaseAbility
		+use_ability(slot) bool
		Signal: ability_activated
	}

	%% Entities
	class Player {
		+speed: float
		+movement_enabled: bool
		+set_movement_enabled(bool)
	}

	class Enemy {
		+current_state: State
		+vision_range: float
		+change_state(state)
		+check_target_vision()
	}

	class NPCBase {
		+npc_display_name: String
		+starting_dialog_id: String
		+use()
	}

	class DashAbility {
		+dash_speed: float
		+dash_duration: float
	}

	class FireballAbility {
		+damage: float
		+projectile_speed: float
	}

	%% Inheritance
	Node <|-- HealthComponent
	Node <|-- TeamComponent
	Node <|-- CombatComponent
	Node <|-- AbilityComponent
	Node <|-- BaseAbility

	Node3D <|-- Node
	Node3D <|-- MeleeWeaponComponent
	Node3D <|-- Interactable
	Node3D <|-- CharacterBody3D

	Area3D <|-- Node3D
	Area3D <|-- HitboxComponent
	Area3D <|-- HurtboxComponent

	RayCast3D <|-- Node3D
	RayCast3D <|-- InteractRay

	CharacterBody3D <|-- Player
	CharacterBody3D <|-- Enemy

	Interactable <|-- NPCBase

	BaseAbility <|-- DashAbility
	BaseAbility <|-- FireballAbility
```

---

### 3. Структура Player Entity

```mermaid
graph TB
	Player["Player<br/>(CharacterBody3D)"]

	subgraph "Movement & Camera"
		Pivot["Pivot (Node3D)"]
		Camera["Camera3D"]
		InteractRay["InteractRay<br/>(RayCast3D)"]
	end

	subgraph "Combat"
		CombatComp["CombatComponent"]
		MeleeWeapon["MeleeWeaponComponent"]
		Hitbox["HitboxComponent"]
		Hurtbox["HurtboxComponent"]
	end

	subgraph "Stats"
		Health["HealthComponent"]
		Team["TeamComponent"]
	end

	subgraph "Abilities"
		AbilityComp["AbilityComponent"]
		Ability1["Ability Slot 1"]
		Ability2["Ability Slot 2"]
	end

	Player --> Pivot
	Pivot --> Camera
	Pivot --> InteractRay

	Player --> CombatComp
	Player --> MeleeWeapon
	MeleeWeapon --> Hitbox
	Player --> Hurtbox

	Player --> Health
	Player --> Team

	Player --> AbilityComp
	AbilityComp --> Ability1
	AbilityComp --> Ability2

	CombatComp -.->|controls| MeleeWeapon
	Hurtbox -.->|damages| Health

	style Player fill:#99ccff
	style CombatComp fill:#ffcc99
	style Health fill:#ff9999
```

---

### 4. Структура Enemy Entity

```mermaid
graph TB
	Enemy["Enemy<br/>(CharacterBody3D)"]

	subgraph "AI System"
		StateMachine["State Machine<br/>(IDLE, PATROL, ALERT,<br/>CHASE, ATTACK, RETREAT)"]
		VisionRay["VisionRay<br/>(RayCast3D)"]
		DetectionArea["DetectionArea<br/>(Area3D)"]
		NavAgent["NavigationAgent3D"]
	end

	subgraph "Combat"
		MeleeWeapon["MeleeWeaponComponent"]
		Hitbox["HitboxComponent"]
		Hurtbox["HurtboxComponent"]
	end

	subgraph "Stats"
		Health["HealthComponent"]
		Team["TeamComponent"]
	end

	subgraph "Visuals"
		Mesh["MeshInstance3D"]
	end

	Enemy --> StateMachine
	Enemy --> VisionRay
	Enemy --> DetectionArea
	Enemy --> NavAgent

	Enemy --> MeleeWeapon
	MeleeWeapon --> Hitbox
	Enemy --> Hurtbox

	Enemy --> Health
	Enemy --> Team

	Enemy --> Mesh

	StateMachine -.->|uses| VisionRay
	StateMachine -.->|uses| DetectionArea
	StateMachine -.->|uses| NavAgent
	StateMachine -.->|attacks with| MeleeWeapon

	DetectionArea -.->|checks| Team
	Hurtbox -.->|damages| Health
	Health -.->|triggers| StateMachine

	style Enemy fill:#ffcc99
	style StateMachine fill:#ff9999
	style Health fill:#ff9999
```

---

### 5. Dialog System Architecture

```mermaid
graph LR
	subgraph "Player Interaction"
		Player["Player"]
		InteractRay["InteractRay"]
	end

	subgraph "NPC"
		NPCBase["NPCBase<br/>(Interactable)"]
		NPCDialog["NPCDialogComponent"]
	end

	subgraph "Dialog System"
		DialogManager["DialogManager<br/>(Autoload)"]
		DialogsJSON["dialogs.json<br/>(Database)"]
		DialogUI["DialogUI<br/>(CanvasLayer)"]
	end

	subgraph "Game Events"
		EventHandlers["Event Handlers<br/>(buy_item, start_quest, etc.)"]
	end

	Player -->|Aims at| NPCBase
	InteractRay -->|Detects| NPCBase
	Player -->|Presses E| NPCBase
	NPCBase -->|use()| NPCDialog
	NPCDialog -->|start_dialog(id)| DialogManager
	DialogManager -->|loads| DialogsJSON
	DialogManager -->|dialog_started| DialogUI
	DialogUI -->|Shows choices| Player
	Player -->|Selects choice| DialogUI
	DialogUI -->|process_choice()| DialogManager
	DialogManager -->|trigger_event()| EventHandlers
	DialogManager -->|dialog_ended| NPCDialog
	NPCDialog -->|Releases control| Player

	style DialogManager fill:#ff9999
	style NPCBase fill:#99ff99
```

---

### 6. Combat Data Flow

```mermaid
sequenceDiagram
	participant P as Player
	participant CC as CombatComponent
	participant MW as MeleeWeaponComponent
	participant HB as HitboxComponent
	participant HT as HurtboxComponent
	participant HC as HealthComponent
	participant E as Enemy

	P->>CC: Press LMB (attack input)
	CC->>CC: Check combo, cooldown
	CC->>MW: try_attack(LIGHT)
	MW->>MW: Check can_attack()
	MW->>HB: activate()
	HB->>HB: Enable collision detection

	Note over HB,HT: Collision occurs

	HB->>HT: area_entered(hurtbox)
	HT->>HT: Check if already hit
	HT->>HC: apply_damage(damage)
	HC->>HC: health -= damage
	HC-->>E: Signal: health_changed

	alt Health <= 0
		HC-->>E: Signal: health_depleted
		E->>E: queue_free()
	end

	HT-->>E: Signal: hit_received(knockback)
	E->>E: Apply knockback
	HB-->>MW: Signal: hit_detected
	MW-->>CC: Signal: hit_landed

	MW->>HB: deactivate()
	MW-->>CC: Signal: attack_ended
```

---

### 7. Enemy AI State Machine

```mermaid
stateDiagram-v2
	[*] --> IDLE

	IDLE --> PATROL: Has patrol points
	IDLE --> CHASE: Enemy detected (vision/proximity)

	PATROL --> PATROL: Moving between points
	PATROL --> IDLE: Patrol complete
	PATROL --> ALERT: Enemy detected

	ALERT --> CHASE: Enemy in sight
	ALERT --> IDLE: Lost sight timeout

	CHASE --> ATTACK: In attack range
	CHASE --> ALERT: Lost sight
	CHASE --> RETREAT: Health < 25%

	ATTACK --> CHASE: Out of range
	ATTACK --> RETREAT: Health < 25%
	ATTACK --> ATTACK: Cooldown & in range

	RETREAT --> CHASE: Health recovered
	RETREAT --> RETREAT: Health low

	note right of IDLE
		Standing still
		Looking around
	end note

	note right of PATROL
		Following patrol_points
		Waiting at each point
	end note

	note right of ALERT
		Moving to last_known_position
		Searching for target
	end note

	note right of CHASE
		Following target
		Using NavigationAgent3D
		Vision + proximity checks
	end note

	note right of ATTACK
		Maintaining attack distance
		Performing attacks
		Managing cooldown
	end note

	note right of RETREAT
		Moving away from target
		Survival mode
	end note
```

---

### 8. Collision Layers & Masks

```mermaid
graph LR
	subgraph "Layer 2: Hitbox"
		Hitbox["HitboxComponent<br/>Layer: 2<br/>Mask: 4"]
	end

	subgraph "Layer 4: Hurtbox"
		Hurtbox["HurtboxComponent<br/>Layer: 4<br/>Mask: 2"]
	end

	Hitbox -->|Detects| Hurtbox
	Hurtbox -->|Detects| Hitbox

	style Hitbox fill:#ff9999
	style Hurtbox fill:#99ccff
```

---

### 9. Team System (Faction Hostility Matrix)

```mermaid
graph TB
	subgraph "Teams"
		CULT["CULT<br/>(Cultists)"]
		REGULAR["REGULAR<br/>(Military/Player)"]
		MOBS["MOBS<br/>(Monsters)"]
		NEUTRAL["NEUTRAL"]
	end

	CULT -->|Hostile| REGULAR
	CULT -->|Hostile| MOBS

	REGULAR -->|Hostile| CULT
	REGULAR -->|Hostile| MOBS

	MOBS -->|Hostile| CULT
	MOBS -->|Hostile| REGULAR

	NEUTRAL -.->|Not Hostile| CULT
	NEUTRAL -.->|Not Hostile| REGULAR
	NEUTRAL -.->|Not Hostile| MOBS

	style CULT fill:#ff6666
	style REGULAR fill:#6666ff
	style MOBS fill:#66ff66
	style NEUTRAL fill:#cccccc
```

---

### 10. Signal Flow Map

```mermaid
graph TB
	subgraph "Health System Signals"
		HC_changed["health_changed<br/>(current, max, damaged)"]
		HC_depleted["health_depleted()"]
	end

	subgraph "Combat System Signals"
		CC_attack["attack_performed<br/>(attack_type)"]
		CC_combo["combo_started<br/>(combo_index)"]
		MW_started["attack_started<br/>(attack_type)"]
		MW_ended["attack_ended()"]
		MW_hit["hit_landed<br/>(target)"]
		HB_detected["hit_detected<br/>(hurtbox)"]
		HT_received["hit_received<br/>(damage, knockback, pos)"]
	end

	subgraph "Dialog System Signals"
		DM_started["dialog_started<br/>(dialog_id)"]
		DM_ended["dialog_ended()"]
		DM_event["dialog_event<br/>(event_name, params)"]
	end

	subgraph "Ability System Signals"
		AB_used["ability_used<br/>(ability_name)"]
		AB_ready["ability_ready<br/>(ability_name)"]
		AC_activated["ability_activated<br/>(ability_name)"]
	end

	HC_changed -->|Player/Enemy| UI["UI Updates"]
	HC_depleted -->|Entity| Death["Entity Death"]

	CC_attack -->|Player| AnimSystem["Animation System"]
	MW_hit -->|Weapon| VFX["VFX/SFX"]
	HT_received -->|Enemy| AIReaction["AI Reaction"]

	DM_started -->|DialogUI| ShowDialog["Show Dialog Panel"]
	DM_ended -->|NPCDialog| ReleasePlayer["Release Player Control"]

	AB_used -->|UI| CooldownUI["Cooldown Display"]

	style HC_depleted fill:#ff6666
	style DM_started fill:#66ff66
```

---

## Легенда

- **Прямоугольники** - Компоненты/Системы
- **Ромбы** - Точки принятия решений
- **Стрелки →** - Прямые зависимости
- **Пунктирные стрелки -.->** - Использование/Ссылки
- **Цвета:**
  - 🔴 Красный - Autoload/Критичные системы
  - 🔵 Синий - Player
  - 🟠 Оранжевый - Enemy
  - 🟢 Зеленый - NPC
