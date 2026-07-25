@tool
extends Node2D
class_name CellNode

		
var time_alive:= 0.0
var cell: Generator.Cell

@export var cell_type: Generator.CellType:
	set(value):
		exit_sprite.set_visible(Generator.CellType.Exit == value)
		entrance_sprite.set_visible(Generator.CellType.Entrance == value)
		monster_sprite.set_visible(Generator.CellType.Enemy == value)
		key_sprite.set_visible(Generator.CellType.Key == value)
		lock_sprite.set_visible(Generator.CellType.Lock == value)
		reward_sprite.set_visible(Generator.CellType.Reward == value)
		cell_type = value

@export var allowed_directions: Array[Directions]: 
	set(value):
		left_sprite.set_visible(value.has(Directions.Left))
		top_sprite.set_visible(value.has(Directions.Top))
		right_sprite.set_visible(value.has(Directions.Right))
		bottom_sprite.set_visible(value.has(Directions.Bottom))
		allowed_directions = value
		changed.emit()

@export var required_rooms: Array[PackedScene]:
	set(value):
		required_rooms = value
		for r in rooms_container.get_children(): r.queue_free()
		for r in required_rooms:
			rooms_container.add_child(r.instantiate())

@export var repeat := 0 :
	set(value):
		repeat = value
		repeat_label.text = str("x", repeat)
		repeat_label.set_visible(repeat > 1)

signal changed()

@export_category("Nodes")
@export var next: CellNode:
	set(value):
		if next: next.parent = null
		next = value
		if value: value.parent = self
@export var branch: CellNode:
	set(value):
		if branch: branch.parent = null
		branch = value
		if value: value.parent = self
@export var parent: CellNode
@export var sprite: Sprite2D
@export var state_sprite_container: Node2D
@export var rooms_container: Node2D
@export var repeat_label: Label
@export var exit_sprite: Sprite2D
@export var entrance_sprite: Sprite2D
@export var monster_sprite: Sprite2D
@export var key_sprite: Sprite2D
@export var lock_sprite: Sprite2D
@export var reward_sprite: Sprite2D
@export var left_sprite: Sprite2D
@export var top_sprite: Sprite2D
@export var right_sprite: Sprite2D
@export var bottom_sprite: Sprite2D
@export var generation_state_sprite: Sprite2D
enum Directions {
	Left,
	Top,
	Right,
	Bottom
}
	
func _process(delta):
	position = round(position / 32.0) * 32.0
