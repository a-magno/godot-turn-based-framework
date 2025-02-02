extends Node2D
class_name CombatActor

signal active_changed( actor : CombatActor, is_active : bool )

signal turn_started( actor : CombatActor )
signal turn_ended( actor : CombatActor )

@export var active : bool = true :
	set = set_active

var acted : bool = false

func turn_start()->void:
	acted = false
	active = true
	turn_started.emit(self)

func turn_end()->void:
	active = false
	turn_ended.emit(self)


func play_turn()->void:
	pass


func can_act()->bool:
	return active

func set_active( a : bool )->void:
	active = a
	active_changed.emit( self, active )
