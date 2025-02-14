extends RefCounted
class_name Command

enum Priority { HIGH, LOW, MEDIUM }
const PRIORITIES : Dictionary = {
	Priority.HIGH : 1.0,
	Priority.MEDIUM : 0.5,
	Priority.LOW : 0.0,
}
var priority : float = PRIORITIES[Priority.MEDIUM]

func execute()->void:
	pass

func set_priority( value : Priority )->Command:
	priority = PRIORITIES[value]
	return self

func get_class_name():
	return ""
