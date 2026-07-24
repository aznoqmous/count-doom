extends GridEntity
class_name Foe

@export var hp_label : Label
@export var max_health := 3
@export var move_each := 3
const DAMAGE_PARTICLES = preload("res://scenes/particles/damage_particles.tscn")

var current_health := 0
var current_move_attempt := 0

func _ready():
	current_health = max_health
	update_health()
	current_move_attempt = randf_range(0, move_each)
	
func take_damage(value):
	current_health = max(0, current_health - value)
	update_health()
	var dp = DAMAGE_PARTICLES.instantiate() as GPUParticles2D
	get_parent().get_parent().add_child(dp)
	dp.global_position = global_position
	dp.emitting = true
	await Utility.sleep(dp.lifetime)
	dp.queue_free()
	
func update_health():
	hp_label.text = str(current_health)
	
func is_alive():
	return current_health > 0

func will_move():
	current_move_attempt += 1
	return not current_move_attempt % move_each
