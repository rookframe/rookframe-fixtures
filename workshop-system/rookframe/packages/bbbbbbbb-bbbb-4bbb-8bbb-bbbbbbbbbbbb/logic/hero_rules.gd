extends RefCounted
const HeroData = preload("res://rookframe/packages/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/logic/hero_data.gd")

## Shared System calculation; all endpoints run this same textual Implementation.
func train(current: HeroData) -> HeroData:
	var trained: HeroData = HeroData.new()
	trained.display_name = current.display_name
	trained.hit_points = current.hit_points + 1
	return trained
