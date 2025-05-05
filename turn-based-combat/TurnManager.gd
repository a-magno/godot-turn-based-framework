@tool
## Manages the turn order and execution for CombatActors in a turn-based system.
## Provides signals for round start/end and active actor changes.
## Allows for custom sorting of the turn order based on actor properties.
extends Node
class_name TurnManager

## Emitted when a full round of turns (all active actors) has completed.
signal round_finished()

## Emitted when the active actor changes. Useful for UI updates.
signal active_actor_changed(actor: CombatActor)

## Emitted at the absolute start of a new round, before any actor takes a turn.
signal round_start()

## Emitted at the absolute end of a round, after all actors have finished their turns.
signal round_end()

## If true, the TurnManager will automatically proceed through turns when play_round is called.
## If false, you might control turn progression externally by calling advance_turn() manually (requires further implementation).
@export var auto_advance_turns: bool = true

@export var sort : bool = false :
	set(s):
		sort = s
		notify_property_list_changed()
@export_subgroup("Sorting")
## The property name on CombatActor used for sorting the turn order (e.g., "speed", "initiative").
@export var sorting_property: StringName = ""

## The expression used for comparing two actors during sorting. 'a' and 'b' represent the values
## of the sorting_property for the two actors being compared. Should return true if 'a' comes before 'b'.
## Example: "a > b" (for descending order, higher value goes first)
## Example: "a < b" (for ascending order, lower value goes first)
@export_multiline var sort_expression: String = "a > b" # Default: Higher value goes first
@export_subgroup("")
# Private variables
var _turn_order: Array[CombatActor] = [] # The authoritative list of actors in the turn order.
var _current_turn_index: int = -1      # Index in _turn_order of the currently active actor.
var _needs_sort: bool = true          # Flag indicating if the turn order needs resorting.
var _parsed_sort_expression: Expression = null # Cached parsed expression for sorting.
var _is_playing_round: bool = false   # Flag to prevent re-entrant calls to play_round.

## Returns the currently active CombatActor, or null if none.
var current_actor: CombatActor = null:
	set( actor ):
		_set_current_actor
	get():
		if _current_turn_index >= 0 and _current_turn_index < _turn_order.size():
			var actor = _turn_order[_current_turn_index]
			# Ensure the actor is still valid before returning
			if is_instance_valid(actor):
				return actor
		return null# Internal use only

#region Public Methods

## Adds a CombatActor to the turn management system.
## The actor node is added as a child of the TurnManager.
func add_actor(actor: CombatActor) -> void:
	if not is_instance_valid(actor):
		push_warning("Attempted to add an invalid CombatActor instance.")
		return
	if actor.get_parent() == self or _turn_order.has(actor):
		push_warning("CombatActor '%s' is already managed by this TurnManager." % actor.name)
		return

	# Add to internal list and make it a child
	_turn_order.append(actor)
	add_child(actor) # Manage the node lifecycle

	# Connect signals from the actor if needed (example)
	# actor.health_depleted.connect(_on_actor_defeated.bind(actor))

	# Mark that sorting is needed
	_needs_sort = true
	print("Actor '%s' added to TurnManager." % actor.name)


## Removes a CombatActor from the turn management system.
## The actor node is removed from the scene tree and freed.
func remove_actor(actor: CombatActor) -> void:
	if not is_instance_valid(actor):
		push_warning("Attempted to remove an invalid CombatActor instance.")
		return
	if not _turn_order.has(actor):
		push_warning("CombatActor '%s' is not managed by this TurnManager." % actor.name)
		return

	print("Removing actor '%s' from TurnManager." % actor.name)

	# Disconnect signals connected in add_actor (important!)
	# if actor.health_depleted.is_connected(_on_actor_defeated):
	#	 actor.health_depleted.disconnect(_on_actor_defeated)

	# If the actor being removed is the current actor, handle appropriately
	if actor == current_actor:
		# Option 1: Immediately end its turn (might be complex depending on game logic)
		# Option 2: Let the turn finish, removal takes effect next round (simpler)
		# Option 3: Advance turn index if mid-round (careful with iteration)
		# For simplicity, we'll just nullify current_actor reference if it matches.
		# The play_round loop's checks should handle the rest.
		pass # The loop in play_round will naturally skip it or handle invalid instance

	# Remove from internal list
	_turn_order.erase(actor)

	# Remove the node from the tree and free it
	if actor.get_parent() == self:
		remove_child(actor)
	actor.queue_free() # Safely remove the node

	# Adjust current turn index if necessary
	# If the removed actor was before the current one in the list, decrement the index
	var removed_index = _turn_order.find(actor) # Find its *previous* index conceptually
	# Note: Since we already erased, direct index comparison is tricky.
	# A safer approach might be needed if removing mid-round needs precise index handling.
	# However, iterating over a copy in play_round mitigates most immediate issues.

	# Mark that sorting might be needed again (though removal doesn't strictly require resort unless order matters)
	_needs_sort = true # Or set based on specific game logic


## Starts and manages a full round of turns for all actors currently in the system.
## Waits for each actor's turn to complete before proceeding.
func play_round() -> void:
	if _is_playing_round:
		push_warning("play_round called while a round is already in progress.")
		return
	if _turn_order.is_empty():
		print("TurnManager: No actors to play a round.")
		round_finished.emit() # Signal completion even if empty
		return

	_is_playing_round = true
	print("--- Round Start ---")
	round_start.emit()

	# 1. Sort actors if needed
	if _needs_sort and len(sorting_property) > 0 and len(sort_expression) > 0:
		_sort_turn_order()

	# 2. Create a copy of the turn order to iterate over.
	# This prevents issues if actors are added/removed *during* this loop's awaits.
	var current_round_actors = _turn_order.duplicate()
	_current_turn_index = -1 # Reset index for the start of the round

	# 3. Iterate through the actors for this round
	for i in range(current_round_actors.size()):
		var actor: CombatActor = current_round_actors[i]

		# Update the internal index to match the actor we are about to process
		# Find the actor's *current* index in the main _turn_order, as it might have shifted
		_current_turn_index = _turn_order.find(actor)

		# Check if the actor is still valid and able to act *before* starting its turn
		if not _can_act(actor):
			print("TurnManager: Actor '%s' cannot act or is no longer valid, skipping." % actor.name if is_instance_valid(actor) else "[Invalid Actor]")
			continue # Skip to the next actor

		# Set as the active actor and notify
		# We set the internal variable directly to bypass the public setter's logic if needed,
		# but using the setter ensures the signal is emitted.
		# self.current_actor = actor # Incorrect - setter is private
		_set_current_actor(actor) # Use internal setter

		print("TurnManager: Starting turn for %s" % actor.name)
		# Actor's turn logic begins (signal emitted in _set_current_actor)
		# actor.turn_start() # Called by _set_current_actor

		# Wait for the actor to signal that its turn has ended
		# Add a timeout? Consider what happens if turn_ended is never emitted.
		await actor.turn_ended
		print("TurnManager: Finished turn for %s" % actor.name)

		# Optional: Short delay between turns?
		# await get_tree().create_timer(0.1).timeout

	# 4. Round End
	print("--- Round End ---")
	_current_turn_index = -1 # No actor is active between rounds
	_set_current_actor(null) # Signal that no actor is active
	_is_playing_round = false
	round_end.emit()
	round_finished.emit() # Signal the entire round process is complete

## Resets the TurnManager, removing all actors and clearing state.
func reset() -> void:
	print("TurnManager: Resetting...")
	# Make a copy to avoid modification issues while iterating
	var actors_to_remove = _turn_order.duplicate()
	for actor in actors_to_remove:
		remove_actor(actor) # Use the proper removal function

	_turn_order.clear()
	_current_turn_index = -1
	_set_current_actor(null)
	_needs_sort = true
	_parsed_sort_expression = null
	_is_playing_round = false


#endregion

#region Internal Logic

## Checks if a CombatActor is valid and meets the criteria to take a turn.
func _can_act(actor: CombatActor) -> bool:
	# Basic check: Is the instance valid and in the tree?
	if not is_instance_valid(actor) or not actor.is_inside_tree():
		return false
	# Check game-specific conditions (e.g., Is the actor conscious? Not stunned?)
	# This assumes CombatActor has an 'active' or similar property.
	# Replace 'active' with your actual property name if different.
	
	#if not actor.has_method("can_take_turn") or not actor.can_take_turn():
		#if not actor.has_meta("active") or not actor.get_meta("active", true): # Example fallback
		## print("Actor '%s' is not active." % actor.name)
			#return false

	# Add any other conditions necessary for an actor to act
	# ...

	return true


## Internal setter for current_actor to manage signal emission.
func _set_current_actor(actor: CombatActor) -> void:
	# Check if it's actually changing and the new actor is valid or null
	if current_actor == actor:
		return # No change

	# Update the internal reference (getter will use _current_turn_index)
	# The primary role here is managing the signal emission.
	# Note: We rely on _current_turn_index being correct for the 'current_actor' getter.
	# If actor is null, _current_turn_index should be -1.

	var previous_actor = current_actor # Store previous for comparison/logging if needed

	# Emit the signal *before* calling turn_start on the new actor
	active_actor_changed.emit(actor)

	if is_instance_valid(actor):
		# Call the actor's turn start logic *after* signaling the change
		actor.turn_start()
		# print("> Current Actor: %s" % actor.name)
	else:
		# print("> Current Actor: None")
		pass


## Sorts the _turn_order array based on the sorting_property and sort_expression.
func _sort_turn_order() -> void:
	if _turn_order.size() <= 1:
		_needs_sort = false # No sorting needed for 0 or 1 actor
		return

	print("TurnManager: Sorting turn order by '%s'..." % sorting_property)

	# 1. Parse the expression if not already done or if it changed
	if _parsed_sort_expression == null or _parsed_sort_expression.get_expression() != sort_expression:
		_parsed_sort_expression = Expression.new()
		var err = _parsed_sort_expression.parse(sort_expression, ["a", "b"])
		if err != OK:
			push_error("Failed to parse sort expression '%s': %s" % [sort_expression, _parsed_sort_expression.get_error_text()])
			_parsed_sort_expression = null # Invalidate on error
			_needs_sort = false # Avoid repeated attempts with bad expression
			return # Cannot sort

	# 2. Perform the sort using the custom comparison function
	# Use a lambda for cleaner access to the parsed expression
	_turn_order.sort_custom(
		func(actor_a: CombatActor, actor_b: CombatActor):
			# Ensure actors and property are valid before getting
			if not is_instance_valid(actor_a) or not is_instance_valid(actor_b):
				return false # Or handle based on how invalid instances should be sorted
			if not actor_a.has_method("get") or not actor_b.has_method("get"):
				push_error("One of the actors does not have 'get' method for sorting.")
				return false # Cannot compare reliably

			var val_a = actor_a.get(sorting_property)
			var val_b = actor_b.get(sorting_property)

			# Check if properties were successfully retrieved (might be null)
			# Handle nulls if necessary (e.g., treat null as lowest/highest value)
			if val_a == null or val_b == null:
				push_warning("Sorting property '%s' returned null for actor %s or %s." % [sorting_property, actor_a.name, actor_b.name])
				# Define behavior for nulls, e.g., treat them as equal or place them last
				return false # Default: treat as equal if null encountered

			# Execute the pre-parsed expression
			var inputs = [val_a, val_b]
			var result = _parsed_sort_expression.execute(inputs, null, true) # Use weak typing for safety

			if _parsed_sort_expression.has_execute_failed():
				push_error("Failed to execute sort expression '%s' for values (%s, %s): Potential type mismatch or logic error in expression." % [sort_expression, str(val_a), str(val_b)])
				return false # Treat as equal on execution error

			# The expression should return true if a comes before b, false otherwise.
			# The result needs to be a boolean.
			if typeof(result) == TYPE_BOOL:
				return result
			else:
				push_error("Sort expression '%s' did not return a boolean value. Returned: %s" % [sort_expression, str(result)])
				return false # Treat as equal if result is not boolean
	)

	# 3. Update node order in the scene tree to match (optional, but good practice)
	# This ensures the editor hierarchy reflects the logical turn order.
	for i in range(_turn_order.size()):
		var actor = _turn_order[i]
		if is_instance_valid(actor) and actor.get_parent() == self:
			move_child(actor, i)

	_needs_sort = false # Sorting is done
	print("TurnManager: Sorting complete.")
	# For debugging: print sorted order
	# var names = _turn_order.map(func(actor): return actor.name if is_instance_valid(actor) else "[Invalid]")
	# print("Sorted Order: %s" % str(names))


#endregion

#region Signal Connections (Example)

# Example of handling an actor being defeated
# func _on_actor_defeated(actor: CombatActor) -> void:
#	 print("TurnManager: Actor '%s' was defeated." % actor.name)
#	 # Remove the actor from the turn order
#	 remove_actor(actor)

#endregion

#region Godot Lifecycle Methods (Optional Overrides)

# _ready() can be used for initial setup if needed,
# like finding initial CombatActor children if they aren't added dynamically.
# func _ready() -> void:
#	 # Example: Find existing children that are CombatActors
#	 for child in get_children():
#		 if child is CombatActor and not _turn_order.has(child):
#			 print("TurnManager: Found existing CombatActor child '%s'. Adding." % child.name)
#			 # Call add_actor to ensure consistent setup and signal connection
#			 add_actor(child)
#	 # Initial sort if needed
#	 if _needs_sort and len(sorting_property) > 0 and len(sort_expression) > 0:
#		 _sort_turn_order()

# Ensure cleanup if the TurnManager node itself is removed
func _exit_tree() -> void:
	# Clean up any remaining actors to avoid potential memory leaks
	# if they rely on the TurnManager
	reset() # Use reset to handle removal and freeing properly
	# Disconnect any global signals if connected
	# ...

#endregion

func _validate_property(property: Dictionary) -> void:
	if property.name in ["sorting_property", "sort_expression"] and not sort:
		property.usage = PROPERTY_USAGE_NO_EDITOR
