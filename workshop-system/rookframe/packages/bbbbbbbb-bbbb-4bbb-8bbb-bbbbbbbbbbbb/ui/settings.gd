extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/settings_view.gd"
const Settings = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/logic/settings.gd")
const TextField = preload("res://rookframe/ui/components/forms/text_field.gd")
@onready var heading: TextField = get_node("Heading")
@onready var preview: Label = get_node("Preview")

func edit() -> void:
	heading.label_text = "Personal heading" if scope == SettingsScope.Kind.USER else "Table heading"
	heading.value = draft.text(Settings.LOCAL_LABEL) if scope == SettingsScope.Kind.USER else draft.text(Settings.WORLD_LABEL)
	update_heading(heading.value)

func update_heading(value: String) -> void:
	if draft == null:
		return
	if scope == SettingsScope.Kind.USER:
		draft.set_text(Settings.LOCAL_LABEL, value)
	else:
		draft.set_text(Settings.WORLD_LABEL, value)
	preview.text = "Preview: " + value
