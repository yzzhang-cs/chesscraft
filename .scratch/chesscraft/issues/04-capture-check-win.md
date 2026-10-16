# 04: Capture, check, and win detection with undo

**What to build:** Captures remove pieces, check is detected, a match ends in checkmate or by a side having no legal move, a win banner shows the result, and the player can undo the last move.

**Blocked by:** 03 — Xiangqi movement with click-to-move

**Status:** ready-for-agent

- [ ] Moving onto an enemy piece captures it (removed from play for Xiangqi).
- [ ] Check is detected when a general is threatened.
- [ ] Checkmate ends the match with the checkmated side losing.
- [ ] A side with no legal move (and not in check) loses.
- [ ] A win banner shows the result.
- [ ] Undo reverts the last move and restores any captured piece.
- [ ] Headless tests assert check, checkmate, and no-legal-move losses.
