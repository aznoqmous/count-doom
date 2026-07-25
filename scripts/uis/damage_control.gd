extends Node2D
class_name DamageControl

@export var label: Label

var start
func _ready():
	start = Time.get_ticks_msec()

func _process(delta):
	if Time.get_ticks_msec() - start > 1000.0: return queue_free()
	position.y -= delta

func set_value(value):
	label.text = value
