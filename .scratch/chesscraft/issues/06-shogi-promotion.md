# 06: Shogi promotion

**What to build:** Shogi pieces promote in the promotion zone, an optional promotion prompts the player, stranded pieces are forced to promote, and captured promoted pieces revert in hand.

**Blocked by:** 05 — Shogi movement

**Status:** ready-for-agent

- [x] A move that begins or ends in the promotion zone (the enemy's three back ranks) may promote.
- [x] An optional promotion shows an accept/decline prompt.
- [x] A pawn or lance on the last rank, or a knight on the last two ranks, is forced to promote.
- [x] Promoted movement: 龍王 (rook + 1 diagonal), 龍馬 (bishop + 1 orthogonal), 成銀/成桂/成香/と (gold move).
- [x] A captured promoted piece reverts to its unpromoted form in hand.
- [x] Headless tests assert optional and mandatory promotion.

## Comments

Implemented at the spec's architecture seam (rules engine is pure GDScript, presentation is thin):

- `src/rules/piece.gd` — a `promoted` flag plus `promoted_glyph(kind)` (龍王/龍馬/成銀/成桂/成香/と), `is_promotable(kind)` (rook/bishop/silver/knight/lance/pawn only), and `unpromote()` (the reversion a captured promoted piece uses; issue 07 wires it into the capture-into-hand path). `glyph()` returns the promoted glyph when promoted.
- `src/board/board.gd` — promotion-zone geometry: `is_in_promotion_zone(side, row)` (the enemy's three back ranks), `enemy_back_rank(side)`, and `is_enemy_last_two_ranks(side, row)`.
- `src/rules/match.gd` — `can_promote(piece, row)` (optional: a move beginning or ending in the zone) and `must_promote(piece, row)` (forced: pawn/lance on the last rank, knight on the last two ranks). `move(piece, column, row, promote)` applies promotion when requested or forced, and `undo()` reverts it via a per-move `was_promoted` record.
- `src/rules/moves.gd` — promoted movement: 龍王 = rook + 1 diagonal, 龍馬 = bishop + 1 orthogonal, and 成銀/成桂/成香/と all move as a gold.
- `src/board/board_view.gd` — an accept/decline `ConfirmationDialog` prompts on an optional promotion (forced promotions skip the prompt); a single-character glyph (と) is centered.
- `tests/shogi_promotion_test.gd` — headless test asserting optional vs. forced promotion, promoted movement, promotion application and undo, and the `unpromote()` reversion primitive.

Verified: `--check-only` exits 0 on every touched script; `smoke_test`, `board_test`, `openings_test`, `xiangqi_movement_test`, `check_win_test`, `shogi_movement_test`, and `shogi_promotion_test` all pass; the main scene boots headless (`--quit-after` exits 0).
