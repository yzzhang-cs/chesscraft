# 01: Scaffold the project and render the empty board

**What to build:** Launching the game shows the empty 9-column × 10-row board, drawn with the river between rows 5 and 6 and both 3×3 palaces marked, so players can read the board like a real Xiangqi board.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] The project has a main scene that boots (headless and in the editor).
- [x] The board model exposes 9 columns × 10 rows of points, the river boundary (between rows 5 and 6), and both palaces (columns 4–6, rows 1–3 and 8–10).
- [x] The board renders with grid lines, the river, and both palaces visibly marked.
- [x] A headless test asserts the board geometry (9×10, river, palaces).

## Comments

Implemented. The board is split at the spec's architecture seam:

- `src/board/board.gd` — pure `Board` model (`RefCounted`, no Node/scene): 9×10, river (rows 5/6), both palaces.
- `src/board/board_view.gd` — thin `BoardView` (`Node2D`) that draws grid, river band (inner verticals broken at the river, as on a real board), and palace diagonals.
- `src/main.gd` + `scenes/main.tscn` — main scene; `run/main_scene` and a 640×704 viewport wired in `project.godot`.
- `tests/board_test.gd` — headless `SceneTree` test asserting the geometry.

Verified: `--check-only` exits 0 on every touched script; `tests/board_test.gd` and `tests/smoke_test.gd` pass; the main scene boots headless (`--quit-after` exits 0); a GL render capture was pixel-checked for grid/river/palace colors.
