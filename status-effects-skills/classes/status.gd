extends Resource
class_name Status

signal status_applied( status : Status )
signal status_changed( status : Status )

enum Type {TURN_START, TURN_END, ROUND_START, ROUND_END, EVENT}
enum Stack {NONE, INTENSITY, DURATION}

@export_group("Data")
@export var id : StringName
@export var duration : int : set = set_duration
@export var max_stacks : int
var stacks : int : set = set_stacks
@export var type : Type
@export var stack_type : Stack

@export_group("Details")
@export var icon : Texture
@export_multiline var tooltip : String

func initialize( target : Node )->void:
	pass

func apply( target : Node )->void:
	status_applied.emit(self)

func can_expire()->bool:
	return duration > -1

func set_stacks( value : int )->void:
	stacks = value
	status_changed.emit( self )

func set_duration( value : int )->void:
	duration = value
	#print_debug("%s duration changed to %d" % [id, value])
	status_changed.emit( self )
