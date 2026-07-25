@tool
extends GridEntity
class_name Projectile

@export var position_oriented := false
@export var life := 1.0
@export var damage := 1.0
@export var move_per_turn := 1.0
@export var free_after_animated_sprite : AnimatedSprite2D
@export var free_after_sec := 0.0
func _ready() -> void:
	if move_per_turn: move_speed /= move_per_turn

func _process(delta):
	super(delta)
	if Engine.is_editor_hint():
		if position_oriented: sprites_container.rotation = atan2(position.y, position.x)
		else: sprites_container.rotation = 0.0

func tick():
	life -= 1
	
