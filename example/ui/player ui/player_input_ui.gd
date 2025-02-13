extends Control

var player : Combatant
var _active_tab : Control :
	set(tab):
		if _active_tab: _active_tab.hide()
		_prev_tab = _active_tab
		_active_tab = tab
		_active_tab.show()

var _prev_tab : Control

func _enter_tree() -> void:
	%Attack.pressed.connect(_on_attack_pressed)
	%Skill.pressed.connect(_on_skill_pressed)
	#_set_up_skills()

func _set_player( a : Combatant )->void:
	if not a.is_in_group(GameManager.GROUPS.PLAYERS.id): return
	# Disconecting from old player if they're different ones
	if player != a and player != null:
		player.active_changed.disconnect(_on_active_changed)
	if not a.active_changed.is_connected(_on_active_changed):
		a.active_changed.connect(_on_active_changed)
	# Sets new player
	player = a
	_set_skills()
	_active_tab = %Actions

func _on_attack_pressed()->void:
	#print("Attack Selected...")
	if player == null: return
	%Actions.hide()
	var target : Node
	#print("Waiting for target selection...")
	while target == null or target.is_in_group(GameManager.GROUPS.PLAYERS.id):
		target = await GameManager.event.player_target_selected
	player.queue_command( AttackCommand.new( target ).set_attacker( player ).modify_damage( randi_range(-2, 2) ) )

func _on_skill_pressed()->void:
	_active_tab = %Skills
	var skill : Skill = await GameManager.event.player_skill_selected
	%Skills.hide()
	var targets : Array[Node]
	if skill.target == Skill.Targets.ALL_ENEMIES:
		targets = get_tree().get_nodes_in_group(GameManager.GROUPS.ENEMIES.id)
	else:
		targets += [ await GameManager.event.player_target_selected as Node ]
	skill.set_caster( player )
	skill.use( targets as Array[Node] )
	#print(skill.id)

func _on_active_changed( _actor, value )->void:
	if value:
		show()
	else:
		hide()

func _set_skills():
	for c in %SkillsList.get_children():
		c.queue_free()
	var skills =  player.stats.skills
	for skill in skills:
		var btn = Button.new()
		btn.text = skill.id.capitalize()
		btn.pressed.connect(
			func():
				GameManager.event.player_skill_selected.emit( skill )
		)
		btn.tooltip_text = skill.tooltip
		btn.icon = skill.icon
		%SkillsList.add_child( btn )
		btn.custom_minimum_size = Vector2(80, 0)

func _on_prev_menu_pressed() -> void:
	_active_tab = _prev_tab

func _on_skip_pressed() -> void:
	player.turn_end()
