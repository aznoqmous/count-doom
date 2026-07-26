extends Node2D
class_name Main

@export var credits: Control

@export_category("Tilemaps")
@export var tileset: TileSet
@export var tile_map_layer: TileMapLayer
@export var foes_container: Node2D
@export var projectiles_container: Node2D
@export var objects_container: Node2D
@export var generator: Generator

var foes: Array[Foe]
var active_foes: Array[Foe]:
	get(): return foes.filter(func(f): return f and f.is_active)
var projectiles: Array[Projectile]
var entities_dict: Dictionary[Vector2i, GridEntity]

@export_category("Player")
@export var player: Player
@export var spells: Array[SpellResource]
@export var count_down_length:= 6
@export var number_container: NumberContainer
@export var unlock_container: UnlockContainer

const SPELL_DISPLAY = preload("res://scenes/uis/spell_display.tscn")
@export var spells_display_container: Node2D

@export_category("Objects")
@export var skull_scene: PackedScene
@export var chest_scene: PackedScene
@export var spell_stand_scene: PackedScene
@export var stone_scene: PackedScene
@export var trap_scene: PackedScene
@export var exit_scene: PackedScene

var current_count_down_index := 0

var is_ticking := false
var additional_ticks := 0
var current_tick := 0

var current_room: Room

var astar_grid: AStarGrid2D
var foes_astar_grid: AStarGrid2D
var exit_position: Vector2i
@export var astar_debug_layer: TileMapLayer

@export_category("Levels")
@export var cell_containers: Array[CellsContainer]
var current_level_index = 0

func _ready():
	generator.set_visible(false)
	await generate_dungeon()
	
	number_container.build_countdown(count_down_length)
	number_container.update_countdown(current_count_down_index)
	number_container.update_available_spells(spells)
	
	number_container.paste(unlock_container.number_container)
	
	unlock_container.number_container.spells_changed.connect(func():
		unlock_container.number_container.update_available_spells(spells)
	)
	unlock_container.submitted.connect(func(): unlock_container.number_container.paste(number_container))
	
	if spells:
		unlock_container.number_container.update_available_spells(spells)
		unlock_container.set_visible(true)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Restart"): get_tree().reload_current_scene()
	#if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		#var target_pos = round(get_global_mouse_position() / Utility.tileset_size)
		#var path = astar_grid.get_point_path(player.pos, target_pos)
		#for p in path:
			#var dir = Vector2i(p) - player.pos
			#if dir != Vector2i.ZERO:
				#await move_entity(player, dir)
	pass
	
@export var path_layer: TileMapLayer
var target_cell: Vector2i
var target_path: PackedVector2Array
var is_astar_moving := false
func _process(delta: float) -> void:
	if unlock_container.is_visible(): return;
	if player.is_moving or is_astar_moving: return;
	
	var target_pos = Vector2i(round(get_global_mouse_position() / Utility.tileset_size))
	if target_pos != target_cell:
		for sd in spells_display_container.get_children(): sd.queue_free()
		target_cell = target_pos
		path_layer.clear()
		target_path = astar_grid.get_point_path(player.pos, target_pos)
		var nspells = number_container.get_spells()
		var has_active_foes = !!active_foes.size()
		var effective_length = 0
		for i in target_path.size():
			var p = target_path[i]
			effective_length = i
			if Vector2i(p) != player.pos and not is_walkable(p): break
			path_layer.set_cell(p, tile_map_layer.get_cell_source_id(p), tile_map_layer.get_cell_atlas_coords(p))
			if has_active_foes and i > 0:
				var sd = SPELL_DISPLAY.instantiate() as SpellDisplay
				spells_display_container.add_child(sd)
				sd.set_spell(nspells[(current_count_down_index + i)%count_down_length])
				sd.position = p * Utility.tileset_size
				sd.label.text = str(count_down_length - (current_count_down_index + i)%count_down_length)
		for f in foes:
			if f: f.update_exclamation_sprite(effective_length + 1)
			
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and target_path.size():
		for sd in spells_display_container.get_children(): sd.queue_free()
		path_layer.clear()
		is_astar_moving = true
		for p in target_path:
			var dir = Vector2i(p) - player.pos
			if dir != Vector2i.ZERO:
				if not await move_entity(player, dir): break
		is_astar_moving = false
	#if not is_ticking:
		#if Input.is_action_pressed("MoveLeft"): 
			#move_entity(player, Vector2i.LEFT)
			#return
		#if Input.is_action_pressed("MoveUp"): 
			#move_entity(player, Vector2i.UP)
			#return
		#if Input.is_action_pressed("MoveRight"): 
			#move_entity(player, Vector2i.RIGHT)
			#return
		#if Input.is_action_pressed("MoveDown"): 
			#move_entity(player, Vector2i.DOWN)
			#return

func generate_dungeon(index=0):
	generator.cells_container = cell_containers[index]
	
	tile_map_layer.clear()
	for f in foes: if f: f.queue_free()
	for p in projectiles: p.queue_free()
	for o in objects_container.get_children(): o.queue_free()
	entities_dict.clear()
	foes.clear()
	projectiles.clear()
	
	await generator.generate_rooms()
	for r in generator.final_rooms:
		for c in r.background_layer.get_used_cells():
			tile_map_layer.set_cell(c + Vector2i(r.position / Utility.tileset_size), r.background_layer.get_cell_source_id(c), Vector2i(1 if (c.x + c.y)%2 else 2, 0))
			
		for c in r.get_used_cells():
			if r.get_cell_tile_data(c).get_custom_data("wall"):
				tile_map_layer.set_cell(c + Vector2i(r.position / Utility.tileset_size), r.get_cell_source_id(c), r.get_cell_atlas_coords(c))
		
		if r == generator.entrance: continue
		r.foes.shuffle()
		var rfoes = r.foes.slice(0, r.max_foes) if r.max_foes > 0 else r.foes
		for f in rfoes:
			if not r.enemy_tiles.size(): break
			var new_foe = f.instantiate() as Foe
			r.enemy_tiles.shuffle()
			new_foe.position = r.enemy_tiles.pop_front() *  Utility.tileset_size + r.position
			foes_container.add_child(new_foe)
			r.foe_instances.append(new_foe)
	
	
	astar_grid = AStarGrid2D.new()
	astar_grid.cell_shape = AStarGrid2D.CELL_SHAPE_SQUARE
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.region = tile_map_layer.get_used_rect()
	astar_grid.update()
	foes_astar_grid = AStarGrid2D.new()
	foes_astar_grid.cell_shape = AStarGrid2D.CELL_SHAPE_SQUARE
	foes_astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	foes_astar_grid.region = tile_map_layer.get_used_rect()
	foes_astar_grid.update()
	
	for c in tile_map_layer.get_used_cells():
		if tile_map_layer.get_cell_tile_data(c).get_custom_data("wall"):
			## WALL
			tile_map_layer.set_cell(c, tile_map_layer.get_cell_source_id(c), Vector2i.ZERO)
			set_astar_point(c)
		else:
			## FLOOR
			tile_map_layer.set_cell(c, tile_map_layer.get_cell_source_id(c), Vector2i(1 if (c.x + c.y)%2 else 2, 0))
			set_astar_point(c, false)
	
	
	for r in generator.final_rooms:
		for t in r.traps:
			var obj = trap_scene.instantiate() as GridEntity
			objects_container.add_child(obj)
			obj.position = t * Utility.tileset_size + r.position
			entities_dict.set(t + Vector2i(r.position / Utility.tileset_size), obj)
			foes_astar_grid.set_point_solid(t + Vector2i(r.position / Utility.tileset_size))
		for t in r.rocks:
			var obj = stone_scene.instantiate() as GridEntity
			objects_container.add_child(obj)
			obj.position = t * Utility.tileset_size + r.position
			entities_dict.set(t + Vector2i(r.position / Utility.tileset_size), obj)
			set_astar_point(t + Vector2i(r.position / Utility.tileset_size))
		for t in r.skulls:
			var obj = skull_scene.instantiate() as LivingEntity
			objects_container.add_child(obj)
			obj.position = t * Utility.tileset_size + r.position
			entities_dict.set(t + Vector2i(r.position / Utility.tileset_size), obj)
			set_astar_point(t + Vector2i(r.position / Utility.tileset_size))
		if r.chest:
			var obj = chest_scene.instantiate() as ChestEntity
			objects_container.add_child(obj)
			obj.position = r.chest * Utility.tileset_size + r.position
			entities_dict.set(r.chest + Vector2i(r.position / Utility.tileset_size), obj)
			#set_astar_point(r.chest + Vector2i(r.position / Utility.tileset_size))
		if r.stand:
			var obj = spell_stand_scene.instantiate() as SpellStandEntity
			objects_container.add_child(obj)
			obj.position = r.stand * Utility.tileset_size + r.position
			entities_dict.set(r.stand + Vector2i(r.position / Utility.tileset_size), obj)
			#set_astar_point(r.stand + Vector2i(r.position / Utility.tileset_size))
			obj.on_interact.connect(func(player):
				spells.append(obj.spell_resource)
				unlock_container.number_container.update_available_spells(spells)
				unlock_container.set_visible(true)
			)
	
	player.position = generator.entrance.spawn_position * Utility.tileset_size
	for r in generator.final_rooms:
		if not r.exit_position: continue;
		exit_position = r.exit_position + Vector2i(r.position / Utility.tileset_size)
		var exit = exit_scene.instantiate() as GridEntity
		objects_container.add_child(exit)
		exit.position = exit_position * Utility.tileset_size
		entities_dict.set(exit_position, exit)
	
	entities_dict.set(player.pos, player)
	for f in foes_container.get_children():
		f = f as Foe
		if not f: 
			push_error(f, " is not a Foe !")
			continue
		foes.append(f)
		entities_dict.set(f.pos, f)

func set_astar_point(pos: Vector2i, is_solid:=true, is_foe:=true):
	astar_grid.set_point_solid(pos, is_solid)
	if is_foe: foes_astar_grid.set_point_solid(pos, is_solid)

func move_entity(entity: GridEntity, dir: Vector2i)->bool:
	if not is_walkable(entity.pos + dir): return false;
	if entity is not Player:
		entities_dict.erase(entity.pos)
		entities_dict.set(entity.pos + dir, entity)
		astar_grid.set_point_solid(entity.pos, false)
		astar_grid.set_point_solid(entity.pos + dir, true)
	await entity.move(dir)
	
	if entity is Player:
		if entities_dict.has(player.pos):
			var interactable = entities_dict.get(player.pos) as InteractableEntity
			if interactable: 
				interactable.trigger(player)
				if interactable.destroyed_on_interact:
					entities_dict.erase(interactable.pos)
					interactable.queue_free()
			
		if entity.pos == exit_position:
			current_level_index += 1
			if cell_containers.size() - 1 < current_level_index:
				tile_map_layer.clear()
				for f in foes: if f: f.queue_free()
				for p in projectiles: p.queue_free()
				for o in objects_container.get_children(): o.queue_free()
				entities_dict.clear()
				foes.clear()
				projectiles.clear()
				credits.set_visible(true)
				player.set_visible(false)
				number_container.set_visible(false)
			else: generate_dungeon(current_level_index)
			return false;
			
		var room = generator.get_room_at_position(Vector2i(player.position / Utility.tileset_size))
		if room and room != current_room:
			for f in room.foe_instances:
				if not f: continue
				f.is_active = true
			current_room = room
			if active_foes.size():
				close_room_doors(current_room)
				current_count_down_index = -2
		
		number_container.close_spells()
		
		if active_foes.size():
			await tick()
		else:
			update_projectiles()
			clear_projectiles()
			player.spell_sprite.set_visible(false)
		if not player.is_alive(): get_tree().reload_current_scene()
		
	return true
	
func remove_entity(entity: GridEntity):
	if entity is Foe:
		foes.erase(entity)
		if not active_foes.size(): open_room_doors(current_room)
		await Utility.sleep(0.5)
		entity.queue_free()
	else:
		entity.queue_free()
		
	set_astar_point(entity.pos, false)
	entities_dict.erase(entity.pos)
	
func tick():

	is_ticking = true
	current_count_down_index = (current_count_down_index + 1) % count_down_length
	update_countdown()

	await update_projectiles()
	
	var next_spell = number_container.number_controls[(current_count_down_index + 1) % count_down_length].spell_resource
	player.spell_sprite.set_visible(!!next_spell)
	if next_spell:
		player.spell_sprite.texture = next_spell.texture
	
	var current_spell := number_container.number_controls[current_count_down_index].spell_resource
	if current_spell:
		cast_spell(current_spell, player)

	update_projectiles_collisions()
	if current_tick >= additional_ticks: await update_foes()
	update_projectiles_collisions()
	
	for f in foes: if f: f.projectiles_whitelist.clear()
	
	clear_projectiles()
			
	is_ticking = false
	
func clear_projectiles():
	var removed_ps : Array[Projectile]
	for p in projectiles.duplicate():
		if p.life <= 0 or not active_foes.size():
			projectiles.erase(p)
			removed_ps.append(p)
	for p in removed_ps:
		if not p: continue
		if p.free_after_animation:
			p.animation_player.animation_finished.connect(func(): p.queue_free())
		elif p.free_after_sec:
			get_tree().create_timer(p.free_after_sec).timeout.connect(p.queue_free)
		else: p.queue_free()
	
	if current_tick < additional_ticks:
		current_tick += 1
		tick()
	else:
		additional_ticks = 0
		current_tick = 0
		
func update_foes():
	var moved = false
	for f in active_foes:
		f.is_active = true
		var distance = player.pos - f.pos
		if distance.length() <= 1.0: player.take_damage(1)
		if not f.will_move(): continue
		var path = foes_astar_grid.get_point_path(f.pos, player.pos, true)
		if not path.size() > 1: continue;
		distance = Vector2i(path[1]) - f.pos
		var dir = distance
		if is_walkable(f.pos + dir):
			move_entity(f, dir)
			moved = true
			
	if moved: await Utility.sleep(0.1)

func update_countdown():
	number_container.update_countdown(current_count_down_index)

func update_projectiles():
	for p in projectiles: p.tick()
	for p in projectiles.duplicate():
		move_projectile(p)
	await Utility.sleep(0.1)
			
func move_projectile(p: Projectile):
	if p.direction != Vector2i.ZERO:
		var dir = p.direction
		for i in p.move_per_turn:
			update_projectile_collision(p)
			if not p.life: break;
			await p.move(dir)
		update_projectile_collision(p)
	
func update_projectiles_collisions():
	for p in projectiles:
		update_projectile_collision(p)

func update_projectile_collision(p: Projectile):
	if not is_walkable(p.pos):
		var target_entity = entities_dict.get(p.pos)
		if target_entity and target_entity is Foe:
			if target_entity.projectiles_whitelist.has(p): return
			target_entity.projectiles_whitelist.append(p)
			target_entity.take_damage(p.damage)
			if not target_entity.is_alive():
				remove_entity(target_entity)
		p.life = 0
	

func cast_spell(sr: SpellResource, caster: GridEntity):
	if not sr.spell_cast: return;
	var ps = get_projectiles(sr, caster)
	for p in ps:
		p.reparent(projectiles_container)
		p.position += player.global_position
		projectiles.append(p)
		move_projectile(p)
	await Utility.sleep(0.1)
		
func get_projectiles(sr: SpellResource, caster: GridEntity)->Array[Projectile]:
	var ps : Array[Projectile]
	var sc = sr.spell_cast.instantiate() as SpellCast
	for p in sc.get_children():
		p = p as Projectile
		if not p: continue;
		if caster.direction != Vector2i.ZERO:
			var casted_direction = Vector2(p.direction)
			if sc.direction_oriented:
				p.position = p.position.rotated(atan2(caster.direction.y, caster.direction.x))
				casted_direction = casted_direction.rotated(atan2(caster.direction.y, caster.direction.x))
			if p.position_oriented: casted_direction = casted_direction.rotated(p.position.angle())
			p.direction = round(casted_direction)
			p.sprites_container.rotation = atan2(p.direction.y, p.direction.x)
		ps.append(p)
	return ps
	
func close_room_doors(room:Room):
	for d in room.doors.filter(func(d): return d.linked):
		set_wall(Vector2i(d.position) + Vector2i(room.position / Utility.tileset_size))

func open_room_doors(room:Room):
	for d in room.doors.filter(func(d): return d.linked):
		set_floor(Vector2i(d.position) + Vector2i(room.position / Utility.tileset_size))

func set_wall(pos: Vector2i):
	tile_map_layer.set_cell(pos, 0, Vector2i.ZERO)
	set_astar_point(pos)
		
func set_floor(pos: Vector2i):
	tile_map_layer.set_cell(pos, 0, Vector2i(1 if (pos.x + pos.y)%2 else 2, 0))
	set_astar_point(pos, false)
	
func is_walkable(pos: Vector2i)->bool:
	var cell = tile_map_layer.get_cell_tile_data(pos)
	if not cell: return false
	if cell.get_custom_data("wall"): return false
	if entities_dict.get(pos) and not entities_dict.get(pos).walkable: return false
	if pos == player.pos: return false
	return true
