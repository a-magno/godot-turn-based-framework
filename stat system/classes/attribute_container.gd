extends Node
class_name AttributeContainer

signal attribute_changed( attr : Attribute)

@export var base_stats : Dictionary = { "max_health" : 50 }
var stats : Dictionary = {}
@export var attributes : Array[Attribute]

func _ready() -> void:
	for key in base_stats.keys():
		stats.merge({
			key : Stat.new(key, base_stats[key])
		})
	for attrib in attributes:
		attrib.stat = get_stat( attrib.target_stat )
		attrib.attribute_changed.connect(update_attribute)
		print_debug("Attrib %s value: %.1f" % [attrib.id, attrib.stat.value])

		await get_tree().create_timer(2.0).timeout
		apply_modifier( StatModifier.new("Frail", StatModifier.ModType.PERCENTAGE, -0.5), "max_health" )
		print_debug("Attrib %s value: %.1f" % [attrib.id, attrib.stat.value])

func get_stat( stat_id : StringName )->Stat:
	return stats.get(stat_id, null)

func get_stats()->Dictionary:
	return stats

func apply_modifier( mod : StatModifier, target_stat : StringName )->void:
	mod.set_target( get_stat(target_stat) ).apply_to_target()

func update_attribute( attr : Attribute )->void:
	attribute_changed.emit( attr )
