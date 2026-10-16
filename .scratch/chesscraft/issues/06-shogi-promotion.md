# 06: Shogi promotion

**What to build:** Shogi pieces promote in the promotion zone, an optional promotion prompts the player, stranded pieces are forced to promote, and captured promoted pieces revert in hand.

**Blocked by:** 05 — Shogi movement

**Status:** ready-for-agent

- [ ] A move that begins or ends in the promotion zone (the enemy's three back ranks) may promote.
- [ ] An optional promotion shows an accept/decline prompt.
- [ ] A pawn or lance on the last rank, or a knight on the last two ranks, is forced to promote.
- [ ] Promoted movement: 龍王 (rook + 1 diagonal), 龍馬 (bishop + 1 orthogonal), 成銀/成桂/成香/と (gold move).
- [ ] A captured promoted piece reverts to its unpromoted form in hand.
- [ ] Headless tests assert optional and mandatory promotion.
