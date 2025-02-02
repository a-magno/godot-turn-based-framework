extends Node
class_name Queue

@export var enabled : bool = true
var _stack : Array

func _add_to_stack( value : Variant )->void:
	_stack.push_front( value )

func _remove_from_stack( value : Variant )->void:
	_stack.erase( value )

func add_to_stack( value : Variant )->void:
	_add_to_stack( value )

func remove_from_stack( value : Variant )->void:
	remove_from_stack( value )

func execute()->void:
	pass
