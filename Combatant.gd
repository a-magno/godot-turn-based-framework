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



func _ready() -> void:
	randomize()
	$Vitals.initialize()

func set_active( _a : bool ):
	if health <= 0:
		return
	super(_a)

#region TEST
func test_attack()->void:
	var targets : Array = get_tree().get_nodes_in_group(target_group)
	#print_debug("%s's choices: %s" % [name, str(targets)])
	if targets.size() > 0:
		var target
		while not is_instance_valid(target):
			target = targets.pick_random() as CombatActor

		action_queued.emit( AttackCommand.new( target )
							.set_priority(speed)
							.modify_damage( randi_range(-2, 2) ) 
							)
		turn_end()

#endregion

func queue_command( command : Command )->void:
	if acted: return
	#print("Command queued")
	action_queued.emit(command)
	acted = true
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
