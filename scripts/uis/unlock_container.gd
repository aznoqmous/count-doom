extends Control
class_name UnlockContainer

@export var confirm_buttom: Button
@export var number_container: NumberContainer

func _ready():
	confirm_buttom.pressed.connect(func():
		set_visible(false)
		submitted.emit()
	)
	
	number_container.spells_changed.connect(func():
		confirm_buttom.set_visible(number_container.get_spells().filter(func(s): return s).size() > 0)
	)


signal submitted()
