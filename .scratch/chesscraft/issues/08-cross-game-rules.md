# 08: Cross-game rules

**What to build:** Cross-army matches work: a Shogi side capturing a Xiangqi piece puts it in hand, dropped 相/士 are freed, dropped 兵 go only behind the river, and dropped Xiangqi pieces render as pentagons.

**Blocked by:** 04 — Capture, check, and win detection with undo; 07 — Shogi drops and the hand

**Status:** ready-for-agent

- [x] A Shogi side capturing a Xiangqi/大肥鱼 piece puts it in the Shogi hand; it remains droppable and keeps Xiangqi movement.
- [x] A Xiangqi/大肥鱼 side capturing a Shogi piece removes it permanently.
- [x] A dropped 相 or 士 is freed: advisor moves 1 diagonal anywhere; elephant moves 2 diagonal anywhere with the eye still applying and may cross the river.
- [x] A dropped 兵 goes only on the dropper's own half (behind the river) and starts with its crossed-river flag false.
- [x] A dropped Xiangqi piece renders as a pentagon (ownership shown by orientation).
- [x] Headless tests assert cross-game capture, freed pieces, and the 兵 drop restriction.

## Comments

Implemented at the spec's architecture seam (rules engine is pure GDScript, presentation is thin):

- Cross-game capture already flowed through `Match._captures_into_hand` (a Shogi side routes a capture into its hand; a Xiangqi/大肥鱼 side removes it permanently) and `Match._add_to_hand` (re-owned, off-board, unpromoted) while preserving the piece's intrinsic `army`, so a captured Xiangqi piece stays droppable with Xiangqi movement. The new test pins that down.
- `src/rules/moves.gd` — the freed 相/士 rule. `_is_freed(board, piece)` is true when a Xiangqi-family piece is owned by a Shogi side (its intrinsic `army` differs from its owner's army). A freed 士 steps one diagonal anywhere (no palace); a freed 相 steps two diagonals anywhere, may cross the river, and keeps its eye block. Deriving freedness from the piece's army vs. the owner's army means no extra state to keep in sync with undo.
- `src/rules/match.gd` — `can_drop` now rejects a 兵 dropped onto the far half (`Board.is_on_own_side`), so a dropped 兵 stays behind the river; its crossed-river state is position-derived and therefore starts false.
- `src/board/board_view.gd` — already drew every piece from its owner's army (`match.army_of(piece.side) == SHOGI` → pentagon), so a dropped Xiangqi piece renders as a pentagon pointing at the opponent; no change needed.
- `tests/cross_game_test.gd` — headless test asserting Shogi-captures-Xiangqi into hand (kept army, re-owned, off-board), Xiangqi-captures-Shogi permanent removal, the 大肥鱼 army path (a captured 相 keeps its army and is freed on drop), the 馬 leg block (Xiangqi movement survives a drop), freed 士/相 (anywhere, river crossing, eye still blocks), and the 兵 half-board drop restriction plus its false crossed-river start. Test setup drives the public API (capture via `move`, turn via a real move, drop via `drop`), matching the existing drop test.

Verified: `--check-only` exits 0 on `moves.gd`, `match.gd`, and `cross_game_test.gd`; `smoke_test`, `board_test`, `openings_test`, `xiangqi_movement_test`, `check_win_test`, `shogi_movement_test`, `shogi_promotion_test`, `shogi_drops_hand_test`, and `cross_game_test` all pass; the main scene boots headless (`--quit-after` exits 0).
