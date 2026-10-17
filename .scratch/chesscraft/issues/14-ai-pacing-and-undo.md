# 14: AI pacing and two-ply undo

**What to build:** The AI replies after a short delay so the human can see their move land; AI-vs-AI matches chain one AI after another until they end; and in a human-vs-AI match Undo reverts the human's last move together with the AI's reply (disabled before the human's first move), while two-human matches keep single-ply undo.

**Blocked by:** 13

**Status:** ready-for-agent

- [x] The AI moves after a short (~0.7 s) delay.
- [x] AI-vs-AI chains moves until the match ends.
- [x] Human-vs-AI Undo reverts the last human move plus the AI's reply; disabled before the human's first move since start/restart.
- [x] Two-human Undo stays single-ply.

## Comments

Implemented AI pacing and two-ply undo in `src/main.gd`: the AI replies after a ~0.7 s timer, AI-vs-AI chains one AI after another, human-vs-AI Undo reverts the last human move plus the AI's reply (disabled until the human has moved), and two-human Undo stays single-ply.

Verified: `--check-only` exits 0 on every touched script; the full headless suite passes; the main scene boots headless.
