extends VBoxContainer
const SDK = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/package_sdk_facade.gd")
const AccessEntry = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/actor_access_entry.gd")
var _sdk: SDK
var _actor: SDK.ActorId
var _participant: String
var _level: String
var _busy: bool = false

func configure(sdk: SDK, actor: SDK.ActorId, entry: AccessEntry) -> void:
	_sdk = sdk
	_actor = actor
	_participant = entry.participant_id
	_level = entry.access_level
	get_node("Name").text = entry.display_name
	refresh()

func refresh() -> void:
	get_node("Choices/None").disabled = _busy or _level == "None"
	get_node("Choices/Viewer").disabled = _busy or _level == "Viewer"
	get_node("Choices/Owner").disabled = _busy or _level == "Owner"
	get_node("Status").text = "Saving…" if _busy else _level

func set_none() -> void:
	save("None")
func set_viewer() -> void:
	save("Viewer")
func grant_owner() -> void:
	save("Owner")

func save(level: String) -> void:
	if _busy:
		return
	_busy = true
	refresh()
	var result: SDK.OperationResult = await _sdk.actors.set_access(_actor, _participant, level)
	_busy = false
	if result.ok:
		_level = level
	refresh()
	if not result.ok:
		get_node("Status").text = result.message + " Choose an access level to retry."
