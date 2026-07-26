extends Node2D
class_name SpellDisplay

@export var spell_sprite: Sprite2D
#@export var background_spell_sprite: Sprite2D
@export var label: Label

func set_spell(sr: SpellResource):
	spell_sprite.texture = sr.texture if sr else null
	#set_visible(!!sr)
