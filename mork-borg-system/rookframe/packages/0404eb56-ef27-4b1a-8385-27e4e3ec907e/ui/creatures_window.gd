extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

const CREATURE_KIND := "actor_definition"
const StructuredRow = preload("res://rookframe/ui/components/data/structured_row.gd")

var _route := "creatures"
var _compact := false
var _definitions: Array[SDK.ContentEntry] = []
var _actors: Array[SDK.Actor] = []
var _selected_definition: SDK.ContentEntry
var _selected_actor: SDK.Actor
var _busy := false

@onready var _header_title := get_node(^"Layout/Header/Title") as Label
@onready var _header_subtitle := get_node(^"Layout/Header/Subtitle") as Label
@onready var _routes = get_node(^"Layout/Header/Routes")
@onready var _routes_desktop := get_node(^"Layout/Header/Routes/Desktop") as Control
@onready var _routes_compact := get_node(^"Layout/Header/Routes/Compact") as Control
var _route_creatures: Button
var _route_creature: Button
var _route_edit: Button
var _route_inventory: Button
@onready var _search = get_node(^"Layout/Body/Content/Search")
@onready var _definition_heading := get_node(^"Layout/Body/Content/DefinitionHeading") as Label
@onready var _definition_list := get_node(^"Layout/Body/Content/DefinitionList") as VBoxContainer
@onready var _live_heading := get_node(^"Layout/Body/Content/LiveHeading") as Label
@onready var _live_list := get_node(^"Layout/Body/Content/LiveList") as VBoxContainer
@onready var _public_heading := get_node(^"Layout/Body/Content/PublicHeading") as Label
@onready var _public_list := get_node(^"Layout/Body/Content/PublicList") as VBoxContainer
@onready var _detail := get_node(^"Layout/Body/Content/Detail") as VBoxContainer
@onready var _detail_title := get_node(^"Layout/Body/Content/Detail/Title") as Label
@onready var _detail_summary := get_node(^"Layout/Body/Content/Detail/Summary") as Label
@onready var _public_identity := get_node(^"Layout/Body/Content/Detail/PublicIdentity") as Label
@onready var _private_fields := get_node(^"Layout/Body/Content/Detail/PrivateFields") as VBoxContainer
@onready var _edit_fields := get_node(^"Layout/Body/Content/Detail/EditFields") as VBoxContainer
@onready var _private_name = get_node(^"Layout/Body/Content/Detail/EditFields/PrivateName")
@onready var _public_label = get_node(^"Layout/Body/Content/Detail/EditFields/PublicLabel")
@onready var _hit_points = get_node(^"Layout/Body/Content/Detail/EditFields/HitPoints")
@onready var _maximum_hit_points = get_node(^"Layout/Body/Content/Detail/EditFields/MaximumHitPoints")
@onready var _morale = get_node(^"Layout/Body/Content/Detail/EditFields/Morale")
@onready var _inventory := get_node(^"Layout/Body/Content/Detail/Inventory") as VBoxContainer
@onready var _inventory_items := get_node(^"Layout/Body/Content/Detail/Inventory/Items") as VBoxContainer
@onready var _inventory_summary: StructuredRow = get_node(^"Layout/Body/Content/Detail/Inventory/Items/InventorySummary")
@onready var _action_bar = get_node(^"Layout/Body/Content/ActionBar")
@onready var _action_desktop := get_node(^"Layout/Body/Content/ActionBar/Desktop") as Control
@onready var _action_compact := get_node(^"Layout/Body/Content/ActionBar/Compact") as Control
var _create_button: Button
var _edit_button: Button
var _inventory_button: Button
var _duplicate_button: Button
var _place_button: Button
var _save_button: Button
var _add_item_button: Button
var _back_button: Button
@onready var _status := get_node(^"Layout/Status") as Label


func ready() -> void:
	if sdk == null:
		_set_status("Install the published MÖRK BORG System to load Creature definitions.", true)
		return
	_compact = not sdk.presentation_experience().is_desktop
	_routes_desktop.visible = not _compact
	_routes_compact.visible = _compact
	_action_desktop.visible = not _compact
	_action_compact.visible = _compact
	var route_first_row: Node = _routes.get_node(^"Compact/RowOne") if _compact else _routes.get_node(^"Desktop")
	var route_second_row: Node = route_first_row
	_route_creatures = route_first_row.get_node(^"Creatures") as Button
	_route_creature = route_first_row.get_node(^"Creature") as Button
	_route_edit = route_second_row.get_node(^"EditCreature") as Button
	_route_inventory = route_second_row.get_node(^"CreatureInventory") as Button
	var action_group: Node = _action_bar.get_node(^"Compact") if _compact else _action_bar.get_node(^"Desktop")
	if _compact:
		_create_button = action_group.get_node(^"RowOne/CreateCreature") as Button
		_edit_button = action_group.get_node(^"RowOne/EditCreature") as Button
		_inventory_button = action_group.get_node(^"RowTwo/CreatureInventory") as Button
		_duplicate_button = action_group.get_node(^"RowTwo/Duplicate") as Button
		_place_button = action_group.get_node(^"RowThree/PlaceRook") as Button
		_save_button = action_group.get_node(^"RowThree/SaveChanges") as Button
		_add_item_button = action_group.get_node(^"RowFour/AddItem") as Button
		_back_button = action_group.get_node(^"RowFour/Back") as Button
		_edit_button.text = "Edit"
	else:
		_create_button = action_group.get_node(^"CreateCreature") as Button
		_edit_button = action_group.get_node(^"EditCreature") as Button
		_inventory_button = action_group.get_node(^"CreatureInventory") as Button
		_duplicate_button = action_group.get_node(^"Duplicate") as Button
		_place_button = action_group.get_node(^"PlaceRook") as Button
		_save_button = action_group.get_node(^"SaveChanges") as Button
		_add_item_button = action_group.get_node(^"AddItem") as Button
		_back_button = action_group.get_node(^"Back") as Button
	for button in [
		_route_creatures,
		_route_creature,
		_route_edit,
		_route_inventory,
	]:
		button.focus_mode = 2
	_search.focus_mode = 2
	_search.value_changed.connect(_filter_definitions)
	_route_creatures.pressed.connect(_on_creatures_route)
	_route_creature.pressed.connect(_on_creature_route)
	_route_edit.pressed.connect(_on_edit_route)
	_route_inventory.pressed.connect(_on_inventory_route)
	_edit_button.pressed.connect(_on_edit_route)
	_inventory_button.pressed.connect(_on_inventory_route)
	_create_button.pressed.connect(_create_creature)
	_duplicate_button.pressed.connect(_duplicate_creature)
	_save_button.pressed.connect(_save_creature)
	_place_button.pressed.connect(_place_rook)
	_add_item_button.pressed.connect(_add_item)
	_back_button.pressed.connect(_on_back)
	if sdk.world_changed.is_connected(_refresh_world) == false:
		sdk.world_changed.connect(_refresh_world)
	_refresh_world()


func _refresh_world() -> void:
	if _busy or sdk == null:
		return
	_set_status("Loading Creature catalogue…")
	var content: SDK.ContentEntryListResult = sdk.content.list(SDK.ContentKind.Value.ACTOR_DEFINITION)
	if not content.ok:
		_set_status(content.message, true)
		return
	_definitions = []
	for entry in content.items:
		if entry.kind == SDK.ContentKind.Value.ACTOR_DEFINITION:
			_definitions.append(entry)
	_render_definitions()
	var actors: SDK.ActorListResult = sdk.actors.list()
	if not actors.ok:
		_set_status(actors.message, true)
		return
	_actors = actors.items
	_render_live_actors()
	_render_public_names()
	_set_status("Ready — immutable definitions are available to the GM.")


func _render_definitions() -> void:
	var list: VBoxContainer = _definition_list
	for child in list.get_children():
		child.queue_free()
	for entry in _definitions:
		var button: Button = Button.new()
		button.text = entry.title
		button.custom_minimum_size = Vector2(0, 44)
		button.focus_mode = 2
		button.alignment = 0
		button.pressed.connect(_select_definition.bind(entry))
		list.add_child(button)


func _render_live_actors() -> void:
	var list: VBoxContainer = _live_list
	for child in list.get_children():
		child.queue_free()
	for actor in _actors:
		var button: Button = Button.new()
		button.text = "Private Creature"
		button.custom_minimum_size = Vector2(0, 44)
		button.focus_mode = 2
		button.alignment = 0
		button.pressed.connect(_select_actor.bind(actor))
		list.add_child(button)


func _render_public_names() -> void:
	var list: VBoxContainer = _public_list
	for child in list.get_children():
		child.queue_free()
	if sdk == null:
		return
	var identities: SDK.PublicIdentityListResult = sdk.public_identities.list()
	if not identities.ok:
		_set_status(identities.message, true)
		return
	for identity in identities.items:
		var label: Label = Label.new()
		label.text = identity.label
		label.autowrap_mode = 2
		list.add_child(label)


func _select_definition(entry: SDK.ContentEntry) -> void:
	_selected_definition = entry
	_detail_title.text = entry.title
	_detail_summary.text = "Immutable core Creature definition. Create a private live Actor to edit its encounter sheet."
	_create_button.disabled = false
	_show_route("creatures")


func _select_actor(actor: SDK.Actor) -> void:
	_selected_actor = actor
	_show_route("creature")
	_render_actor()


func _render_actor() -> void:
	if _selected_actor == null:
		return
	_header_title.text = "Private Creature"
	_header_subtitle.text = "Private Creature sheet · GM"
	_detail_title.text = "Private Creature"
	_detail_summary.text = "Private sheet · GM"
	if _selected_actor.public_label.is_empty():
		_public_identity.text = "Public label: Unassigned"
	else:
		_public_identity.text = "Public label: %s" % _selected_actor.public_label
	var actor_data: Dictionary = _selected_actor.data
	var private_name: String = actor_data.get("name", "Creature")
	var hit_points: int = actor_data.get("hit_points", 0)
	var maximum_hit_points: int = actor_data.get("maximum_hit_points", 0)
	var morale: Dictionary = actor_data.get("morale", {})
	var morale_value: int = morale.get("value", 0)
	_private_name.set("value", private_name)
	_public_label.set("value", _selected_actor.public_label)
	_hit_points.set("value", str(hit_points))
	_maximum_hit_points.set("value", str(maximum_hit_points))
	_morale.set("value", str(morale_value))
	_inventory_summary.title = "ITEMS"
	_inventory_summary.value_text = "GM-only"
	_save_button.disabled = not sdk.context().is_gm
	_duplicate_button.disabled = not sdk.context().is_gm
	_place_button.disabled = not sdk.context().is_gm
	_edit_button.disabled = not sdk.context().is_gm
	_inventory_button.disabled = false


func _show_route(route: String) -> void:
	_route = route
	var catalogue := route == "creatures"
	var sheet := route == "creature"
	var edit := route == "edit-creature"
	var inventory := route == "creature-inventory"
	if catalogue:
		_header_title.text = "Creature catalogue"
		_header_subtitle.text = "Immutable definitions · private Actors" if _compact else "Twelve immutable definitions · durable private Actors"
		_set_status("Ready — immutable definitions are available to the GM.")
	_search.set("visible", catalogue)
	_definition_heading.visible = catalogue
	_definition_list.visible = catalogue
	_live_heading.visible = catalogue or not sdk.context().is_gm
	_live_list.visible = catalogue and sdk.context().is_gm
	_public_heading.visible = catalogue
	_public_list.visible = catalogue
	_detail.visible = sheet or edit or inventory
	_private_fields.visible = sheet or edit
	_inventory.visible = inventory
	_edit_fields.visible = edit
	_action_bar.visible = catalogue or edit or inventory or sheet
	_create_button.visible = catalogue and sdk.context().is_gm
	_edit_button.visible = sheet and sdk.context().is_gm
	_inventory_button.visible = sheet
	_duplicate_button.visible = sheet and sdk.context().is_gm
	_place_button.visible = sheet and sdk.context().is_gm
	_save_button.visible = edit and sdk.context().is_gm
	_add_item_button.visible = inventory and sdk.context().is_gm
	_back_button.visible = inventory
	if sheet or edit or inventory:
		_render_actor()


func _on_creatures_route() -> void:
	_show_route("creatures")


func _on_creature_route() -> void:
	_show_route("creature")


func _on_edit_route() -> void:
	_show_route("edit-creature")


func _on_inventory_route() -> void:
	_show_route("creature-inventory")


func _filter_definitions(_query: String) -> void:
	var query: String = str(_search.get("value")).strip_edges()
	for child in _definition_list.get_children():
		var button := child as Button
		if button != null:
			button.visible = query.is_empty() or button.text.to_lower().contains(query.to_lower())


func _create_creature() -> void:
	if _busy or _selected_definition == null or sdk == null:
		return
	_set_busy(true, "Creating private Creature sheet…")
	var result: SDK.ActorResult = await sdk.actors.create(_selected_definition.reference, {})
	_set_busy(false, result.message if not result.ok else "Creature created.", not result.ok)
	if result.ok:
		_selected_actor = result.actor
		_show_route("creature")
		_render_live_actors()


func _duplicate_creature() -> void:
	if _busy or _selected_actor == null or sdk == null:
		return
	var source: SDK.ActorResult = sdk.actors.read(_selected_actor.id)
	if not source.ok or source.actor == null:
		_set_status(source.message if not source.ok else "Private Creature data is unavailable.", true)
		return
	var data: Dictionary = source.actor.data
	if _selected_definition == null:
		_set_status("Select an immutable Creature definition before duplicating.", true)
		return
	var definition_id: String = _selected_definition.reference.local_id
	_set_busy(true, "Duplicating private Creature sheet…")
	var result: SDK.ActorResult = await sdk.actors.create(SDK.ContentReference.new(sdk.package_id(), definition_id), data)
	_set_busy(false, result.message if not result.ok else "Creature duplicated.", not result.ok)
	if result.ok:
		_selected_actor = result.actor
		_show_route("creature")


func _save_creature() -> void:
	if _busy or _selected_actor == null or sdk == null:
		return
	var source: SDK.ActorResult = sdk.actors.read(_selected_actor.id)
	if not source.ok or source.actor == null:
		_set_status(source.message if not source.ok else "Private Creature data is unavailable.", true)
		return
	var data: Dictionary = source.actor.data
	data["name"] = str(_private_name.get("value")).strip_edges()
	data["hit_points"] = int(_hit_points.get("value"))
	data["maximum_hit_points"] = int(_maximum_hit_points.get("value"))
	data["morale"] = {"kind": "fixed", "value": int(_morale.get("value"))}
	_set_busy(true, "Saving private Creature sheet…")
	var updated: SDK.ActorResult = await sdk.actors.update(_selected_actor.id, data)
	if updated.ok and sdk.context().is_gm:
		var label: String = str(_public_label.get("value")).strip_edges()
		var identity: SDK.OperationResult = await sdk.public_identities.assign(_selected_actor.id, label)
		if not identity.ok:
			updated.ok = false
			updated.message = identity.message
	_set_busy(false, updated.message if not updated.ok else "Creature changes saved.", not updated.ok)
	if updated.ok:
		_selected_actor = updated.actor
		_show_route("creature")


func _place_rook() -> void:
	if _busy or _selected_actor == null or sdk == null:
		return
	var miniatures: SDK.ContentEntryListResult = sdk.content.list(SDK.ContentKind.Value.MINIATURE)
	if not miniatures.ok or miniatures.items.is_empty():
		_set_status("Choose a published Miniature Package before placing this Rook.", true)
		return
	_set_busy(true, "Placing Rook and assigning its public identity…")
	var created: SDK.RookResult = await sdk.rooks.create(miniatures.items[0].reference, SDK.SceneId.new("main"), Vector2(0, 0))
	if not created.ok:
		_set_busy(false, created.message, true)
		return
	var linked: SDK.OperationResult = await sdk.rooks.link(created.rook.id, _selected_actor.id)
	if not linked.ok:
		_set_busy(false, linked.message, true)
		return
	var label := _selected_actor.public_label
	if label.is_empty():
		label = str((_detail_title.text if _selected_actor != null else "Creature"))
	var identity: SDK.OperationResult = await sdk.public_identities.assign(_selected_actor.id, label)
	_set_busy(false, identity.message if not identity.ok else "Rook placed with a separate public label.", not identity.ok)
	_refresh_world()


func _add_item() -> void:
	if _selected_actor == null:
		return
	_set_status("Inventory is durable Actor data. Add an item through the private sheet editor.")


func _on_back() -> void:
	_show_route("creature")


func _set_busy(value: bool, message: String, error: bool = false) -> void:
	_busy = value
	_set_status(message, error)
	_create_button.disabled = value
	_duplicate_button.disabled = value
	_save_button.disabled = value
	_place_button.disabled = value
	_add_item_button.disabled = value


func _set_status(message: String, error: bool = false) -> void:
	_status.text = message
	_status.tooltip_text = message
