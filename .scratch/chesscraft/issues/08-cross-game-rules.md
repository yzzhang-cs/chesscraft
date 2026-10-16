# 08: Cross-game rules

**What to build:** Cross-army matches work: a Shogi side capturing a Xiangqi piece puts it in hand, dropped 相/士 are freed, dropped 兵 go only behind the river, and dropped Xiangqi pieces render as pentagons.

**Blocked by:** 04 — Capture, check, and win detection with undo; 07 — Shogi drops and the hand

**Status:** ready-for-agent

- [ ] A Shogi side capturing a Xiangqi/大肥鱼 piece puts it in the Shogi hand; it remains droppable and keeps Xiangqi movement.
- [ ] A Xiangqi/大肥鱼 side capturing a Shogi piece removes it permanently.
- [ ] A dropped 相 or 士 is freed: advisor moves 1 diagonal anywhere; elephant moves 2 diagonal anywhere with the eye still applying and may cross the river.
- [ ] A dropped 兵 goes only on the dropper's own half (behind the river) and starts with its crossed-river flag false.
- [ ] A dropped Xiangqi piece renders as a pentagon (ownership shown by orientation).
- [ ] Headless tests assert cross-game capture, freed pieces, and the 兵 drop restriction.
