extends VBoxContainer

@export var combatant : Combatant :
	set(c):
		combatant = c
		
func initialize()->void:
	%Healthbar.max_value = combatant.max_health
	%Healthbar.value = combatant.max_health
	_update_label(%Healthbar.value, %Healthbar.max_value)
	%Name.text = combatant.name
	combatant.health_changed.connect(_on_health_changed)

func _on_health_changed(value)->void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(%Healthbar, "value", value, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_method(_update_label.bind(%Healthbar.max_value), %Healthbar.value, value, 0.3)

func _update_label(value, max_value)->void:
	%HealthLabel.text = "%d / %d" % [value, max_value]
