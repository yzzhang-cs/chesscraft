# 07: Shogi drops and the hand

**What to build:** Shogi captures enter the player's hand, a hand tray renders the held pieces, held pieces drop onto empty points, and drop-legality is enforced.

**Blocked by:** 06 — Shogi promotion

**Status:** ready-for-agent

- [ ] A Shogi capture moves the captured piece into the captor's hand, unpromoted.
- [ ] A hand tray shows the Shogi player's held pieces.
- [ ] Clicking a hand piece and then an empty point drops it.
- [ ] Drops are always unpromoted.
- [ ] A pawn or lance cannot drop onto the last rank; a knight cannot drop onto the last two ranks.
- [ ] Headless tests assert capture-to-hand, legal drops, and illegal drops.
