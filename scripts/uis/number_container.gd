extends Control
class_name NumberContainer

const NUMBER_CONTROL = preload("res://scenes/uis/number_control.tscn")

var number_controls: Array[NumberControl]
@export var container: HBoxContainer

func build_countdown(length):
	for nc in container.get_children(): nc.queue_free()
	for i in length:
		var nc = NUMBER_CONTROL.instantiate() as NumberControl
		container.add_child(nc)
		number_controls.append(nc)
		nc.number = length - i
		nc.spell_changed.connect(func(sr):
			print("NC SPELLS CHANGED !")
			spells_changed.emit()
			close_spells()
		)
		nc.mouse_entered.connect(func():
			for n in number_controls:
				n.selection_opened = nc == n
		)


func close_spells():
	for n in number_controls:
		n.selection_opened = false

func update_available_spells(srs: Array[SpellResource]):
	var equipped_spells = number_controls.map(func(nc): return nc.spell_resource).filter(func(a): return a)
	var available_spells = srs.duplicate()
	for sr in equipped_spells:
		available_spells.erase(sr)
	
	for nc in number_controls:
		nc.update_available_spells(available_spells)

func update_countdown(index):
	for i in number_controls.size():
		number_controls[i].is_current_cooldown = index == i
	
signal spells_changed()
