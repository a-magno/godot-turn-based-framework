extends Command
class_name Defeated

var target : CombatActor

func _init( defeated_actor : CombatActor ):
	target = defeated_actor

func execute():
	#target.active = false
	GameManager.event.combatant_dead.emit(target)
	print("%s has been defeated." % target.name)
