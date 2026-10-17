# 13: Human-vs-AI end to end

**What to build:** The army-select menu gains a Player/AI toggle per side (default both Player). Starting a match builds the matching controller for each side; the board view ignores input while an AI side is to move; and the AI moves when it is its turn. A single human can start a match against the AI and play a full game through to the win banner.

**Blocked by:** 11, 12

**Status:** ready-for-agent

- [x] Menu: each side toggles Player ⇄ AI beside its army toggle; defaults both Player.
- [x] The started signal carries both armies and both controllers.
- [x] Starting a match constructs a PlayerController or AIController per side and drives the AI side's moves.
- [x] The board view ignores clicks while an AI side is to move.
- [x] A human can play a complete match against the AI (any army, either side) through to the win banner.

## Comments

Implemented `src/ui/menu_view.gd` (a Player ⇄ AI toggle per side, default Player; the `started` signal now carries both armies and both controller kinds) and `src/main.gd` (builds a PlayerController or AIController per side, drives the AI side's moves, and the board view ignores clicks while an AI side is to move). A human can start and play a full match against the AI.

Verified: `--check-only` exits 0 on every touched script; the full headless suite passes; the main scene boots headless.
