# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BakChangKhom — a Godot 4.7 2D game (GL Compatibility renderer). GDScript codebase with Thai-language dialog/UI text. Main scene: `uid://d2rbfnaviwwmi` (`Scene/MainGame.tscn`).

## Directory Structure

- `Scripts/` — GDScript classes, subdivided by area: `Home/`, `Map/`, `Market/`, `MiniGame/`, `Room/`, `StartMenu/`, `EventManager/`, `DialogSystem/`, `Resources/`
- `Scene/` — `.tscn` scene files (also contains legacy `.scn` files, e.g. `Scene/Computer_test.scn.depren`)
- `Assets/` — textures, sprites, and dialog `.txt` files
- `Resources/` — `.tres` resources (events, tutorial slides)
- `Test/` — manual test scenes/scripts, not part of any automated suite

## Key Scripts

- `Scripts/player.gd` — WASD + arrow-key movement, collision
- `Scripts/DialogSystem/dialog_scene.gd` — dialog engine (see Dialog System below)
- `Scripts/EventManager/event_manager.gd` — event/signal hub (see Event System below)
- `Scripts/EventManager/time_system.gd` — time progression (MORNING/NOON/EVENING, 30-day months)
- `Scripts/Resources/Event.gd` — `Event` resource class

## Commands

This project has no CLI build/test tooling (no npm/CMake/CI config) — all building, running, and testing happens through the Godot 4 editor or its CLI:

- **Run the game**: open the project in Godot 4.7 and press Play, or `godot --path . `
- **Run a specific scene**: `godot --path . res://Scene/<Scene>.tscn`
- **Export builds**: use presets defined in `export_presets.cfg` via Project > Export in the editor, or `godot --headless --export-release "Windows Desktop" Build/BCK_demo.exe`. A "Web" preset also exists, exporting to `../BakChangKhomExport/docs/BakChangKhom.html`.
- There is no automated test suite; `Test/` contains manual test scenes/scripts (e.g. `Test/test.tscn`) opened and run directly in the editor.

## Autoloaded Singletons (project.godot)

- `Global` (`Scripts/global.gd`) — character texture map (`_CharacterMap`), minigame registry (`MiniGames`), and global flags (`dialogShown`, `in_minigame`, `on_start`)
- `EventManager` (`Scripts/EventManager/event_manager.gd`) — event/signal hub; owns `QuestBoard`, `TimeSystem`, and `Tutorial` as child nodes (not separate autoloads) and exposes them via `@onready` references
- `DialogScene` (`Scene/Dialog_Scene.tscn` / `Scripts/DialogSystem/dialog_scene.gd`) — dialog engine and text display
- `Market` (`Scene/Location/Market.tscn`) — market UI
- `MapPanel` (`Scene/map.tscn`) — map navigation

Cross-system communication runs through signals on these autoloads rather than direct references — e.g. `EventManager.showDialogEvent` is connected to by `DialogScene`, and `EventManager.sendUpdatedEvent` notifies quest UI.

## Event System

- Events are `Resource` classes (`class_name Event`, `Scripts/Resources/Event.gd`) holding an ordered `Tasks: Array[String]`; `next_step()`/`get_task()` advance/read the current task, emitting `on_task_update`.
- `EventManager.eventMap: Dictionary[EventID, Event]` maps an `EventID` enum (currently just `NONE`, `MAIN`) to `Event` resources; `update_event(id)` advances the active event and pushes the new task to `QuestBoard`.
- `EventManager.show_dialog(title, file_path, bg_name, chars)` is the entry point scripts call to trigger dialog — it emits `showDialogEvent`, which `DialogScene` is listening for.

## Dialog System

- Dialog scripts live under `Scripts/DialogSystem/`; source files are plain text under `Assets/Chapter*.txt`, `Assets/Prolouge.txt`, `Assets/Epilogue.txt`, etc.
- Format: `CharacterName,Dialog text` (comma-separated; no spaces around the comma in Thai text).
- Choices: a line `Choice: option1,option2` followed by `option1:` and `option2:` blocks containing the branch's dialog lines.
- Comment lines start with `#`.
- `dialog_stack`/`index_stack` in `dialog_scene.gd` track nested choice branches; `DialogDict` holds parsed lines keyed by `"dialog"`/`"choice"`.
- **Export presets bundle `*.txt` via `include_filter="*.txt"`** — new dialog files must stay as `.txt` under `Assets/` to be included in exports.

## Shared Constants

`Scripts/constant.gd` (`class_name Constant`) centralizes `res://` asset paths (scenes, dialog files, sprite sheets) as constants — prefer adding new frequently-referenced paths here over hardcoding string literals in scripts.

## Physics Layers

- Layer 1: Player
- Layer 2: Wall
- Layer 3: Exit

## Assets & Git LFS

- `*.png` and `*.jpg` are tracked via Git LFS (`.gitattributes`).
- `.godot/`, `/Build/*`, `/BakChangKhom`, and `**/*.zip` are gitignored — don't commit editor cache or build output.

## Coding Conventions

- GDScript with `@onready`, `@export`, `extends`; `class_name` used for reusable types (`Event`, `Constant`, `CharacterSprite`, etc.).
- Thai is used for in-game character names/strings (e.g. `"ขม"`, `"ยาย"`) and for explanatory comments — match this when touching dialog/content code.
- Inter-node communication favors signals over direct method calls across systems.
