extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/actor_definition.gd"

## Immutable MÖRK BORG core definitions. A live Actor receives a deep copy and
## can then edit its private encounter sheet without changing this catalogue.
const CORE_DEFINITIONS: Dictionary = {
	"aland-wickhead": {"display_name": "Aland, Wickhead knife-wielder", "hit_points": 10, "morale": {"kind": "fixed", "value": 7}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Knife with dried blood", "dice": "d4"}]},
	"arbint-troll": {"display_name": "Arbint, Troll", "hit_points": 32, "morale": {"kind": "special"}, "armor": {"name": "Thick hide", "reduction": "d2"}, "attacks": [{"name": "Fist", "dice": "2d6"}]},
	"belze-skeleton": {"display_name": "Belze, blood-drenched skeleton", "hit_points": 7, "morale": {"kind": "fixed", "value": 8}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Shortsword", "dice": "d4"}, {"name": "Knife", "dice": "d4"}, {"name": "Bony knuckles", "dice": "d2"}]},
	"bent-scum": {"display_name": "Bent, Scum", "hit_points": 7, "morale": {"kind": "fixed", "value": 8}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Poisoned knife", "dice": "d4"}]},
	"eulotha-wyvern": {"display_name": "Eulotha, Wyvern", "hit_points": 25, "morale": {"kind": "fixed", "value": 10}, "armor": {"name": "Thick hide", "reduction": "d4"}, "attacks": [{"name": "Bite / Sting", "dice": "d6"}]},
	"lady-porcelain": {"display_name": "Lady Porcelain, undead doll", "hit_points": 11, "morale": {"kind": "none"}, "armor": {"name": "Porcelain", "reduction": "d2"}, "attacks": [{"name": "Claws / piercing bite", "dice": "d4"}]},
	"lich-necromancer": {"display_name": "Lich, Undead (weak) necromancer", "hit_points": 15, "morale": {"kind": "none"}, "armor": {"name": "Barrier (necro)", "reduction": "d4"}, "attacks": [{"name": "Strike", "dice": "d6"}]},
	"nodh-zombie": {"display_name": "Nodh, zombie", "hit_points": 7, "morale": {"kind": "none"}, "armor": {"name": "Leather scraps", "reduction": "d2"}, "attacks": [{"name": "Claw / bite", "dice": "d2"}]},
	"seth-goblin": {"display_name": "Seth, Goblin", "hit_points": 6, "morale": {"kind": "fixed", "value": 7}, "armor": {"name": "Ropy skin", "reduction": "d2"}, "attacks": [{"name": "Knife / shortbow", "dice": "d4"}]},
	"thinx-grotesque": {"display_name": "Thinx, Grotesque", "hit_points": 18, "morale": {"kind": "none"}, "armor": {"name": "Clay / stone", "reduction": "d6"}, "attacks": [{"name": "Claws", "dice": "d6"}, {"name": "Eye-beam", "dice": "d8"}]},
	"wrat-wraith": {"display_name": "Wrat, Wraith", "hit_points": 15, "morale": {"kind": "none"}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Touch", "dice": "d4"}]},
	"zukuma-berserker": {"display_name": "Zukuma, berserker", "hit_points": 13, "morale": {"kind": "fixed", "value": 9}, "armor": {"name": "Hardened skin", "reduction": "d2"}, "attacks": [{"name": "Long flail", "dice": "d8"}, {"name": "Heavy mace", "dice": "d6"}, {"name": "Chained sword", "dice": "d6"}, {"name": "Huge warhammer", "dice": "d10"}]},
}


func create_data(raw_choices: Variant) -> Variant:
	var choices: Dictionary = raw_choices
	var definition: Dictionary = CORE_DEFINITIONS.get(resource_name, {}).duplicate(true)
	var data: Dictionary = {
		"schema": "mork-borg-adversary/v1",
		"definition_id": resource_name,
		"name": definition.get("display_name", "Creature"),
		"hit_points": definition.get("hit_points", 0),
		"maximum_hit_points": definition.get("hit_points", 0),
		"morale": definition.get("morale", {"kind": "none"}),
		"armor": definition.get("armor", {"name": "No armor", "reduction": ""}),
		"attacks": definition.get("attacks", []),
		"inventory": [],
	}
	for key in ["name", "hit_points", "maximum_hit_points", "morale", "armor", "attacks", "inventory"]:
		if choices.has(key):
			data[key] = choices[key]
	return data
