# ChessCraft

A Godot 4.7 game. Engine version is pinned to `4.7.2.stable.official.ed1daf0bf`.

## Running Godot

Godot is installed at `C:\tools\godot\4.7.2\` and that directory is on the user
PATH, so invoke it by bare name:

- `godot` — the editor build (GUI subsystem). Use it to open the editor.
- `godot_console` — the same engine, launched attached to the calling console. Use
  this for all command-line work, so output is visible and exit codes mean
  something.

The two files must be renamed and moved as a pair. The `_console` stub finds its
engine by stripping `_console` from its own filename, so renaming only the engine
makes the stub fail with `Main executable ... not found`.

| Goal | Command |
| --- | --- |
| Engine version | `godot_console --version` |
| Import assets after adding files | `godot_console --headless --path . --import` |
| Parse-check one script | `godot_console --headless --path . --check-only --script res://path/to.gd` |
| Run a headless script | `godot_console --headless --path . --script res://tests/smoke_test.gd` |
| Run the game headless | `godot_console --headless --path . --quit-after 120` |

The last row needs `run/main_scene` set in `project.godot`; without it Godot exits
1 with `Can't run project: no main scene defined in the project.`

## `user://` under the agent sandbox

Godot stores a running project's `user://` directory (saves, logs, config) in
`%APPDATA%\Godot\app_userdata\<project>`, which is outside the agent's writable
workspace. Those writes fail with `Cannot write user://...`, and a test that needs
them exits 1. Godot has no `--user-data-dir` flag, so redirect the data
directories in that one command:

```powershell
$env:APPDATA      = "$PWD/.godot-userdata/AppData/Roaming"
$env:LOCALAPPDATA = "$PWD/.godot-userdata/AppData/Local"
godot_console --headless --path . --script res://tests/smoke_test.gd
```

Commands that never touch `user://` — `--version`, `--check-only`, `--import` —
run plain. `.godot-userdata/` is git-ignored.

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

## Agent skills

### Issue tracker

Issues and specs live as markdown files under `.scratch/<feature>/` in this repo. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage roles, each label equal to its role name: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` at the repo root plus `docs/adr/`. See `docs/agents/domain.md`.
