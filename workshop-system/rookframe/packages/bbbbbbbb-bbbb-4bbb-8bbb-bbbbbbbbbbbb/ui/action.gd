extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/window.gd"

const WORKSHOP: SDK.ExtensionSurface = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/workshop.tres")
func activate() -> void:
	sdk.windows.open(WORKSHOP)
