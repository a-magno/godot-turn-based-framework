extends Node

var active_enemy : Combatant
var attacks_registered : int = 0

func _process(delta: float) -> void:
	_attack()

func _on_actor_active_changed( actor : Combatant )->void:
	if not actor.is_in_group(GameManager.GROUPS.ENEMIES.id):
		return 
	active_enemy = actor
	
func _attack()->void:
	if is_instance_valid( active_enemy ) and active_enemy.active:
		var player = get_tree().get_first_node_in_group(GameManager.GROUPS.PLAYERS.id)
		active_enemy.queue_command( AttackCommand.new( player ).set_attacker(active_enemy) )
		attacks_registered += 1
		print("attacks registered: %d" % attacks_registered)
