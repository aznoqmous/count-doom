@tool
extends GridEntity
class_name Projectile

@export var position_oriented := false
@export var sprite_2d: Sprite2D
@export var life := 1.0
@export var damage := 1.0
@export var move_per_turn := 1.0

func _ready() -> void:
	if move_per_turn: move_speed /= move_per_turn

func _process(delta):
	if Engine.is_editor_hint():
		if position_oriented: sprite_2d.rotation = atan2(position.y, position.x)
		else: sprite_2d.rotation = 0.0

## Called once after each player movement
func tick():
	life -= 1
	
