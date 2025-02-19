extends Resource
class_name Item

signal stack_changed( remaining : int )

enum GameState { OVERWORLD, BATTLE, ANY }

@export var id : StringName
@export var usable_state : GameState = GameState.ANY
@export var max_stack : int = 99 
var stack : int = 1 :
	set(s):
		stack = s
		stack_changed.emit( stack )
@export var icon : Texture
@export_multiline var tooltip : String
#@export var usable_by :

func _can_use()->bool:
	return (GameManager.state == usable_state) and stack > 0

func use( target : Node )->void:
	if not _can_use(): return
	stack -= 1
	apply_effects( target )

func apply_effects( target : Node )->void:
	print("%s used on %s" % [id, target.name])
