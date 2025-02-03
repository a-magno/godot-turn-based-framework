extends Command
class_name ApplyStatusCommand

var status : Status
var target : StatusHandler

func _init( _status : Status, _target : StatusHandler )->void:
	status = _status
	target = _target
	priority = PRIORITIES[Priority.HIGH]

func execute()->void:
	target.add_status( status )
