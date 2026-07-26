extends Node2D
class_name TileSelection

@export var hovered_sprite: Sprite2D
@export var default_sprite: Sprite2D
@export var area_2d: Area2D
var direction : Vector2i:
	get(): return round(position / Utility.tileset_size)

var hovered := false
func _ready():
	area_2d.mouse_entered.connect(func(): hovered = true)
	area_2d.mouse_exited.connect(func(): hovered = false)
	
func _process(delta):
	hovered_sprite.set_visible(hovered)
	default_sprite.set_visible(not hovered)

func _input(event: InputEvent) -> void:
	if not hovered: return;
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		clicked.emit()
		
signal clicked()
