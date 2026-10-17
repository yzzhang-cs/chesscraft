# 02: Split the hand tray into two always-visible per-side trays

**What to build:** Side 1's captured pieces always render in a tray at the bottom and Side 2's always render in a tray at the top, both visible regardless of whose turn it is; tokens point toward the opponent per side; only the side-to-move's own tray is clickable for a drop, while the opponent's tray is display-only and its clicks are ignored; the trays sit clear of the board's clickable points.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] Side 1's hand always renders in the bottom tray and Side 2's always renders in the top tray, regardless of turn.
- [x] An empty hand (or a non-Shogi side) draws no tokens.
- [x] Hand tokens point up for Side 1 and down for Side 2.
- [x] Only the side-to-move's own tray is clickable; drops still work.
- [x] The opponent's tray is display-only; clicking it does nothing and does not select a board piece.
- [x] Trays do not swallow clicks on the board's top or bottom rows.
- [x] All existing headless tests pass; touched scripts pass `--check-only`; the main scene boots headless.

## Comments

Implemented in commit `fbbf685`. `_draw_hand` now renders both trays (Side 1 at `HAND_Y_BOTTOM`, Side 2 at `HAND_Y_TOP`), each token oriented per side; `_hand_token_at` returns only the side-to-move's tray token while `_over_any_hand_token` swallows clicks on the display-only opponent tray; `_nearest_point` was corrected to invert y with `TOP_MARGIN` so board clicks still land.

Verified: `--check-only` exits 0; the full headless suite passes (10/10); the main scene boots headless.
