@tool
extends Node2D
class_name Generator

@export_category("Generation Settings")
@export var level_length: int
@export var branches_count: int
@export var min_branch_length: int
@export var max_branch_length: int
@export var foe_gain := 1.0
@export var foe_increment := 0.1
@export var cell_size := 32.0
@export var seed: String
@export var is_seeded:= false
@export_tool_button("Generate cells") var generate_btn = generate_cells
@export_tool_button("Generate rooms") var generate_rooms_btn = generate_rooms
@export_tool_button("Next step") var next_step_btn = func():
	wait_for_next_step = false

var wait_for_next_step = true

@export_tool_button("Bruteforce generate") var generate_brute_force = func():
	var time = 0.0
	var iterations = 10.0
	var start
	for i in iterations:
		#rooms_container.modulate = Color.BLACK
		start = Time.get_ticks_msec()
		if await generate_rooms():
			#pass
			#rooms_container.modulate = Color.WHITE
			print("SUCCESS AFTER ", i, " TRIES")
		time += Time.get_ticks_msec() - start
		
		await get_tree().process_frame
	print(time / iterations / 1000.0, " avg sec over ", iterations, " iterations")

@export_category("Nodes")
@export var cells_container: CellsContainer
@export var rooms_container: Node2D
@export var seed_label: Label


@export_category("Cells")
@export var cell_snap_size := 40.0
const CELL = preload("res://scenes/pcg/cell.tscn")

@export var entrance_sprite: CompressedTexture2D
@export var exit_sprite: CompressedTexture2D
@export var key_sprite: CompressedTexture2D
@export var lock_sprite: CompressedTexture2D
@export var portal_sprite: CompressedTexture2D
@export var reward_sprite: CompressedTexture2D
@export var foe_sprite: CompressedTexture2D

var cells: Array[Cell]

@export_category("Rooms")
@export var entrance_rooms: Array[PackedScene]
var regular_rooms: Array[Room]
var rooms: Array[Room]
var final_rooms: Array[Room]
var entrance : Room
var used_rects: Dictionary[Room, Rect2i]
var rooms_dict: Dictionary[String, Room]
var rooms_by_type_dict: Dictionary[CellType, Array]

var current_direction: Vector2i

var random_number_generator: RandomNumberGenerator

func _ready():
	cells_container.child_entered_tree.connect(func(cell: CellNode):
		cell.changed.connect(generate_cells)
	)
	for cell in cells_container.get_children():
		cell = cell as CellNode
		if not cell: continue
		cell.changed.connect(generate_cells)

#func _process(delta) -> void:
	#if Input.is_action_just_pressed("ui_down"):
		#wait_for_next_step = false
		#position.y -= 1

var current_room_draw: Room
var current_door_draw: Room.Door
func _draw():
	if current_room_draw:
		var rect = get_room_rect(current_room_draw)
		rect.position *= cell_size
		rect.size *= cell_size
		draw_rect(rect, Color.BLUE, true)
		#for door in current_room_draw.untested_doors:
			#rect = door.projection_rect
			#rect.position *= cell_size
			#rect.size *= cell_size
			#draw_rect(rect, Color.GREEN if is_available_rect(door.projection_rect) else Color.RED, true)
			
	if current_door_draw:
		var rect = current_door_draw.projection_rect
		rect.position *= cell_size
		rect.size *= cell_size
		draw_rect(rect, Color.GREEN if is_available_rect(current_door_draw.projection_rect) else Color.RED, true)
	return;
	
	#for r in used_rects.values():
		#var rect = r
		#rect.position = Vector2i(rect.position * cell_size)
		#rect.size = Vector2i(rect.size * cell_size)
		#draw_rect(rect, Color.WHITE, false, 5)
	#
	#for r in final_rooms:
		#var rect = get_room_rect(r)
		#rect.position *= cell_size
		#rect.size *= cell_size
		#draw_rect(rect, Color.WHITE, true)
		#for door in r.doors:
			#rect = door.projection_rect
			#rect.position *= cell_size
			#rect.size *= cell_size
			#draw_rect(rect, Color.GREEN if is_available_rect(door.projection_rect) else Color.RED, true)
		
func init_generator():
	random_number_generator = RandomNumberGenerator.new()
	
	if is_seeded:
		random_number_generator.seed = hash(seed)
	else:
		seed = str(randi_range(100000, 999999))
	seed_label.text = str("Seed : ", seed)
	random_number_generator.seed = hash(seed)
	
func generate_rooms():
	generate_cells()
	print("Generate rooms with seed: ", seed)
	
	## Reset
	var start = Time.get_ticks_msec()
	var it = 0
		
	#return;
	## Entrance
	var current_cell := cells[0]
	entrance = init_room(pick_random(entrance_rooms).instantiate() as Room, current_cell)
	update_door_projection_rects(entrance)
	var current_room := entrance
	var current_door = pick_random(entrance.get_unlinked_doors())
	current_cell = current_cell.next
	used_rects.set(entrance, get_room_rect(entrance))
	
	var pending_cells: Array[Cell]
	var last_skip_time = Time.get_ticks_msec()
	
	while current_cell:
		it+=1
		#if Time.get_ticks_msec() - last_skip_time > 10.0:
			#last_skip_time = Time.get_ticks_msec()
			#await get_tree().process_frame
		if not current_cell.parent:
			print(current_cell)
		current_room = current_cell.parent.room
		
		#current_room_draw = current_room
		#queue_redraw()
		
		if it > 10000:
			print("Failed attempt")
			return false

		
		## BACK PROPAGATION
		current_room.untested_doors = current_room.untested_doors.filter(func(a): return is_available_rect(a.projection_rect))
		if not current_room.untested_doors.size():
			await get_tree().process_frame
			#await get_tree().create_timer(0.1).timeout
			var rm_cells = [current_cell.parent]
			while rm_cells:
				var cell = rm_cells.pop_front()
				if cell.room:
					if cell.room.is_unique:
						regular_rooms.append(rooms_dict[cell.room.str_id])
						rooms.append(rooms_dict[cell.room.str_id])
					final_rooms.erase(cell.room)
					used_rects.erase(cell.room)
					cell.room.queue_free()
				pending_cells.erase(cell)
				if cell.next: rm_cells.append(cell.next)
				if cell.branch: rm_cells.append(cell.branch)
			current_cell = current_cell.parent
			continue
		
		
		current_door = pick_random(current_room.untested_doors)
		
		if current_cell.parent and current_door.untested_rooms.size() > 1:
			current_door.untested_rooms.erase(current_cell.parent.room.str_id)
		#print(target_rooms)

		var target_rooms = rooms_by_type_dict[current_cell.type]
		target_rooms = target_rooms.filter(func(a): return not a.is_required or current_cell.required_rooms.has(a.str_id))
		target_rooms = target_rooms.filter(func(a): return current_cell.allowed_rooms.has(a.str_id))
		target_rooms = target_rooms.filter(func(a): return a.doors.size() >= current_cell.doors_count and (a.min_doors <= 0 or a.min_doors <= current_cell.doors_count))
		target_rooms = target_rooms.filter(func(a): return a.get_doors_by_direction(-current_door.direction).size() > 0)
		target_rooms = target_rooms.filter(func(a): return current_door.untested_rooms.has(a.str_id))
		target_rooms = shuffle(target_rooms)
		
		target_rooms.sort_custom(func(a,b): return a.priority > b.priority)
		
		
		var picked_room = null
		if current_cell.parent and rooms_dict.has(current_cell.parent.room.str_id) and current_cell.required_rooms.has(current_cell.parent.room.str_id):
			target_rooms.append(rooms_dict[current_cell.parent.room.str_id])
		
		for tr in target_rooms:
			current_door.untested_rooms.erase(tr.str_id)
			var nroom = init_room(tr.duplicate(), current_cell)
			nroom.str_id = tr.str_id # lost in duplicate ??
			var doors = nroom.get_unlinked_doors_by_direction(-current_door.direction)
			#doors.shuffle()
			doors = shuffle(doors)
			
			for ndoor in doors:
				if current_cell.allowed_directions.size() > 0 and not current_cell.allowed_directions.has(ndoor.direction): continue
				
				current_door.link_to(nroom, ndoor)
				ndoor.link_to(current_room, current_door)
				nroom.position = current_door.position * cell_size - ndoor.position * cell_size + current_room.position
				var rect = get_room_rect(nroom)
				if not is_available_rect(rect):
					current_door.unlink()
					continue
					
				used_rects.set(nroom, rect)
				picked_room = nroom
				nroom.label.text = str(final_rooms.size())
				nroom.label.text = str(current_cell.cell_node.name)
				if tr.is_unique: regular_rooms.erase(tr)
				if tr.is_unique: rooms.erase(tr)
				break
				
			if picked_room:
				current_direction = current_door.direction
				break
			else:
				final_rooms.erase(nroom)
				nroom.queue_free()
				
		if not picked_room:
			current_room.untested_doors.erase(current_door)
			continue
		
		#await get_tree().process_frame
		#await get_tree().create_timer(0.1).timeout
		
		picked_room.state_sprite_container.modulate = current_cell.cell_node.modulate
		current_cell.room = picked_room
		update_door_projection_rects(picked_room)

		## Move forward
		if current_cell.next: pending_cells.append(current_cell.next)
		if current_cell.branch: pending_cells.append(current_cell.branch)
		current_cell = pending_cells.pop_front()
		
	for c in cells:
		c.room.modulate = Color.WHITE if c.y == 0 else Color.GRAY

	await update_doors()
	apply_variations()
	
	print(it, " iterations - ", final_rooms.size(), "/", cells.size()," rooms")
	print((Time.get_ticks_msec() - start) / 1000.0, "s")
	
	return final_rooms.size() == cells.size()

func apply_variations():
	for r in final_rooms:
		r.apply_variations()

func update_doors():
	current_room_draw = null
	current_door_draw = null
	
	var it = 0
	for r in final_rooms:

		var doors = r.doors
		doors.append_array(r.alt_doors)
		#current_room_draw = r
		for d in doors:
			it += 1
			if not it % 100: await get_tree().process_frame
			#await get_tree().create_timer(0.1).timeout
			d.projection_rect = get_door_projection_rect(d, r.position, 0, Vector2.ONE)
			#current_door_draw = d
			var dpos = Vector2i(d.position + r.position / cell_size) + d.direction * Vector2i(1, -1)
			var target_room = get_room_at_position(dpos)
			if target_room and target_room != r:
				if target_room.cell != r.cell.next and target_room.cell != r.cell.parent and target_room.cell != r.cell.branch:
					r.close_door(d)
				else:
					var local_pos = (r.position - target_room.position) / cell_size + d.position
					if not target_room.get_cell_tile_data(local_pos): r.close_door(d)
			else:
				r.close_door(d)
			queue_redraw()
	
	for r in final_rooms:
		for d in r.doors:
			if r.get_cell_tile_data(d.position).get_custom_data("direction"): r.hide_door(d)
	

func remove_room(room: Room):
	var rect = get_room_rect(room)
	used_rects.erase(room)
	final_rooms.erase(room)
	room.cell.room = null
	room.queue_free()
	
func init_room(room : Room, cell)->Room:
	rooms_container.add_child(room)
	final_rooms.append(room)
	room.cell = cell
	cell.room = room
	room.init()
	room.set_visible(true)
	room.set_cell_sprite(cell.type)
	for d in room.doors:
		d.untested_rooms = rooms_dict.keys()
	return room
	
func get_rooms_by_type(type):
	var target_rooms = rooms
	match type:
		CellType.Default: target_rooms = regular_rooms
		CellType.Entrance: target_rooms = [entrance]
		CellType.Exit: target_rooms = regular_rooms
		CellType.Key: target_rooms = rooms.filter(func(a: Room): return a.is_key)
		CellType.Lock: target_rooms = rooms.filter(func(a: Room): return a.is_lock)
		CellType.Portal: target_rooms = regular_rooms
		CellType.Reward: target_rooms = regular_rooms
		CellType.Enemy: target_rooms = regular_rooms
	return target_rooms

func update_door_projection_rects(room):
	for d in room.doors:
		d.projection_rect = get_door_projection_rect(d, room.position, room.cell.branch_length - room.cell.branch_index)

@export_category("Projection")
@export var projection_size := 10.0
@export var projection_size_per_rooms_left := 5.0
@export var max_projection_size := 20.0
@export var is_raycast_projection := false
func get_door_projection_rect(door, room_position, rooms_left, forced_size=null):
	var rect = Rect2()
	if forced_size: rect.size = forced_size
	else: 
		rect.size = Vector2.ONE * min(projection_size + projection_size_per_rooms_left * rooms_left, max_projection_size) * (Vector2.ONE + abs(Vector2(door.direction)))
		if is_raycast_projection: rect.size = Vector2(pow(rect.size.x, abs(door.direction.x)), pow(rect.size.y, abs(door.direction.y)))
	rect.position = -rect.size / 2.0 + rect.size / 2.0 * Vector2(door.direction * Vector2i(1, -1)) + door.position + room_position / cell_size
	if door.direction == Vector2i.RIGHT: rect.position.x += 1
	if door.direction == Vector2i.UP: rect.position.y += 1
	return rect
	
func get_room_rect(room):
	var rect = Rect2(room.get_used_rect())
	rect.position = room.position / cell_size + Vector2.ONE
	rect.size = rect.size - Vector2.ONE * 2.0
	return rect

func is_available_rect(rect):
	for room in used_rects.keys():
		if used_rects[room].intersects(rect):
			return false
	return true
	
func get_room_at_position(position):
	var rect : Rect2i
	rect.position = position
	rect.size = Vector2i.ONE
	for room in used_rects.keys():
		if used_rects[room].intersects(rect):
			return room
	return null

func generate_cells():
	init_generator()
	cells.clear()
	var cells_left : Array[CellNode]
	cells_left.append(cells_container.get_child(0))
	
	## POSITION BASED CELL GENERATION
	var offset = cells_container.get_child(0).position
	var cells_dict : Dictionary[Vector2, CellNode]
	for c in cells_container.get_children():
		c.parent = null
		c.next = null
		c.branch = null
		var cpos = (c.position - offset) / cell_snap_size
		cells_dict.set(cpos, c)
	
	var positions = cells_dict.keys()
	positions.sort_custom(func(a, b): return a.x < b.x if a.x != b.x else a.y < b.y)
	for pos in positions:
		var cell = cells_dict[pos]
		var next = pos + Vector2.RIGHT
		var branch = pos + Vector2.DOWN
		if cells_dict.has(next) and pos.y == 0.0: cell.next = cells_dict[next]
		if cells_dict.has(branch): cell.branch = cells_dict[branch]
	
	var current_repeat = 0
	
	while cells_left.size() > 0:
		
		var cell_node = cells_left.pop_front()
		if not cell_node.cell: cell_node.cell = Cell.new()
		var cell = cell_node.cell

		cell.cell_node = cell_node
		cells.append(cell)
		cell_node.name = str("Cell ", cells.size())
		cell.type = cell_node.cell_type
		cell.required_rooms = cell_node.required_rooms.map(func(a): return a.resource_path)

		for direction in cell_node.allowed_directions:
			match direction:
				CellNode.Directions.Left: cell.allowed_directions.append(Vector2i.LEFT)
				CellNode.Directions.Right: cell.allowed_directions.append(Vector2i.RIGHT)
				CellNode.Directions.Top: cell.allowed_directions.append(Vector2i.UP)
				CellNode.Directions.Bottom: cell.allowed_directions.append(Vector2i.DOWN)
		
		
		if cell_node.repeat > 1 and current_repeat == 0:
			current_repeat = cell_node.repeat
			
		if current_repeat:
			current_repeat -= 1
			
			if current_repeat:
				if cell_node.next:
					cell_node.next.cell = Cell.new()
					cell.next = cell_node.next.cell
					cell.next.parent = cell
					cell_node.cell = cell_node.next.cell
					cells_left.push_front(cell_node)
					
				if cell_node.branch:
					cell_node.branch.cell = Cell.new()
					cell.branch = cell_node.branch.cell
					cell.branch.parent = cell
					cell_node.cell = cell_node.branch.cell
					cells_left.push_front(cell_node)
				
				continue
			
		
		## Move Forward
		if cell_node.next:
			cell_node.next.cell = Cell.new()
			cell.next = cell_node.next.cell
			cell.next.parent = cell
			cells_left.append(cell_node.next)
			
		if cell_node.branch:
			cell_node.branch.cell = Cell.new()
			cell.branch = cell_node.branch.cell
			cell.branch.parent = cell
			cells_left.append(cell_node.branch)	
	
	
	for i in cells.size():
		cells[i].cell_node.name = str("Cell ", i)
		
	for c in cells:
		c.doors_count = c.get_doors_count()
		
	print(cells.size(), "/", cells_container.get_child_count())
	
	## INIT ROOMS
	regular_rooms.clear()
	final_rooms.clear()
	rooms.clear()
	used_rects.clear()
	rooms_dict.clear()
		
	for c in rooms_container.get_children(): c.queue_free()
	
	for r in cells_container.packed_rooms:
		var new_room = r.instantiate() as Room
		rooms_container.add_child(new_room)
		rooms.append(new_room)
		new_room.str_id = r.resource_path
		rooms_dict.set(new_room.str_id, new_room)
		new_room.init()
		new_room.set_visible(false)

	regular_rooms = rooms.filter(func(a): return not a.is_key and not a.is_lock)
	for type in CellType.values():
		rooms_by_type_dict.set(type, get_rooms_by_type(type))
	
	
	for cell in cells:
		var next_cell = cell.next
		var branch_cell = cell.branch
		var prev_cell = cell.parent
		var allowed_rooms : Array[Room]
		
		if cell.allowed_directions.size():
			allowed_rooms = rooms.filter(func(a): return cell.allowed_directions.find_custom(func(b): return not a.directions.has(b)))
		else:
			allowed_rooms = rooms
		if next_cell and next_cell.allowed_directions.size():
			allowed_rooms = allowed_rooms.filter(func(a): return next_cell.allowed_directions.find_custom(func(b): return not a.directions.has(b)))
		if branch_cell and branch_cell.allowed_directions.size():
			allowed_rooms = allowed_rooms.filter(func(a): return branch_cell.allowed_directions.find_custom(func(b): return not a.directions.has(b)))
		cell.allowed_rooms = allowed_rooms.map(func(a): return a.str_id)
		
		if cell.required_rooms.size():
			cell.allowed_rooms = cell.allowed_rooms.filter(func(a): return cell.required_rooms.has(a))
		cell.cell_node.generation_state_sprite.modulate = Color.from_hsv(float(cell.allowed_rooms.size()) / float(rooms.size()) * 0.3 - (0.05 if cell.branch and cell.next else 0.0), 0.7, 0.7)
			
func push_cells(last_cell, count, is_branch:= false):
	for i in count:
		var curr_cell := Cell.new()
		if is_branch: last_cell.branch = curr_cell
		else: last_cell.next = curr_cell
		curr_cell.parent = last_cell
		cells.append(curr_cell)
		last_cell = curr_cell
		curr_cell.branch_length = count
		curr_cell.branch_index = i
	return last_cell

func get_leaf(cell):
	while cell.branch:
		cell = cell.branch
	return cell

func get_stem(cell):
	while cell.parent and cell.parent.branch == cell:
		cell = cell.parent
	return cell

enum CellType {
	Default,
	Entrance,
	Exit,
	Key,
	Lock,
	Portal,
	Reward,
	Enemy
}

class Cell:
	var parent: Cell:
		set(value):
			parent = value
			x = parent.x
			y = parent.y
			if parent.next == self:
				x = parent.x + 1
			else:
				y = parent.y + 1
			
	var next: Cell
	var branch: Cell
	var cell_node: CellNode
	var x := 0
	var y := 0
	var type: CellType
	var room: Room
	var current_doors_count := 0
	var doors_count := 0
	var branch_length := 0
	var branch_index := 0
	var allowed_directions: Array[Vector2i]
	var allowed_rooms
	var required_rooms
	
	func get_doors_count():
		var doors = 1
		if type != CellType.Entrance:
			if branch: doors += 1
			if next: doors += 1
		return doors
		
	func _to_string() -> String:
		return str("Cell ", x, " ", y)
		
	func set_texture(tex):
		cell_node.sprite.texture = tex

func pick_random(array: Array):
	return array[random_number_generator.randi_range(0, array.size()-1)]

func shuffle(array: Array):
	for i in array.size() - 2:
		var j := random_number_generator.randi_range(i, array.size() - 1)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp
	return array
