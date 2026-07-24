extends Node

var tileset_size := 120.0

func tween()->Tween:
	return get_tree().create_tween()
	
func sleep(time):
	await get_tree().create_timer(time).timeout
