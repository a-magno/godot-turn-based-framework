extends Command
class_name AttackCommand

var target : Combatant
var attacker : Combatant
var damage : int

func _init( _target : Combatant )->void:
	target = _target

func execute():
	if not is_instance_valid(target): return
	#if attacker:
		#print("%s is attacking %s" % [attacker.name, target.name])
	var dmg_effect = DamageEffect.new( damage )
	dmg_effect.execute([target])

func modify_damage( value : int )->AttackCommand:
	damage += value
	return self

func by_attacker( a : CombatActor, set_dmg : bool = false )->AttackCommand:
	attacker = a
	with_damage( attacker.stat_block.get_stat("atkPow").value )
	return self

func with_damage( d : int )->AttackCommand:
	damage = d
	return self

func get_class_name()->String:
	return "AttackCommand"
