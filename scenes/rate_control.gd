# RatingControl.gd
# Inherits from HBoxContainer to automatically arrange CheckBoxes horizontally.
@tool
class_name RatingControl
extends HBoxContainer

## Signal emitted when the rating value changes.
signal value_changed(new_value: int)

## The total number of rating steps (checkboxes).
@export var max_value: int = 5 : set = set_max_value

## The current rating value.
@export var value: int = 0 : set = set_value

# Internal array to hold references to the CheckBox nodes.
var _checkboxes: Array[CheckBox] = []

# Called when the node is added to the scene tree (or when script is loaded in editor).
func _ready() -> void:
	# Ensure checkboxes are created based on the initial max_value,
	# especially important when running the game.
	# Use call_deferred to avoid issues with node readiness in the editor.
	call_deferred("_initial_setup")

func _initial_setup() -> void:
	# Trigger the creation of checkboxes if they haven't been created yet
	# (e.g., when the scene starts).
	if _checkboxes.size() != max_value:
		set_max_value(max_value) # This will create checkboxes and update visuals.
	# Ensure the initial value is visually represented.
	set_value(value)

# Setter for the 'max_value' property.
func set_max_value(new_max: int) -> void:
	var previous_max = max_value
	# Ensure max_value is not negative.
	max_value = max(0, new_max)

	if max_value != previous_max or _checkboxes.size() != max_value:
		# --- Clear existing checkboxes ---
		for cb in _checkboxes:
			if is_instance_valid(cb): # Check if the node still exists
				cb.toggled.disconnect(_on_checkbox_toggled) # Disconnect signal
				remove_child(cb) # Remove from HBoxContainer
				cb.queue_free() # Free the node
		_checkboxes.clear()

		# --- Create new checkboxes ---
		for i in range(max_value):
			var cb = CheckBox.new()
			cb.toggle_mode = true # Standard checkbox behavior
			# Make checkboxes expand horizontally to fill space if needed.
			cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			# Connect the toggled signal. Pass the index 'i' to the handler.
			# Use bind() to pass the index argument.
			cb.toggled.connect(_on_checkbox_toggled.bind(i))
			cb.focus_mode = Control.FOCUS_NONE
			cb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(cb) # Add to HBoxContainer
			_checkboxes.append(cb) # Store reference

		# Clamp the current value to the new max_value and update visuals.
		# Use call_deferred to avoid potential issues during initialization/editor updates.
		call_deferred("_update_value_and_visuals_after_max_change")


func _update_value_and_visuals_after_max_change() -> void:
	# Ensure the value doesn't exceed the new maximum.
	var clamped_value = clamp(value, 0, max_value)
	if clamped_value != value:
		set_value(clamped_value) # Update value using the setter
	else:
		_update_visuals() # Just update visuals if value didn't need clamping


# Setter for the 'value' property.
func set_value(new_val: int) -> void:
	# Clamp the value between 0 and max_value.
	var clamped_value = clamp(new_val, 0, max_value)

	if clamped_value != value:
		value = clamped_value # <-- Assigns the new value directly
		# Use call_deferred to prevent potential issues during signal handling or editor updates.
		call_deferred("_update_visuals")
		emit_signal("value_changed", value)
	elif not Engine.is_editor_hint():
		# If the value is set to the same but we are not in the editor,
		# ensure visuals are correct (can happen during init).
		call_deferred("_update_visuals")

# Called when any CheckBox is toggled (clicked).
func _on_checkbox_toggled(pressed: bool, index: int) -> void:
	# If a checkbox is checked (pressed = true), set value to index + 1.
	# If a checkbox is unchecked (pressed = false), set value to index.
	# This logic means clicking the 3rd star sets value=3, clicking it again sets value=2.
	var new_potential_value = index + 1 if pressed else index
	#set_value(new_potential_value) # Use the setter to handle updates and signals


# Updates the visual state (checked/unchecked) of all checkboxes.
func _update_visuals() -> void:
	# Ensure we have the correct number of checkboxes before updating.
	if _checkboxes.size() != max_value:
		# This can happen briefly in the editor when max_value changes.
		# The set_max_value function will handle recreating and updating.
		return

	for i in range(max_value):
		if is_instance_valid(_checkboxes[i]): # Check if checkbox exists
			# Check the box if its index is less than the current value.
			_checkboxes[i].button_pressed = (i < value)
