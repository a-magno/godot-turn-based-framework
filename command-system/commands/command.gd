extends RefCounted
class_name Command

enum Priority { HIGH, LOW, MEDIUM }
const PRIORITIES : Dictionary = {
	Priority.HIGH : 100.0,
	Priority.MEDIUM : 50.0,
	Priority.LOW : 0.0,
}
var priority : float = 1.0

func execute()->void:
	pass

func set_priority( value : float )->Command:
	priority = value
	return self

func get_class_name():
	return ""
