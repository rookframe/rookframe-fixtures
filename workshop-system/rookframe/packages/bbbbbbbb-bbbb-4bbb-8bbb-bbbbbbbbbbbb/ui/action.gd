extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/window.gd"

const ACTOR: SDK.ExtensionSurface = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/actor_sheet.tres")

func activate() -> void:
	var selected: SDK.RookId = sdk.rooks.selected()
	if selected == null:
		return
	var found: SDK.RookResult = sdk.rooks.read(selected)
	if found.ok and found.rook.actor != null:
		var result: SDK.OperationResult = sdk.windows.open_actor(ACTOR, found.rook.actor)

		if not result.ok:
			var notice: SDK.FeedbackMessage = SDK.FeedbackMessage.new()
			notice.title = "Actor unavailable"
			notice.message = result.message
			sdk.feedback.warning(notice)
