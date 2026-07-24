@tool
extends Control
class_name NumberControl

const SPELL_CONTAINER = preload("res://scenes/uis/spell_container.tscn")

@export var number_label: Label
@export var label_control: Control
@export var spell_container: SpellContainer
@export var spell_selection_container: VBoxContainer
@export var available_spells_container: VBoxContainer
@export var selection_opened_spacing:= -8
@export var selection_closed_spacing:= -60
@export var clear_spell_container: SpellContainer
@export var selection_opened:= false
@export var is_current_cooldown := false
@export var default_color: Color
@export var active_color: Color

@export var number := 9:
	set(value):
		number = value
		number_label.text = str(value)
		
@export var spell_resource: SpellResource:
	set(value):
		if not spell_container: return;
		spell_container.set_visible(!!value)
		spell_resource = value
		spell_container.spell_resource = value

func _ready():
	spell_resource = spell_resource
	clear_spell_container.clicked.connect(func():
		spell_resource = null
		spell_changed.emit(null)
		selection_opened = false
	)

func _process(delta):
	number_label.modulate = lerp(number_label.modulate, active_color if is_current_cooldown else default_color, delta * 5.0)
	#spell_selection_container.scale.y = lerp(spell_selection_container.scale.y, 1.0 if selection_opened else 0.0, delta * 20.0)
	#spell_selection_container.modulate.a = lerp(spell_selection_container.modulate.a, 1.0 if selection_opened else 0.0, delta * 50.0)
	clear_spell_container.set_visible(!!spell_resource)
	spell_selection_container.set_visible(selection_opened)
	
func update_available_spells(srs: Array[SpellResource]):
	var unique_srs: Array[SpellResource]
	unique_srs = srs.duplicate()
	#for s in srs: 
		##if unique_srs.has(s): continue
		#if spell_resource == s: continue
		#unique_srs.append(s)
		
	for sc in available_spells_container.get_children(): sc.queue_free()
	
	for sr in unique_srs:
		var sc = SPELL_CONTAINER.instantiate() as SpellContainer
		available_spells_container.add_child(sc)
		sc.spell_resource = sr
		sc.clicked.connect(func():
			spell_resource = sc.spell_resource
			spell_changed.emit(sc.spell_resource)
			selection_opened = false
		)

signal spell_changed(sr)
