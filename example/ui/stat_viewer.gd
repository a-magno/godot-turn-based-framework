extends Control

@export var actor : Combatant

func _ready()->void:
	hide()

func _process(delta: float) -> void:
	for c in %StatsContainer.get_children():
		c.queue_free()
	
	var stats = actor.stat_block.stats
	var attribs = actor.stat_block.attributes
	
	for a : Attribute in attribs.values():
		var lbl := Label.new()
		lbl.text = "%s : %d / %d" % [a.id.to_upper(), a.current_value, a.max_value ]
		%StatsContainer.add_child( lbl )
	
	%StatsContainer.add_child( HSeparator.new() )
	
	for stat : Stat in stats.values():
		if stat.hidden: continue
		var lbl := Label.new()
		lbl.text = "%s : %d" % [stat.id.to_upper(), stat.value]
		%StatsContainer.add_child( lbl )
