Status: ready-for-agent

# ChessCraft

## Problem Statement

The user wants a playable local two-player board game, built with Godot 4.7, where each player can field either the Chinese Xiangqi or the Japanese Shogi army — plus a third army, 大肥鱼的象棋 — and where different armies can face each other on one shared board. Each army must move and capture by its original rules, Shogi's special rules (promotion, dropping captured pieces) must apply to the Shogi side only, and the game must remain simple and 2D while staying extensible toward online multiplayer later. The player also wants to play solo: one human against a computer opponent, chosen per side in the same setup menu.

## Solution

A Godot 4.7 2D game that splits cleanly into a **rules engine** (pure GDScript, no scene dependency) and a **presentation layer** (scenes/nodes). Each side is controlled by a Player (human) or an AI (computer): pick armies and controllers, then click a piece and a destination to move, with Shogi drops, promotion prompts, legal-move highlighting, a turn indicator, undo/restart, and a win banner. The AI picks legal moves and Shogi drops greedily and replies after a short delay, so one human can play against the computer. Three armies are supported (Xiangqi, Shogi, 大肥鱼的象棋), including cross-game matches where the two sides use different armies.

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
39. As a player, I want to choose whether each side is a Player or an AI when selecting armies, so that I can play alone against the computer.
40. As a player, I want the army-select menu to default both sides to Player, so that two-player hotseat stays the default and I opt into AI play.
41. As a player, I want to set either side to AI, so that I can choose whether to move first or second against the computer.
42. As a player, I want to set both sides to AI, so that I can watch an AI-vs-AI match.
43. As a player, I want the AI to make only legal moves and drops, so that the match never enters an illegal state.
44. As a player, I want the AI to prefer capturing higher-value pieces, so that it plays with at least a minimal sense of material rather than purely at random.
45. As a player, I want the AI to prefer a move that gives check when captures are otherwise equal, so that it plays with a hint of purpose.
46. As a player, I want the AI to promote a Shogi piece when promotion is optional, so that its Shogi play uses promotion.
47. As a Shogi player facing an AI, I want the AI to drop pieces from its hand when useful, so that it plays Shogi's drop rule.
48. As a player, I want the AI to reply after a short delay, so that I can see my own move land before the computer's reply.
49. As a player, I want the AI never to move out of turn, so that turn order stays unambiguous.
50. As a player, I want to be unable to move the AI's pieces, so that I cannot accidentally play for the computer.
51. As a player, I want Undo against the AI to revert my last move together with the AI's reply, so that I can cleanly retake my move.
52. As a player, I want Undo disabled when I have not yet moved since the start or restart, so that I cannot undo into a state where the AI re-moves immediately.
53. As a developer, I want the AI to be a pure, headless-testable module and the human path to flow through a symmetric controller, so that future multiplayer and stronger AIs can reuse the same seam.

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
- **Menu.** A simple local-match setup: Side 1 and Side 2 each toggle Xiangqi / Shogi / 大肥鱼的象棋 and each toggle Player / AI, then start.
- **Controller layer.** Each side is controlled by a Controller: a PlayerController (human) or an AIController (AI). Both are pure (RefCounted, no Node dependency), symmetric, and share a base Controller holding the side and the apply-move seam. The board view becomes render plus input-capture: it forwards the human's clicks to the side's PlayerController and ignores input while an AI side is to move.
- **AI strength.** A greedy one-ply chooser: enumerate every legal move and drop, score each by the value of the piece captured (0 when none), prefer a move that gives check, and break ties randomly. Optional Shogi promotion is always taken. Search (minimax) is deliberately deferred; the scoring step is written so a stronger AI can replace it later.
- **Material values.** A heuristic, tunable table used to score captures: Xiangqi 兵/卒 1, 仕/士 2, 相/象 2, 馬 4, 炮 4, 車 9; Shogi unpromoted 歩 1, 香 3, 桂 4, 銀 5, 金 6, 角 8, 飛 10; Shogi promoted と/成香/成桂/成銀 6, 龍馬 11, 龍王 13. Kings/generals are never captured and have no value.
- **Turn scheduling.** The main scene holds the per-side controllers, built from the menu's choices. After a human move (or on start when Side 1 is an AI), the AI's move is scheduled after a short timer (~0.7 s); AI-vs-AI chains one AI after another until the match ends.
- **Undo.** In a human-vs-AI match, Undo reverts the last human move plus any AI replies that followed it, and is disabled when the human has not moved since the last start or restart. Two-human matches keep single-ply undo.
- **Determinism.** The AIController uses a seeded random-number generator so headless tests are reproducible.

## Testing Decisions

- **Single seam.** All rules tests drive the rules engine's public API (set up a match, query legal moves and drops, apply a move, undo, read winner/in-check). No test reaches into presentation.
- **Test external behavior only.** Tests assert observable outcomes — which destinations are legal, whether a capture enters a hand or is removed, whether a drop is allowed, whether a promotion is forced, whether the match reports a winner — never internal representation details.
- **Modules tested.** The rules engine only: openings for all three armies; every piece's movement (palace, river, eye, leg, cannon screen, soldier river-cross); capture-to-hand vs removed; drop legality; the dropped-兵 half-board restriction; the freed 相/士 rule; optional and mandatory promotion; check, checkmate, and no-legal-move losses.
- **Prior art.** The repo already has `tests/smoke_test.gd`, a headless `SceneTree` script run with `godot_console --headless --path . --script res://tests/...`. Rules tests follow the same pattern, plus `--check-only` as a per-script parse gate.
- **New module tested.** The AIController, headlessly, asserting only external behavior: every move or drop it chooses is legal, playing advances the turn, greedy scoring prefers the highest-value capture, and a Shogi AI both drops and promotes.

## Out of Scope

- Shogi edge rules: `nifu` (two pawns per file), `uchifuzume` (drop-pawn mate), `sennichite` (repetition), impasse/`jishogi`.
- The Xiangqi flying-general rule (moot: the general is never captured, so two generals never share the board).
- A rules-toggle game mode for enabling/disabling specific Xiangqi/Shogi rules.
- Online multiplayer (the rules/presentation split is designed to allow it later, but no networking now).
- A stronger AI: minimax/search beyond the greedy one-ply heuristic is deferred (the scoring step is written so a stronger AI can replace it later).
- Art assets beyond simple shapes and text glyphs.
- Exporting a standalone binary (export templates are not installed).

## Further Notes

- Cross-game matches are the headline feature; same-army matches are supported with no extra rules.
- The rules engine should be data-driven about pieces, moves, and openings so that future rules toggles and the third army's distinct opening are cheap to express.
- The decoupled rules engine is the extension point for the eventual online-multiplayer requirement.
- The controller layer (PlayerController / AIController over the rules-engine seam) is that same extension point: a remote controller can later sit where the AIController sits.
