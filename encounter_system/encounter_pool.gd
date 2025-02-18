extends Resource
class_name EncounterPool

@export var id : StringName
## A weight key, with the value being the enemy's statblock
@export var available_encounters : Array[Encounter]
var _available_encounters := {}
var rng := RandomNumberGenerator.new()

func initialize()->void:
	for e in available_encounters:
		_available_encounters.merge({ e.weight : e.enemy })

func pick_enemy()->Entity:
	var weights = _available_encounters.keys()
	var enemies = _available_encounters.values()
	var idx = rng.rand_weighted(weights)
	return enemies[idx]
