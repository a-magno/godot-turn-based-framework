extends Command
class_name UseItem

var item : Item
var target : Node

func _init( i : Item)->void:
	item = i

func on_target( t : Node )->UseItem:
	target = t
	return self

func execute()->void:
	item.use(target)

func get_class_name()->String:
	return "UseItem : %s" % item.id
