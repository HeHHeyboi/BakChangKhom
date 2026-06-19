# BakChangKhom - Godot 4 Game Project

## Project Overview
- Godot 4.6, GL Compatibility renderer
- Language: GDScript with Thai UI text
- Main scene: `uid://d2rbfnaviwwmi` (MainGame.tscn)

## Directory Structure
- `Scripts/` - GDScript classes (subdirs: Home/, Map/, Market/, MiniGame/, Room/, StartMenu/, TimeSystem/, Resources/)
- `Scene/` - .tscn scene files (also contains legacy .scn files)
- `Assets/` - Textures, dialog files (.txt), sprites
- `Resources/Events/` - .tres event resources
- `Test/` - Test scenes and scripts

## Autoloaded Nodes
- `DialogScene` - Dialog system, text display
- `Global` - Character textures map, minigame registry
- `Market` - Market UI
- `MapPanel` - Map navigation
- `TimeSystem` - Time/date tracking (MORNING/NOON/EVENING, 30-day months)
- `EventManager` - Event system coordinator

## Dialog System
- Dialog files: `Assets/Chapter*.txt`, `Prolouge.txt`, etc.
- Format: `CharacterName,Dialog text` (comma-separated, no spaces in Thai text)
- Choices: `Choice: option1,option2` then `option1:` or `option2:` blocks
- Comments: Lines starting with `#`
- Load via: `EventManager.show_dialog(file_path, bg_name, chars_array)`

## Key Scripts
- `Scripts/player.gd` - WASD movement (WASD + arrow keys), collision
- `Scripts/dialog_scene.gd` - Full dialog engine
- `Scripts/EventManager.gd` - Event/signal hub
- `Scripts/TimeSystem/time_system.gd` - Time progression
- `Scripts/Resources/Event.gd` - Event resource class

## Build & Export
- Export preset: Windows Desktop x86_64 (`export_presets.cfg`)
- Output: `Build/BCK_demo.exe`
- **Export includes `*.txt` files** (dialog content must be exported)
- Ignore in git: `.godot/`, `Build/`, `*.zip`, `BakChangKhom`

## Physics Layers
- Layer 1: Player
- Layer 2: Wall
- Layer 3: Exit

## Coding Conventions
- GDScript with `@onready`, `@export`, `extends`
- Thai comments throughout codebase
- Character name strings in Thai (e.g., "ขม", "ยาย")
- Signals for inter-node communication
