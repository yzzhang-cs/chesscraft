extends SceneTree
## Toolchain smoke test.
##
## Proves that Godot can boot headless, read the project, load a script and
## write to user:// (the directory a game uses for saves and config) while
## running inside the agent sandbox.
##
## Run with:
##   pwsh -NoProfile -File tools/godot.ps1 --headless --path . --script res://tests/smoke_test.gd


func _initialize() -> void:
	var failures: Array[String] = []

	var info := Engine.get_version_info()
	print("godot_version=%s" % info.string)
	print("project_name=%s" % ProjectSettings.get_setting("application/config/name"))
	print("user_dir=%s" % OS.get_user_data_dir())

	# res:// must be readable.
	if not FileAccess.file_exists("res://project.godot"):
		failures.append("cannot read res://project.godot")

	# user:// must be writable, since saves and config go there.
	var probe := "user://smoke_probe.txt"
	var f := FileAccess.open(probe, FileAccess.WRITE)
	if f == null:
		failures.append("cannot write %s (error %d)" % [probe, FileAccess.get_open_error()])
	else:
		f.store_string("ok")
		f.close()
		var r := FileAccess.open(probe, FileAccess.READ)
		if r == null or r.get_as_text() != "ok":
			failures.append("cannot read back %s" % probe)
		else:
			print("user_write=ok")
			DirAccess.remove_absolute(ProjectSettings.globalize_path(probe))

	if failures.is_empty():
		print("smoke_test=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("smoke_test=FAIL %s" % failure)
		quit(1)
