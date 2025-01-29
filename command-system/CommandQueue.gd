extends Node
class_name CommandQueue

signal get_commands()
signal stack_empty()

@export var active : bool = true
@export var log_commands : bool = false

var command_stack : Array[Command]
var _command_history : Array[Command]
var _was_executing : bool = false

func execute_all():
	if command_stack.is_empty(): return

	while command_stack.size() > 0:
		if not active:
			_was_executing = true
			return
			
		var command = command_stack.pop_front()
		command.execute()
		# Put commands in command history
		if log_commands:
			_command_history.push_front(command)

func clear()->void:
	command_stack.clear()

func command_queued( command : Command )->void:
	#print_debug("Command queued.")
	active = false
	command_stack.append( command )
	command_stack.sort_custom(_sort_highest_priority)
	active = true
	
	if _was_executing:
		_was_executing = false
		execute_all()

func _sort_highest_priority(a : Command, b : Command)->bool:
	return a.priority > b.priority
