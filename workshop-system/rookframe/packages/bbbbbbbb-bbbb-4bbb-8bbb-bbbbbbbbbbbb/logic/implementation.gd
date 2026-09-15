extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/implementation.gd"
const Settings = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/logic/settings.gd")

func describe_settings() -> SDK.SettingsRegistration:
	var registration: SDK.SettingsRegistration = SDK.SettingsRegistration.new()
	registration.user = [Settings.LOCAL_LABEL]
	registration.world = [Settings.WORLD_LABEL]
	return registration

func validate_settings(candidate: SDK.SettingsCandidate) -> SDK.SettingsValidation:
	var label: String = candidate.text(Settings.LOCAL_LABEL) if candidate.scope == SDK.SettingsScope.Kind.USER else candidate.text(Settings.WORLD_LABEL)
	if label.strip_edges().is_empty():
		return SDK.SettingsValidation.new("Enter a heading containing visible text.")
	return SDK.SettingsValidation.new()
