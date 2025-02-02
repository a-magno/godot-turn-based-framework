extends Resource
class_name Skill

enum Targets { SELF, SINGLE, ALL_ENEMIES }

@export_group("Data")
@export var id : StringName
@export var cost : int
@export var target : Targets
var _caster : Node


@export_group("Visuals")
@export var icon : Texture
@export_multiline var tooltip : String

func is_single_target()->bool:
	return target == Targets.SINGLE

func set_caster( node : Node )->Skill:
	_caster = node
	return self

## Used to process targets that are not a selected via
## targetting by mouse system
func _get_targets( targets : Array[Node])->Array[Node]:
	if not targets: return []
	var tree := targets[0].get_tree()
	print_debug(tree)
	match target:
		Targets.SELF:
			return [_caster]
		Targets.ALL_ENEMIES:
			return tree.get_nodes_in_group(GameManager.GROUPS.ENEMIES.id)
		_:
			return []

func use( targets : Array[Node] )->void:
	# EventBus.player_onSkillCast.emit()
	# if _caster != null: _caster.stamina -= cost
	print("using skill %s" % self.id)
	if is_single_target():
		apply_effects(targets)
	else:
		apply_effects( _get_targets(targets) )

func apply_effects(_targets : Array[Node])->void:
	pass

# EOF #
