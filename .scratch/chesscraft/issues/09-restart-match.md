# 09: Restart the match

**What to build:** A player can restart the current match at any time — the board returns to the opening layout for the two chosen armies, Side 1 moves first, and any undo history and win banner clear.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] A Restart control is available during the match and after it ends.
- [x] Restart returns the board to the opening position for the same two armies and restores any captured pieces.
- [x] After restart, Side 1 moves first, the turn indicator shows Side 1, and the win banner is cleared.
- [x] After restart, the undo control has nothing to undo (the pre-restart move history is gone).
- [x] Headless tests assert the restored opening layout, Side 1 to move, and an empty undo history.

## Comments

Implemented at the spec's architecture seam (rules engine is pure GDScript, presentation is thin):

- `src/rules/match.gd` — `restart()` resets a match to its opening: it clears the board, hands, and undo history via the existing `clear()`, then re-places both armies' opening pieces through a `_place_opening()` helper extracted from `_init`. Side 1 moves first and the winner/end state clear with the position.
- `src/board/board_view.gd` — `clear_selection()` now also cancels a pending promotion (`cancel_promotion()`), so a restart while the promote/decline prompt is open cannot leave a stale answer that fires against the reset position.
- `src/main.gd` — a Restart button resets the match and a New match button returns to the army-select menu; both go through a shared `_refresh_board()` that clears selection, refreshes status, and repaints.
- `tests/restart_test.gd` — headless test asserting restart restores the opening layout for all three armies and both cross-game directions, empties hands and undo history, returns Side 1 to move, and clears a finished (won) match.

Verified: `--check-only` exits 0 on every touched script; `smoke_test`, `board_test`, `openings_test`, `xiangqi_movement_test`, `shogi_movement_test`, `shogi_promotion_test`, `shogi_drops_hand_test`, `check_win_test`, `cross_game_test`, and `restart_test` all pass; the main scene boots headless (`--quit-after` exits 0).
