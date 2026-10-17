# 02: Split the hand tray into two always-visible per-side trays

**What to build:** Side 1's captured pieces always render in a tray at the bottom and Side 2's always render in a tray at the top, both visible regardless of whose turn it is; tokens point toward the opponent per side; only the side-to-move's own tray is clickable for a drop, while the opponent's tray is display-only and its clicks are ignored; the trays sit clear of the board's clickable points.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Side 1's hand always renders in the bottom tray and Side 2's always renders in the top tray, regardless of turn.
- [ ] An empty hand (or a non-Shogi side) draws no tokens.
- [ ] Hand tokens point up for Side 1 and down for Side 2.
- [ ] Only the side-to-move's own tray is clickable; drops still work.
- [ ] The opponent's tray is display-only; clicking it does nothing and does not select a board piece.
- [ ] Trays do not swallow clicks on the board's top or bottom rows.
- [ ] All existing headless tests pass; touched scripts pass `--check-only`; the main scene boots headless.
