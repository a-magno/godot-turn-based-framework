extends Node
class_name EnemyAI

var actor : Combatant
var attacks_registered : int = 0

func _init( _actor : Combatant = null ):
	if not _actor: return
	actor = _actor
	actor.turn_started.connect( _activated )

func _activated( actor : Combatant )->void:
	var is_active = actor.active
	if not actor or not is_active: return
	print("Turning on EnemyAI Process...")
	#while( actor.stat_block.get_attribute("ap").current_value > 0 ):
	_attack()

func _attack()->void:
	if not is_instance_valid( actor ): return
	var player = get_tree().get_first_node_in_group(GameManager.GROUPS.PLAYERS.id)
	if not actor.alive(): return
	actor.attack( player )
	print("Turning off EnemyAI Process...")
	if actor.stat_block.get_attribute("ap").is_depleted():
		actor.turn_end()
	#set_process(false)
