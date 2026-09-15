extends PanelContainer
const SDK = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/package_sdk_facade.gd")
const AccessEntry = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/actor_access_entry.gd")
var _sdk: SDK
var _actor: SDK.ActorId
var participant_id: String
var _level: String
var _published_level: String
var _busy: bool = false

func configure(sdk: SDK, actor: SDK.ActorId, entry: AccessEntry) -> void:
	_sdk = sdk
	_actor = actor
	participant_id = entry.participant_id
	_published_level = entry.access_level
	if not _busy:
		_level = _published_level
	get_node("Content/Row/Identity/Name").text = entry.display_name
	get_node("Content/Row/Identity/Presence").text = "Connected" if entry.is_connected else "Offline"
	refresh()

func reflow() -> void:
	var row: BoxContainer = get_node("Content/Row")
	row.vertical = size.x < 440.0

func refresh() -> void:
	get_node("Content/Row/Choices/None").button_pressed = _level == "None"
	get_node("Content/Row/Choices/Viewer").button_pressed = _level == "Viewer"
	get_node("Content/Row/Choices/Owner").button_pressed = _level == "Owner"
	get_node("Content/Row/Choices/None").theme_type_variation = "RookframePrimaryButton" if _level == "None" else "RookframeSecondaryButton"
	get_node("Content/Row/Choices/Viewer").theme_type_variation = "RookframePrimaryButton" if _level == "Viewer" else "RookframeSecondaryButton"
	get_node("Content/Row/Choices/Owner").theme_type_variation = "RookframePrimaryButton" if _level == "Owner" else "RookframeSecondaryButton"
	get_node("Content/Row/Choices/None").disabled = _busy
	get_node("Content/Row/Choices/Viewer").disabled = _busy
	get_node("Content/Row/Choices/Owner").disabled = _busy
	get_node("Content/Status").text = "Updating access…" if _busy else ""
	get_node("Content/Status").visible = _busy

func set_none() -> void:
	save("None")
func set_viewer() -> void:
	save("Viewer")
func grant_owner() -> void:
	save("Owner")

func save(level: String) -> void:
	if _busy or level == _published_level:
		refresh()
		return
	_busy = true
	_level = level
	refresh()
	var result: SDK.OperationResult = await _sdk.actors.set_access(_actor, participant_id, level)
	_busy = false
	_level = _published_level
	var current: SDK.ActorAccessListResult = _sdk.actors.access(_actor)
	if current.ok:
		for entry in current.items:
			if entry.participant_id == participant_id:
				_published_level = entry.access_level
				_level = _published_level
	refresh()
	if not result.ok:
		get_node("Content/Status").text = result.message + " Choose an access level to retry."
		get_node("Content/Status").visible = true
