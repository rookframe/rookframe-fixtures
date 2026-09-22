extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/presentation.gd"

const WINDOW_BUTTON: SDK.WindowButton = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window_button.tres")
const DESKTOP_WINDOW_BUTTON: SDK.WindowButton = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window_button_desktop.tres")

func compose() -> void:
	var experience: SDK.DeviceExperience = sdk.presentation_experience()
	var rail: SDK.Rail = sdk.rails.left
	rail.push(DESKTOP_WINDOW_BUTTON if experience.is_desktop else WINDOW_BUTTON)
