extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/window.gd"

const HeroData = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/logic/hero_data.gd")
const Rules = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/logic/hero_rules.gd")
const AccessRow = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/access_row.gd")
const ACCESS_ROW: PackedScene = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/access_row.tscn")
@onready var name_label: Label = get_node("Layout/Header/Name")
@onready var hp_label: Label = get_node("Layout/Body/Fields/Character/HitPoints")
@onready var status: Label = get_node("Layout/Status")
@onready var train: Button = get_node("Layout/Body/Fields/Character/Train")
var actor_id: SDK.ActorId
var busy: bool = false
var access_rows: Array[AccessRow] = []

func ready() -> void:
	if sdk != null:
		sdk.world_changed.connect(refresh)
		sdk.targeting.changed.connect(show_targets)
		sdk.feedback.action_selected.connect(confirm_delete)
	show_character()

func opened(actor: SDK.ActorId) -> void:
	actor_id = actor
	refresh()
	var targets: SDK.TargetSnapshotResult = await sdk.targeting.snapshot()
	if targets.ok:
		show_targets(targets.snapshot)

func show_targets(snapshot: SDK.TargetSnapshot) -> void:
	if actor_id != null:
		refresh_access()
	if snapshot.session_id == sdk.context().session_id:
		get_node("Layout/Body/Fields/Character/Targets").text = "Your targets: " + str(snapshot.rooks.size())

func refresh() -> void:
	if actor_id == null or sdk == null:
		return
	var result: SDK.ActorResult = sdk.actors.read(actor_id)
	if not result.ok:
		train.disabled = true
		status.text = result.message
		return
	var hero: HeroData = result.actor.data
	name_label.text = hero.display_name
	hp_label.text = str(hero.hit_points)
	var can_edit: bool = result.actor.access_level == "Owner"
	get_node("Layout/Header/ViewOnly").visible = not can_edit
	train.disabled = busy or not can_edit
	get_node("Layout/Body/Fields/Character/Delete").disabled = busy or not can_edit
	get_node("Layout/Tabs/Access").visible = sdk.context().is_gm
	get_node("Layout/Body/Fields/Access/GM/Identity/Name").text = sdk.context().display_name
	get_node("Layout/Body/Fields/Access/Title").text = "Share " + hero.display_name
	refresh_access()

func train_actor() -> void:
	if busy or actor_id == null:
		return
	var result: SDK.ActorResult = sdk.actors.read(actor_id)
	if not result.ok:
		status.text = result.message
		return
	var hero: HeroData = result.actor.data
	busy = true
	train.disabled = true
	status.text = "Saving…"
	var saved: SDK.ActorResult = await sdk.actors.update(actor_id, Rules.new().train(hero))
	busy = false
	refresh()
	status.text = "Training saved: +1 HP." if saved.ok else saved.message

func delete_actor() -> void:
	if busy or actor_id == null:
		return
	var message: SDK.FeedbackMessage = SDK.FeedbackMessage.new()
	message.title = "Delete " + name_label.text + "?"
	message.message = "The Actor will be deleted. Its Rooks will remain on the tabletop."
	var confirm: SDK.FeedbackAction = SDK.FeedbackAction.new()
	confirm.id = "delete_actor"
	confirm.title = "Delete Actor"
	message.actions.append(confirm)
	sdk.feedback.confirm(message)

func confirm_delete(action: String) -> void:
	if action != "delete_actor" or busy:
		return
	busy = true
	refresh()
	var result: SDK.OperationResult = await sdk.actors.delete(actor_id)
	if not result.ok:
		busy = false
		refresh()
		status.text = result.message

func show_character() -> void:
	get_node("Layout/Body/Fields/Character").visible = true
	get_node("Layout/Body/Fields/Access").visible = false
	get_node("Layout/Tabs/Character").button_pressed = true
	get_node("Layout/Tabs/Access").button_pressed = false

func show_access() -> void:
	get_node("Layout/Body/Fields/Character").visible = false
	get_node("Layout/Body/Fields/Access").visible = true
	get_node("Layout/Tabs/Character").button_pressed = false
	get_node("Layout/Tabs/Access").button_pressed = true

func refresh_access() -> void:
	if not sdk.context().is_gm:
		return
	var entries: SDK.ActorAccessListResult = sdk.actors.access(actor_id)
	if not entries.ok:
		status.text = entries.message
		return
	var rows: VBoxContainer = get_node("Layout/Body/Fields/Access/Rows")
	var active: Array[AccessRow] = []
	for entry in entries.items:
		var row: AccessRow
		for existing in access_rows:
			if existing.participant_id == entry.participant_id:
				row = existing
		if row == null:
			row = ACCESS_ROW.instantiate()
			rows.add_child(row)
		row.configure(sdk, actor_id, entry)
		active.append(row)
	for previous in rows.get_children():
		if not active.has(previous):
			rows.remove_child(previous)
			previous.queue_free()
	access_rows = active
