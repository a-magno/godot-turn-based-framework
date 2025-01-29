extends CombatActor
class_name Combatant

signal queue_action( command : Command )
signal health_changed(new_value)

@export var target_group : StringName = GameManager.GROUPS.PLAYERS

@export var stats : Stats :
	set(s):
		stats = s
		if stats == null: return
		max_health = stats.max_health
		damage = stats.attack
		speed = stats.speed
		name = stats.id

@export var max_health : int :
	set(h):
		max_health = h
		
@onready var health : int = max_health :
	set(h):
		health = h
		health_changed.emit(health)
		print(name, "'s HP at %d/%d" % [health, max_health])
@export var speed : int = 0 :
	set(s):
		speed = s
		#data_changed.emit(self, {"speed":speed})
@export var damage : int

func _ready() -> void:
	randomize()
	$Vitals.initialize()

func set_active( _a : bool ):
	if health <= 0:
		return
	super(_a)

func play_turn():
	if not active: return
	await test_attack()
	active = false
	
	
#region TEST
func test_attack()->void:
	var targets : Array = get_tree().get_nodes_in_group(target_group)
	#print_debug("%s's choices: %s" % [name, str(targets)])
	if targets.size() > 0:
		var target
		while not is_instance_valid(target):
			target = targets.pick_random() as CombatActor
		#print_debug("%s is queueing an attack." % name)
		queue_action.emit( AttackCommand.new( target, self ).set_priority(speed) )

func test_skill()->void:
	pass

#endregion


func take_damage( amount : int ):
	health -= amount
	if not is_alive():
		queue_action.emit( Defeated.new( self ).set_priority(Defeated.Priority.HIGH) )

func is_alive()->bool:
	return health > 0


func print_stats():
	print("\nName: %s\nMax HP: %d\nDamage: %d\nSpeed: %d\n" % [name, max_health, damage, speed])

# EOF #
