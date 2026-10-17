# 11: Controller seam — human moves through a PlayerController

**What to build:** Route the human's move flow through a controller layer so the board view stops applying moves itself and each side is driven by a controller. Introduce a base Controller and a PlayerController that owns selection, move/drop, and the promotion prompt; the board view becomes render plus input-capture and forwards clicks to the side-to-move's controller. Two-human hotseat behaves exactly as before, now flowing through the controller seam.

**Blocked by:** 10 — New match (restructures the same start flow)

**Status:** ready-for-agent

- [x] A base Controller (pure, no Node dependency) holds a side and the apply-move seam.
- [x] A PlayerController owns the human's selection, move/drop, and promotion-prompt logic.
- [x] The board view forwards clicks to the side-to-move's controller and no longer applies moves itself.
- [x] Two-human hotseat — armies, moves, drops, promotion, undo, restart, new match — behaves as before.

## Comments

Implemented the controller seam: `src/controller/controller.gd` (base Controller holding the side and the apply-move seam through the Match) and `src/controller/player_controller.gd` (owns selection, move/drop, and the promotion-prompt decision). `src/board/board_view.gd` is now render plus input-capture: it forwards clicks to the side-to-move's controller and no longer applies moves itself. Two-human hotseat still flows through the seam.

Verified: `--check-only` exits 0 on every touched script; the full headless suite passes including the new `player_controller_test`; the main scene boots headless.
