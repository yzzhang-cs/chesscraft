# 07: Shogi drops and the hand

**What to build:** Shogi captures enter the player's hand, a hand tray renders the held pieces, held pieces drop onto empty points, and drop-legality is enforced.

**Blocked by:** 06 — Shogi promotion

**Status:** ready-for-agent

- [x] A Shogi capture moves the captured piece into the captor's hand, unpromoted.
- [x] A hand tray shows the Shogi player's held pieces.
- [x] Clicking a hand piece and then an empty point drops it.
- [x] Drops are always unpromoted.
- [x] A pawn or lance cannot drop onto the last rank; a knight cannot drop onto the last two ranks.
- [x] Headless tests assert capture-to-hand, legal drops, and illegal drops.

## Comments

Implemented at the spec's architecture seam (rules engine is pure GDScript, presentation is thin):

- `src/rules/match.gd` — a per-side hand (`hand1`/`hand2` with `hand_of(side)`). A capture by a Shogi side (`_captures_into_hand`, i.e. `army_of(side) == SHOGI`) routes the captured piece into the captor's hand via `_add_to_hand` (unpromoted, re-owned, off-board at column/row 0); a Xiangqi/大肥鱼 side still removes captures permanently. The drop API is `can_drop(piece, column, row)` (empty point, pawn/lance not on the enemy back rank, knight not on the enemy's last two ranks), `legal_drop_destinations(piece)` (drop rules plus a no-self-check filter), and `drop(piece, column, row)`. `undo()` reverts both a capture-into-hand (restoring the piece's original side, point, and promoted state) and a drop (returning the piece to hand). `has_any_legal_move(side)` now also counts legal drops, so check/win detection sees drop responses.
- `src/board/board_view.gd` — a hand tray drawn below the board showing the side-to-move's held pieces as pentagon glyph tokens; clicking a token selects it and highlights its drop destinations, clicking an empty highlighted point drops it. Window height grew (704→780) to fit the tray, and the undo button moved down accordingly (`src/main.gd`).
- `tests/shogi_drops_hand_test.gd` — headless test asserting capture-into-hand (re-owned and off-board), capture unpromotes a promoted piece, legal drops onto an empty point, illegal drops (occupied point, pawn/lance last rank, knight last two ranks), and undo of both capture and drop.

Verified: `--check-only` exits 0 on every touched script; `smoke_test`, `board_test`, `openings_test`, `xiangqi_movement_test`, `check_win_test`, `shogi_movement_test`, `shogi_promotion_test`, and `shogi_drops_hand_test` all pass; the main scene boots headless (`--quit-after` exits 0).

The cross-game dropped-兵 half-board restriction and freed 相/士 rule are issue 08, not here.
