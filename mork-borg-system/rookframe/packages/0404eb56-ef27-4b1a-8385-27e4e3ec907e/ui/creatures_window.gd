extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

const CREATURE_KIND := "actor_definition"

var _route := "creatures"
var _compact := false
var _definitions: Array[SDK.ContentEntry] = []
var _actors: Array[SDK.Actor] = []
var _selected_definition: SDK.ContentEntry
var _selected_actor: SDK.Actor
var _busy := false

@onready var _layout := get_node(^"Layout") as VBoxContainer
@onready var _header := get_node(^"Layout/Header") as VBoxContainer
@onready var _brand := get_node(^"Layout/Header/Brand") as Label
@onready var _header_title := get_node(^"Layout/Header/Title") as Label
@onready var _header_subtitle := get_node(^"Layout/Header/Subtitle") as Label
@onready var _routes := get_node(^"Layout/Header/Routes") as Control
@onready var _routes_desktop := get_node(^"Layout/Header/Routes/Desktop") as Control
@onready var _routes_compact := get_node(^"Layout/Header/Routes/Compact") as Control
var _route_creatures: Button
var _route_creature: Button
var _route_edit: Button
var _route_inventory: Button
@onready var _body := get_node(^"Layout/Body") as ScrollContainer
@onready var _content := get_node(^"Layout/Body/Content") as VBoxContainer
@onready var _search = get_node(^"Layout/Body/Content/Search")
@onready var _definition_heading := get_node(^"Layout/Body/Content/DefinitionHeading") as Label
@onready var _definition_list := get_node(^"Layout/Body/Content/DefinitionList") as VBoxContainer
@onready var _live_heading := get_node(^"Layout/Body/Content/LiveHeading") as Label
@onready var _live_list := get_node(^"Layout/Body/Content/LiveList") as VBoxContainer
@onready var _public_heading := get_node(^"Layout/Body/Content/PublicHeading") as Label
@onready var _public_list := get_node(^"Layout/Body/Content/PublicList") as VBoxContainer
@onready var _detail := get_node(^"Layout/Body/Content/Detail") as VBoxContainer
@onready var _stats := get_node(^"Layout/Body/Content/Detail/Stats") as Control
@onready var _hit_points_metric := get_node(^"Layout/Body/Content/Detail/Stats/HitPoints/Content/Value") as Label
@onready var _morale_metric := get_node(^"Layout/Body/Content/Detail/Stats/Morale/Content/Value") as Label
@onready var _protection_metric := get_node(^"Layout/Body/Content/Detail/Stats/Protection/Content/Value") as Label
@onready var _protection_label := get_node(^"Layout/Body/Content/Detail/Stats/Protection/Content/Label") as Label
@onready var _sheet_grid := get_node(^"Layout/Body/Content/Detail/SheetGrid") as BoxContainer
@onready var _identity_section := get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/IdentitySection") as Control
@onready var _public_identity := get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/IdentitySection/Content/BodySlot/PublicIdentity") as Label
@onready var _equipment_section := get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/EquipmentSection") as Control
@onready var _equipment_list := get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/EquipmentSection/Content/BodySlot/EquipmentList") as VBoxContainer
@onready var _rules_section := get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/SpecialRulesSection") as Control
@onready var _rules := get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/SpecialRulesSection/Content/BodySlot/Rules") as Label
@onready var _access_section := get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/AccessSection") as Control
@onready var _edit_fields := get_node(^"Layout/Body/Content/Detail/EditFields") as VBoxContainer
@onready var _private_name = get_node(^"Layout/Body/Content/Detail/EditFields/PrivateName")
@onready var _public_label = get_node(^"Layout/Body/Content/Detail/EditFields/PublicLabel")
@onready var _hit_points = get_node(^"Layout/Body/Content/Detail/EditFields/HitPoints")
@onready var _maximum_hit_points = get_node(^"Layout/Body/Content/Detail/EditFields/MaximumHitPoints")
@onready var _morale = get_node(^"Layout/Body/Content/Detail/EditFields/Morale")
@onready var _inventory := get_node(^"Layout/Body/Content/Detail/Inventory") as Control
@onready var _inventory_items := get_node(^"Layout/Body/Content/Detail/Inventory/Content/BodySlot/Items") as VBoxContainer
@onready var _inventory_carried := get_node(^"Layout/Body/Content/Detail/Inventory/Content/BodySlot/CarriedItems") as VBoxContainer
@onready var _inventory_add := get_node(^"Layout/Body/Content/Detail/Inventory/Content/Header/AddItem") as Button
@onready var _action_bar := get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/ActionBar") as Control
@onready var _catalogue_bar := get_node(^"Layout/CatalogueBar") as Control
@onready var _status := get_node(^"Layout/Status") as Label
var _create_button: Button
var _edit_button: Button
var _inventory_button: Button
var _duplicate_button: Button
var _place_button: Button
var _save_button: Button
var _add_item_button: Button
var _back_button: Button
var _catalogue_create: Button
var _catalogue_back: Button


func ready() -> void:
	if sdk == null:
		_set_status("Install the published MÖRK BORG System to load Creature definitions.", true)
		return
	_compact = not sdk.presentation_experience().is_desktop
	_routes_desktop.visible = not _compact
	_routes_compact.visible = _compact
	var route_group: Node = _routes_compact if _compact else _routes_desktop
	_route_creatures = route_group.get_node(^"Creatures") as Button
	_route_creature = route_group.get_node(^"Creature") as Button
	_route_edit = route_group.get_node(^"EditCreature") as Button
	_route_inventory = route_group.get_node(^"CreatureInventory") as Button

	_create_button = _action_bar.get_node(^"LeadingSlot/CreateCreature") as Button
	_edit_button = _action_bar.get_node(^"LeadingSlot/EditCreature") as Button
	_inventory_button = _action_bar.get_node(^"LeadingSlot/CreatureInventory") as Button
	_duplicate_button = _action_bar.get_node(^"LeadingSlot/Duplicate") as Button
	_place_button = _action_bar.get_node(^"LeadingSlot/PlaceRook") as Button
	_save_button = _action_bar.get_node(^"LeadingSlot/SaveChanges") as Button
	_add_item_button = _action_bar.get_node(^"LeadingSlot/AddItem") as Button
	_back_button = _action_bar.get_node(^"LeadingSlot/Back") as Button
	_catalogue_create = _catalogue_bar.get_node(^"TrailingSlot/CreateCreature") as Button
	_catalogue_back = _catalogue_bar.get_node(^"LeadingSlot/Back") as Button

	for button in [
		_route_creatures,
		_route_creature,
		_route_edit,
		_route_inventory,
		_search,
		_create_button,
		_edit_button,
		_inventory_button,
		_duplicate_button,
		_place_button,
		_save_button,
		_add_item_button,
		_inventory_add,
		_back_button,
		_catalogue_create,
		_catalogue_back,
	]:
		button.focus_mode = 2

	_search.value_changed.connect(_filter_definitions)
	_route_creatures.pressed.connect(_on_creatures_route)
	_route_creature.pressed.connect(_on_creature_route)
	_route_edit.pressed.connect(_on_edit_route)
	_route_inventory.pressed.connect(_on_inventory_route)
	_edit_button.pressed.connect(_on_edit_route)
	_inventory_button.pressed.connect(_on_inventory_route)
	_create_button.pressed.connect(_create_creature)
	_catalogue_create.pressed.connect(_create_creature)
	_duplicate_button.pressed.connect(_duplicate_creature)
	_save_button.pressed.connect(_save_creature)
	_place_button.pressed.connect(_place_rook)
	_add_item_button.pressed.connect(_add_item)
	_inventory_add.pressed.connect(_add_item)
	_back_button.pressed.connect(_on_back)
	_catalogue_back.pressed.connect(_on_back)
	if sdk.world_changed.is_connected(_refresh_world) == false:
		sdk.world_changed.connect(_refresh_world)
	_apply_density()
	_show_route("creatures")
	_refresh_world()


func _apply_density() -> void:
	_layout.add_theme_constant_override("separation", 6 if _compact else 10)
	_header.add_theme_constant_override("separation", 2 if _compact else 4)
	_content.add_theme_constant_override("separation", 8 if _compact else 12)
	_detail.add_theme_constant_override("separation", 8 if _compact else 12)
	_sheet_grid.vertical = _compact
	_sheet_grid.add_theme_constant_override("separation", 12 if _compact else 20)
	_content.custom_minimum_size = Vector2(0, 0) if _compact else Vector2(0, 520)
	_brand.visible = not _compact
	_header_subtitle.visible = not _compact
	_header_title.visible = true
	_status.visible = not _compact
	_body.add_theme_constant_override("scrollbar_width", 8 if _compact else 12)
	_stats.add_theme_constant_override("separation", 2 if _compact else 4)
	if _compact:
		get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/IdentitySection/Content/Header/Description").visible = false
		get_node(^"Layout/Body/Content/Detail/SheetGrid/Left/EquipmentSection/Content/Header/Description").visible = false
		get_node(^"Layout/Body/Content/Detail/SheetGrid/Right/AccessSection/Content/Header/Description").visible = false
		get_node(^"Layout/Body/Content/Detail/Inventory/Content/Header/Description").visible = false
		_protection_label.text = "ARMOR"


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
	for child in _definition_list.get_children():
		child.queue_free()
	for entry in _definitions:
		var button := Button.new()
		button.text = entry.title
		button.custom_minimum_size = Vector2(0, 44)
		button.focus_mode = 2
		button.alignment = 0
		button.theme_type_variation = "RookframeSecondaryButton"
		button.pressed.connect(_select_definition.bind(entry))
		_definition_list.add_child(button)


func _render_live_actors() -> void:
	for child in _live_list.get_children():
		child.queue_free()
	for actor in _actors:
		var button := Button.new()
		var actor_data: Dictionary = actor.data
		var private_name: String = actor_data.get("name", "Private Creature")
		var public_name := actor.public_label if not actor.public_label.is_empty() else "Public name pending"
		button.text = "%s  ·  Public: %s" % [private_name, public_name]
		button.custom_minimum_size = Vector2(0, 44)
		button.focus_mode = 2
		button.alignment = 0
		button.theme_type_variation = "RookframeSecondaryButton"
		button.pressed.connect(_select_actor.bind(actor))
		_live_list.add_child(button)


func _render_public_names() -> void:
	for child in _public_list.get_children():
		child.queue_free()
	if sdk == null:
		return
	var identities: SDK.PublicIdentityListResult = sdk.public_identities.list()
	if not identities.ok:
		_set_status(identities.message, true)
		return
	for identity in identities.items:
		var label := Label.new()
		label.text = identity.label
		label.autowrap_mode = 2
		_public_list.add_child(label)


func _select_definition(entry: SDK.ContentEntry) -> void:
	_selected_definition = entry
	_create_button.disabled = false
	_catalogue_create.disabled = false
	_set_status("Selected %s. Create a private Actor to edit its encounter sheet." % entry.title)
	_show_route("creatures")


func _select_actor(actor: SDK.Actor) -> void:
	_selected_actor = actor
	_show_route("creature")
	_render_actor()


func _render_actor() -> void:
	if _selected_actor == null:
		return
	var actor_data: Dictionary = _selected_actor.data
	var private_name: String = actor_data.get("name", "Creature")
	var hit_points: int = actor_data.get("hit_points", 0)
	var maximum_hit_points: int = actor_data.get("maximum_hit_points", hit_points)
	var morale_data: Dictionary = actor_data.get("morale", {})
	var morale_kind: String = morale_data.get("kind", "none")
	var morale_number: int = morale_data.get("value", 0)
	var morale_value: String = "Special"
	if morale_kind == "fixed":
		morale_value = "%d" % morale_number
	var armor: Dictionary = actor_data.get("armor", {})
	var armor_name: String = armor.get("name", "No armor")
	var armor_reduction: String = armor.get("reduction", "")
	var attacks: Array = actor_data.get("attacks", [])

	_header_title.text = private_name.to_upper()
	_header_subtitle.text = "Private Creature sheet · GM"
	_set_window_title(private_name)
	if _compact:
		_header_subtitle.visible = false
	_detail_title_if_present(private_name)
	_public_identity.text = _selected_actor.public_label if not _selected_actor.public_label.is_empty() else "Public name pending"
	_hit_points_metric.text = "%d / %d" % [hit_points, maximum_hit_points]
	_morale_metric.text = morale_value
	_protection_label.text = armor_name.to_upper()
	_protection_metric.text = armor_reduction if not armor_reduction.is_empty() else "—"
	_rules.text = "Quick, attacks and defence are DR14."
	if armor_name != "No armor":
		_rules.text = "%s · quick, attacks and defence are DR14." % armor_name
	_private_name.set("value", private_name)
	_public_label.set("value", _selected_actor.public_label)
	_hit_points.set("value", str(hit_points))
	_maximum_hit_points.set("value", str(maximum_hit_points))
	_morale.set("value", str(morale_number))
	_render_equipment(attacks)
	_render_inventory(attacks)
	_save_button.disabled = not sdk.context().is_gm
	_duplicate_button.disabled = not sdk.context().is_gm
	_place_button.disabled = not sdk.context().is_gm
	_edit_button.disabled = not sdk.context().is_gm
	_inventory_button.disabled = false


func _detail_title_if_present(private_name: String) -> void:
	var title := get_node(^"Layout/Body/Content/Detail/Title") as Label
	var summary := get_node(^"Layout/Body/Content/Detail/Summary") as Label
	title.text = private_name.to_upper()
	summary.text = "Private Creature sheet · GM"
	title.visible = not _compact
	summary.visible = not _compact


func _set_window_title(title: String) -> void:
	if sdk == null:
		return
	var result: SDK.OperationResult = sdk.windows.set_title(title if _compact else "MÖRK BORG")
	if not result.ok:
		_set_status(result.message, true)


func _render_equipment(attacks: Array) -> void:
	for child in _equipment_list.get_children():
		child.queue_free()
	if attacks.is_empty():
		var empty := Label.new()
		empty.text = "No private attacks recorded."
		empty.theme_type_variation = "RookframeMeta"
		_equipment_list.add_child(empty)
		return
	for index in range(attacks.size()):
		var attack: Dictionary = attacks[index]
		var row := Button.new()
		row.custom_minimum_size = Vector2(0, 54)
		row.alignment = 0
		row.focus_mode = 2
		row.theme_type_variation = "RookframeSecondaryButton"
		var attack_name: String = attack.get("name", "Attack")
		var attack_dice: String = attack.get("dice", "—")
		var detail: String = "%s · Equipped" % attack_dice
		row.text = "%s\n%s" % [attack_name, detail]
		_equipment_list.add_child(row)


func _render_inventory(attacks: Array) -> void:
	for child in _inventory_items.get_children():
		child.queue_free()
	for child in _inventory_carried.get_children():
		child.queue_free()
	if attacks.is_empty():
		var empty := Label.new()
		empty.text = "No private items recorded."
		empty.theme_type_variation = "RookframeMeta"
		_inventory_items.add_child(empty)
		return
	for index in range(attacks.size()):
		var attack: Dictionary = attacks[index]
		var target := _inventory_items if index == 0 else _inventory_carried
		target.add_child(_inventory_row(attack, index == 0))
	if _inventory_carried.get_child_count() == 0:
		var carried_empty := Label.new()
		carried_empty.text = "No carried items recorded."
		carried_empty.theme_type_variation = "RookframeMeta"
		_inventory_carried.add_child(carried_empty)


func _inventory_row(attack: Dictionary, equipped: bool) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 58)
	row.add_theme_constant_override("separation", 8)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = 3
	var attack_name: String = attack.get("name", "Item")
	var attack_dice: String = attack.get("dice", "—")
	var item_label := Label.new()
	item_label.text = attack_name
	item_label.theme_type_variation = "RookframeBody"
	var detail := Label.new()
	detail.text = "%s · %s" % [attack_dice, "Equipped" if equipped else "Carried"]
	detail.theme_type_variation = "RookframeMeta"
	details.add_child(item_label)
	details.add_child(detail)
	row.add_child(details)
	var action := Button.new()
	action.custom_minimum_size = Vector2(96, 44)
	action.focus_mode = 2
	action.theme_type_variation = "RookframeSecondaryButton"
	action.text = "Attack" if equipped else "Equip"
	action.pressed.connect(_set_status.bind("Inventory action is ready for the private Creature sheet."))
	row.add_child(action)
	return row


func _show_route(route: String) -> void:
	_route = route
	var catalogue := route == "creatures"
	var sheet := route == "creature"
	var edit := route == "edit-creature"
	var inventory := route == "creature-inventory"
	_sheet_grid.vertical = _compact or edit
	_routes.visible = not catalogue and not edit
	_route_creatures.visible = false
	_route_creature.visible = not catalogue
	_route_edit.visible = false
	_route_inventory.visible = not catalogue
	_route_creatures.button_pressed = catalogue
	_route_creature.button_pressed = sheet
	_route_edit.button_pressed = edit
	_route_inventory.button_pressed = inventory
	_header_title.visible = not _compact
	_header_subtitle.visible = not _compact
	_catalogue_bar.visible = catalogue
	_detail.visible = sheet or edit or inventory
	_search.visible = catalogue
	_definition_heading.visible = catalogue
	_definition_list.visible = catalogue
	_live_heading.visible = catalogue and sdk.context().is_gm
	_live_list.visible = catalogue and sdk.context().is_gm
	_public_heading.visible = false
	_public_list.visible = false
	_stats.visible = sheet
	_identity_section.visible = sheet
	_equipment_section.visible = sheet
	_rules_section.visible = sheet
	_access_section.visible = sheet
	_edit_fields.visible = edit
	_inventory.visible = inventory
	_action_bar.visible = sheet or edit
	_create_button.visible = false
	_edit_button.visible = sheet and sdk.context().is_gm
	_inventory_button.visible = sheet
	_duplicate_button.visible = sheet and sdk.context().is_gm
	_place_button.visible = sheet and sdk.context().is_gm
	_save_button.visible = edit and sdk.context().is_gm
	_add_item_button.visible = false
	_inventory_add.visible = inventory and sdk.context().is_gm
	_back_button.visible = edit
	_back_button.text = "Cancel"
	if catalogue:
		_header_title.text = "CREATURES"
		_header_subtitle.text = "Immutable definitions · private Actors"
		_set_window_title("CREATURES")
		_header_title.visible = not _compact
		_header_subtitle.visible = not _compact
		_set_status("Ready — immutable definitions are available to the GM.")
	elif _selected_actor != null:
		_render_actor()
	if edit:
		_header_title.text = "EDIT CREATURE"
		_header_subtitle.text = "Private values · public name"
		_set_window_title("EDIT CREATURE")
	elif inventory:
		var selected_data: Dictionary = _selected_actor.data
		var inventory_name: String = selected_data.get("name", "CREATURE")
		_header_title.text = inventory_name.to_upper()
		_header_subtitle.text = "Private inventory · GM"
		_set_window_title(inventory_name)
	_set_status(_status.text)


func _on_creatures_route() -> void:
	_show_route("creatures")


func _on_creature_route() -> void:
	_show_route("creature")


func _on_edit_route() -> void:
	_show_route("edit-creature")


func _on_inventory_route() -> void:
	_show_route("creature-inventory")


func _filter_definitions(_query: String) -> void:
	var query := str(_search.get("value")).strip_edges().to_lower()
	for child in _definition_list.get_children():
		var button := child as Button
		if button != null:
			button.visible = query.is_empty() or button.text.to_lower().contains(query)


func _create_creature() -> void:
	if _busy or _selected_definition == null or sdk == null:
		return
	_set_busy(true, "Creating private Creature sheet…")
	var result: SDK.ActorResult = await sdk.actors.create(_selected_definition.reference, {})
	_set_busy(false, result.message if not result.ok else "Creature created.", not result.ok)
	if result.ok:
		_selected_actor = result.actor
		_render_live_actors()
		_show_route("creature")


func _duplicate_creature() -> void:
	if _busy or _selected_actor == null or sdk == null:
		return
	var source: SDK.ActorResult = sdk.actors.read(_selected_actor.id)
	if not source.ok or source.actor == null:
		_set_status(source.message if not source.ok else "Private Creature data is unavailable.", true)
		return
	if _selected_definition == null:
		_set_status("Select an immutable Creature definition before duplicating.", true)
		return
	var data: Dictionary = source.actor.data
	_set_busy(true, "Duplicating private Creature sheet…")
	var result: SDK.ActorResult = await sdk.actors.create(_selected_definition.reference, data)
	_set_busy(false, result.message if not result.ok else "Creature duplicated.", not result.ok)
	if result.ok:
		_selected_actor = result.actor
		_render_live_actors()
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
	# Keep the pending state observable for one rendered frame before the
	# authority update completes.
	await get_tree().process_frame
	await get_tree().process_frame
	var updated: SDK.ActorResult = await sdk.actors.update(_selected_actor.id, data)
	if updated.ok and sdk.context().is_gm:
		var label := str(_public_label.get("value")).strip_edges()
		var identity: SDK.OperationResult = await sdk.public_identities.assign(_selected_actor.id, label)
		if not identity.ok:
			updated.ok = false
			updated.message = identity.message
		else:
			updated.actor.public_label = label
	_set_busy(false, updated.message if not updated.ok else "Creature changes saved.", not updated.ok)
	if updated.ok:
		_selected_actor = updated.actor
		_render_live_actors()
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
		label = str(_private_name.get("value")).strip_edges()
	var identity: SDK.OperationResult = await sdk.public_identities.assign(_selected_actor.id, label)
	if identity.ok:
		_selected_actor.public_label = label
		_refresh_world()
		_set_busy(false, "Rook placed with public identity: %s." % label)
	else:
		_set_busy(false, identity.message, true)


func _add_item() -> void:
	if _selected_actor == null:
		return
	_set_status("Inventory is durable Actor data. Add an item through the private sheet editor.")


func _on_back() -> void:
	if _route == "creature-inventory":
		_show_route("creature")
	else:
		_show_route("creatures")


func _set_busy(value: bool, message: String, error: bool = false) -> void:
	_busy = value
	_set_status(message, error)
	_create_button.disabled = value or _selected_definition == null
	_catalogue_create.disabled = value or _selected_definition == null
	_duplicate_button.disabled = value
	_save_button.disabled = value
	_place_button.disabled = value
	_add_item_button.disabled = value
	_inventory_add.disabled = value


func _set_status(message: String, error: bool = false) -> void:
	_status.text = message
	_status.tooltip_text = message
	_status.visible = error or _busy
