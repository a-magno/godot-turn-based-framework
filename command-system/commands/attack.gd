extends Command
class_name AttackCommand

var target : Combatant
var attacker : Combatant
var damage : int

func _init( _target : Combatant, _attacker : Combatant )->void:
	target = _target
	damage = _attacker.damage
	attacker = _attacker

func execute():
	if not attacker.is_alive() or not is_instance_valid(target):
		return
	
	print("\n%s attacked %s for %d damage!\n" % [attacker.name, target.name, damage])
	var dmg_effect = DamageEffect.new( damage )
	dmg_effect.execute([target])
	#target.take_damage( damage )
