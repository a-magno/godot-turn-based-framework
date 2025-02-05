extends Node
class_name GameManager

const GROUPS := {
	"PLAYERS" : {
		"id": "players",
		"color": Color.ROYAL_BLUE
	},
	"ENEMIES" : {
		"id": "enemies",
		"color": Color.MAROON
	}
}

class Events:
	signal combatant_dead( combatant : Combatant )
	signal player_target_selected( combatant : Combatant )
	signal player_skill_selected( skill : Skill )
	signal combat_round_start()
	signal combat_round_end()

static var event : Events = Events.new()
