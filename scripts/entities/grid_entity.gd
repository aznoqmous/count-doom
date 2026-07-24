extends Node2D
class_name GridEntity

@export var movement_oriented := true
@export var sprites_container: Node2D
@export var direction : Vector2i

var pos: Vector2i:
	set(value):
		position = pos / Utility.tileset_size
	get():
		return position / Utility.tileset_size

var move_speed := 0.1
var is_moving := false
var jump_state := 0.0
var h_orientation := 1.0

func move(dir: Vector2i):
	if is_moving: return;
	direction = dir
	is_moving = true
	jump_state = 0.0
	sprites_container.scale = Vector2(h_orientation * 1.0 / 1.1, 1.1)
	if dir.x != 0 and movement_oriented: h_orientation = sign(dir.x)
	var pos = position + Vector2(dir * Utility.tileset_size)
	var t = Utility.tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_property(self, "position", pos, move_speed)
	t.tween_property(self, "jump_state", 1.0, move_speed)
	await Utility.sleep(move_speed)
	position = pos
	is_moving = false
	sprites_container.scale = Vector2(h_orientation * 1.1, 1.0 / 1.1)

func _process(delta):
	sprites_container.scale = lerp(sprites_container.scale, Vector2(h_orientation, 1.0), delta * 5.0)
	sprites_container.position.y = sin(min(jump_state, 1.0) * PI) * -20.0
