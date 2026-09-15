extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/presentation.gd"
const SELECTED_ROOK: SDK.Contribution = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/selected_rook.tres")
const ACTOR_CREATION: SDK.Contribution = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/actor_creation.tres")
const SHEET: SDK.ExtensionSurface = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/actor_sheet.tres")
const Hero = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/logic/hero_data.gd")

const JOURNAL: SDK.WindowButton = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/journal_entry.tres")

func compose() -> void:
	settings_view = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/settings.tres")
	sdk.slots.selected_rook.push(SELECTED_ROOK)
	sdk.slots.actor_creation.push(ACTOR_CREATION)
	sdk.rails.left.push(JOURNAL)

func describe_actor(actor: SDK.Actor) -> SDK.ActorSummary:
	var data: Hero = actor.data
	return SDK.ActorSummary.new(data.display_name)

func inspect_actor(actor: SDK.ActorId) -> void:
	sdk.windows.open_actor(SHEET, actor)
