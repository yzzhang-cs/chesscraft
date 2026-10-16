# ChessCraft

A Godot 4.7 game. Engine version is pinned to `4.7.2.stable.official.ed1daf0bf`.

## Running Godot

Run every Godot invocation through `tools/godot.ps1`. It is the single source of
truth for the engine's location, and it exists because two environment facts are
easy to get wrong:

- It selects `Godot_v4.7.2-stable_win64_console.exe`. The plain
  `Godot_v4.7.2-stable_win64.exe` is a GUI-subsystem binary, so its output never
  reaches the calling console and every command looks silent.
- It repoints `APPDATA` and `LOCALAPPDATA` at repo-local `.godot-userdata/`.
  Godot otherwise writes editor settings, caches and `user://` outside the
  workspace, where the agent sandbox denies them; the run then fails with
  `Cannot save file` / `Could not open 'user://'`. Set
  `GODOT_USE_SYSTEM_APPDATA=1` to use the real profile instead.

| Goal | Command |
| --- | --- |
| Engine version | `pwsh -NoProfile -File tools/godot.ps1 --version` |
| Import assets after adding files | `pwsh -NoProfile -File tools/godot.ps1 --headless --path . --import` |
| Parse-check one script | `pwsh -NoProfile -File tools/godot.ps1 --headless --path . --check-only --script res://path/to.gd` |
| Run a headless script | `pwsh -NoProfile -File tools/godot.ps1 --headless --path . --script res://tests/smoke_test.gd` |
| Run the game headless | `pwsh -NoProfile -File tools/godot.ps1 --headless --path . --quit-after 120` |

The last row needs `run/main_scene` set in `project.godot`; without it Godot exits
1 with `Can't run project: no main scene defined in the project.`

## Gate

`tests/smoke_test.gd` is the environment check: it asserts `res://` reads and
`user://` writes, then prints `smoke_test=PASS` and exits 0. `--check-only` exits
1 on a parse error and 0 on a clean script, so it works as a per-file lint.

A change is verified when `--check-only` exits 0 for every touched script and the
relevant headless test exits 0.

## Gotchas

- Export templates are not installed, so `--export-release` / `--export-debug`
  fail. Install them from the editor (`Editor > Manage Export Templates`) before
  exporting a standalone binary; that download is outside the sandbox.
- `.godot/` is a generated import cache, not source. It is git-ignored. Delete it
  and re-run `--import` when imports look stale or an asset is reported missing.
- Godot prints `Failed to read the root certificate store` on every sandboxed run.
  It comes from the sandbox denying a read of the Windows certificate store and is
  harmless unless the game makes HTTP requests.
