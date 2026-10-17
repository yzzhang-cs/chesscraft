Status: ready-for-agent

# Hand-tray layout: always visible, pinned to each side

## Problem Statement

A Shogi player seated as Side 2 captures an opponent piece, but that captured piece is shown only while it is Side 2's turn, and it appears at the bottom of the board — the same place Side 1's captures appear — so it reads as Side 1's piece. The player cannot see what they hold in hand while planning on the opponent's turn, and the tray's fixed position mislabels ownership.

## Solution

Show each side's Hand in its own tray, always visible and pinned to that side's edge of the board: Side 1's captured pieces in a tray at the bottom, Side 2's in a tray at the top. Each tray renders regardless of whose turn it is. Only the side-to-move's own tray is clickable for a Drop; the other side's tray is display-only.

## User Stories

1. As a Shogi player seated as Side 2, I want my captured pieces shown in a tray at the top of the board, so that their screen position matches my seat and I can tell they are mine.
2. As a Shogi player seated as Side 1, I want my captured pieces shown in a tray at the bottom of the board, so that their screen position matches my seat and I can tell they are mine.
3. As a Shogi player, I want my hand tray to stay visible on my opponent's turn, so that I can see what I will be able to drop before it is my move.
4. As a player, I want both hands visible simultaneously, so that I can read both sides' captured pieces at a glance without waiting for a turn.
5. As a player, I want each hand token to point toward its owner's opponent, like that side's board pieces, so that a token's orientation tells me whose hand it is.
6. As a player, I want an empty hand — or a side that never holds a hand — to show no tokens, so that empty trays do not clutter the board.
7. As the side to move, I want to click a piece in my own hand tray and then an empty point to drop it, so that dropping still works after the tray is split.
8. As a player, I want the non-moving side's tray to be display-only, so that I cannot drop out of turn or drop the opponent's pieces.
9. As a player, I want a click on the non-moving side's tray to do nothing rather than select a nearby board piece, so that clicking a captured piece never causes a wrong selection.
10. As a player, I want the trays positioned clear of the board's clickable points, so that I can still click pieces on the top and bottom rows without hitting a tray.
11. As a player, I want the "Side N to move" indicator to stay readable and not overlap a tray, so that turn order remains unambiguous even when a hand is full.
12. As a player, I want the Undo/Restart/New-match controls to remain reachable below the board, so that the two trays do not push the controls off-screen.

## Implementation Decisions

- **Two trays, one per side.** Each side's Hand renders in its own tray: Side 1 at the bottom, Side 2 at the top. Both draw on every frame regardless of `side_to_move`. A side with an empty hand (or a Xiangqi/大肥鱼 side, which never holds a hand) draws nothing.
- **Per-side token orientation.** A hand token's pentagon points the same way as that side's board pieces: up for Side 1, down for Side 2.
- **Drop interaction stays with the mover.** Only the side-to-move's own tray is selectable for a Drop. The opponent's tray is drawn but not selectable; a click on it is consumed (ignored) rather than falling through to board hit-testing.
- **Room above and below the board.** The window is enlarged vertically and the board shifted down so each tray has a clean band: Side 2's tray above the board, Side 1's tray below it, both clear of the board's clickable points and the window edges.
- **Turn indicator.** The "Side N to move" label moves to a centered position where it cannot collide with either tray. The win banner is unchanged; it and the turn label are mutually exclusive.
- **No rules-engine change.** The rules engine is untouched; the per-side hands it already holds are all the trays need.

## Testing Decisions

- **Presentation stays untested-by-design** (consistent with the existing "rules engine only" seam). No new automated test is added.
- **Regression guard:** the full existing headless rules suite must still pass — it exercises the rules engine, which this change does not touch, and confirms nothing regressed.
- **Parse gate:** every touched script must pass `--check-only` (exit 0).
- **Boot gate:** the main scene must boot headless without error.
- **Manual verification:** a human confirms visually that Side 2's captures render at the top always, Side 1's at the bottom always, tokens point per side, and the opponent's tray cannot be clicked.

## Out of Scope

- Any change to Capture/Drop/Promotion rules.
- A scroll or wrap for very large hands (a hand exceeding the tray's single row), which is a pre-existing limitation shared by the old tray.
- Side-by-side komadai placement (real Shogi's off-board stands) and any other visual redesign of the board.
- Automated presentation/rendering tests.

## Further Notes

- The two trays are symmetric about the board: same token size, spacing, and distance from the board edge; only the y-coordinate (above vs below) and pentagon orientation differ.
- A Xiangqi or 大肥鱼 side's tray is always empty, so in a cross-game match only the Shogi side's tray ever shows tokens.
