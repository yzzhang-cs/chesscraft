# 12: Greedy AIController

**What to build:** The AI controller — a pure AI that, on its turn, enumerates every legal move and Shogi drop, scores each by the value of the captured piece (promoted values included), prefers a move that gives check, breaks ties randomly, and always takes an optional promotion — plus a headless test proving it only ever plays legal moves.

**Blocked by:** 11 — Controller seam (needs the base Controller and apply seam)

**Status:** ready-for-agent

- [ ] AIController extends the base Controller and is pure (no Node dependency).
- [ ] It enumerates all legal moves and drops for its side and applies one through the rules engine.
- [ ] Scoring prefers the highest-value capture, then check, with random tiebreaks.
- [ ] Optional Shogi promotion is always taken; drops are considered.
- [ ] A seeded random generator makes choices reproducible.
- [ ] Headless tests assert: only legal moves, turn advance, higher-value capture preference, and Shogi drop/promote.
