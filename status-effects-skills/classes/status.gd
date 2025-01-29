extends Resource
class_name Status

@export var id : StringName
@export var duration : int
@export var stacks : int
@export_multiline var tooltip : String

func initialize( targets : Array[Node] )->void:
	pass

func apply( targets : Array[Node] )->void:
	pass
