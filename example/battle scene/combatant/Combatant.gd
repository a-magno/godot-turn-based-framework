extends CombatActor
class_name Combatant

signal action_queued( command : Command )
signal vitals_updated()
signal health_changed(new_value)

#@export var target_group : StringName = GameManager.GROUPS.PLAYERS.id

@export var stats : Stats :
	set(s):
		stats = s
		if stats == null: return
		#max_health = stats.max_health
		damage = stats.attack
		speed = stats.speed

@export var max_health : int :
	set(h):
		max_health = h
		
@onready var health : int = max_health :
	set(h):
		health = h
		health_changed.emit(health)
		#print(name, "'s HP at %d/%d" % [health, max_health])
@export var speed : int = 0 :
	set(s):
		speed = s
@export var damage : int

@export var status_handler : StatusHandler
@export var attribute_container : AttributeContainer

func _ready() -> void:
	randomize()
	status_handler.target = self
	max_health = attribute_container.get_stat("max_health").value
	health = attribute_container.get_attribute("health").value
	#attribute_container.get_attribute("health").value_changed.connect(
		#func(v):
			#health = v
	#)
	health_changed.connect(
		func(v):
			attribute_container.get_attribute("health").value = v
	)
	
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


func take_damage( amount : int ):
	health -= amount
	if not alive():
		die()

func alive()->bool:
	return health > 0

func die()->void:
	#action_queued.emit( Defeated.new( self ).set_priority(Defeated.Priority.HIGH) )
	await vitals_updated
	Defeated.new( self ).execute()
	set_active(false)
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
