extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/window.gd"
const TextField = preload("res://rookframe/ui/components/forms/text_field.gd")
@onready var journal_title: TextField = get_node("Layout/Body/Fields/Journal/JournalTitle")
@onready var status: Label = get_node("Layout/Status")
var selected_record: SDK.SystemRecordId
var busy: bool = false

func ready() -> void:
	if sdk != null:
		sdk.world_changed.connect(refresh)
		refresh()

func refresh() -> void:
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
	get_node("Layout/Body/Fields/Journal/CreateEntry").disabled = busy or not sdk.context().is_gm
	get_node("Layout/Body/Fields/Journal/SaveEntry").disabled = busy or selected_record == null or not sdk.context().is_gm
	get_node("Layout/Body/Fields/Journal/DeleteEntry").disabled = busy or selected_record == null or not sdk.context().is_gm

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
