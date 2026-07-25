extends GridEntity
class_name LivingEntity

@export var hp_label : Label
@export var max_health := 3
@export var sprite_material: ShaderMaterial

const DAMAGE_PARTICLES = preload("res://scenes/particles/damage_particles.tscn")
const DAMAGE_CONTROL = preload("res://scenes/uis/damage_control.tscn")
var current_health := 0
var current_move_attempt := 0

func _ready():
	current_health = max_health
	update_health()

var current_color_ratio = 0.0
func _process(delta):
	current_color_ratio = lerp(current_color_ratio, 0.0, delta * 5.0)
	sprite_material.set_shader_parameter("color_ratio", current_color_ratio)
	pass

func take_damage(value):
	current_color_ratio = 1.0

	current_health = max(0, current_health - value)
	update_health()
	
	var dc = DAMAGE_CONTROL.instantiate() as DamageControl
	dc.set_value(str("-", value))
	dc.global_position = global_position
	get_parent().get_parent().add_child(dc)
	
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
