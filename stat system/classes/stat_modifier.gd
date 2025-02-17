extends Resource
class_name StatModifier

enum ModType { CONSTANT, PERCENTAGE }

@export var id : StringName
@export var value : float
@export var target_stat : StringName
@export var type : ModType
var _target : Stat

func _init( _id : StringName)->void:
	id = _id

func with_name( n : StringName )->StatModifier:
	id = n
	return self

func with_value( v : float )->StatModifier:
	value = v
	return self

func target( s : Stat )-> StatModifier:
	_target = s
	return self

func targets( s : StringName )->StatModifier:
	target_stat = s
	return self


func apply_modifier()->void:
	match type:
		ModType.CONSTANT:
			_target._add += value
		ModType.PERCENTAGE:
			_target._mult += value

func undo_modifier()->void:
	match type:
		ModType.CONSTANT:
			_target._add -= value
		ModType.PERCENTAGE:
			_target._mult -= value

func apply_to_target()->void:
	if not _target: return
	_target.apply_modifier(self)

func remove_from_target()->void:
	_target.remove_modifier(id)
