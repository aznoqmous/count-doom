extends InteractableEntity
class_name SpellStandEntity

@export var spell_sprites_container: Node2D
@export var available_spells: Array[SpellResource]
@export var spell_sprite: Sprite2D
var spell_resource: SpellResource

func _ready() -> void:
	load_resource(available_spells.pick_random())
	on_interact.connect(func(player): spell_sprites_container.set_visible(false))
	
func load_resource(res: SpellResource):
	spell_resource = res
	spell_sprite.texture = res.texture
