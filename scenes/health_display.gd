extends PanelContainer

@export var entity_data : Entity
@export var stat_block : StatBlock

func _process(delta: float) -> void:
	%Name.text = entity_data.name
	%HealthBar.value = stat_block.get_attribute("health").current_value
	%HealthBar.max_value = stat_block.get_attribute("health").max_value
