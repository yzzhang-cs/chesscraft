# 05: Shogi movement

**What to build:** Shogi pieces move by their standard patterns, so a Shogi side can play its pieces correctly.

**Blocked by:** 02 — Three armies, openings, piece rendering, and army-select menu

**Status:** ready-for-agent

- [x] King moves 1 step in any of 8 directions.
- [x] Rook slides any orthogonal distance.
- [x] Bishop slides any diagonal distance.
- [x] Gold moves 1 step forward/back/left/right plus the two forward-diagonals.
- [x] Silver moves 1 step forward plus the four diagonals.
- [x] Knight jumps 2 forward + 1 sideways.
- [x] Lance slides any forward distance.
- [x] Pawn moves 1 step forward.
- [x] Headless tests assert legal moves for every Shogi piece.

## Comments

Implemented at the spec's architecture seam (rules engine is pure GDScript, presentation is thin):

- `src/rules/moves.gd` — the eight Shogi movement patterns as pure functions: king (1 step, 8 directions), rook (orthogonal slide), bishop (diagonal slide), gold (6 steps: forward/back/left/right plus the two forward-diagonals), silver (5 steps: forward plus the four diagonals), knight (jumps 2 forward + 1 sideways, no leg block), lance (forward slide), and pawn (1 forward). "Forward" is toward the opponent via a `_forward(side)` helper (+1 row for Side 1, -1 for Side 2). A shared `_steps` single-step helper and the existing `_slide` cover the patterns, which issue 06's promoted forms reuse.
- `tests/shogi_movement_test.gd` — headless test asserting the exact destination set for every Shogi piece on both sides, plus slide-blocking by a friendly piece and the knight's jump over intervening pieces.

Verified: `--check-only` exits 0 on every touched script; `smoke_test`, `board_test`, `openings_test`, `xiangqi_movement_test`, `check_win_test`, `shogi_movement_test`, and `shogi_promotion_test` all pass; the main scene boots headless (`--quit-after` exits 0).
