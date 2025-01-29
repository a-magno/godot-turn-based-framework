extends Effect
class_name DamageEffect

var amount : int = 0

func _init(dmg_amount : int)->void:
	amount = dmg_amount

func execute( _targets : Array[Node] )->void:
	for target in _targets:
		if target == null: return
		if target is Combatant:
			target.take_damage( amount )
