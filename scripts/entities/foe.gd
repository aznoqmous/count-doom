extends LivingEntity
class_name Foe

@export var move_each := 3
@export var exclamation_sprite: Sprite2D

var projectiles_whitelist : Array[Projectile]
var is_active := false

func _ready():
	super()
	current_move_attempt = randf_range(0, move_each)

func _process(delta):
	super(delta)
	#exclamation_sprite.set_visible(not (current_move_attempt + 1) % move_each and is_active)
	modulate = Color.WHITE if is_active else Color.DIM_GRAY
	
func will_move():
	current_move_attempt += 1
	return not current_move_attempt % move_each

func update_exclamation_sprite(count):
	var state = ((current_move_attempt) % move_each + count) > move_each
	exclamation_sprite.set_visible(state and is_active and is_alive())
