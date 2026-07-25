@tool
class_name Room
extends TileMapLayer
var str_id: String
@export var is_unique:= false
@export var is_required := false ## prevent regular cell to instantiate this room
@export var min_doors:= 0
@export var priority := 0

@export_category("Nodes")
@export var background_layer: TileMapLayer
@export var state_sprite_container: Node2D
@export var label: Label
@export var exit_sprite: Sprite2D
@export var entrance_sprite: Sprite2D
@export var monster_sprite: Sprite2D
@export var key_sprite: Sprite2D
@export var lock_sprite: Sprite2D
@export var reward_sprite: Sprite2D

@export var variations: Array[TileMapLayer]
@export var foes: Array[PackedScene]
var foe_instances: Array[Foe] 
var traps: Array[Vector2i]
var rocks: Array[Vector2i]
var skulls: Array[Vector2i]
var stand: Vector2i
var chest: Vector2i

var doors : Array[Door]
var alt_doors: Array[Door]
var doors_dict: Dictionary[Vector2i, Door]
var is_key := false
var is_lock := false
var cell: Generator.Cell
var untested_doors : Array[Door]
var directions : Dictionary[Vector2i, int]
var spawn_position : Vector2i
var exit_position : Vector2i
var enemy_tiles: Array[Vector2i]

func init() -> void:
	var cells = get_used_cells()
	doors.clear()
	is_lock = false
	is_key = false
	
	for v in variations:
		v.set_visible(false)
		
	for c in cells:
		var td = get_cell_tile_data(c)
		var direction = td.get_custom_data("direction")
		if td.get_custom_data("lock"): is_lock = true
		if td.get_custom_data("key"): is_key = true
		if td.get_custom_data("spawn"): spawn_position = c
		if td.get_custom_data("exit"): exit_position = c
		if td.get_custom_data("enemy"): enemy_tiles.append(c)
		
		var chances = td.get_custom_data("randomized")
		if not chances: chances = 1.0
		var rand = randf()
		if td.get_custom_data("trap") and rand < chances: traps.append(c)
		if td.get_custom_data("rock") and rand < chances: rocks.append(c)
		if td.get_custom_data("skull") and rand < chances: skulls.append(c)
		if td.get_custom_data("spell_stand") and rand < chances: stand = c
		if td.get_custom_data("chest") and rand < chances: chest
		if td.get_custom_data("hazard") and rand < chances:
			if rand < 0.3: traps.append(c)
			elif rand < 0.6: rocks.append(c)
			else: skulls.append(c)
			
		if direction and direction != Vector2i.ZERO:
			var door = Door.new()
			door.position = c
			door.direction = direction
			if td.get_custom_data("alt_door"):
				alt_doors.append(door)
			else:
				doors.append(door)
				untested_doors.append(door)
				if not directions.has(door.direction): directions.set(door.direction, 0)
				directions[door.direction] += 1

func apply_variations():
	for v in variations:
		var required_doors = 0
		var required_walls = 0
		for c in v.get_used_cells():
			var td = v.get_cell_tile_data(c)
			var d = td.get_custom_data("direction")
			if d and d != Vector2i.ZERO:
				var target = get_cell_tile_data(c)
				if td.get_custom_data("alt_door"):
					required_walls += 1
					if target: required_walls -= 1
					td.set_custom_data("erase", true)
				else:
					v.erase_cell(c)
					required_doors += 1
					if not target: required_doors -= 1

		if not required_doors and not required_walls:
			#v.set_visible(true)
			apply_variation(v)
			
func apply_variation(v):
	for c in v.get_used_cells():
		var td = v.get_cell_tile_data(c)
		if td.get_custom_data("erase"):
			erase_cell(c)
			#v.erase_cell(c)
			background_layer.erase_cell(c)
		else:
			set_cell(c, v.get_cell_source_id(c), v.get_cell_atlas_coords(c))
				
func set_cell_sprite(cell_type):
	match cell_type:
		#CellType.Default: target_rooms = regular_rooms
		Generator.CellType.Entrance: entrance_sprite.set_visible(true)
		Generator.CellType.Exit: exit_sprite.set_visible(true)
		Generator.CellType.Key: key_sprite.set_visible(true)
		Generator.CellType.Lock: lock_sprite.set_visible(true)
		Generator.CellType.Reward: reward_sprite.set_visible(true)
		Generator.CellType.Enemy: monster_sprite.set_visible(true)

func get_door_position(door):
	return position + door.position

func get_unlinked_doors():
	return doors.filter(func(a): return not a.linked_room)

func get_linked_doors():
	return doors.filter(func(a): return a.linked_room)

func get_unlinked_doors_by_direction(direction):
	var ds: Array[Door]
	for d in doors:
		if d.linked: continue
		if d.direction == direction: ds.append(d)

	return ds

func get_doors_by_direction(direction):
	var ds: Array[Door]
	for d in doors:
		if d.direction == direction: ds.append(d)
	return ds

func close_door(door: Door):
	set_cell(door.position, 0, Vector2i.ZERO)
	
func hide_door(door: Door):
	erase_cell(door.position)
		
func close_unlinked_doors():
	get_unlinked_doors().map(func(d): close_door(d))

class Door:
	var direction: Vector2i
	var position: Vector2
	var linked_room: Room
	var linked_door: Door
	var linked = false
	var projection_rect: Rect2
	var untested_rooms: Array[String]
	
	func link_to(room: Room, door: Door):
		linked_room = room
		linked_door = door
		linked = true
		
	func unlink():
		if linked_door: linked_door.linked = false
		linked = false
		
	func _to_string() -> String:
		return str("Door ", position, " ", direction)
