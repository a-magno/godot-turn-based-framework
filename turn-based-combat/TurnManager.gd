extends Node
class_name TurnManager

## Emitted when the TurnManager finishes looping.
signal finished()

## Emitted when the active actor changes.
## Good to use with UIs to signal what player character is acting.
signal active_actor_changed( actor : CombatActor )

signal round_start()
signal round_end()

static var NAME_DIFFERENTIATORS = ["A", "B", "C", "D", "E", "F"]

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
var _combat_actors : Array[Node]

## Loops through and awaits the turn execution of each CombatActor child. 
func play_turns()->void:
	if get_children().size() <= 0:
		print("No children for combat, exiting...")
		return
	_combat_actors = get_children()
	
	#New round
	round_start.emit()
	
	for actor : CombatActor in _combat_actors:
		if not _can_act( actor ): continue
		if not _actors_sorted and len(sorting_property) > 0:
			_sort_actors()
		#current actor's turn
		current_actor = actor
		# turn start
		current_actor.turn_start()
		
		await current_actor.turn_ended
		#turn end
	#end of round
	round_end.emit()

func _can_act( actor : CombatActor )->bool:
	return is_instance_valid(actor) and actor.is_inside_tree()

## Clears the TurnManager and resets it's values.
func reset()->void:
	_combat_actors.clear()
	_actors_sorted = false
	current_actor = null

## Adds a CombatActor to the actor stack.
## CombatActor must be activated externally.
func add_to_queue( actor : CombatActor, group : StringName )->void:
	if get_children().has( actor ):
		push_warning("%s already in the list." % actor.name)
		return
	actor.add_to_group(group)
	actor.set_meta("group", group)
	round_start.connect(actor.set_active.bind(true))
	add_child(actor)
	#actor.active_changed.connect(_on_actor_active_changed)
	return

func remove_from_queue( actor : CombatActor )->void:
	assert( actor.is_inside_tree(), "%s is not inside tree." % actor.name )
	actor.remove_from_group( actor.get_meta("group") )
	assert( _combat_actors.has( actor ), "%s is not a part of the turn queue." % actor.name)
	_combat_actors.erase( actor )
	actor.queue_free()
	_actors_sorted = false

func _enter_tree() -> void:
	child_entered_tree.connect(_on_child_entered)

#region SIGNALS
# Connecting to signals and adding newest actor to turn order stack.
func _on_child_entered( _child : Node )->void:
	if _child is CombatActor:
		_actors_sorted = false

func _on_actor_dead( actor : CombatActor ):
	actor.remove_from_group( actor.get_meta("group") )
	_combat_actors.erase(actor)
	actor.queue_free()
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
