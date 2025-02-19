extends Node2D

const COMBATANT = preload("res://scenes/combatant.tscn")
@export var OVERWORLD : PackedScene

@onready var positions = [
	Vector2(190, 170),
	Vector2(470, 130),
	Vector2(470, 240),
	Vector2(580, 20),
	Vector2(580, 130),
	Vector2(580, 235),
	Vector2(580, 345),
	]

var active : bool = true
var _round_counter : int = 0 :
	set(r):
		_round_counter = r
		if _round_counter > 0:
			%RoundCounter.text = "Round %d" % _round_counter

func _ready() -> void:
	GameManager.event.combatant_dead.connect(_on_actor_death)
	# Adding player first
	add_to_combat( Combatant.new_player( GameManager.PLAYER ) )
	# Adding enemies
	for enemy in EncounterManager.current_enemies:
		add_to_combat( Combatant.new_enemy( enemy ) )

	begin_combat()

func _process(delta: float) -> void:
	%CommandStack.text = "Stack: %s" % str($CommandQueue.get_commands())
	%TurnStack.text = "Current Actor: %s" % $TurnManager.current_actor.name if is_instance_valid($TurnManager.current_actor) else ""

func begin_combat():
	print_rich("[b]Combat begins!")
	while active:
		#await %play_round.pressed
		_round_counter += 1
		GameManager.event.combat_round_start.emit()
		#print("Getting turn actions...")
		await %TurnManager.play_turns()

		#print("Executing actions...")
		await %CommandQueue.execute_all()
		
		GameManager.event.combat_round_end.emit()
		#print("Checking groups...")
		#await _check_groups()

func end_combat(player_win : bool):
	print_rich("\n[b]Ending combat...")
	active = false
	%TurnManager.reset()
	%CommandQueue.clear()
	EncounterManager.current_enemies.clear()
	if player_win:
		print("Player win")
		await get_tree().create_timer(0.5).timeout
		#get_tree().unload_current_scene()
	else:
		print("Enemy win")
	GameManager.state = GameManager.GameState.OVERWORLD
	get_tree().change_scene_to_file("res://example/world/overworld.tscn")

func _check_groups():
	#print("Checking groups...")
	var enemy_count = get_tree().get_nodes_in_group(GameManager.GROUPS.ENEMIES.id).size()
	var player_count = get_tree().get_nodes_in_group(GameManager.GROUPS.PLAYERS.id).size()
	#prints(enemy_count, player_count)
	if enemy_count <= 0 or player_count <= 0:
		end_combat( player_count > enemy_count )
		return

func _on_actor_death( actor : Combatant )->void:
	await %TurnManager.remove_from_queue(actor)
	actor.queue_free()
	_check_groups()
	#actor.action_queued.disconnect(%CommandQueue.command_queued)

func add_to_combat( actor : Combatant ):
	
	actor.position = positions[0] if actor.is_player() else positions.pop_at(1)
	if %TurnManager.has_node("%s" % actor.name) and not actor.is_player():
		var letters = TurnManager.NAME_DIFFERENTIATORS
		actor.name += " %s" % letters.pop_front()
	actor.name.capitalize()
	
	%TurnManager.add_to_queue(actor)
	actor.action_queued.connect(%CommandQueue.command_queued)
	actor.set_active(true)
	
