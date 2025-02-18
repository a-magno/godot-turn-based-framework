extends Node2D
class_name Overworld

@onready var encounter_manager: EncounterManager = $EncounterManager
static var player_steps : int = 0

func _ready() -> void:
	update_counter()

func _on_player_moved(pos: Vector2) -> void:
	player_steps += 1
	if player_steps - encounter_manager.encounter_steps == 0:
		var generated = encounter_manager.generate_encounter( $Player.area )
		player_steps = 0
		if generated:
			#get_tree().unload_current_scene()
			get_tree().change_scene_to_file("res://example/battle scene/battle_scene.tscn")
	update_counter()

func update_counter():
	%EncounterIn.text = "Encounter in: %d steps" % (encounter_manager.encounter_steps - player_steps)
