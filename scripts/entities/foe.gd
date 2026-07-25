extends LivingEntity
class_name Foe

@export var move_each := 3
@export var exclamation_sprite: Sprite2D

var projectiles_whitelist : Array[Projectile]

func _ready():
	super()
	current_move_attempt = randf_range(0, move_each)

func _process(delta):
	exclamation_sprite.set_visible(not (current_move_attempt + 1) % move_each)
	
func will_move():
	current_move_attempt += 1
	return not current_move_attempt % move_each
