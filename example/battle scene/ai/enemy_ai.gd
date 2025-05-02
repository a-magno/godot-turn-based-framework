extends Node

var active_enemy : Combatant
var attacks_registered : int = 0

func _process(delta: float) -> void:
	if not active_enemy: return
	if active_enemy.acted or active_enemy.stat_block.get_attribute("ap").current_value <= 0: return
	_attack()

func _on_actor_active_changed( actor : Combatant )->void:
	if not actor.is_in_group(GameManager.GROUPS.ENEMIES.id):
		return 
	active_enemy = actor
	print("Turning on EnemyAI Process...\n")
	set_process(true)

func _attack()->void:
	if (
		is_instance_valid( active_enemy )
		and active_enemy.active
		and active_enemy.stat_block.get_attribute("ap").current_value > 0
		):
		var player = get_tree().get_first_node_in_group(GameManager.GROUPS.PLAYERS.id)
		if not active_enemy.alive(): return
		active_enemy.attack( player )
		set_process(false)
		print("Turning off EnemyAI Process...\n")
