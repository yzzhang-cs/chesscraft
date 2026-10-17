# 01: Make vertical room for two hand trays

**What to build:** Enlarge the window and shift the board down so there is a clean band above the board for Side 2's hand tray and one below for Side 1's, while the "Side N to move" label becomes centered at the top and the bottom hand tray and Undo/Restart/New-match controls stay below the shifted board. The match plays exactly as before — one side-to-move tray at the bottom, just repositioned.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The window is 840 pixels tall.
- [ ] The board shifts down 60 pixels; grid, river, palaces, pieces, and highlights all follow and stay correct.
- [ ] The "Side N to move" label is centered at the top.
- [ ] The bottom hand tray and the Undo/Restart/New-match buttons remain below the board and clear of it.
- [ ] All existing headless tests pass; touched scripts pass `--check-only`; the main scene boots headless.
