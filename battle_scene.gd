extends Node2D

const COMBATANT = preload("res://scenes/combatant.tscn")
@export var test_stats : Array[Stats]

@onready var positions = [
	%Marker2D.position,
	%Marker2D2.position,
	%Marker2D3.position]

var active : bool = true
var _round_counter : int = 0 :
	set(r):
		_round_counter = r
		if _round_counter > 0:
			print_rich("\n[b]Round %d" % _round_counter)

func _ready() -> void:
	GameManager.event.combatant_dead.connect(_on_actor_death)
	
	for stat in test_stats:
		var combatant = COMBATANT.instantiate()
		combatant.stats = stat
		combatant.name = combatant.stats.id.capitalize()
		
		await _add_to_combat( combatant, 
			GameManager.GROUPS.PLAYERS.id if stat.is_player else 
			GameManager.GROUPS.ENEMIES.id)
		
		combatant.position = positions[0] if stat.is_player else positions.pop_at(1)

		if %TurnManager.has_node("%s" % combatant.name) and combatant.is_in_group(GameManager.GROUPS.ENEMIES.id):
			print(combatant.name)
			var letters = TurnManager.NAME_DIFFERENTIATORS
			combatant.name += " %s" % letters.pop_front()
			print(combatant.name)

	begin_combat()

func begin_combat():
	print_rich("[b]Combat begins!")
	while active:
		#await %play_round.pressed
		_round_counter += 1
		await %TurnManager.play_turns()
		await %CommandQueue.execute_all()
		_check_groups(0)

func end_combat(player_win : bool):
	print_rich("\n[b]Ending combat...")
	active = false
	%TurnManager.reset()
	%CommandQueue.clear()
	if player_win:
		print("Player win")
	else:
		print("Enemy win")


func _check_groups(_c):
	#print("Checking groups...")
	var enemy_count = get_tree().get_nodes_in_group(GameManager.GROUPS.ENEMIES.id).size()
	var player_count = get_tree().get_nodes_in_group(GameManager.GROUPS.PLAYERS.id).size()
	#prints(enemy_count, player_count)
	if enemy_count <= 0 or player_count <= 0:
		end_combat( player_count > enemy_count )
		return
		
func _on_actor_death( actor : CombatActor )->void:
	%TurnManager.remove_from_queue(actor)

func _add_to_combat( actor : Combatant, group : StringName ):
	%TurnManager.add_to_queue(actor, group)
	actor.action_queued.connect(%CommandQueue.command_queued)
	
