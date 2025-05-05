## Manages the overall flow of a combat encounter.
## Sets up the scene, adds combatants, and runs the main combat loop.
extends Node2D

# Preload necessary scenes
const COMBATANT_SCENE = preload("res://scenes/combatant.tscn") # Assuming Combatant inherits from CombatActor
# @export var OVERWORLD_SCENE : PackedScene # Make sure this is assigned in the Inspector

# Node references - Ensure these nodes exist in your scene tree
@onready var turn_manager: TurnManager = %TurnManager
@onready var command_queue = %CommandQueue # Assuming this node exists and has expected methods/signals
@onready var ui_round_counter = %RoundCounter # Label node
@onready var ui_command_stack = %CommandStack # Label node for debugging
@onready var ui_turn_stack = %TurnStack # Label node for debugging
@onready var ui_round_state = %RoundState # Label node for debugging

# Configuration for positioning actors
# Consider making this more dynamic or data-driven if needed
@export var player_start_position: Vector2 = Vector2(190, 170)
@export var enemy_start_positions: Array[Vector2] = [
	Vector2(470, 130), Vector2(470, 240), Vector2(580, 20),
	Vector2(580, 130), Vector2(580, 235), Vector2(580, 345)
]

# Internal state variables
var _combat_active: bool = false
var _round_counter: int = 0:
	set(value):
		_round_counter = value
		if is_instance_valid(ui_round_counter):
			ui_round_counter.text = "Round %d" % _round_counter if _round_counter > 0 else "Starting..."

var _current_round_state: String = "": # For UI debugging display
	set(value):
		_current_round_state = value
		if is_instance_valid(ui_round_state):
			ui_round_state.text = "State: %s" % _current_round_state


func _ready() -> void:
	# Validate essential components
	if not is_instance_valid(turn_manager):
		push_error("TurnManager node not found or invalid!")
		get_tree().quit() # Or handle error appropriately
		return
	if not is_instance_valid(command_queue):
		push_error("CommandQueue node not found or invalid!")
		get_tree().quit() # Or handle error appropriately
		return
	# if OVERWORLD_SCENE == null:
	#	 push_error("Overworld Scene not set in the Inspector!")
	#	 get_tree().quit()
	#	 return

	# Connect to global events if GameManager.event exists and emits this signal
	if GameManager.has_signal("combatant_dead"):
		GameManager.event.combatant_dead.connect(_on_combatant_death)
	else:
		push_warning("GameManager.event.combatant_dead signal not found.")

	# Setup combatants
	_setup_combatants()

	# Start the combat sequence asynchronously
	begin_combat() # No await here, let it run in the background


func _process(_delta: float) -> void:
	# Update debug UI - Consider updating only when values change for performance
	if is_instance_valid(ui_command_stack) and is_instance_valid(command_queue):
		# Assuming command_queue has a method like get_commands_debug_string()
		ui_command_stack.text = "CmdQ: %s" % str(command_queue.command_stack)
		# Replace with actual method if available
	if is_instance_valid(ui_turn_stack) and is_instance_valid(turn_manager):
		var current_actor_name = "None"
		if is_instance_valid(turn_manager.current_actor):
			current_actor_name = turn_manager.current_actor.name
		ui_turn_stack.text = "Actor: %s" % current_actor_name
	# ui_round_state is updated via its setter


## Sets up the player and enemy combatants for the encounter.
func _setup_combatants() -> void:
	print("Setting up combatants...")
	# --- Add Player ---
	# Assuming Combatant has a static helper or you instance and configure
	# Also assuming GameManager.PLAYER holds the necessary player data
	if GameManager.PLAYER != null:
		# var player_combatant = COMBATANT_SCENE.instantiate() # Or use a specific player scene
		# player_combatant.setup_player(GameManager.PLAYER) # Example setup method
		var player_combatant = Combatant.new_player(GameManager.PLAYER) # Using your original static method convention
		if is_instance_valid(player_combatant):
			add_combatant( player_combatant )
		else:
			push_error("Failed to create player combatant.")
	else:
		push_error("GameManager.PLAYER data is missing.")


	# --- Add Enemies ---
	# Assuming EncounterManager provides the list of enemy data
	if EncounterManager.current_enemies != null:
		var available_positions = enemy_start_positions.duplicate() # Use a copy
		for enemy_data in EncounterManager.current_enemies:
			if available_positions.is_empty():
				push_warning("Ran out of enemy start positions!")
				break # Stop adding enemies if no positions left

			# var enemy_combatant = COMBATANT_SCENE.instantiate()
			# enemy_combatant.setup_enemy(enemy_data) # Example setup method
			var enemy_combatant = Combatant.new_enemy(enemy_data) # Using your original static method convention

			if is_instance_valid(enemy_combatant):
				# Assign a position
				enemy_combatant.global_position = available_positions.pop_front() # Take the next available position
				add_combatant( enemy_combatant )

				# Add AI Controller (if applicable)
				# Assuming EnemyAI takes the combatant node in its constructor or an init method
				var ai_controller = EnemyAI.new(enemy_combatant)
				enemy_combatant.add_child(ai_controller)
			else:
				push_error("Failed to create enemy combatant from data.")
	else:
		push_warning("EncounterManager.current_enemies is null or empty.")

	# Ensure TurnManager sorts actors initially if needed
	turn_manager._needs_sort = true


## Adds a configured Combatant node to the scene and registers it with managers.
func add_combatant(actor: Combatant) -> void:
	if not is_instance_valid(actor):
		push_error("Attempted to add invalid combatant instance.")
		return

	# Assign position if not already set (player might use a fixed one)
	if actor.is_player() and actor.global_position == Vector2.ZERO: # Check if not already positioned
		actor.global_position = player_start_position

	# Handle potential name collisions (simple numeric suffix approach)
	var base_name = actor.name
	var counter = 1
	while get_node_or_null("TurnManager/" + actor.name) != null: # Check if child node with name exists
		actor.name = "%s_%d" % [base_name, counter]
		counter += 1
	actor.name = actor.name.capitalize() # Capitalize after potential renaming

	# Add to TurnManager (which also adds as child)
	turn_manager.add_actor(actor)

	# Add to appropriate group for win/loss checking
	var group_name = GameManager.GROUPS.PLAYERS.id if actor.is_player() else GameManager.GROUPS.ENEMIES.id
	actor.add_to_group(group_name)

	# Connect actor signals to relevant systems
	if command_queue != null and actor.has_signal("action_queued"):
		# Ensure the target method exists before connecting
		if command_queue.has_method("command_queued"):
			var err = actor.action_queued.connect(command_queue.command_queued)
			if err != OK:
				push_error("Failed to connect action_queued from %s to CommandQueue. Error: %s" % [actor.name, str(err)])
		else:
			push_warning("CommandQueue is missing the 'command_queued' method.")
	else:
		push_warning("Cannot connect action_queued: CommandQueue invalid or actor missing signal.")

	# Combatant should connect to TurnManager's round_start/end signals itself,
	# possibly in its _ready or an initialization function after being added.
	# Example (should be in Combatant.gd):
	# func _ready():
	#	 var tm = get_node_or_null("/root/Game/CombatScene/TurnManager") # Find TurnManager
	#	 if tm:
	#		 tm.round_start.connect(_on_round_start)
	#		 tm.round_end.connect(_on_round_end)

	print("Added combatant '%s' to group '%s'." % [actor.name, group_name])


## Starts and runs the main combat loop asynchronously.
func begin_combat() -> void:
	if _combat_active:
		push_warning("Combat already in progress.")
		return

	print_rich("[b]Combat begins![/b]")
	_combat_active = true
	_round_counter = 0 # Reset round counter

	# Main combat loop
	while _combat_active:
		_round_counter += 1
		_current_round_state = "Round Start"
		print("\n--- Starting Round %d ---" % _round_counter)

		# Emit global start signal if GameManager exists
		if GameManager.has_signal("combat_round_start"):
			GameManager.event.combat_round_start.emit()
		await GameManager.wait(0.2) # Short delay for visual pacing

		# --- Turn Phase ---
		_current_round_state = "Turn Phase"
		print("Running turn phase...")
		if is_instance_valid(turn_manager):
			# play_round is async, so we await its completion
			await turn_manager.play_round() # This internally handles sorting and turn execution
		else:
			push_error("TurnManager invalid, cannot play round.")
			_combat_active = false # Stop combat on critical error
			break
		_current_round_state = "Turn Phase Complete"
		print("Turn phase finished.")
		await GameManager.wait(0.2)

		# --- Action Execution Phase ---
		_current_round_state = "Action Execution"
		print("Executing actions...")
		if is_instance_valid(command_queue):
			# Assuming execute_all is an async function
			await command_queue.execute_all()
		else:
			push_error("CommandQueue invalid, cannot execute actions.")
			# Decide if combat should stop here
		_current_round_state = "Action Execution Complete"
		print("Action execution finished.")
		await GameManager.wait(0.2)

		# --- Round End Phase ---
		_current_round_state = "Round End"
		print("--- Ending Round %d ---" % _round_counter)
		# Emit global end signal if GameManager exists
		if GameManager.has_signal("combat_round_end"):
			GameManager.event.combat_round_end.emit()

		# Check win/loss conditions *after* actions are resolved
		if not _check_win_loss_conditions():
			# If _check_win_loss_conditions returned false, it means combat ended.
			# The loop condition (_combat_active) will be false next iteration.
			print("Combat end condition met.")
		else:
			# Combat continues, prepare for next round
			await GameManager.wait(0.5) # Delay before next round starts
			_current_round_state = "Waiting for Next Round"


## Ends the combat encounter and transitions back to the overworld.
func end_combat(player_won: bool) -> void:
	if not _combat_active: return # Prevent double execution

	print_rich("\n[b]Combat Ended.[/b]")
	_combat_active = false
	_current_round_state = "Combat Over"

	if player_won:
		print("Result: Player Victory!")
		# Add rewards, XP, etc. here
	else:
		print("Result: Player Defeat!")
		# Handle game over sequence?

	# Clean up TurnManager and CommandQueue
	if is_instance_valid(turn_manager):
		turn_manager.reset()
	if is_instance_valid(command_queue):
		command_queue.clear() # Assuming a clear method exists

	# Clear encounter data (optional, depending on game structure)
	# EncounterManager.current_enemies.clear()

	# Wait briefly before changing scene
	await get_tree().create_timer(1.0).timeout

	# Change state and scene
	# Assuming GameManager manages game state
	# GameManager.state = GameManager.GameState.OVERWORLD
	print("Returning to Overworld...")
	# if OVERWORLD_SCENE != null:
	#	 get_tree().change_scene_to_packed(OVERWORLD_SCENE)
	# else:
	#	 push_error("Cannot change to Overworld scene: Scene not loaded.")
	# For testing, using file path:
	get_tree().change_scene_to_file("res://example/world/overworld.tscn")


## Checks if either side has been eliminated. Ends combat if necessary.
## Returns true if combat should continue, false if combat has ended.
func _check_win_loss_conditions() -> bool:
	if not _combat_active: return false # Don't check if already ending

	# Use get_nodes_in_group for dynamic checking
	var enemy_count = get_tree().get_nodes_in_group(GameManager.GROUPS.ENEMIES.id).size()
	var player_count = get_tree().get_nodes_in_group(GameManager.GROUPS.PLAYERS.id).size()

	print("Checking win/loss: Players=%d, Enemies=%d" % [player_count, enemy_count])

	if enemy_count <= 0:
		end_combat(true) # Player wins
		return false
	elif player_count <= 0:
		end_combat(false) # Player loses
		return false
	else:
		return true # Combat continues


## Handles a combatant death signal (e.g., from GameManager).
func _on_combatant_death(actor: Combatant) -> void:
	if not _combat_active: return # Don't process deaths after combat ends

	print("Processing death for: %s" % actor.name if is_instance_valid(actor) else "[Invalid Actor]")

	if is_instance_valid(actor):
		# Disconnect signals *before* removing/freeing
		if is_instance_valid(command_queue) and actor.has_signal("action_queued") and command_queue.has_method("command_queued"):
			if actor.action_queued.is_connected(command_queue.command_queued):
				actor.action_queued.disconnect(command_queue.command_queued)

		# Remove the actor using TurnManager's method.
		# This handles removal from the turn order list, removing the child node,
		# and queueing it for freeing. No need to call actor.queue_free() here.
		if is_instance_valid(turn_manager):
			await turn_manager.remove_actor(actor) # Use await if remove_actor becomes async
		else:
			push_error("TurnManager invalid, cannot remove dead actor.")
			# Fallback cleanup if TurnManager is gone?
			if actor.get_parent() == turn_manager: # Check parent before removing
				turn_manager.remove_child(actor)
			actor.queue_free()

		# Check win/loss conditions immediately after death processing
		_check_win_loss_conditions() # This might call end_combat

	else:
		push_warning("Received death signal for an already invalid actor instance.")
