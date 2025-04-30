extends Command
class_name UseSkill

var user : Combatant
var skill : Skill
var targets : Array[Node]

func _init( _skill : Skill )->void:
	skill = _skill

func execute()->void:
	if not user: return
	await user.play_anim("attack")
	skill.set_caster( user )
	skill.use( targets )

func used_by( actor : Combatant )->UseSkill:
	user = actor
	return self

func targetting( _targets : Array[Node])->UseSkill:
	targets = _targets
	return self

func _to_string()->String:
	return "<Skill : %s>" % skill.id
