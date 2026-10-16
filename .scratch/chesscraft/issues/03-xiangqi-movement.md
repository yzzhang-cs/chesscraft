# 03: Xiangqi movement with click-to-move

**What to build:** A player clicks a Xiangqi piece, sees its legal destinations highlighted, and moves by clicking one of them, with every piece honoring its movement rules (this movement also powers 大肥鱼的象棋).

**Blocked by:** 02 — Three armies, openings, piece rendering, and army-select menu

**Status:** ready-for-agent

- [x] General moves 1 orthogonal, confined to its palace.
- [x] Advisor moves 1 diagonal, confined to its palace.
- [x] Elephant moves 2 diagonal, blocked by its eye, and cannot cross the river.
- [x] Horse moves 2+1, blocked by its leg.
- [x] Chariot slides any orthogonal distance.
- [x] Cannon slides like a chariot and captures only by jumping exactly one screen.
- [x] Soldier moves 1 forward, and gains sideways movement only after crossing the river.
- [x] Clicking a piece highlights only legal destinations; clicking a highlighted point moves it.
- [x] A turn indicator shows whose turn it is (Side 1 first).
- [x] Headless tests assert legal moves for every piece type.

## Comments

Implemented at the spec's architecture seam (rules engine is pure GDScript, presentation is thin):

- `src/rules/moves.gd` — pure `Moves` module computing each Xiangqi piece's destinations: general/advisor palace-confined steps, elephant (2-diagonal, eye block, no river crossing), horse (2+1 with leg block), chariot slide, cannon (slides to empty, captures over exactly one screen), soldier (1 forward, sideways only after crossing the river). Shogi kinds report no moves yet (issue 05).
- `src/board/board.gd` — side-aware geometry helpers (`is_in_palace_for_side`, `is_on_own_side`, `has_crossed_river`); `is_in_palace` now delegates to the side-specific helper.
- `src/rules/match.gd` — public `place`/`clear` (test seam, reused by drops later), `legal_destinations(piece)`, and `move(piece, column, row)` which enforces turn, applies a capture (removes the enemy piece), and toggles `side_to_move`.
- `src/board/board_view.gd` — click-to-move: clicking a side-to-move piece selects it and highlights its legal destinations (dot for empty, ring for a capture); clicking a highlighted point applies the move and emits `move_made`.
- `src/main.gd` — a "Side N to move" turn indicator, refreshed on match start and after each move (Side 1 first).
- `tests/xiangqi_movement_test.gd` — headless test asserting legal moves for every piece type (palace/river/eye/leg/screen/river-cross), plus move application, turn alternation, and capture.

Verified: `--check-only` exits 0 on every touched script; `smoke_test`, `board_test`, `openings_test`, and `xiangqi_movement_test` all pass; the main scene boots headless (`--quit-after` exits 0).
