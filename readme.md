# ChessCraft

A local two-sided board game built with **Godot 4.7**. Each side plays with the
Chinese **Xiangqi**, the Japanese **Shogi**, or **大肥鱼的象棋** (a Xiangqi
variant that only changes the opening placement) — and the two sides can field
*different* armies against each other in a **cross-game match**.

The rules engine is pure GDScript (no scene dependency), so it runs headlessly
in tests and is ready to be reused behind an online multiplayer layer later.

## Features

- **Three armies, independently chosen per side** — Xiangqi, Shogi, and 大肥鱼的象棋.
- **Cross-game matches** where different armies face each other on one shared
  9-column × 10-row board.
- **Faithful per-army rules**:
  - Xiangqi: palace confinement, the river, elephant eye-blocks, horse leg-blocks,
    cannon screen-jump captures, soldier river promotion.
  - Shogi: promotion (with an optional-promotion prompt), captured pieces entering
    a **hand**, drops, and unpromotion of captured promoted pieces.
- **Local play** against another human (hotseat), against a **greedy AI**, or
  **AI-vs-AI** — each side's controller is chosen in the setup menu.
- **Controls**: turn indicator, check flag, win banner, Undo, Restart, and
  New match.
- **Clean separation** between a headless-testable rules engine and the 2D
  presentation layer.

## Requirements

- **Godot 4.7.2** (`4.7.2.stable.official.ed1daf0bf`). The engine version is
  pinned in [`project.godot`](project.godot).

The game uses the Forward Plus renderer and the 2D scene system; no export
templates or third-party addons are required to run from source.

## Running the game

Open the project in the Godot editor and press **Play**, or run it headless from
the command line:

```powershell
# Open the editor (GUI)
godot --path .

# Run the game headless for 120 seconds
godot_console --headless --path . --quit-after 120
```

The main scene is `res://scenes/main.tscn` (already set as `run/main_scene` in
[`project.godot`](project.godot)).

## Testing

Tests are headless GDScript scripts under [`tests/`](tests/). Run one with:

```powershell
godot_console --headless --path . --script res://tests/smoke_test.gd
```

[`tests/smoke_test.gd`](tests/smoke_test.gd) is the environment gate: it asserts
that `res://` reads and `user://` writes work, prints `smoke_test=PASS`, and
exits 0.

Other test files cover board setup, movement, check/checkmate/win, Shogi
promotion/drops/hand, cross-game rules, openings, controllers (player & AI), and
restart.

> **Note for sandboxed/CI runs:** Godot writes `user://` to
> `%APPDATA%\Godot\app_userdata\<project>`, which may be outside a writable
> workspace. Redirect the data directories for tests that touch `user://`:
>
> ```powershell
> $env:APPDATA      = "$PWD/.godot-userdata/AppData/Roaming"
> $env:LOCALAPPDATA = "$PWD/.godot-userdata/AppData/Local"
> godot_console --headless --path . --script res://tests/smoke_test.gd
> ```

## Project structure

```
.
├── project.godot          # Project config, main scene, window size
├── CONTEXT.md             # Domain glossary (the vocabulary to use)
├── docs/
│   ├── game-rules.md      # Authoritative rules spec for the build
│   └── agents/            # Agent-facing workflow docs (issue tracker, triage, domain)
├── scenes/
│   └── main.tscn          # Main scene: board view + menu view
├── src/
│   ├── main.gd            # Match orchestration, status, undo/restart/new-match
│   ├── board/             # Board model and 2D rendering
│   ├── controller/        # PlayerController, AIController (shared Controller seam)
│   ├── rules/             # Pure rules engine: Match, Piece, Army, moves, openings
│   └── ui/                # Army-select menu view
├── tests/                 # Headless GDScript test suites
└── .scratch/              # Issue tracker: specs and issues as markdown
```

The rules engine (`src/rules/`) depends on no scenes or nodes — it models the
match, pieces, armies, moves, and openings as plain `RefCounted` objects, so it
is fully testable headlessly.

## Rules at a glance

The authoritative spec is [`docs/game-rules.md`](docs/game-rules.md). In short:

- The **board** is a 9 × 10 grid of points; Side 1 sits at the bottom and always
  moves first.
- Each side's pieces move and capture by its army's rules. A **Shogi** capture
  moves the piece into the captor's **hand** (for later drops); a **Xiangqi**
  capture removes it from play permanently.
- Shogi pieces **promote** in the enemy's three back ranks; Xiangqi pieces never
  promote, even when held and dropped by a Shogi side.
- A king/general in check with no legal escape is **checkmate**; a side with no
  legal move (and not in check) also **loses** (unified stalemate rule).

See the deferred-items list in the rules doc for what is intentionally out of
scope for now (e.g. Shogi `nifu`/`uchifuzume`, repetition rules, online play).

## Domain vocabulary

The project has a precise glossary in [`CONTEXT.md`](CONTEXT.md) that defines
terms like **match**, **side**, **army**, **point**, **hand**, **drop**, and
**freed piece**. Use that vocabulary when naming things in code, issues, and
tests — several common synonyms (e.g. "team", "square", "captured tray") are
deliberately avoided.

## Development notes

- **Import assets** after adding files: `godot_console --headless --path . --import`
- **Parse-check one script**: `godot_console --headless --path . --check-only --script res://path/to.gd`
- `.godot/` and `.godot-userdata/` are generated and git-ignored; delete `.godot/`
  and re-run `--import` if imports look stale.
- Export templates are not installed, so `--export-release` / `--export-debug`
  fail until templates are installed from the editor
  (`Editor > Manage Export Templates`).
- A "Failed to read the root certificate store" warning on sandboxed runs is
  harmless unless the game makes HTTP requests.
