extends Node
class_name TurnManager

## Emitted when the TurnManager finishes looping.
signal finished()

## Emitted when the active actor changes.
## Good to use with UIs to signal what player character is acting.
signal active_actor_changed( actor : CombatActor )

signal round_start()
signal round_end()

## Enables or disables internal looping.
## Good if your plan is to control the turn order externally.
@export var active : bool = true

## In case sorting is needed for the turn order, define the name of the target property
@export var sorting_property : StringName = ""

## The expression to be used when sorting the turn order.
@export_multiline var sort_expression : String = "a > b"

var current_actor : CombatActor = null :
	set(c):
		current_actor = c
		if current_actor == null: return
		active_actor_changed.emit( current_actor )

var _actors_sorted : bool = false
var _combat_actors : Array[CombatActor]

func _ready() -> void:
	GameManager.events.combatant_dead.connect(_on_combatant_dead)

## Loops through and awaits the turn execution of each CombatActor child. 
func play_turns()->void:
	if _combat_actors.size() <= 0:
		print("No children for combat, exiting...")
		return

	#New round
	round_start.emit()
	
	for actor : CombatActor in _combat_actors:
		if not is_instance_valid(actor):
			continue
		if actor.active == false: continue
		if not actor.is_inside_tree(): continue
		
		#current actor's turn
		current_actor = actor
		current_actor.turn_start()
		
		#turn end
		await current_actor.play_turn()
		
		#print_debug("%s turn end." % actor.name)
		current_actor.turn_end()
	
	#end of round
	await get_tree().create_timer(0.5)
	round_end.emit()

## Clears the TurnManager and resets it's values.
func reset()->void:
	_combat_actors.clear()
	_actors_sorted = false
	current_actor = null

## Adds a CombatActor to the actor stack.
## CombatActor must be activated externally.
func add_combat_actor( actor : CombatActor, group : StringName ):
	if _combat_actors.has( actor ):
		push_warning("%s already in the list." % actor.name)
		return
	_combat_actors.push_front(actor)
	actor.add_to_group(group)
	round_start.connect(actor.set_active.bind(true))
	add_child(actor)
	#actor.active_changed.connect(_on_actor_active_changed)
	return

func _enter_tree() -> void:
	child_entered_tree.connect(_on_child_entered)

#region SIGNALS
# Connecting to signals and adding newest actor to turn order stack.
func _on_child_entered( _child : Node )->void:
	if _child is CombatActor:
		_combat_actors.push_back( _child )
		#_test_grouping(_child)

# To ensure dynamic sorting, in case of value-changing effects affecting actors
func _on_actor_data_changed( _actor : CombatActor, _data : Dictionary )->void:
	if _data.has(sorting_property):
		_actors_sorted = false

func _on_combatant_dead( combatant : Combatant ):
	# HACK
	combatant.remove_from_group(GameManager.GROUPS.ENEMIES)
	combatant.remove_from_group(GameManager.GROUPS.PLAYERS)
	_combat_actors.erase(combatant)
	combatant.queue_free()
	#print("Nodes in groups:\nPLAYERS: %d\nENEMIES: %d" % [
		#get_tree().get_node_count_in_group(GROUPS.player_group),
		#get_tree().get_node_count_in_group(GROUPS.enemy_group)
	#])
#endregion

#region SORTING
func _sort_actors():
	if len(sorting_property) < 0: return
	_combat_actors.sort_custom(_sort_by_property)
	for actor in _combat_actors:
		move_child(actor, _combat_actors.find(actor))
	_actors_sorted = true

func _sort_by_property(a : CombatActor, b : CombatActor):
	var exp : Expression = Expression.new()
	var inputs : Array = [a.get(sorting_property), b.get(sorting_property)]
	
	var err = exp.parse(sort_expression, ["a", "b"])
	if err != OK:
		push_error(exp.get_error_text())
		return
	var result = exp.execute(inputs)
	if not exp.has_execute_failed():
		return result
	return false
#endregion
