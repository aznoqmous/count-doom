@tool
extends Control
class_name SpellContainer

@export var spell_texture_rect: TextureRect
@export var spell_resource: SpellResource:
	set(value):
		spell_resource = value
		spell_texture_rect.texture = spell_resource.texture if spell_resource else null

var hovered := false

func _ready() -> void:
	mouse_entered.connect(func(): hovered = true)
	mouse_exited.connect(func(): hovered = false)

func _input(input:InputEvent):
	if not hovered: return;
	if input is InputEventMouseButton and input.is_pressed() and input.button_index == 1:
		clicked.emit()

signal clicked()
