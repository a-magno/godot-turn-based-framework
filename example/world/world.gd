extends Node2D
class_name Overworld

@onready var encounter_manager: EncounterManager = $EncounterManager
static var player_steps : int = 0

func _ready() -> void:
	update_counter()

func _on_player_moved(pos: Vector2) -> void:
	if player_steps - encounter_manager.encounter_steps == 0:
		var generated = encounter_manager.generate_encounter( $Player.area )
		player_steps = 0
		if generated:
			#get_tree().unload_current_scene()
			GameManager.state = GameManager.GameState.BATTLE
			get_tree().change_scene_to_file("res://example/battle scene/battle_scene.tscn")
	player_steps += 1
	update_counter()

func update_counter():
	%EncounterIn.text = "Encounter in: %d steps" % (encounter_manager.encounter_steps - player_steps)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_TAB:
			if not InventoryUI.inventory_open:
				%PlayerWindows.add_child( InventoryUI.open_inventory() )
			else:
				InventoryUI.close_inventory( %PlayerWindows.get_child(0) )
