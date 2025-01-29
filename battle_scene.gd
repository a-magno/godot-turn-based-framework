extends Node2D

const COMBATANT = preload("res://scenes/combatant.tscn")
@export var test_enemies : Array[Stats]
@export var test_player : Array[Stats]

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

func setup( players : Array[Stats], enemies : Array[Stats] )->void:
	for p in players:
		var combatant = COMBATANT.instantiate()
		combatant.stats = p
		await add_to_combat( combatant, 
			GameManager.GROUPS.PLAYERS )
		combatant.target_group = GameManager.GROUPS.ENEMIES
		combatant.position = positions[0]
	
	for e in enemies:
		var combatant = COMBATANT.instantiate()
		combatant.stats = e
		await add_to_combat( combatant, 
			GameManager.GROUPS.ENEMIES )
		var pos = positions.pop_at( randi_range(1, positions.size()-1) )
		print(pos)
		combatant.position = pos

func _ready() -> void:
	setup( test_player, test_enemies )
	begin_combat()

func add_to_combat( actor : Combatant, group : StringName ):
	%TurnManager.add_combat_actor(actor, group)
	actor.print_stats()
	actor.queue_action.connect(%CommandQueue.command_queued)

func begin_combat():
	print_rich("[b]Combat begins!")
	while active:
		await %play_round.pressed
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
	var enemy_count = get_tree().get_nodes_in_group(GameManager.GROUPS.ENEMIES).size()
	var player_count = get_tree().get_nodes_in_group(GameManager.GROUPS.PLAYERS).size()
	#prints(enemy_count, player_count)
	if enemy_count <= 0 or player_count <= 0:
		end_combat( player_count > enemy_count )
		return
		
