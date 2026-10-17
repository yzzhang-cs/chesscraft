# 12: Greedy AIController

**What to build:** The AI controller — a pure AI that, on its turn, enumerates every legal move and Shogi drop, scores each by the value of the captured piece (promoted values included), prefers a move that gives check, breaks ties randomly, and always takes an optional promotion — plus a headless test proving it only ever plays legal moves.

**Blocked by:** 11 — Controller seam (needs the base Controller and apply seam)

**Status:** ready-for-agent

- [x] AIController extends the base Controller and is pure (no Node dependency).
- [x] It enumerates all legal moves and drops for its side and applies one through the rules engine.
- [x] Scoring prefers the highest-value capture, then check, with random tiebreaks.
- [x] Optional Shogi promotion is always taken; drops are considered.
- [x] A seeded random generator makes choices reproducible.
- [x] Headless tests assert: only legal moves, turn advance, higher-value capture preference, and Shogi drop/promote.

## Comments

Implemented `src/controller/ai_controller.gd`: a pure greedy one-ply AI that enumerates every legal move and Shogi drop, scores by captured-piece value (promoted values included), prefers check, breaks ties randomly, always takes optional promotion, and is seeded for reproducibility. The tunable material table lives in `AIController.value_of`.

Verified: the new `ai_controller_test` asserts only-legal moves, turn advance, higher-value capture preference, check preference, drop, optional promotion, and seed reproducibility; all pass.
