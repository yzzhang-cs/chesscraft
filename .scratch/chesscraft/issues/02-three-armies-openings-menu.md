# 02: Three armies, openings, piece rendering, and army-select menu

**What to build:** Each side picks an army (Xiangqi / 大肥鱼的象棋 / Shogi) from a menu, and the board renders every piece in its correct opening position with the right shape and glyph, so the match starts correctly for any pairing.

**Blocked by:** 01 — Scaffold the project and render the empty board

**Status:** ready-for-agent

- [ ] Three armies exist: Xiangqi, 大肥鱼的象棋, Shogi.
- [ ] Xiangqi opening: back rank 車馬相仕帥仕相馬車, 炮 on row 3 (cols 2, 8), 兵 on row 4 (cols 1, 3, 5, 7, 9).
- [ ] 大肥鱼的象棋 opening: back rank 車馬相仕帥仕相馬車, 炮 on row 2 (cols 2, 8), 兵 on row 3 (cols 1, 3, 5, 7, 9).
- [ ] Shogi opening: 香桂銀金王金銀桂香 on row 1, 飛車 on the owner's right and 角行 on the owner's left on row 2, 歩兵 on all nine files of row 3.
- [ ] Xiangqi pieces render as circles with Chinese characters (red/black); Shogi pieces render as pentagons pointing at the opponent with Japanese characters.
- [ ] A menu lets each side toggle its army independently; Side 1 always moves first.
- [ ] Headless tests assert each army's opening placement.
