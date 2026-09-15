extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/presentation.gd"
const SELECTED_ROOK: SDK.Contribution = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/selected_rook.tres")
const ACTOR_CREATION: SDK.Contribution = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/actor_creation.tres")
const UI_ROOT: SDK.Contribution = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/ui_root.tres")

func compose() -> void:
	settings_view = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/settings.tres")
	sdk.ui_root.push(UI_ROOT)
	sdk.slots.selected_rook.push(SELECTED_ROOK)
	sdk.slots.actor_creation.push(ACTOR_CREATION)
