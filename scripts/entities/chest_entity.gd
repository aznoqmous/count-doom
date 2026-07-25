extends InteractableEntity
class_name ChestEntity

func _ready() -> void:
	on_interact.connect(func(player):
		print("CHESTED")
	)
