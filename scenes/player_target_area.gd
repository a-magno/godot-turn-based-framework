extends Area2D

@export var skin : Node2D
@onready var skin_material := skin.material as ShaderMaterial

func _on_mouse_entered() -> void:
	%StatViewer.global_position = get_global_mouse_position()
	%StatViewer.show()
	if _is_player(): return
	skin_material.set_shader_parameter("enabled", true)

func _on_mouse_exited() -> void:
	%StatViewer.hide()
	if _is_player(): return
	skin_material.set_shader_parameter("enabled", false)


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if _is_player(): return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var target = get_parent()
			#print("target selected: %s" % target.name )
			GameManager.event.player_target_selected.emit( target )

func _on_combatant_health_changed(new_value: Variant) -> void:
	if new_value <= 0:
		input_pickable = false
	else:
		input_pickable = true

func _is_player()->bool:
	return get_parent().stats.is_player
