@tool
extends Resource
class_name StatBlock

@export var name : String
@export var base_stats : Array[Stat]
var stats : Dictionary = {}
@export var base_attributes : Array[Attribute]
var attributes : Dictionary = {}

## Ensure the statblock has been duplicated first before initializing
func initialize()->void:
	for s in base_stats:
		add_stat( s )
	for a in base_attributes:
		add_attribute( a )

#region Stat handling
func add_stat( stat : Stat )->void:
	var new_stat = stat.duplicate()
	stats.merge({ stat.id : new_stat })

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
	var new_attribute = attribute.duplicate()
	attributes.merge( { attribute.id : new_attribute })
	if len(new_attribute.target_stat) > 0:
		new_attribute.find_stat( self )
		new_attribute.calculate()
	
func get_attribute( id : StringName )->Attribute:
	return attributes.get( id, null)
	
func has_attribute( id : StringName )->bool:
	return attributes.has( id )

func calculate_attributes()->void:
	for attr : Attribute in attributes.values():
		attr.calculate()

#endregion
