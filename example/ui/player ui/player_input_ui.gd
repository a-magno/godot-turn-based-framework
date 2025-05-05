## Manages the Player's Combat UI, handling action selection, targeting, skill use, and item use.
extends Control

# Enum to define the different states the UI can be in
enum UIState {
	HIDDEN,           # UI is not visible (not player's turn)
	SELECTING_ACTION, # Top-level action buttons (Attack, Skill, Item, Skip) are visible
	SELECTING_ATTACK_TARGET,
	SELECTING_SKILL,  # Skill list is visible
	SELECTING_SKILL_TARGET,
	SELECTING_ITEM,   # Item inventory UI is expected to be shown
	PROCESSING      # Waiting for an action to complete (optional state to disable input)
}

# References to UI panels (ensure these nodes exist in your scene)
@onready var actions_panel = %Actions
@onready var attacking_panel = %Attacking # Panel shown during attack target selection (optional)
@onready var skills_panel = %Skills
@onready var skills_list = %SkillsList # VBoxContainer or similar for skill buttons
@onready var items_panel = %Selections # Panel where inventory might be added
# Add references to Back buttons if you have them (e.g., %SkillBackButton)

# Reference to the currently controlled player combatant
var player: Combatant = null

# Current state of the UI
var current_state: UIState = UIState.HIDDEN:
	set(new_state):
		if current_state == new_state:
			return # No change

		# print("UI State changing from %s to %s" % [UIState.keys()[current_state], UIState.keys()[new_state]])
		current_state = new_state
		_update_ui_visibility()

# --- Initialization and Player Setup ---

func _ready() -> void:
	# Connect main action buttons
	%Attack.pressed.connect(_on_attack_button_pressed)
	%Skill.pressed.connect(_on_skill_button_pressed)
	%Items.pressed.connect(_on_items_button_pressed)
	%Skip.pressed.connect(_on_skip_button_pressed)
	# Connect any "Back" buttons if applicable
	# %SkillBackButton.pressed.connect(_on_back_button_pressed) 

	# Initial state is hidden
	hide()
	current_state = UIState.HIDDEN


## Sets the active player combatant for this UI.
## Called by the combat scene manager when the player's turn starts.
func set_player(new_player: Combatant) -> void:
	if new_player.get_meta("group") != GameManager.GROUPS.PLAYERS.id:
		push_warning("Not part of player group!")
		return
	if not is_instance_valid(new_player) or not new_player.is_in_group(GameManager.GROUPS.PLAYERS.id):
		push_warning("Attempted to set invalid player or non-player combatant.")
		return

	# Disconnect from the old player if different
	if is_instance_valid(player) and player != new_player:
		if player.active_changed.is_connected(_on_player_active_changed):
			player.active_changed.disconnect(_on_player_active_changed)
		# Disconnect other signals if necessary (e.g., AP changed)

	player = new_player

	# Connect to the new player's signals
	if not player.active_changed.is_connected(_on_player_active_changed):
		player.active_changed.connect(_on_player_active_changed)
	# Connect to other relevant signals from the player if needed:
	# player.ap_changed.connect(_on_player_ap_changed) # Example

	# Update UI based on player's active state
	_on_player_active_changed(player, player.is_active()) # Call manually to set initial state


## Called when the controlled player's 'active' status changes.
func _on_player_active_changed(_actor: Combatant, is_active: bool) -> void:
	if is_active:
		# Player's turn is starting
		show()
		_populate_skill_list() # Update skills in case they changed
		# Reset to the main action selection state
		current_state = UIState.SELECTING_ACTION
		# Check if the player *can* even act (e.g., has AP)
		if not _can_player_act():
			# Optionally show a message or immediately skip turn
			print("%s has no AP to act." % player.name)
			_end_player_turn() # Or transition to a state showing "No AP"
	else:
		# Player's turn is ending or they are no longer active
		current_state = UIState.HIDDEN
		hide()


# --- UI State Management ---

## Updates which UI panels are visible based on the current_state.
func _update_ui_visibility() -> void:
	# Hide all panels by default
	actions_panel.hide()
	attacking_panel.hide()
	skills_panel.hide()
	items_panel.hide() # Assumes inventory is managed externally or added here

	# Show the correct panel(s) based on state
	match current_state:
		UIState.HIDDEN:
			hide() # Hide the entire control
		UIState.SELECTING_ACTION:
			show() # Show the main control
			actions_panel.show()
		UIState.SELECTING_ATTACK_TARGET:
			show()
			attacking_panel.show() # Show targeting instructions/UI
			# Potentially highlight selectable targets in the main scene
		UIState.SELECTING_SKILL:
			show()
			skills_panel.show()
		UIState.SELECTING_SKILL_TARGET:
			show()
			# Show targeting instructions, potentially reuse attacking_panel
			attacking_panel.show() 
		UIState.SELECTING_ITEM:
			show()
			items_panel.show()
			# Expect external InventoryUI.open_inventory() to be called
		UIState.PROCESSING:
			show()
			# Optionally disable buttons or show a "waiting" indicator
			pass


# --- Button Press Handlers ---

func _on_attack_button_pressed() -> void:
	if current_state != UIState.SELECTING_ACTION or not _can_player_act():
		return

	print("Attack action selected.")
	current_state = UIState.SELECTING_ATTACK_TARGET
	# Start the process to get a target
	_select_target_and_attack()


func _on_skill_button_pressed() -> void:
	if current_state != UIState.SELECTING_ACTION or not _can_player_act():
		return

	print("Skill action selected.")
	_populate_skill_list() # Ensure list is up-to-date
	current_state = UIState.SELECTING_SKILL
	# The UI now waits for a skill button press within the skills_panel


func _on_items_button_pressed() -> void:
	if current_state != UIState.SELECTING_ACTION or not _can_player_act():
		return

	print("Item action selected.")
	current_state = UIState.SELECTING_ITEM
	_select_and_use_item()


func _on_skip_button_pressed() -> void:
	if current_state != UIState.SELECTING_ACTION or not is_instance_valid(player):
		return

	print("Skip action selected.")
	# Directly end the turn
	_end_player_turn()


func _on_back_button_pressed() -> void:
	# Logic to return to the previous state, typically SELECTING_ACTION
	if current_state in [UIState.SELECTING_ATTACK_TARGET, UIState.SELECTING_SKILL, UIState.SELECTING_ITEM, UIState.SELECTING_SKILL_TARGET]:
		current_state = UIState.SELECTING_ACTION
	# Add more specific back logic if needed


# --- Action Execution Flows ---

## Handles the process of selecting a target and executing the basic attack.
func _select_target_and_attack() -> void:
	if not is_instance_valid(player): return

	print("Waiting for attack target selection...")
	# Use a signal await to get the target selected by the player (e.g., clicking on an enemy)
	# Ensure GameManager.event.player_target_selected only emits valid enemy targets for attack
	var target = await GameManager.event.player_target_selected 

	if not is_instance_valid(target):
		print("Target selection cancelled or invalid.")
		current_state = UIState.SELECTING_ACTION # Return to action select
		return
	
	# Check if player still has AP right before committing
	if not _check_ap( 1 ): # Assume player has get_attack_ap_cost()
		print("Not enough AP to attack.")
		# Optionally show a message to the player here
		# Buzz sound? Flash AP red?
		current_state = UIState.SELECTING_ACTION # Return to action select
		return

	print("Target selected: %s. Executing attack." % target.name)
	current_state = UIState.PROCESSING # Optional: Disable UI while action processes

	# Call the player's attack function (assuming it queues the command)
	player.attack(target) # This should handle AP deduction and emit action_queued

	# Wait for the action to be queued/processed if needed, or just check turn end
	# await player.action_queued # Only if subsequent actions depend on this queueing

	_check_and_potentially_end_turn()


## Handles selecting a skill from the list. Called by skill buttons.
func _on_skill_selected(skill: Skill) -> void:
	if current_state != UIState.SELECTING_SKILL or not is_instance_valid(player):
		return
	if not is_instance_valid(skill):
		push_error("Invalid skill object received.")
		return

	print("Skill selected: %s" % skill.id)

	# *** CRITICAL CHECK: Can the player use this skill *before* selecting targets? ***
	var can_use_result = player.stat_block.get_attribute("ap").current_value - skill.cost >= 0 # Assume this method exists in Combatant
	if not can_use_result:
		print("Cannot use skill '%s': %s" % [skill.id, can_use_result.reason])
		# Provide feedback to the player:
		# - Show a temporary message on screen
		# - Play a "cannot use" sound effect
		# - Briefly flash the skill button red?
		# Do NOT proceed to target selection. Stay in SELECTING_SKILL state.
		# Example feedback:
		#GameManager.show_floating_message(can_use_result.reason, player.global_position)
		return 

	# If the skill can be used, proceed to target selection (if required)
	_select_targets_and_use_skill(skill)


## Handles target selection (if needed) and execution for a chosen skill.
func _select_targets_and_use_skill(skill: Skill) -> void:
	if not is_instance_valid(player) or not is_instance_valid(skill): return

	var targets: Array[Node] = []

	# Determine target acquisition based on skill's target type
	match skill.target:
		Skill.Targets.SELF:
			targets = [player]
		Skill.Targets.SINGLE:
			print("Waiting for skill target selection for '%s'..." % skill.id)
			current_state = UIState.SELECTING_SKILL_TARGET
			# Ensure player_target_selected signal emits appropriate target types based on skill.target
			var single_target = await GameManager.event.player_target_selected
			if not is_instance_valid(single_target):
				print("Skill target selection cancelled or invalid.")
				current_state = UIState.SELECTING_SKILL # Go back to skill list
				return
			targets = [single_target]
		Skill.Targets.ALL_ENEMIES:
			targets = get_tree().get_nodes_in_group(GameManager.GROUPS.ENEMIES.id)
		#Skill.Targets.ALL_ANY:
			#targets = get_tree().get_nodes_in_group(GameManager.GROUPS.PLAYERS.id) + \
					  #get_tree().get_nodes_in_group(GameManager.GROUPS.ENEMIES.id)
		_:
			push_error("Unhandled skill target type: %s" % skill.target)
			current_state = UIState.SELECTING_SKILL # Go back
			return

	if targets.is_empty():
		print("No valid targets found for skill '%s'." % skill.id)
		# Provide feedback (e.g., message: "No valid targets available")
		#GameManager.show_floating_message("No valid targets", player.global_position)
		current_state = UIState.SELECTING_SKILL # Go back
		return

	print("Targets acquired for skill '%s'. Executing." % skill.id)
	current_state = UIState.PROCESSING # Optional: Disable UI

	# Call the player's use_skill function (assuming it queues the command)
	# This function should handle AP/resource deduction internally *if successful*
	var success = await player.use_skill(skill, targets) # Assume use_skill is async or returns quickly

	if not success:
		# This might happen if, e.g., the target became invalid between selection and execution,
		# or if there was a last-second resource check failure within use_skill.
		print("Failed to execute skill '%s' after target selection." % skill.id)
		# Provide feedback (e.g., "Skill Failed!")
		#GameManager.show_floating_message("Skill Failed!", player.global_position)
		# Decide where to return the player - skill list or action select?
		current_state = UIState.SELECTING_SKILL
	else:
		# Skill was successfully queued/executed
		_check_and_potentially_end_turn()


## Handles opening the inventory, selecting an item, and using it.
func _select_and_use_item() -> void:
	if not is_instance_valid(player): return

	print("Opening Inventory UI...")
	# Assume InventoryUI.open_inventory() returns the inventory node and handles its own display
	var inventory_node = InventoryUI.open_inventory() 
	# You might want to add the inventory_node as a child of items_panel temporarily
	# items_panel.add_child(inventory_node) 

	# Wait for the player to select an item from the inventory UI
	var item: Item = await GameManager.event.combat_item_selected

	# Assume InventoryUI.close_inventory() handles hiding/removing the node
	InventoryUI.close_inventory(inventory_node) 

	if not is_instance_valid(item):
		print("Item selection cancelled or invalid.")
		current_state = UIState.SELECTING_ACTION
		return

	# Check if the item can be used (optional, depends on item logic)
	# if not player.can_use_item(item): ... return

	print("Item selected: %s. Queuing use." % item.name) # Assuming item has a name
	current_state = UIState.PROCESSING

	# Queue the command to use the item
	player.queue_command(
		UseItem.new(item) # Assuming UseItem command exists
		.on_target(player) # Default target is self? Or prompt for target?
		.set_priority(Command.Priority.HIGH) # Example priority
	)
	
	# await player.action_queued # Only if needed

	_check_and_potentially_end_turn()


# --- Turn Management and Helpers ---

## Checks if the player has enough AP and potentially ends the turn.
func _check_and_potentially_end_turn() -> void:
	if not is_instance_valid(player): return

	# Check AP after the action has been successfully queued/executed
	if not _can_player_act():
		print("Player has no more AP or cannot act.")
		_end_player_turn()
	else:
		# Return to action selection if the turn isn't over
		current_state = UIState.SELECTING_ACTION


## Checks if the player has enough AP to perform *any* action.
## You might expand this to check for other conditions (e.g., status effects).
func _can_player_act() -> bool:
	if not is_instance_valid(player):
		return false
	# Simple check based on AP. Assume 1 AP is the minimum cost for any action (like skip).
	# Adjust the check based on your game's rules (e.g., check specific action costs).
	var ap_attribute = player.stat_block.get_attribute("ap") 
	return is_instance_valid(ap_attribute) and ap_attribute.current_value > 0


## Checks if the player has a specific amount of AP.
func _check_ap(required_ap: int) -> bool:
	if not is_instance_valid(player): return false
	var ap_attribute = player.stat_block.get_attribute("ap")
	return is_instance_valid(ap_attribute) and ap_attribute.current_value >= required_ap


## Tells the player object to end its turn.
func _end_player_turn() -> void:
	print("Ending player turn via UI.")
	if is_instance_valid(player):
		player.turn_end() # Player combatant is responsible for emitting turn_ended signal
	# The _on_player_active_changed(false) callback will handle hiding the UI.
	current_state = UIState.PROCESSING # Or HIDDEN directly


## Populates the skill list UI based on the player's available skills.
func _populate_skill_list() -> void:
	if not is_instance_valid(player) or not is_instance_valid(skills_list):
		return

	# Clear existing buttons
	for child in skills_list.get_children():
		child.queue_free()

	var available_skills = player.get_skills() # Assume this returns an array of Skill objects
	if available_skills.is_empty():
		# Optionally display a "No Skills" label
		var no_skills_label = Label.new()
		no_skills_label.text = "No Skills Available"
		skills_list.add_child(no_skills_label)
		return

	for skill in available_skills:
		if not is_instance_valid(skill): continue

		var btn = Button.new()
		btn.text = skill.id.capitalize() # Assuming skill has an 'id' property
		btn.tooltip_text = skill.tooltip # Assuming skill has a 'tooltip'
		btn.icon = skill.icon # Assuming skill has an 'icon'

		# Check if the skill can be used *right now* for visual feedback (optional)
		var can_use_result = player.can_use_skill(skill) # Assume this returns {can_use: bool, reason: String}
		if not can_use_result.can_use:
			btn.disabled = true
			btn.tooltip_text += "\n(Cannot use: %s)" % can_use_result.reason
			# Add visual styling for disabled state (e.g., modulate color)
			btn.modulate = Color(0.5, 0.5, 0.5) 
		else:
			btn.disabled = false
			btn.modulate = Color(1, 1, 1)


		# Connect the button's pressed signal to _on_skill_selected
		# Use bind to pass the specific skill object
		btn.pressed.connect(_on_skill_selected.bind(skill))

		skills_list.add_child(btn)
		btn.custom_minimum_size = Vector2(80, 0) # Example minimum size
