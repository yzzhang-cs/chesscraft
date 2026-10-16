# 09: Restart the match

**What to build:** A player can restart the current match at any time — the board returns to the opening layout for the two chosen armies, Side 1 moves first, and any undo history and win banner clear.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] A Restart control is available during the match and after it ends.
- [ ] Restart returns the board to the opening position for the same two armies and restores any captured pieces.
- [ ] After restart, Side 1 moves first, the turn indicator shows Side 1, and the win banner is cleared.
- [ ] After restart, the undo control has nothing to undo (the pre-restart move history is gone).
- [ ] Headless tests assert the restored opening layout, Side 1 to move, and an empty undo history.
