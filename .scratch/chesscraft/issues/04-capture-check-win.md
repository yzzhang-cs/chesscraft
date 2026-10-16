# 04: Capture, check, and win detection with undo

**What to build:** Captures remove pieces, check is detected, a match ends in checkmate or by a side having no legal move, a win banner shows the result, and the player can undo the last move.

**Blocked by:** 03 — Xiangqi movement with click-to-move

**Status:** ready-for-agent

- [x] Moving onto an enemy piece captures it (removed from play for Xiangqi).
- [x] Check is detected when a general is threatened.
- [x] Checkmate ends the match with the checkmated side losing.
- [x] A side with no legal move (and not in check) loses.
- [x] A win banner shows the result.
- [x] Undo reverts the last move and restores any captured piece.
- [x] Headless tests assert check, checkmate, and no-legal-move losses.

## Comments

Implemented at the spec's architecture seam (rules engine is pure GDScript, presentation is thin):

- `src/rules/match.gd` — check and win detection plus undo, all on the existing public seam. `king_of(side)` finds a side's general/king; `is_in_check(side)` reports when it is threatened; `has_any_legal_move(side)` reports whether a side has any move that does not leave its own king in check. `legal_destinations(piece)` now filters moves that leave the mover's own king in check and never offers a king as a capture target. `winner` (0/1/2) and `end_reason` ("checkmate"/"no_legal_move") are derived from the current position; `move()` records each move and `undo()` reverts the last one, restoring any captured piece and the turn.
- `src/board/board_view.gd` — ignores clicks once the match is over; `clear_selection()` supports undo.
- `src/main.gd` — a win banner (checkmate vs. no-legal-move), a "check!" flag on the turn indicator, and an Undo button.
- `tests/check_win_test.gd` — headless test asserting check detection, checkmate, no-legal-move losses, the never-capture-a-king rule, self-check filtering, and undo restore.

Verified: `--check-only` exits 0 on every touched script; `smoke_test`, `board_test`, `openings_test`, `xiangqi_movement_test`, and `check_win_test` all pass; the main scene boots headless (`--quit-after` exits 0).
