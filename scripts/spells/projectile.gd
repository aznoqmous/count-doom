@tool
extends GridEntity
class_name Projectile

@export var position_oriented := false
@export var life := 1.0
@export var damage := 1.0
@export var move_per_turn := 1.0
@export var free_after_sec := 0.0
@export var free_after_animation:= false
@export var animation_player: AnimationPlayer
@export var sprite2d: Sprite2D

func _ready() -> void:
	if move_per_turn: move_speed /= move_per_turn

func _process(delta):
	super(delta)
	if Engine.is_editor_hint():
		if position_oriented: sprite2d.rotation = atan2(position.y, position.x)
		else: sprite2d.rotation = 0.0

func tick():
	life -= 1
	
