extends PanelContainer

@export var entity_data : Entity
@export var stat_block : StatBlock

func _process(delta: float) -> void:
	%Name.text = entity_data.name
	
	var value = stat_block.get_attribute("health").current_value
	var max_value = stat_block.get_attribute("health").max_value
	%HealthBar.value = value
	%HealthBar.max_value = max_value
	$MarginContainer/VBoxContainer/HealthBar/Label.text = "%d/%d" %[value, max_value]
