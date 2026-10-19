extends RefCounted
## Repository consumers share this reader; standalone SDKs carry a release snapshot.
var dependency: Dictionary


func _init() -> void:
	var path: String = get_script().resource_path.get_base_dir().path_join("ui-kit-dependency.json")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary and parsed.has("tag") and parsed.has("commit"), "Invalid UI Kit dependency record.")
	dependency = parsed
	var version := OS.get_environment("ROOKFRAME_UI_KIT_VERSION").strip_edges()
	if version.is_empty():
		return
	var commit_pattern := RegEx.create_from_string("^[0-9a-f]{40}$")
	if commit_pattern.search(version):
		dependency = {"tag": version, "commit": version}
		return
	var tag_pattern := RegEx.create_from_string("^v[0-9]+\\.[0-9]+\\.[0-9]+(?:-[0-9A-Za-z.-]+)?(?:\\+[0-9A-Za-z.-]+)?$")
	if not tag_pattern.search(version):
		_fail_override("ROOKFRAME_UI_KIT_VERSION must be a release tag or full commit.")
		return
	var ref := "refs/tags/" + version
	var output: Array = []
	if OS.execute("git", ["ls-remote", "--tags", "https://github.com/rookframe/rookframe-ui-kit.git", ref, ref + "^{}"], output) != 0:
		_fail_override("Could not resolve UI Kit release tag: " + version)
		return
	var refs := {}
	for line in str(output[0]).split("\n", false):
		var fields := line.split("\t")
		if fields.size() == 2:
			refs[fields[1]] = fields[0]
	var commit: String = refs.get(ref + "^{}", refs.get(ref, ""))
	if not commit_pattern.search(commit):
		_fail_override("UI Kit release tag not found: " + version)
		return
	dependency = {"tag": version, "commit": commit}


func _fail_override(message: String) -> void:
	push_error(message)
	dependency = {}


func options() -> Dictionary:
	return {"commit": dependency.commit, "include": ["rookframe/ui"]}


var installation_error := OK


func _run_adapter(action: String, extra: Array = []) -> Dictionary:
	var python := OS.get_environment("ROOKFRAME_PYTHON")
	if python.is_empty():
		python = "python" if OS.get_name() == "Windows" else "python3"
	var adapter: String = get_script().resource_path.get_base_dir().path_join("rookframe_ui_kit_install.py")
	var args: Array = [ProjectSettings.globalize_path(adapter), action,
		"--project", ProjectSettings.globalize_path("res://"),
		"--commit", dependency.commit, "--version", dependency.tag]
	args.append_array(extra)
	var output: Array = []
	var result := OS.execute(python, PackedStringArray(args), output, true)
	if result != 0:
		push_error("UI Kit installation failed: " + str(output))
		installation_error = ERR_CANT_CREATE
		return {}
	var parsed = JSON.parse_string(str(output[0]))
	if not parsed is Dictionary:
		installation_error = ERR_INVALID_DATA
		return {}
	return parsed


func install(runner, plugin: Dictionary) -> void:
	var extra: Array = []
	var legacy_path := ""
	if runner._installed_plugins.has(plugin.name):
		var previous: Dictionary = runner.get_installed_plugin(plugin.name)
		legacy_path = "res://.plugged/rookframe-ui-kit-legacy-files.json"
		var legacy_file := FileAccess.open(legacy_path, FileAccess.WRITE)
		if legacy_file == null:
			installation_error = FileAccess.get_open_error()
			push_error("Cannot save the previous UI Kit file inventory.")
			return
		legacy_file.store_string(JSON.stringify(previous.get("dest_files", [])))
		legacy_file.close()
		extra = ["--previous-commit", previous.get("commit", ""),
			"--legacy-files-json", ProjectSettings.globalize_path(legacy_path)]
	var installed := _run_adapter("install", extra)
	if not legacy_path.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))
	if installed.is_empty():
		return
	plugin.commit = installed.commit
	plugin.dest_files = installed.dest_files
	plugin.source_root = installed.sourceRoot
	runner.set_installed_plugin(plugin)


func write_provenance(application: bool = false) -> Error:
	if installation_error != OK:
		return installation_error
	_run_adapter("verify", ["--application"] if application else [])
	return installation_error
