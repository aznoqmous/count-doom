@tool
extends TextureRect

@export var speed := 1.0
func _process(delta: float) -> void:
	rotation += delta * speed
