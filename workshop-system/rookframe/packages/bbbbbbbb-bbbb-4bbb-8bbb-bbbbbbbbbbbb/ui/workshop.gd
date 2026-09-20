extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/window.gd"
const TextField = preload("res://rookframe/ui/components/forms/text_field.gd")
@onready var journal_title: TextField = get_node("Layout/Body/Fields/Journal/JournalTitle")
@onready var status: Label = get_node("Layout/Status")
var selected_record: SDK.SystemRecordId
var busy: bool = false

func capture_reconnect_state() -> Dictionary:
	return {"journal_title": journal_title.value}

func restore_reconnect_state(state: Dictionary) -> void:
	var title: String = state.get("journal_title", "")
	journal_title.value = title

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
	get_node("Layout/Body/Fields/ResolveAttack").disabled = busy

func resolve_attack() -> void:
	if busy:
		return
	busy = true
	refresh()
	var request := SDK.DiceRequest.new([
		SDK.DiceTerm.new("attack", 20),
		SDK.DiceTerm.new("damage", 6, 2)
	])
	var rolled: SDK.DiceRollResult = await sdk.dice.roll(request)
	if not rolled.ok:
		finish(rolled, "")
		return
	var attack: int = rolled.terms[0].results[0]
	var damage: int = 0
	for value in rolled.terms[1].results:
		damage += value
	var hit: bool = attack >= 12
	var report := SDK.ActionLogMessage.new("Workshop attack")
	report.text = [SDK.ActionLogText.new("Attack %d " % attack, "strong"),
		SDK.ActionLogText.new("meets DR 12." if hit else "misses DR 12.")]
	for term in rolled.terms:
		for value in term.results:
			report.dice.append(SDK.ActionLogDie.new(term.faces, value))
	report.result = ("HIT · %d" % damage) if hit else "MISS"
	report.tone = "success" if hit else "attention"
	var published: SDK.ActionLogResult = await sdk.action_log.publish(report)
	finish(published, "Attack resolved and shared.")

func create_entry() -> void:
	if busy or journal_title.value.strip_edges().is_empty():
		return
	busy = true
	refresh()
	var result: SDK.SystemRecordResult = await sdk.system_records.create("journal", {"title": journal_title.value.strip_edges()})
	if result.ok:
		selected_record = result.system_record.id
		var report := SDK.ActionLogMessage.new("Journal entry added")
		report.text = [SDK.ActionLogText.new(journal_title.value.strip_edges(), "strong")]
		report.tone = "success"
		var published: SDK.ActionLogResult = await sdk.action_log.publish(report)
		if not published.ok:
			finish(published, "")
			return
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
