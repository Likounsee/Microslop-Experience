# Microslop Experience

**Microslop Experience** is a satirical desktop simulation planned for commercial release on Steam. You try to use a familiar-looking computer while ads, unwanted recommendations, updates, and an overly enthusiastic AI assistant get in the way.

> The game simulates its own desktop. It does not modify the player's real Windows settings or access personal files.

## Current status

**Prototype stage — P0 in progress.** The repository now contains a Windows 11-inspired desktop shell using the wallpaper supplied in `assets/wallpaper.jpg`, a floating translucent centered taskbar, a Start menu with a pinned-app grid, a quick-settings flyout with working in-game volume control, rounded draggable app windows with minimize/maximize/close controls, interactive simulated applications, timed notifications, a three-step tutorial mission, locally saved campaign progress, and persistent display, audio, and FPS settings. Notification count and open windows are bounded to avoid unbounded UI growth.

## Direction

The game combines three elements:

- **A fake desktop OS:** a convincing desktop shell that acts as the stage, not the main goal.
- **A narrative campaign:** the player starts with ordinary setup tasks, notices suspicious update notes, discovers the internal ORCHID programme through the AI assistant, and finds evidence that interruptions are deliberately engineered to maximize engagement.
- **A systemic comedy layer:** ads, update prompts, AI suggestions, and events that interrupt the player at increasingly revealing moments.

### Story chapter 1 — ORCHID

Chapter 1 is an investigation told through the simulated desktop: open Start, inspect the apparently empty Documents folder, review the update stuck at 99%, question an evasive Microslop AI, then search for ORCHID. The browser now opens a full internal report describing predictive interruptions, sponsored-result diversion, and the rebranding of engagement metrics as user comfort. A new investigation casebook contains eight evidence pieces spanning notifications, indexing, update notes, AI dialogue, sponsored results, biased surveys, and an A/B test; the player opens each piece, tracks collected evidence across sessions, and can reconstruct a provisional timeline after examining at least four. The player can publish the report or keep a local copy; that ending choice is saved separately in the existing campaign file. The AI now deflects before explaining the clue, and accepting recommendations remains a satirical detour rather than a softlock. The full narrative, evidence chain, and remaining implementation work are tracked in [`docs/ORCHID_CAMPAIGN.md`](docs/ORCHID_CAMPAIGN.md).

### Chapter 2 — Separate DLC: your home OS

The second chapter is planned as a separately distributed DLC, not as a required continuation bundled into the base game. It will focus on the creator's own operating system, designed to replace Windows. Its name, interface, capabilities, lore, and missions will be defined only after the creator supplies the OS files and documentation; the project will not invent technical claims about it. The base game remains complete and playable without this DLC. The in-game teaser currently marks Chapter 2 as in preparation.

The DLC architecture and outstanding requirements are tracked in [`dlc/chapter-2/README.md`](dlc/chapter-2/README.md).

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
- `Esc`: close the Start menu and quick settings

## Roadmap

| Phase | Scope | Status |
|---|---|---|
| P0 | Project foundation, desktop shell, window system | In progress |
| P1 | Fake OS applications and persistent display/audio/performance settings | Partly prototyped |
| P2 | Campaign, missions, ads, update events and progression | ORCHID report, two saved endings, and eight-piece evidence casebook implemented; narrative QA and richer systemic interruptions remain |
| P3 | Audio, animation, accessibility, saves and polish | Planned |
| P4 | Steam store page, builds, QA and release | Planned |

Percentages will be reported as estimates based on verified implementation and tests, not as claims that unimplemented work is complete.

## Development principles

- Never access or alter the player's real personal files or Windows settings.
- Keep simulated OS behaviour isolated inside the game.
- Save game settings under Godot's `user://` path.
- Prefer small, testable systems over one giant script.
- Do not claim a test or build passed unless it was actually run.


### Windows 11-inspired visual pass

The desktop UI uses a consistent light acrylic-inspired palette, more pronounced rounded surfaces and shadows, a narrower centered taskbar, and matching Start, Quick Settings, notification, mission, and app-window surfaces. App windows now restore their previous position and size when unmaximized, and dragging keeps enough of the title bar on-screen to recover a window. These are in-game visual approximations, not native Windows acrylic or blur effects.


### Desktop interaction polish

The Start menu now has a Windows 11-inspired pinned-app header, a distinct recommended/sponsored card, and a profile/power row. The system-tray clock is presented on a compact two-line layout. App windows raise when clicked and support double-clicking the title bar to maximize or restore. Power options remain simulated in-game and never affect the host operating system.


### Version du moteur

Le projet et la CI ciblent Godot **4.7.2-stable**, dernière version stable au moment de cette mise à jour. Godot 4.8 étant encore en bêta, il n'est pas utilisé sur la branche de production. La CI importe/vérifie le projet et lance la scène principale en mode headless.
