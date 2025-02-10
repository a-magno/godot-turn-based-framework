extends Resource
class_name Attribute

signal value_changed( value : float )

@export var id : StringName
@export var target_stat : StringName
# Determines the max value
var stat : Stat :
	set(s):
		stat = s
		if stat == null: return
		max_value = stat.value
		value = max_value
		stat.stat_changed.connect(_on_max_stat_changed)

# Internal value
var value : float :
	set(v):
		value = v
		value_changed.emit(value)
# Determines current value
#var current_value : Stat = Stat.new(id, stat.value):
	#set(v):
		#current_value = v
		#if not current_value: return
		#if current_value.stat_changed.is_connected(_set_internal): return
		#current_value.stat_changed.connect(_set_internal)

var max_value : float
@export var min_value : float = 0.0

@export_multiline var formula : String

func _on_max_stat_changed( stat : Stat )->void:
	max_value = stat.value

func increase( amount : float )->void:
	value += amount

func decrease( amount : float )->void:
	value -= amount
