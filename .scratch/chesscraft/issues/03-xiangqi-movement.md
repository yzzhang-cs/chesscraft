# 03: Xiangqi movement with click-to-move

**What to build:** A player clicks a Xiangqi piece, sees its legal destinations highlighted, and moves by clicking one of them, with every piece honoring its movement rules (this movement also powers 大肥鱼的象棋).

**Blocked by:** 02 — Three armies, openings, piece rendering, and army-select menu

**Status:** ready-for-agent

- [ ] General moves 1 orthogonal, confined to its palace.
- [ ] Advisor moves 1 diagonal, confined to its palace.
- [ ] Elephant moves 2 diagonal, blocked by its eye, and cannot cross the river.
- [ ] Horse moves 2+1, blocked by its leg.
- [ ] Chariot slides any orthogonal distance.
- [ ] Cannon slides like a chariot and captures only by jumping exactly one screen.
- [ ] Soldier moves 1 forward, and gains sideways movement only after crossing the river.
- [ ] Clicking a piece highlights only legal destinations; clicking a highlighted point moves it.
- [ ] A turn indicator shows whose turn it is (Side 1 first).
- [ ] Headless tests assert legal moves for every piece type.
