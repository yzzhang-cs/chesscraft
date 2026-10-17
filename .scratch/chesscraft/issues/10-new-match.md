# 10: New match (return to the army-select menu)

**What to build:** A player can abandon the current match and return to the army-select menu to start a fresh match, choosing each side's army anew.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] A New match control is available during the match and after it ends.
- [x] Choosing it returns to the army-select menu with the Side 1 and Side 2 army pickers.
- [x] Starting from that menu begins a fresh match: the board shows the chosen openings, Side 1 moves first, and there is no undo history or win banner.
- [x] The previous board, undo history, and win banner are discarded.

## Comments

Implemented at the spec's architecture seam (rules engine is pure GDScript, presentation is thin):

- `src/main.gd` — the army-select menu is now hidden (`hide()`) instead of freed when a match starts. A New match button tears down the in-match controls (turn/win labels and the Undo/Restart/New match buttons), discards the match, and shows the menu again with both army pickers. Starting a fresh match from it builds a brand-new `Match`, so there is no undo history or win banner.
- `src/board/board_view.gd` — `clear_selection()` now cancels a pending promotion, so abandoning a match while the promote/decline prompt is open leaves no stale state.
- `src/rules/match.gd` — `restart()` (issue 09) is shared by Restart; New match discards the whole match object.

Verified: `--check-only` exits 0 on every touched script; `smoke_test`, `board_test`, `openings_test`, `xiangqi_movement_test`, `shogi_movement_test`, `shogi_promotion_test`, `shogi_drops_hand_test`, `check_win_test`, `cross_game_test`, and `restart_test` all pass; the main scene boots headless (`--quit-after` exits 0).
