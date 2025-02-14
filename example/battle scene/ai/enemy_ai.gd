extends Node

var active_enemy : Combatant
var attacks_registered : int = 0

func _physics_process(delta: float) -> void:
	if not active_enemy: return
	if active_enemy.acted: return
	_attack()

func _on_actor_active_changed( actor : Combatant )->void:
	if not actor.is_in_group(GameManager.GROUPS.ENEMIES.id):
		return 
	active_enemy = actor
	print("Turning on EnemyAI Process...\n")
	set_physics_process(true)
	
func _attack()->void:
	if is_instance_valid( active_enemy ) and active_enemy.active:
		var player = get_tree().get_first_node_in_group(GameManager.GROUPS.PLAYERS.id)
		set_physics_process(false)
		print("Turning off EnemyAI Process...\n")
		active_enemy.queue_command( AttackCommand.new( player ).set_attacker(active_enemy) )
