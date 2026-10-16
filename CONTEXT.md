# ChessCraft

A local two-player game where each side plays with the Chinese Xiangqi, the Japanese Shogi, or 大肥鱼的象棋 piece set and rules, including the cross-game match where different armies face each other.

## Language

### Game structure

**Match**:
One complete game between two sides.
_Avoid_: game, round, session

**Side**:
One of the two opposing forces in a match, each controlled by a human in local hotseat play. Side 1 always moves first.
_Avoid_: player, color, team

**Army**:
The piece set and rule set a side uses: Xiangqi, Shogi, or 大肥鱼的象棋.
_Avoid_: faction, variant, race, deck

**大肥鱼的象棋** (Big Fat Whale's Xiangqi):
A Xiangqi-variant army that opens with 炮 on row 2 and 兵 on row 3, while the Xiangqi army opens 炮 on row 3 and 兵 on row 4.

**Cross-game match**:
A match whose two sides use different armies.
_Avoid_: hybrid, mixed game

**Same-army match**:
A match whose two sides use the same army.
_Avoid_: mirror match

**Red / Black**:
The two Xiangqi sides' colors: red is the first mover, black the second.

**Sente / Gote**:
The two Shogi sides' seats: sente is the first mover, gote the second.

### Board

**Board**:
The shared 9-column × 10-row grid of points both armies play on.

**Point**:
A single board position where a piece stands and moves.
_Avoid_: square, cell, space

**River**:
The gap between rows 5 and 6, which Xiangqi elephants may not cross and which Xiangqi soldiers must cross to gain sideways movement.

**Palace**:
Either of the two 3×3 regions (center three columns, rows 1–3 and 8–10) where a Xiangqi general and advisor are confined.

### Pieces and rules

**Piece**:
A single unit on the board belonging to one side, moving by its army's rules.

**Hand**:
The set of captured pieces a side may later drop back onto the board. Only the Shogi side has a hand.
_Avoid_: captured tray, reserve, bench

**Drop**:
Placing a piece from a side's hand onto an empty board position as a move (a Shogi rule; the Xiangqi side never drops).

**Capture**:
Removing an opponent's piece by moving onto its position. A Shogi capture moves the piece into the captor's hand; a Xiangqi capture removes it from play permanently.

**Promotion**:
The Shogi rule upgrading certain pieces that move within the promotion zone. Xiangqi pieces never promote, even when held and dropped by a Shogi side.

**Promotion zone**:
The enemy's three back ranks, where a Shogi piece's promotable move begins or ends.

**Freed piece**:
A captured Xiangqi 相 or 士 re-dropped by the Shogi side, released from its river (相) or palace (士) confinement while keeping its diagonal move and the 相's eye block.
