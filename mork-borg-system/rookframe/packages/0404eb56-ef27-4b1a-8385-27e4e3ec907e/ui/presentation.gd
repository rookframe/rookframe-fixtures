extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/presentation.gd"

const WINDOW_BUTTON: SDK.WindowButton = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window_button.tres")

func compose() -> void:
	var rail: SDK.Rail = sdk.rails.left
	rail.push(WINDOW_BUTTON)
