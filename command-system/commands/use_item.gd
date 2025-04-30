extends Command
class_name UseItem

var item : Item
var target : Node

func _init( i : Item)->void:
	item = i
	priority = PRIORITIES[Priority.HIGH]

func on_target( t : Node )->UseItem:
	target = t
	return self

func execute()->void:
	item.use(target)

func _to_string()->String:
	return "<Item : %s>" % item.id
