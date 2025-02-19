extends Command
class_name Defeated

var target : CombatActor

func _init( defeated_actor : CombatActor ):
	target = defeated_actor

func execute():
	#target.active = false
	#print("%s has been defeated." % target.name)
	GameManager.event.combatant_dead.emit(target)

func get_class_name()->String:
	return "Defeated"
