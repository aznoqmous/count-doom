extends InteractableEntity
class_name TrapEntity

func _ready() -> void:
	on_interact.connect(func(player: Player):
		player.take_damage(1)
	)
