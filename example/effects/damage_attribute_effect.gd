@tool
extends Effect
class_name DamageAttributeEffect

enum DamageType { PERCENTAGE, CONSTANT, SET }

@export var amount : int = 0
@export var type : DamageType = DamageType.CONSTANT :
	set(t):
		type = t
		notify_property_list_changed()
@export var target_stat : StringName = "maxHp"

func execute( _targets : Array[Node] )->void:
	for target in _targets:
		if target == null: return
		if target is Combatant:
			match(type):
				DamageType.CONSTANT:
					target.take_damage( amount )
				DamageType.PERCENTAGE:
					var total = target.stat_block.get_attribute(target_stat).current_value * (amount / 100)
					target.take_damage( total )
			
func set_damage( a : int )->DamageAttributeEffect:
	amount = a
	return self

func _to_string()->String:
	return "DamageEffect (%d)" % amount

func _validate_property(property: Dictionary):
	if property.name == "target_stat" and type != DamageType.PERCENTAGE:
		property.usage = PROPERTY_USAGE_NO_EDITOR
