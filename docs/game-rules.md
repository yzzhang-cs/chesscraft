# ChessCraft — Game Rules

The authoritative rules spec for the build. Coordinates use columns 1–9 (left → right) and rows 1–10 (bottom → top).

## Board

- 9 columns × 10 rows of **points** (intersections).
- **Side 1** sits at the bottom (rows 1–5), **Side 2** at the top (rows 6–10).
- **River** between rows 5 and 6.
- **Palaces**: columns 4–6, rows 1–3 (Side 1) and rows 8–10 (Side 2).

"Row N" is measured from the army's **own back edge** (row 1 = its back rank); for Side 2 the absolute row is `11 − N`.

## Armies

Three armies. Each side picks one independently; Side 1 always moves first.

| Army | Row 1 (back) | Row 2 | Row 3 | Row 4 |
|---|---|---|---|---|
| Xiangqi | 車馬相仕帥仕相馬車 | — | 炮 (col 2, 8) | 兵 (col 1, 3, 5, 7, 9) |
| 大肥鱼的象棋 | 車馬相仕帥仕相馬車 | 炮 (col 2, 8) | 兵 (col 1, 3, 5, 7, 9) | — |
| Shogi | 香桂銀金王金銀桂香 | 飛 · 角 | 歩 (all 9) | — |

Shogi 飛車 sits on the owner's **right**, 角行 on the owner's **left**.

**Why 大肥鱼的象棋 exists:** [this 小黑盒 post](https://www.xiaoheihe.cn/app/bbs/link/194097707).

## Piece glyphs

Xiangqi (red / black):
帥/將 general · 仕/士 advisor · 相/象 elephant · 傌/馬 horse · 俥/車 chariot · 炮/砲 cannon · 兵/卒 soldier.

Shogi (orientation shows ownership):
王将 king · 飛車 rook → 龍王 · 角行 bishop → 龍馬 · 金将 gold · 銀将 silver → 成銀 · 桂馬 knight → 成桂 · 香車 lance → 成香 · 歩兵 pawn → と.

## Movement

### Xiangqi (and 大肥鱼的象棋)

| Piece | Move |
|---|---|
| 帥/將 general | 1 orthogonal, palace only; never leaves palace |
| 仕/士 advisor | 1 diagonal, palace only (freed: anywhere) |
| 相/象 elephant | 2 diagonal, cannot cross river, "eye" (midpoint) must be empty (freed: may cross river, eye still applies) |
| 傌/馬 horse | 2+1, "leg" (adjacent orthogonal) must be empty — always |
| 俥/車 chariot | any orthogonal distance |
| 炮/砲 cannon | moves like chariot; captures by jumping exactly one screen |
| 兵/卒 soldier | 1 forward; after crossing the river, also 1 sideways; never backward |

### Shogi

| Piece | Move | Promotes to |
|---|---|---|
| 王将 king | 1 step, 8 dirs | — |
| 飛車 rook | any orthogonal | 龍王 (rook + 1 diagonal) |
| 角行 bishop | any diagonal | 龍馬 (bishop + 1 orthogonal) |
| 金将 gold | 1 step: forward/back/left/right + forward-diagonals (6) | — |
| 銀将 silver | 1 step: forward + 4 diagonals (5) | 成銀 (gold move) |
| 桂馬 knight | 2 forward + 1 sideways (jumps) | 成桂 (gold) |
| 香車 lance | forward any distance | 成香 (gold) |
| 歩兵 pawn | 1 forward | と (gold) |

"Forward" = toward the opponent.

## Capture, drops, promotion

- **Capture**: move onto an enemy piece. A **Shogi** capture moves the piece into the captor's **hand**; a **Xiangqi / 大肥鱼** capture removes it permanently (no hand).
- **Drop** (Shogi only): place a hand piece on an empty point. Drops are always unpromoted. A captured promoted piece reverts to unpromoted in hand.
- **Drop legality**: cannot drop a pawn/lance onto the last rank or a knight onto the last two ranks (no forward move). (`nifu`, `uchifuzume` deferred.)
- **Dropped 兵**: may only drop on the dropper's own half (behind the river); its "crossed river" state starts false.
- **Freed piece**: a 相 or 士 captured and re-dropped by Shogi is freed (advisor: 1 diagonal anywhere; elephant: 2 diagonal anywhere, eye still applies, may cross the river).
- **Promotion** (Shogi only): optional when a move begins or ends in the promotion zone (the enemy's three back ranks). Mandatory for a pawn/lance on the last rank or a knight on the last two ranks. Xiangqi pieces never promote.

## Check & win

- 帥/將 and 王将 are never captured; threatening them is **check**.
- **Checkmate** wins: the king/general is in check with no legal escape.
- **No legal move** (not in check) = that side **loses** (unified stalemate rule for both armies).

## Turn flow & UI

- Side 1 moves first; turns alternate.
- Click a piece → highlight legal moves → click a destination. Shogi drops: click a hand piece → click an empty point.
- Promotion prompt appears when a Shogi promotion is optional.
- Show: whose turn, a held-piece tray (Shogi), legal-move highlights, and a win/lose banner.
- Undo and restart available.
- Rendering: Xiangqi = circle + Chinese character (red/black); Shogi = pentagon pointing at the opponent + Japanese character. A Xiangqi piece dropped by Shogi is drawn as a pentagon.

## Deferred (roadmap)

- Shogi: `nifu`, `uchifuzume`, `sennichite` (repetition), impasse / `jishogi`.
- Flying-general rule (moot: the general is never captured, so two generals never share the board).
- A rules-toggle game mode (enable/disable specific Xiangqi/Shogi rules).
- Online multiplayer (the rules engine is decoupled from presentation to allow this).
