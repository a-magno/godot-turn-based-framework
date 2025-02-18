extends CombatActor
class_name Combatant

const SCENE : PackedScene = preload("res://scenes/combatant.tscn")

signal action_queued( command : Command )
signal vitals_updated()
signal health_changed(new_value)

#@export var target_group : StringName = GameManager.GROUPS.PLAYERS.id

#@export var stats : Stats :
	#set(s):
		#stats = s
		#if stats == null: return
		##max_health = stats.max_health
		#damage = stats.attack
		#speed = stats.speed

var max_health : int :
	set(h):
		max_health = h
		
var health : int = max_health :
	set(h):
		health = h
		health_changed.emit(health)
		#print(name, "'s HP at %d/%d" % [health, max_health])
var speed : int = 0 :
	set(s):
		speed = s
var damage : int

@export var status_handler : StatusHandler

var stat_block : StatBlock
var _data : Entity
#@export var attribute_container : AttributeContainer

#region Factory
var _is_player : bool = false

func is_player():
	return _is_player and is_in_group(GameManager.GROUPS.PLAYERS.id)

static func new_player( data : Entity )->Combatant:
	var new_player : Combatant = SCENE.instantiate() as Combatant
	
	new_player.name = data.name
	new_player.stat_block = data.stat_block
	new_player._data = data
	new_player.add_to_group(GameManager.GROUPS.PLAYERS.id)
	new_player.set_meta("group", GameManager.GROUPS.PLAYERS.id)
	
	new_player._is_player = true
	return new_player

static func new_enemy( data : Entity )->Combatant:
	var new_enemy : Combatant = SCENE.instantiate() as Combatant
	
	new_enemy.name = data.name
	new_enemy._data = data
	new_enemy.stat_block = data.stat_block
	
	new_enemy.add_to_group(GameManager.GROUPS.ENEMIES.id)
	new_enemy.set_meta("group", GameManager.GROUPS.ENEMIES.id)
	return new_enemy

#endregion

func _ready() -> void:
	randomize()
	status_handler.target = self
	# Creates a unique duplicate to ensure internal resources
	# are not being shared across multiple combatants
	stat_block.initialize()
	$Vitals.initialize()
	
	GameManager.event.combat_round_start.connect(_on_round_start)
	GameManager.event.combat_round_start.connect(_on_round_end)

func set_active( _a : bool ):
	if not alive(): return
	super(_a)

func turn_start()->void:
	super()

func turn_end()->void:
	super()

func queue_command( command : Command )->void:
	if acted: return
	action_queued.emit(command)
	turn_end()
	#print(">%s queued command type: %s" % [name, command.get_class_name()])
	#acted = true
	#print("Command queued")
	#print("%s turn ended." % name)

func attack( target : Combatant )->void:
	queue_command( 
		AttackCommand.new( target )
		.with_damage( stat_block.get_stat("atkPow").value )
		)

func get_skills()->Array[Skill]:
	return _data.skills


func take_damage( amount : int ):
	stat_block.get_attribute("health").decrease(amount)
	health_changed.emit(stat_block.get_attribute("health").current_value)
	if not alive():
		die()

func alive()->bool:
	return stat_block.get_attribute("health").current_value > 0

func die()->void:
	#action_queued.emit( Defeated.new( self ).set_priority(Defeated.Priority.HIGH) )
	await vitals_updated
	Defeated.new( self ).execute()
	set_active(false)
	remove_from_group( get_meta("group") )
	#Death.new().execute([self])


func print_stats():
	print("\nName: %s\nMax HP: %d\nDamage: %d\nSpeed: %d\n" % [name, max_health, damage, speed])


func _on_round_start()->void:
	if not alive():
		die()
	status_handler.apply_status_by_type( Status.Type.TURN_START )

func _on_round_end()->void:
	if not alive():
		die()
	status_handler.apply_status_by_type( Status.Type.TURN_END )
# EOF #
