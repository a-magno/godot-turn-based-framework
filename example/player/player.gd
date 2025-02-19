extends CharacterBody2D

signal moved( pos : Vector2 )

const TILE_SIZE = 64
var moving : bool = false

@onready var tilemap : TileMapLayer = get_tree().current_scene.find_child("*Map*")

var area : StringName = "":
	set(v):
		area = v
		%InTile.text = "Stepping in: %s" % v

func _ready()->void:
	position = GameManager.player_last_pos

func update_tile():
	var data = tilemap.get_cell_tile_data(tilemap.local_to_map(position))
	if data:
		area = data.get_custom_data("area_type")

func _physics_process(delta: float) -> void:
	move()
	update_tile()

func move()->void:
	var dir = Input.get_vector("ui_left","ui_right","ui_up", "ui_down")
	if dir == Vector2.ZERO: return
	if moving: return
	moving = true
	var target_pos = (dir.normalized() * TILE_SIZE).snapped( Vector2(TILE_SIZE, TILE_SIZE) )
	var t = create_tween()
	t.tween_property($Icon, "position", target_pos, 0.2).from_current()
	await t.finished
	position += target_pos
	$Icon.position = Vector2.ZERO
	moving = false
	GameManager.player_last_pos = position
	moved.emit( position )
