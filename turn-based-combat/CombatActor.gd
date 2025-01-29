extends Node2D
class_name CombatActor

signal active_changed( actor : CombatActor, is_active : bool )

signal turn_started( actor : CombatActor )
signal turn_ended( actor : CombatActor )

@export var active : bool = true :
	set = set_active

func play_turn()->void:
	pass

func turn_start()->void:
	turn_started.emit( self )

func turn_end()->void:
	turn_ended.emit( self )


func set_active( a : bool )->void:
	active = a
	active_changed.emit( self, active )
