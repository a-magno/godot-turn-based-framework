extends Effect
class_name StatusEffect

var status : Status

func _init( _status : Status )->void:
	status = _status

func execute( _targets : Array[Node] )->void:
	for target in _targets:
		if not target: continue
		if target is Combatant:
			target.queue_command(
				ApplyStatusCommand.new(status.duplicate(), target.status_handler)
			)
			#target.status_handler.add_status(status.duplicate())
