extends Node
class_name GameManager

const GROUPS := {
	"PLAYERS" : "PLAYERS",
	"ENEMIES" : "ENEMIES",
}

class Events:
	signal combatant_dead( combatant : Combatant )

static var events : Events = Events.new()
