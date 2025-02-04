extends Resource
class_name StatModifier

enum ModType { CONSTANT, PERCENTAGE }

@export var id : StringName
@export var target_stat : StringName
var target : Stat
@export var type : ModType
@export var value : float

func _init( _id : StringName, _t : ModType, _v : float)->void:
	id = _id
	type = _t
	value = _v

func set_target(stat : Stat)->StatModifier:
	target = stat
	return self


func apply_modifier()->void:
	match type:
		ModType.CONSTANT:
			target._add += value
		ModType.PERCENTAGE:
			target._mult += value

func undo_modifier()->void:
	match type:
		ModType.CONSTANT:
			target._add -= value
		ModType.PERCENTAGE:
			target._mult -= value

func apply_to_target()->void:
	if not target: return
	target.apply_modifier(self)

func remove_from_target()->void:
	target.remove_modifier(id)
