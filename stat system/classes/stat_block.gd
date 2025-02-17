@tool
extends Resource
class_name StatBlock

@export var stats : Dictionary
@export var attributes : Dictionary

func _init()->void:
	stats = {}
	attributes = {}

#region Stat handling
func add_stat( stat : Stat )->void:
	stats.merge({ stat.id : stat.duplicate() })

func get_stat( id : StringName )->Stat:
	return stats.get( id, null )

func get_stat_value( id : StringName )->float:
	return 0.0 if not stats.has( id ) else stats.get( id ).value

func get_stat_values()->Dictionary:
	var out = {}
	for stat in stats.values():
		out.merge({ stat.id : stat.value })
	return out

#endregion

#region Attribute handling
func add_attribute( attribute : Attribute )->void:
	attributes.merge( { attribute.id : attribute })
	if len(attribute.target_stat) > 0:
		attribute.find_stat( self )
	
func get_attribute( id : StringName )->Attribute:
	return attributes.get( id, null)
	
func has_attribute( id : StringName )->bool:
	return attributes.has( id )

func calculate_attributes()->void:
	for attr in attributes.values():
		attr.calculate()

#endregion
