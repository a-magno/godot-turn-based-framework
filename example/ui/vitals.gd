extends VBoxContainer

@export var combatant : Combatant :
	set(c):
		combatant = c

func _process(delta: float) -> void:
	%Name.text = combatant.name

func initialize()->void:
	%Healthbar.max_value = combatant.stat_block.get_stat("maxHealth").value
	%Healthbar.value = combatant.stat_block.get_attribute("health").current_value
	_update_label(%Healthbar.value, %Healthbar.max_value)
	%Name.text = combatant.name
	var status_handler : StatusHandler = combatant.find_child("*StatusHandler*")
	status_handler.new_status_added.connect( %StatusContainer.add_status )
	combatant.health_changed.connect(_on_health_changed)

func _on_health_changed(value)->void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(%Healthbar, "value", value, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_method(_update_label.bind(%Healthbar.max_value), %Healthbar.value, value, 0.3)
	await tween.finished
	combatant.vitals_updated.emit()

func _update_label(value, max_value)->void:
	%HealthLabel.text = "%d / %d" % [clamp(value, 0, max_value), max_value]
