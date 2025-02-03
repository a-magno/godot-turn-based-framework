extends CombatActor
class_name Combatant

signal action_queued( command : Command )

signal health_changed(new_value)

@export var target_group : StringName = GameManager.GROUPS.PLAYERS.id

@export var stats : Stats :
	set(s):
		stats = s
		if stats == null: return
		max_health = stats.max_health
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

func _ready() -> void:
	randomize()
	$Vitals.initialize()
	status_handler.target = self

func turn_start()->void:
	super()
	status_handler.apply_status_by_type( Status.Type.TURN_START )
	
func turn_end()->void:
	super()
	status_handler.apply_status_by_type( Status.Type.TURN_END )

func set_active( _a : bool ):
	if health <= 0:
		return
	super(_a)


func queue_command( command : Command )->void:
	if acted: return
	action_queued.emit(command)
	#acted = true
	#print("Command queued")
	turn_end()


func take_damage( amount : int ):
	health -= amount
	if not is_alive():
		action_queued.emit( Defeated.new( self ).set_priority(Defeated.Priority.HIGH) )

func is_alive()->bool:
	return health > 0


func print_stats():
	print("\nName: %s\nMax HP: %d\nDamage: %d\nSpeed: %d\n" % [name, max_health, damage, speed])

# EOF #
