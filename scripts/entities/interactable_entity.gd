extends GridEntity
class_name InteractableEntity

@export var interact_once := true
@export var destroyed_on_interact := false
var interacted := false

func trigger(player: Player):
	if interact_once and interacted: return;
	interacted = true
	on_interact.emit(player)
	
signal on_interact(player: Player)
