extends Node
#class_name AttributeContainer
#
#signal attribute_changed( attr : Attribute)
#
#@export var base_stats : Dictionary = { "max_health" : 50 }
#var _stats : Dictionary = {}
#@export var attributes : Array[Attribute]
#var _attributes : Dictionary = {}
#
#func _ready() -> void:
	#for key in base_stats.keys():
		#_stats.merge({
			#key : Stat.new(key, base_stats[key])
		#})
#
	#for attrib in attributes:
		#var new_attrib = attrib.duplicate()
		#_attributes.merge({ attrib.id : new_attrib })
		#new_attrib.stat = get_stat( new_attrib.target_stat )
		##new_attrib.attribute_changed.connect(update_attribute)
#
		##await get_tree().create_timer(2.0).timeout
		##apply_modifier( StatModifier.new("Frail", StatModifier.ModType.PERCENTAGE, -0.5), "max_health" )
#
#
#func get_stat( stat_id : StringName )->Stat:
	#return _stats.get(stat_id, null)
#
#func get_stats()->Array:
	#return _stats.values()
#
#func get_attributes()->Array:
	#return _attributes.values()
#
#func get_attribute( id : StringName )->Attribute:
	#return _attributes.get( id, null )
#
#func apply_modifier( mod : StatModifier, target_stat : StringName )->void:
	#mod.set_target( get_stat(target_stat) ).apply_to_target()
#
#func update_attribute( attr : Attribute )->void:
	#attribute_changed.emit( attr )
