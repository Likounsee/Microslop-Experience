# Microslop Experience

**Microslop Experience** is a satirical desktop simulation planned for commercial release on Steam. You try to use a familiar-looking computer while ads, unwanted recommendations, updates, and an overly enthusiastic AI assistant get in the way.

> The game simulates its own desktop. It does not modify the player's real Windows settings or access personal files.

## Current status

**Prototype stage — P0 in progress.** The repository now contains a Windows 11-inspired desktop shell with a procedural blue bloom wallpaper, a translucent centered taskbar and Start menu, rounded draggable app windows with minimize/maximize/close controls, interactive simulated applications, timed notifications, a three-step tutorial mission, locally saved campaign progress, and persistent display, audio, and FPS settings.

## Direction

The game combines three elements:

- **A fake desktop OS:** Windows 11-inspired wallpaper, translucent taskbar, centered Start menu, rounded draggable windows, simulated quick settings, files and settings.
- **A campaign:** short missions that gradually introduce new interruptions and mechanics.
- **A systemic comedy layer:** ads, update prompts, AI suggestions, and events that can interact.

## Technology

- Godot 4.4+
- GDScript
- Windows-first desktop release
- All desktop behaviour is simulated inside the game

## Run locally

1. Install the stable Godot 4.x standard build from <https://godotengine.org/download/windows/>.
2. Open `project.godot` in Godot Project Manager.
3. Press **F6** to run the current scene or **F5** to run the project.

Keyboard shortcuts in the prototype:
- `F1`: open Settings
- `F2`: advance the prototype mission (progress is saved locally)
- `Esc`: close the Start menu

## Roadmap

| Phase | Scope | Status |
|---|---|---|
| P0 | Project foundation, desktop shell, window system | In progress |
| P1 | Fake OS applications and persistent display/audio/performance settings | Partly prototyped |
| P2 | Campaign, missions, ads, update events and progression | Initial tutorial and timed event prototypes |
| P3 | Audio, animation, accessibility, saves and polish | Planned |
| P4 | Steam store page, builds, QA and release | Planned |

Percentages will be reported as estimates based on verified implementation and tests, not as claims that unimplemented work is complete.

## Development principles

- Never access or alter the player's real personal files or Windows settings.
- Keep simulated OS behaviour isolated inside the game.
- Save game settings under Godot's `user://` path.
- Prefer small, testable systems over one giant script.
- Do not claim a test or build passed unless it was actually run.
