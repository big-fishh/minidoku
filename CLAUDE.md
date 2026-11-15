# minidoku

A daily Mini Sudoku game (6x6) built in Godot 4.7, exported for the web and embedded in my games website. A FastAPI backend stores puzzles and serves the board for the current date. This is a learning project.

## How to work with me

- **Backend and website code: explain, don't write.** I'm doing the server and site coding myself to learn. When I ask for help in `backend/` (or the future frontend), explain the concept, point at the problem, or sketch the approach, and let me write the code. Only write it for me if I explicitly ask.
- **Godot code (`game/`)**: writing and editing code directly is fine.
- I'm an experienced Python developer but newer to Godot, web backends, and web frontends. Skip Python basics; do explain Godot and web conventions.
- Keep changes small and focused. Don't refactor or reorganize things I didn't ask about.

## Repo layout

```
minidoku/
├── game/        # Godot project (project.godot, assets, scenes, scripts)
├── backend/     # FastAPI server: stores puzzles + solutions, serves board by date
├── reference/   # My own reference material. Read-only: don't edit or delete.
└── (frontend/)  # Planned, not created yet
```

Run Godot commands from `game/` (that's where `project.godot` lives), not the repo root.

## Game rules and board format

- 6x6 grid, digits 1–6.
- Boxes are **3 cells wide by 2 cells tall**, so the board is 2 boxes across and 3 boxes down.
- Each row, column, and box contains 1–6 exactly once.
- Boards travel as JSON strings. `0` means an empty cell. The solution is the same shape, fully filled.
- Puzzles come from the `py-sudoku` package. I'm not writing my own generator.

## Architecture

- The game does **not** bundle boards. It fetches the day's puzzle from the backend over HTTP.
- The backend picks which board to serve based on the date (it's a daily game).
- Normal play: the solution is sent with the puzzle and checked client-side. Casual cheating is not a concern.
- Contest events (planned): the solution is *not* sent. The game submits the finished board and the server validates it.
- Planned: player statistics for a leaderboard on the site.
- The web export is embedded in a page as an HTML element, so it has to work on both phone and desktop. Keep touch input and small screens in mind for any UI work.

## UI

- Tool buttons: undo, erase, notes, hint.
- Game background is `#f1ede5`.
- The board is a single color that changes daily, cycling through seven palettes: green, blue, orange, pink, purple, teal, yellow.
- The game icon uses the green palette only. Icon files live in `game/assets/icons`.
- **`reference/constants.gd` is the source of truth for colors.** Read it before touching anything color-related, and don't invent hex values. Despite the extension it's a notes file, not runnable GDScript (only the first few lines are real `var` declarations).
- Each palette defines the same five roles: entry color, selected entry color / selection border, selected cell, same-number highlight, and row / col / box highlight. Any code that handles one palette should handle all seven the same way.
- Shared colors (given digits, errors, notes, board frame and thick box lines) are in that file too and don't change with the daily palette.
- `#e0f6e3` (old number-button green) is no longer used. Don't reintroduce it.

## Commands

<!-- TODO: fill these in with what I actually use -->

```bash
# Backend (from backend/)
# uvicorn <module>:app --reload

# Godot web export (from game/)
# godot --headless --export-release "Web" <output path>
```

## Godot conventions

- GDScript, Godot 4.x syntax (typed where practical, `@export`, `@onready`, `signal_name.connect(...)`).
- Don't hand-edit `.tscn`, `.tres`, or `.import` files unless I ask. Tell me what to change in the editor instead.
- Never commit `.godot/` or export output.
