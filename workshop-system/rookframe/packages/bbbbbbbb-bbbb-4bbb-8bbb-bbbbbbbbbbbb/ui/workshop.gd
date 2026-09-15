extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/window.gd"
const ActorRow = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/actor_row.gd")
const ACTOR_ROW: PackedScene = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/actor_row.tscn")
const SHEET: SDK.ExtensionSurface = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/actor_sheet.tres")
const TextField = preload("res://rookframe/ui/components/forms/text_field.gd")
@onready var actor_name: TextField = get_node("Layout/Body/Fields/Actors/ActorName")
@onready var journal_title: TextField = get_node("Layout/Body/Fields/Journal/JournalTitle")
@onready var status: Label = get_node("Layout/Status")
var selected_record: SDK.SystemRecordId
var busy: bool = false

func ready() -> void:
	if sdk != null:
		sdk.world_changed.connect(refresh)
		refresh()
	show_actors()

func refresh() -> void:
	var actors: SDK.ActorListResult = sdk.actors.list()
	var rows: VBoxContainer = get_node("Layout/Body/Fields/Actors/Rows")
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	if actors.ok:
		for actor in actors.items:
			var row: ActorRow = ACTOR_ROW.instantiate()
			rows.add_child(row)
			row.configure(sdk, actor)
	get_node("Layout/Body/Fields/Actors/Empty").visible = actors.ok and actors.items.is_empty()
	if not actors.ok:
		status.text = actors.message
	var records: SDK.SystemRecordListResult = sdk.system_records.list("journal")
	if records.ok and selected_record == null and not records.items.is_empty():
		selected_record = records.items[0].id
	get_node("Layout/Body/Fields/Journal/Summary").text = "No journal entry selected"
	if selected_record != null:
		var result: SDK.SystemRecordResult = sdk.system_records.read(selected_record)
		if result.ok:
			var data: Dictionary = result.system_record.data
			var title: String = data.get("title")
			get_node("Layout/Body/Fields/Journal/Summary").text = title
	get_node("Layout/Body/Fields/Actors/CreateActor").disabled = busy
	get_node("Layout/Body/Fields/Journal/CreateEntry").disabled = busy or not sdk.context().is_gm
	get_node("Layout/Body/Fields/Journal/SaveEntry").disabled = busy or selected_record == null or not sdk.context().is_gm
	get_node("Layout/Body/Fields/Journal/DeleteEntry").disabled = busy or selected_record == null or not sdk.context().is_gm

func create_actor() -> void:
	if busy:
		return
	if actor_name.value.strip_edges().is_empty():
		status.text = "Enter a name before confirming Actor creation."
		return
	busy = true
	refresh()
	var result: SDK.ActorResult = await sdk.actors.create(SDK.ContentReference.new(sdk.package_id(), "hero"), actor_name.value)
	busy = false
	refresh()
	if result.ok:
		actor_name.value = ""
		var opened: SDK.OperationResult = sdk.windows.open_actor(SHEET, result.actor.id)
		status.text = "Actor created. You have Owner access." if opened.ok else opened.message
	else:
		status.text = result.message

func create_entry() -> void:
	if busy or journal_title.value.strip_edges().is_empty():
		return
	busy = true
	refresh()
	var result: SDK.SystemRecordResult = await sdk.system_records.create("journal", {"title": journal_title.value.strip_edges()})
	if result.ok:
		selected_record = result.system_record.id
	finish(result, "Journal entry saved.")

func save_entry() -> void:
	if busy or selected_record == null or journal_title.value.strip_edges().is_empty():
		return
	busy = true
	refresh()
	finish(await sdk.system_records.update(selected_record, {"title": journal_title.value.strip_edges()}), "Journal entry updated.")

func delete_entry() -> void:
	if busy or selected_record == null:
		return
	busy = true
	refresh()
	var result: SDK.OperationResult = await sdk.system_records.delete(selected_record)
	if result.ok:
		selected_record = null
	finish(result, "Journal entry deleted.")

func finish(result: SDK.OperationResult, message: String) -> void:
	busy = false
	refresh()
	status.text = message if result.ok else result.message

func show_actors() -> void:
	get_node("Layout/Body/Fields/Actors").visible = true
	get_node("Layout/Body/Fields/Journal").visible = false
	get_node("Layout/Tabs/Actors").button_pressed = true
	get_node("Layout/Tabs/Journal").button_pressed = false

func show_journal() -> void:
	get_node("Layout/Body/Fields/Actors").visible = false
	get_node("Layout/Body/Fields/Journal").visible = true
	get_node("Layout/Tabs/Actors").button_pressed = false
	get_node("Layout/Tabs/Journal").button_pressed = true
