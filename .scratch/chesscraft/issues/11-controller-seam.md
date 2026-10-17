# 11: Controller seam — human moves through a PlayerController

**What to build:** Route the human's move flow through a controller layer so the board view stops applying moves itself and each side is driven by a controller. Introduce a base Controller and a PlayerController that owns selection, move/drop, and the promotion prompt; the board view becomes render plus input-capture and forwards clicks to the side-to-move's controller. Two-human hotseat behaves exactly as before, now flowing through the controller seam.

**Blocked by:** 10 — New match (restructures the same start flow)

**Status:** ready-for-agent

- [ ] A base Controller (pure, no Node dependency) holds a side and the apply-move seam.
- [ ] A PlayerController owns the human's selection, move/drop, and promotion-prompt logic.
- [ ] The board view forwards clicks to the side-to-move's controller and no longer applies moves itself.
- [ ] Two-human hotseat — armies, moves, drops, promotion, undo, restart, new match — behaves as before.
