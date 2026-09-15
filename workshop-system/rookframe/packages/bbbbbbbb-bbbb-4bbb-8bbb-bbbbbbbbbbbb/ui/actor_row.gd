extends Button
const SDK = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/package_sdk_facade.gd")
const HeroData = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/logic/hero_data.gd")
const SHEET: SDK.ExtensionSurface = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/ui/actor_sheet.tres")
var _sdk: SDK
var _actor: SDK.ActorId

func configure(sdk: SDK, actor: SDK.Actor) -> void:
	_sdk = sdk
	_actor = actor.id
	var hero: HeroData = actor.data
	text = hero.display_name + " · HP " + str(hero.hit_points)

func inspect() -> void:
	var result: SDK.OperationResult = _sdk.windows.open_actor(SHEET, _actor)
	if not result.ok:
		var notice: SDK.FeedbackMessage = SDK.FeedbackMessage.new()
		notice.title = "Actor unavailable"
		notice.message = result.message
		_sdk.feedback.warning(notice)
