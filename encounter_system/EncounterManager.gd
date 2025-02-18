extends Node
class_name EncounterManager

@export var battle_scene : PackedScene
@export var encounter_pools : Array[EncounterPool]
var _pools : Dictionary = {}
@export var max_enemies : int = 3
@export var encounter_steps : int = 100 # steps

static var current_enemies : Array[Entity]

var rng := RandomNumberGenerator.new()

func _ready()->void:
	for p in encounter_pools:
		_pools.merge( { p.id : p } )
		p.initialize()

func generate_encounter( id : StringName ):
	var number_to_generate = randi_range(1, max_enemies)
	var pool : EncounterPool = _pools.get(id, null)
	if not pool:
		print("No encounter pool available in %s" % id)
		return false
	
	for i in range(number_to_generate):
		var new_enemy : Entity = pool.pick_enemy().duplicate(true)
		current_enemies.push_back( new_enemy )
	return true
