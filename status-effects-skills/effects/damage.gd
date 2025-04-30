extends Effect
class_name DamageEffect

@export var amount : int = 0

func execute( _targets : Array[Node] )->void:
	for target in _targets:
		if target == null: return
		if target is Combatant:
			target.take_damage( amount )

func set_damage( a : int )->DamageEffect:
	amount = a
	return self

func _to_string()->String:
	return "DamageEffect (%d)" % amount
