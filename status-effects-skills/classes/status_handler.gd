extends Node
class_name StatusHandler

## Emitted when a new status is added to the [status_stack] property
signal new_status_added( status : Status )

## Emitted when all status of a given type are applied to target. 
signal statuses_applied( type : Status.Type )
@export var target : Node

var status_stack : Dictionary = {}

func apply_status_by_type( status_type : Status.Type )->void:
	if status_type == Status.Type.EVENT: return
	var queue = _get_all_status().filter(
		func( status : Status ):
			return status.type == status_type
	) as Array[Status]
	if queue.is_empty():
		statuses_applied.emit( status_type )
		return
	
	var tween := create_tween()
	for s : Status in queue:
		tween.tween_callback( s.apply.bind(target) )
		tween.tween_interval( 0.25 )
	
	tween.finished.connect(
		func():
			statuses_applied.emit( status_type )
	)

func add_status( status : Status )->void:
	var is_stackable : bool = status.stack_type != Status.Stack.NONE
	if not _has_status( status.id ):
		var new_status = status
		new_status.status_applied.connect(_on_status_applied)
		new_status.status_changed.connect(_on_status_changed)
		new_status.initialize( target )
		status_stack.merge( { new_status.id : new_status } )
		new_status_added.emit( status )
		return
	
	# If the status has a duration, increase it's duration
	if status.can_expire() and status.stack_type == Status.Stack.DURATION:
		_get_status( status.id ).duration += status.duration
		return
	
	if status.stack_type == Status.Stack.INTENSITY:
		_get_status( status.id ).stacks += status.stacks

func _has_status( id : StringName )->bool:
	return status_stack.has( id )

func _get_status( id : StringName )->Status:
	return status_stack.get(id, null)

func _get_all_status()->Array:
	return status_stack.values() 

func _on_status_applied(status: Status) -> void:
	if status.can_expire:
		status.duration -= 1

func _on_status_changed( status : Status )->void:
	if status.can_expire() and status.duration <= 0:
		status_stack.erase( status.id )
	if status.stack_type == Status.Stack.INTENSITY and status.stacks == 0:
		status_stack.erase( status.id )
