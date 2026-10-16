# 02: Three armies, openings, piece rendering, and army-select menu

**What to build:** Each side picks an army (Xiangqi / 大肥鱼的象棋 / Shogi) from a menu, and the board renders every piece in its correct opening position with the right shape and glyph, so the match starts correctly for any pairing.

**Blocked by:** 01 — Scaffold the project and render the empty board

**Status:** ready-for-agent

- [x] Three armies exist: Xiangqi, 大肥鱼的象棋, Shogi.
- [x] Xiangqi opening: back rank 車馬相仕帥仕相馬車, 炮 on row 3 (cols 2, 8), 兵 on row 4 (cols 1, 3, 5, 7, 9).
- [x] 大肥鱼的象棋 opening: back rank 車馬相仕帥仕相馬車, 炮 on row 2 (cols 2, 8), 兵 on row 3 (cols 1, 3, 5, 7, 9).
- [x] Shogi opening: 香桂銀金王金銀桂香 on row 1, 飛車 on the owner's right and 角行 on the owner's left on row 2, 歩兵 on all nine files of row 3.
- [x] Xiangqi pieces render as circles with Chinese characters (red/black); Shogi pieces render as pentagons pointing at the opponent with Japanese characters.
- [x] A menu lets each side toggle its army independently; Side 1 always moves first.
- [x] Headless tests assert each army's opening placement.

## Comments

Implemented at the spec's architecture seam (rules engine is pure GDScript, presentation is thin):

- `src/rules/army.gd` — `Army` enum (Xiangqi / 大肥鱼的象棋 / Shogi) plus display names.
- `src/rules/piece.gd` — `Piece` model (`side`, `army`, `kind`, `column`, `row`) with `glyph()` returning the red/black Chinese glyph for Xiangqi kinds and the two-character Japanese name for Shogi kinds.
- `src/rules/openings.gd` — opening placement in owner coordinates (file 1..9 from the owner's left, row 1 = own back rank), translated to absolute coordinates per side. Shogi 飛車 sits on the owner's right (file 8) and 角行 on the owner's left (file 2), so each owner's rook lands on their own right after the Side-2 mirror.
- `src/rules/match.gd` — `Match` holds each side's army, the opening `pieces`, `piece_at(column, row)`, `army_of(side)`, and `side_to_move == 1` (Side 1 moves first).
- `src/board/board_view.gd` — draws pieces on top of the board: Xiangqi as circles with red/black glyphs, Shogi as pentagons pointing at the opponent with stacked Japanese glyphs. CJK glyphs come from a `SystemFont` fallback list (Microsoft YaHei → Noto → SimSun → Yu Gothic → MS Gothic → Meiryo).
- `src/ui/menu_view.gd` + `src/main.gd` — the menu toggles each side's army independently and starts the match; `scenes/main.tscn` wires the menu node.
- `tests/openings_test.gd` — headless test asserting all three openings on both sides, Side 1 first, glyphs, and cross-game army independence.

Verified: `--check-only` exits 0 on every touched script; `smoke_test`, `board_test`, and `openings_test` all pass; the main scene boots headless; a GL render capture was pixel-checked for circle/pentagon shapes, red/black glyphs, and CJK glyph strokes (not tofu).
