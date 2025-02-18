extends Resource
class_name Attribute

signal value_changed( value : float )

enum Recalculation { PROPORTIONAL, CONSTANT }

@export var id : StringName
@export var target_stat : StringName
@export var recalculation : Recalculation
# Determines the max value
var stat : Stat :
	set(s):
		stat = s
		if stat == null: return
		stat.stat_changed.connect(_on_max_stat_changed)

# Reference kept to make recalculation easier
var _stat_block : StatBlock
# Internal value
var current_value : float :
	set(v):
		current_value = v
		value_changed.emit(current_value)

var max_value : float
@export var min_value : float = 0.0

var _initialized : bool = false

func _on_max_stat_changed( stat : Stat )->void:
	calculate()
	value_changed.emit( current_value )



func increase( amount : float )->void:
	current_value += amount

func decrease( amount : float )->void:
	current_value -= amount

func maximize()->void:
	current_value = max_value

func minimize()->void:
	current_value = min_value

func find_stat( stat_block : StatBlock )->void:
	_stat_block = stat_block
	stat = stat_block.get_stat( target_stat )

func calculate()->void:
	if stat:
		max_value = stat.value
		var prev_max = 0.0
		if _stat_block and _stat_block.has_attribute(id):
			prev_max = _stat_block.get_attribute(id).max_value
		match(recalculation):
			Recalculation.PROPORTIONAL:
				if prev_max != 0:
					var p = current_value / prev_max
					current_value = max_value * p
				else:
					current_value = max_value
			Recalculation.CONSTANT:
				current_value = min(current_value, max_value)
		clamp(current_value, 0, max_value)
		if not _initialized:
			maximize()
			_initialized = true
	else:
		push_warning("Attribute '%s' has no assigned Stat." % id)
		return

# EOF
