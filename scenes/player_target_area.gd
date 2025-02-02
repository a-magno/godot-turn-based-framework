extends Area2D

@export var skin : Node2D
@onready var skin_material := skin.material as ShaderMaterial

func _on_mouse_entered() -> void:
	skin_material.set_shader_parameter("enabled", true)

func _on_mouse_exited() -> void:
	skin_material.set_shader_parameter("enabled", false)


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var target = get_parent()
			#print("target selected: %s" % target.name )
			GameManager.event.player_target_selected.emit( target )
