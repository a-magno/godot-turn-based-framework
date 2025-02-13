extends Control

@export var actor : Combatant
@onready var attrib_container = actor.attribute_container 

func _ready()->void:
	hide()

func _process(delta: float) -> void:
	for c in %StatsContainer.get_children():
		c.queue_free()
	
	var stats = attrib_container.get_stats()
	var attribs = attrib_container.get_attributes()
	
	for a : Attribute in attribs:
		var lbl := Label.new()
		lbl.text = "%s : %.1f / %.1f" % [a.id.capitalize(), a.value, a.max_value ]
		%StatsContainer.add_child( lbl )
	
	%StatsContainer.add_child( HSeparator.new() )
	
	for stat in stats:
		var lbl := Label.new()
		lbl.text = "%s : %d" % [stat.id.capitalize(), stat.value]
		%StatsContainer.add_child( lbl )
