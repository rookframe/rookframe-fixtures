extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/window.gd"
const TextField = preload("res://rookframe/ui/components/forms/text_field.gd")
const SHEET: SDK.ExtensionSurface = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/actor_sheet.tres")
@onready var actor_name: TextField = get_node("Layout/Fields/ActorName")
@onready var submit: Button = get_node("Layout/Fields/CreateActor")
@onready var status: Label = get_node("Layout/Fields/Status")
var busy: bool = false

func capture_reconnect_state() -> Dictionary:
	return {"actor_name": actor_name.value}

func restore_reconnect_state(state: Dictionary) -> void:
	var title: String = state.get("actor_name", "")
	actor_name.value = title

func create_actor() -> void:
	if busy:
		return
	if actor_name.value.strip_edges().is_empty():
		status.text = "Enter an Actor name."
		return
	busy = true
	submit.disabled = true
	status.text = "Creating Actor…"
	var result: SDK.ActorResult = await sdk.actors.create(SDK.ContentReference.new(sdk.package_id(), "hero"), actor_name.value.strip_edges())
	busy = false
	submit.disabled = false
	if not result.ok:
		status.text = result.message
		return
	actor_name.value = ""
	status.text = "Actor created. You have Owner access."
	var opened: SDK.OperationResult = sdk.windows.open_actor(SHEET, result.actor.id)
	if not opened.ok:
		status.text = opened.message
