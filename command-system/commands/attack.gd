extends Command
class_name AttackCommand

var target : Combatant
var attacker : Combatant
var damage : int

func _init( _target : Combatant )->void:
	target = _target

func execute():
	if not is_instance_valid(target): return
	if not attacker.is_alive(): return
	print("%s is attacking %s" % [attacker.name, target.name])
	#print("\n%s attacked %s for %d damage!\n" % [attacker.name, target.name, damage])
	var dmg_effect = DamageEffect.new( damage )
	dmg_effect.execute([target])
	#target.take_damage( damage )

func modify_damage( value : int )->AttackCommand:
	damage += value
	return self

func set_attacker( a : CombatActor )->AttackCommand:
	attacker = a
	set_damage( attacker.damage )
	return self

func set_damage( d : int )->AttackCommand:
	damage = d
	return self
