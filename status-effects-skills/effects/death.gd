extends Effect
class_name Death

func execute( _targets : Array[Node] )->void:
	for target in _targets:
		print("%s has been defeated." % target.name)
		GameManager.event.combatant_dead.emit(target)
