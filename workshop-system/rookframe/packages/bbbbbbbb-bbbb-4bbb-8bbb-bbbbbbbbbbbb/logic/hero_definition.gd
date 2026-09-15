extends "res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/sdk/actor_definition.gd"

const HeroData = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/logic/hero_data.gd")
func create_data(choices: Variant) -> Variant:
	var name: String = choices
	var hero: HeroData = HeroData.new()
	hero.display_name = name.strip_edges()
	return hero
