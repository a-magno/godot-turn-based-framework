extends Resource
class_name EncounterPool

@export var id : StringName
## A weight key, with the value being the enemy's statblock
@export var available_enemies : Dictionary = {1.0 : null}
var rng := RandomNumberGenerator.new()

func pick_enemy()->Stats:
	var weights = available_enemies.keys()
	var enemies = available_enemies.values()
	var idx = rng.rand_weighted(weights)
	
	return enemies[idx]
