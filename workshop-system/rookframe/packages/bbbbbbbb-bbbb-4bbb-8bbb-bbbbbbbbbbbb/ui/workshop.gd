extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/window.gd"

const Settings = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/logic/settings.gd")
const Rules = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/logic/hero_rules.gd")
const AccessRow = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/access_row.gd")
const ACCESS_ROW: PackedScene = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/access_row.tscn")
const HeroData = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/logic/hero_data.gd")
const TextField = preload("res://rookframe/ui/components/forms/text_field.gd")
@onready var actor_name: TextField = get_node("Layout/Body/Fields/ActorName")
@onready var journal_title: TextField = get_node("Layout/Body/Fields/JournalTitle")
@onready var status: Label = get_node("Layout/Status")
var selected_actor: SDK.ActorId
var selected_record: SDK.SystemRecordId
var busy: bool = false
var actor_view: bool = true
var choose_first: bool = true

func ready() -> void:
	if sdk != null:
		sdk.world_changed.connect(refresh)
		sdk.targeting.changed.connect(targeting_changed)
		refresh()
		refresh_targets()
	show_actors()

func refresh() -> void:
	get_node("Layout/Header").text = sdk.settings.user.text(Settings.LOCAL_LABEL) + " · " + sdk.settings.world.text(Settings.WORLD_LABEL)
	var actors: SDK.ActorListResult = sdk.actors.list()
	var records: SDK.SystemRecordListResult = sdk.system_records.list("journal")
	if not actors.ok:
		status.text = actors.message
		return
	if not records.ok:
		status.text = records.message
		return
	if choose_first and selected_actor == null and not actors.items.is_empty():
		selected_actor = actors.items[0].id
		choose_first = false
	if selected_record == null and not records.items.is_empty():
		selected_record = records.items[0].id
	get_node("Layout/Body/Fields/ActorSummary").text = "No Actor selected"
	var can_edit: bool = false
	if selected_actor != null:
		var found: SDK.ActorResult = sdk.actors.read(selected_actor)
		if found.ok:
			can_edit = found.actor.access_level == "Owner"
			var hero: HeroData = found.actor.data
			get_node("Layout/Body/Fields/ActorSummary").text = hero.display_name + " · HP " + str(hero.hit_points) + " · " + str(actors.items.size()) + " Actors" + (" · VIEW ONLY" if not can_edit else "")
		elif found.code == "access_denied":
			selected_actor = null
			status.text = "Actor access was removed. Its Rooks remain on the tabletop."
	get_node("Layout/Body/Fields/JournalSummary").text = "No journal entry selected"
	if selected_record != null:
		var found: SDK.SystemRecordResult = sdk.system_records.read(selected_record)
		if found.ok:
			var data: Dictionary = found.system_record.data
			var title: String = data.get("title")
			get_node("Layout/Body/Fields/JournalSummary").text = title + " · " + str(records.items.size()) + " entries"
	get_node("Layout/Body/Fields/TrainActor").disabled = busy or not can_edit
	get_node("Layout/Body/Fields/DeleteActor").disabled = busy or not can_edit
	get_node("Layout/Body/Fields/SaveEntry").disabled = busy or selected_record == null or not sdk.context().is_gm
	get_node("Layout/Body/Fields/DeleteEntry").disabled = busy or selected_record == null or not sdk.context().is_gm
	get_node("Layout/Body/Fields/CreateEntry").disabled = busy or not sdk.context().is_gm
	get_node("Layout/Body/Fields/CreateActor").disabled = busy
	get_node("Layout/Body/Fields/NextActor").disabled = busy or actors.items.is_empty()
	refresh_access()
	show_view(actor_view)

func create_actor() -> void:
	if busy:
		return
	if actor_name.value.strip_edges().is_empty():
		status.text = "Enter a name before confirming Actor creation."
		return
	var definition: SDK.ContentReference = SDK.ContentReference.new(sdk.package_id(), "hero")
	begin_action()
	var result: SDK.ActorResult = await sdk.actors.create(definition, actor_name.value)
	busy = false
	refresh()
	if result.ok:
		selected_actor = result.actor.id
		refresh()
		status.text = "Actor saved. You have Owner access."
	else:
		status.text = result.message

func train_actor() -> void:
	if busy:
		return
	if selected_actor == null:
		return
	var actor: SDK.ActorId = selected_actor
	begin_action()
	var targeting: SDK.TargetSnapshotResult = await sdk.targeting.snapshot()
	if not targeting.ok:
		finish(targeting, "")
		return
	var found: SDK.ActorResult = sdk.actors.read(actor)
	if not found.ok:
		finish(found, "")
		return
	var hero: HeroData = found.actor.data
	hero = Rules.new().train(hero)
	var result: SDK.ActorResult = await sdk.actors.update(actor, hero)
	finish(result, "Training saved: +1 HP.")

func delete_actor() -> void:
	if busy:
		return
	if selected_actor == null:
		return
	begin_action()
	var result: SDK.OperationResult = await sdk.actors.delete(selected_actor)
	if result.ok:
		selected_actor = null
	finish(result, "Actor deleted; its Rooks remain independent.")

func create_entry() -> void:
	if busy:
		return
	if journal_title.value.strip_edges().is_empty():
		status.text = "Enter a journal title."
		return
	begin_action()
	var result: SDK.SystemRecordResult = await sdk.system_records.create("journal", {"title": journal_title.value.strip_edges()})
	if result.ok:
		selected_record = result.system_record.id
	finish(result, "Journal entry saved.")

func save_entry() -> void:
	if busy:
		return
	if selected_record == null or journal_title.value.strip_edges().is_empty():
		status.text = "Select an entry and enter a journal title."
		return
	begin_action()
	var result: SDK.SystemRecordResult = await sdk.system_records.update(selected_record, {"title": journal_title.value.strip_edges()})
	finish(result, "Journal entry updated.")

func delete_entry() -> void:
	if busy:
		return
	if selected_record == null:
		return
	begin_action()
	var result: SDK.OperationResult = await sdk.system_records.delete(selected_record)
	if result.ok:
		selected_record = null
	finish(result, "Journal entry deleted.")

func finish(result: SDK.OperationResult, message: String) -> void:
	busy = false
	refresh()
	if result.ok:
		status.text = message
	else:
		status.text = result.message

func show_actors() -> void:
	show_view(true)

func show_journal() -> void:
	show_view(false)

func show_view(actors: bool) -> void:
	actor_view = actors
	get_node("Layout/Body/Fields/NextActor").visible = actors
	get_node("Layout/Body/Fields/Access").visible = actors and selected_actor != null and sdk != null and sdk.context().is_gm
	get_node("Layout/Body/Fields/ActorHeading").visible = actors
	get_node("Layout/Body/Fields/ActorName").visible = actors
	get_node("Layout/Body/Fields/CreateActor").visible = actors
	get_node("Layout/Body/Fields/ActorSummary").visible = actors
	get_node("Layout/Body/Fields/TrainActor").visible = actors
	get_node("Layout/Body/Fields/DeleteActor").visible = actors
	get_node("Layout/Body/Fields/JournalHeading").visible = not actors
	get_node("Layout/Body/Fields/JournalTitle").visible = not actors
	get_node("Layout/Body/Fields/CreateEntry").visible = not actors
	get_node("Layout/Body/Fields/JournalSummary").visible = not actors
	get_node("Layout/Body/Fields/SaveEntry").visible = not actors
	get_node("Layout/Body/Fields/DeleteEntry").visible = not actors
	get_node("Layout/Views/Actors").disabled = actors
	get_node("Layout/Views/Journal").disabled = not actors

func begin_action() -> void:
	busy = true
	status.text = "Saving…"
	refresh()

func next_actor() -> void:
	var actors: SDK.ActorListResult = sdk.actors.list()
	if not actors.ok or actors.items.is_empty():
		return
	var next: int = 0
	for index in range(actors.items.size()):
		if selected_actor != null and actors.items[index].id.value == selected_actor.value:
			next = (index + 1) % actors.items.size()
	selected_actor = actors.items[next].id
	choose_first = false
	refresh()

func refresh_targets() -> void:
	var result: SDK.TargetSnapshotResult = await sdk.targeting.snapshot()
	if result.ok:
		targeting_changed(result.snapshot)

func targeting_changed(snapshot: SDK.TargetSnapshot) -> void:
	if snapshot.session_id == sdk.context().session_id:
		get_node("Layout/Targets").text = "Shared targets: " + str(snapshot.rooks.size())

func refresh_access() -> void:
	if sdk == null:
		return
	var rows: VBoxContainer = get_node("Layout/Body/Fields/Access/Rows")
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	if selected_actor == null or not sdk.context().is_gm:
		return
	var result: SDK.ActorAccessListResult = sdk.actors.access(selected_actor)
	if not result.ok:
		return
	for entry in result.items:
		var row: AccessRow = ACCESS_ROW.instantiate()
		rows.add_child(row)
		row.configure(sdk, selected_actor, entry)
