extends RefCounted
class_name Stat

signal stat_changed( stat : Stat )

var id : StringName
var _base_value : float

var _add : float = 0 :
	set(v):
		_add = v
		calculate()
var _mult : float = 0 :
	set(v):
		_mult = v
		calculate()
var value : float :
	get(): 
		#calculate()
		return value
	set(v):
		value = v
		stat_changed.emit(self)

var _mod_stack : Dictionary

func _init( _id : StringName, _b : float )->void:
	id = _id
	_base_value = _b
	calculate()

func calculate()->float:
	value = (_base_value + _add) * (1.0 + _mult)
	return value

func apply_modifier( mod : StatModifier )->void:
	if not _mod_stack.has( mod.id ):
		_mod_stack.merge( {mod.id : mod} )
	if _mod_stack.has( mod.id ):
		mod.apply_modifier()

func remove_modifier( mod_id : StringName )->void:
	assert(_mod_stack.has( mod_id ), "Modifier with ID %s could not be found!" % mod_id)
	var mod = _mod_stack.get(mod_id, null)
	mod.undo_modifier()
	_mod_stack.erase( mod_id )
	calculate()

func increase( value : float )->float:
	_base_value += value
	calculate()
	return _base_value

func decrease( value )->float:
	if value > _base_value:
		_base_value -= value
		return _base_value
	_base_value -= value
	return value
