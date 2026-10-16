Status: ready-for-agent

# ChessCraft

## Problem Statement

The user wants a playable local two-player board game, built with Godot 4.7, where each player can field either the Chinese Xiangqi or the Japanese Shogi army — plus a third army, 大肥鱼的象棋 — and where different armies can face each other on one shared board. Each army must move and capture by its original rules, Shogi's special rules (promotion, dropping captured pieces) must apply to the Shogi side only, and the game must remain simple and 2D while staying extensible toward online multiplayer later.

## Solution

A Godot 4.7 2D game that splits cleanly into a **rules engine** (pure GDScript, no scene dependency) and a **presentation layer** (scenes/nodes). Two humans play hotseat on one screen: pick armies, then click a piece and a destination to move, with Shogi drops, promotion prompts, legal-move highlighting, a turn indicator, undo/restart, and a win banner. Three armies are supported (Xiangqi, Shogi, 大肥鱼的象棋), including cross-game matches where the two sides use different armies.

## User Stories

1. As a player, I want to start a new local match, so that I can play a game against another person on the same screen.
2. As a player, I want to choose my army (Xiangqi, Shogi, or 大肥鱼的象棋) independently of my opponent, so that I can play the army I want.
3. As a player, I want Side 1 to always move first, so that turn order is unambiguous in every match.
4. As a player, I want my army's pieces placed in their correct opening positions, so that the match starts correctly.
5. As a player, I want to see the 9-column × 10-row board with the river and both palaces drawn, so that I can read the board like a real Xiangqi board.
6. As a player, I want to know whose turn it is, so that I don't move out of turn.
7. As a player, I want to identify each piece by its glyph, so that I can tell pieces apart at a glance.
8. As a player, I want Xiangqi pieces drawn as circles with Chinese characters (red/black), so that they look like Xiangqi.
9. As a player, I want Shogi pieces drawn as pentagons pointing at the opponent with Japanese characters, so that ownership is readable by orientation.
10. As a player, I want a Xiangqi piece that is captured and dropped by Shogi to be drawn as a pentagon, so that its new ownership is clear.
11. As a player, I want to click a piece to select it, so that I can begin a move.
12. As a player, I want to see the selected piece's legal destinations highlighted, so that I know where it can move.
13. As a player, I want to move a piece by clicking a highlighted destination, so that I can play a move.
14. As a player, I want to capture by moving onto an enemy piece, so that captures work by each army's rules.
15. As a Shogi player, I want captured enemy pieces to enter my hand, so that I can drop them later.
16. As a Xiangqi player, I want captured enemy pieces to leave the game permanently, so that Xiangqi's no-hand rule applies.
17. As a Shogi player, I want to see my held pieces in a hand tray, so that I know what I can drop.
18. As a Shogi player, I want to drop a held piece by clicking it and then an empty point, so that drops work.
19. As a player, I want to undo my last move and restart the match, so that I can recover from misclicks.
20. As a player, I want a win/lose banner when the match ends, so that I know the result.
21. As a Xiangqi player, I want my general and advisors confined to the palace, so that the palace rule is enforced.
22. As a Xiangqi player, I want my elephants unable to cross the river and blocked by their eye, so that the elephant rule is enforced.
23. As a Xiangqi player, I want my horses blocked by their leg, so that the horse rule is enforced.
24. As a Xiangqi player, I want my chariots to slide any orthogonal distance, so that the chariot rule is enforced.
25. As a Xiangqi player, I want my cannons to move like a chariot but capture only by jumping exactly one screen, so that the cannon rule is enforced.
26. As a Xiangqi player, I want my soldiers to move one step forward and gain sideways movement after crossing the river, so that the soldier rule is enforced.
27. As a Shogi player, I want my rook, bishop, gold, silver, knight, lance, and pawn to move by their standard Shogi patterns, so that Shogi movement is faithful.
28. As a Shogi player, I want to promote a piece when a move begins or ends in the promotion zone, so that promotion works.
29. As a Shogi player, I want to be prompted to accept or decline an optional promotion, so that I keep the choice.
30. As a Shogi player, I want a pawn/lance on the last rank or a knight on the last two ranks to be forced to promote, so that stranded pieces can't stay stuck.
31. As a Shogi player, I want captured promoted pieces to revert to unpromoted in hand and drops to be unpromoted, so that drops stay legal.
32. As a Shogi player, I want drops restricted so a pawn/lance can't drop on the last rank and a knight can't drop on the last two ranks, so that illegal drops are prevented.
33. As a player, I want a 兵 captured and dropped by Shogi to be droppable only on my own half of the board (behind the river), so that the special 兵-drop rule applies.
34. As a player, I want a captured 相 or 士 dropped by Shogi to be "freed" — the advisor moves one step diagonally anywhere, the elephant two steps diagonally anywhere (eye still applies) — so that the cross-game freed-piece rule applies.
35. As a player, I want check to be detected when my king/general is threatened, so that I must respond to it.
36. As a player, I want checkmate to end the match in the checkmated side losing, so that wins resolve correctly.
37. As a player, I want a side with no legal move (and not in check) to lose, so that the unified stalemate rule applies.
38. As a developer, I want the rules engine decoupled from presentation, so that it can be tested headlessly and later reused for online multiplayer.

## Implementation Decisions

- **Three armies.** An army is a piece set plus a rule set plus an opening placement: Xiangqi, Shogi, and 大肥鱼的象棋 (a Xiangqi variant that differs only in opening placement). A side picks one army; the two sides may differ (cross-game match) or match (same-army match).
- **Board.** 9 columns × 10 rows of points. Side 1 is at the bottom (rows 1–5), Side 2 at the top (rows 6–10). River between rows 5 and 6. Palaces at columns 4–6, rows 1–3 (Side 1) and rows 8–10 (Side 2). "Row N" is measured from an army's own back edge (row 1 = back rank); for Side 2 the absolute row is 11 − N.
- **Openings.** Xiangqi: back rank 車馬相仕帥仕相馬車, 炮 on row 3 (cols 2, 8), 兵 on row 4 (cols 1, 3, 5, 7, 9). 大肥鱼的象棋: back rank 車馬相仕帥仕相馬車, 炮 on row 2 (cols 2, 8), 兵 on row 3 (cols 1, 3, 5, 7, 9). Shogi: 香桂銀金王金銀桂香 on row 1, 飛車 on the owner's right and 角行 on the owner's left on row 2, 歩兵 on all nine files of row 3.
- **Roster and glyphs.** Xiangqi glyphs: 帥/將 general, 仕/士 advisor, 相/象 elephant, 傌/馬 horse, 俥/車 chariot, 炮/砲 cannon, 兵/卒 soldier (red/black pairs). Shogi glyphs: 王将 king, 飛車 rook → 龍王, 角行 bishop → 龍馬, 金将 gold, 銀将 silver → 成銀, 桂馬 knight → 成桂, 香車 lance → 成香, 歩兵 pawn → と.
- **Xiangqi movement.** General 1 orthogonal (palace only); advisor 1 diagonal (palace only); elephant 2 diagonal with a blocking eye and no river crossing; horse 2+1 with a blocking leg (always); chariot any orthogonal distance; cannon chariot-like but captures over exactly one screen; soldier 1 forward, +1 sideways after crossing the river, never backward. "Forward" is toward the opponent.
- **Shogi movement.** King 1 step in 8 directions; rook any orthogonal; bishop any diagonal; gold 1 step forward/back/left/right + forward-diagonals; silver 1 step forward + four diagonals; knight 2 forward + 1 sideways (jumps); lance any forward distance; pawn 1 forward. Promoted forms: 龍王 (rook + 1 diagonal), 龍馬 (bishop + 1 orthogonal), 成銀/成桂/成香/と (gold move).
- **Capture and hand.** A Shogi capture moves the piece into the captor's hand; a Xiangqi/大肥鱼 capture removes it permanently. Only the Shogi side has a hand.
- **Drops (Shogi only).** Drop a hand piece onto an empty point; always unpromoted. Drop-legality: no pawn/lance on the last rank, no knight on the last two ranks. A dropped 兵 goes only on the dropper's own half and starts with its crossed-river flag false. A dropped 相/士 is freed (advisor 1 diagonal anywhere; elephant 2 diagonal anywhere, eye still applies, may cross the river).
- **Promotion (Shogi only).** Optional when a move begins or ends in the promotion zone (the enemy's three back ranks); mandatory for a pawn/lance on the last rank or a knight on the last two ranks. Xiangqi pieces never promote.
- **Check and win.** 帥/將 and 王将 are never captured; threatening them is check. Checkmate wins. A side with no legal move (not in check) loses.
- **Architecture seam.** The rules engine is pure GDScript (board state, piece types, move generation, capture, drops, promotion, check/checkmate/win) with no Godot Node/scene dependency. The presentation layer (menu, board rendering, piece rendering, input, promotion prompt, turn banner, undo/restart) is thin and calls into the rules engine. The rules engine's public API is the single seam.
- **Rendering.** Xiangqi = circle + Chinese character (red/black); Shogi = pentagon pointing at the opponent + Japanese character; a Xiangqi piece dropped by Shogi is drawn as a pentagon.
- **Turn flow.** Side 1 moves first; turns alternate. Click a piece → highlight legal moves → click a destination; for Shogi drops, click a hand piece → click an empty point; a prompt appears for optional promotion.
- **Menu.** A simple local-match setup: Side 1 and Side 2 each toggle Xiangqi / Shogi / 大肥鱼的象棋, then start.

## Testing Decisions

- **Single seam.** All rules tests drive the rules engine's public API (set up a match, query legal moves and drops, apply a move, undo, read winner/in-check). No test reaches into presentation.
- **Test external behavior only.** Tests assert observable outcomes — which destinations are legal, whether a capture enters a hand or is removed, whether a drop is allowed, whether a promotion is forced, whether the match reports a winner — never internal representation details.
- **Modules tested.** The rules engine only: openings for all three armies; every piece's movement (palace, river, eye, leg, cannon screen, soldier river-cross); capture-to-hand vs removed; drop legality; the dropped-兵 half-board restriction; the freed 相/士 rule; optional and mandatory promotion; check, checkmate, and no-legal-move losses.
- **Prior art.** The repo already has `tests/smoke_test.gd`, a headless `SceneTree` script run with `godot_console --headless --path . --script res://tests/...`. Rules tests follow the same pattern, plus `--check-only` as a per-script parse gate.

## Out of Scope

- Shogi edge rules: `nifu` (two pawns per file), `uchifuzume` (drop-pawn mate), `sennichite` (repetition), impasse/`jishogi`.
- The Xiangqi flying-general rule (moot: the general is never captured, so two generals never share the board).
- A rules-toggle game mode for enabling/disabling specific Xiangqi/Shogi rules.
- Online multiplayer (the rules/presentation split is designed to allow it later, but no networking now).
- Single-player AI.
- Art assets beyond simple shapes and text glyphs.
- Exporting a standalone binary (export templates are not installed).

## Further Notes

- Cross-game matches are the headline feature; same-army matches are supported with no extra rules.
- The rules engine should be data-driven about pieces, moves, and openings so that future rules toggles and the third army's distinct opening are cheap to express.
- The decoupled rules engine is the extension point for the eventual online-multiplayer requirement.
