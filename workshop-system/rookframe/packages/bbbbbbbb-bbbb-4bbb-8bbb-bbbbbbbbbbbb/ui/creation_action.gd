extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/window.gd"

const CREATION: SDK.ExtensionSurface = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/create_actor.tres")
func activate() -> void:
	sdk.windows.open(CREATION)
