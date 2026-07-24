extends Node2D
class_name Main

@export_category("Tilemaps")
@export var tileset: TileSet
@export var tile_map_layer: TileMapLayer
@export var foes_container: Node2D
@export var projectiles_container: Node2D


var foes: Array[Foe]
var projectiles: Array[Projectile]
var entities_dict: Dictionary[Vector2i, GridEntity]

@export_category("Player")
@export var player: Player
@export var spells: Array[SpellResource]
@export var count_down_length:= 6
@export var number_container: NumberContainer
var current_count_down_index := 0

var is_ticking := false

func _ready():
	entities_dict.set(player.pos, player)
	for f in foes_container.get_children():
		f = f as Foe
		if not f: 
			push_error(f, " is not a Foe !")
			continue
		foes.append(f)
		entities_dict.set(f.pos, f)
	
	number_container.build_countdown(count_down_length)
	number_container.update_countdown(current_count_down_index)
	number_container.update_available_spells(spells)
	number_container.spells_changed.connect(func():
		number_container.update_available_spells(spells)
	)

func _process(delta: float) -> void:
	if not is_ticking and not player.is_moving:
		if Input.is_action_pressed("MoveLeft"): move_entity(player, Vector2i.LEFT)
		if Input.is_action_pressed("MoveUp"): move_entity(player, Vector2i.UP)
		if Input.is_action_pressed("MoveRight"): move_entity(player, Vector2i.RIGHT)
		if Input.is_action_pressed("MoveDown"): move_entity(player, Vector2i.DOWN)
		
func move_entity(entity: GridEntity, dir: Vector2i)->bool:
	if not is_walkable(entity.pos + dir): return false;
	entities_dict.erase(entity.pos)
	entities_dict.set(entity.pos + dir, entity)
	await entity.move(dir)
	if entity is Player:
		number_container.close_spells()
		current_count_down_index = (current_count_down_index + 1) % count_down_length
		tick()
	return true
	
func remove_entity(entity: GridEntity):
	if entity is Foe:
		foes.erase(entity)
	entities_dict.erase(entity.pos)
	entity.queue_free()

func tick():
	is_ticking = true
	
	update_countdown()

	for p in projectiles: p.tick()
	
	print("Update proj")
	await update_projectiles()
	
	var next_spell = number_container.number_controls[(current_count_down_index + 1) % count_down_length].spell_resource
	player.spell_sprite.set_visible(!!next_spell)
	if next_spell:
		player.spell_sprite.texture = next_spell.texture
	
	var current_spell := number_container.number_controls[current_count_down_index].spell_resource
	if current_spell:
		print("Cast spell")

		cast_spell(current_spell, player)
		print("Update proj c")
		update_projectiles_collisions()
		
	print("Update foes")
	await update_foes()
	print("Update proj c 2")
	update_projectiles_collisions()
	
	var removed_ps : Array[Projectile]
	for p in projectiles.duplicate():
		if p.life <= 0:
			projectiles.erase(p)
			removed_ps.append(p)
	
	is_ticking = false
	
	await Utility.sleep(0.2)
	for p in removed_ps: if p: p.queue_free()
	

func update_foes():
	var moved = false
	for f in foes:
		if not f.will_move(): continue
		var distance = player.pos - f.pos
		var dir = Vector2i(sign(distance.x), sign(distance.y))
		if abs(distance.x) >= abs(distance.y): dir.y = 0
		else: dir.x = 0
		if is_walkable(f.pos + dir):
			move_entity(f, dir)
			moved = true
	if moved: await Utility.sleep(0.1)

func update_countdown():
	number_container.update_countdown(current_count_down_index)

func update_projectiles():
	for p in projectiles.duplicate():
		if p.direction != Vector2i.ZERO:
			var dir = p.direction
			print(p.move_per_turn)
			print("BEFORE")
			for i in p.move_per_turn:
				if not p: continue;
				print(i, " ", dir, " ", p.move_speed, " ", p.move_per_turn)
				await p.move(dir)
				print("AFTER")
				update_projectile_collision(p)
				print("AFTER")
			
	await Utility.sleep(0.1)
	#if projectiles.size(): await Utility.sleep(0.1)
	#update_projectiles_collisions()
	
func update_projectiles_collisions():
	for p in projectiles:
		update_projectile_collision(p)

func update_projectile_collision(p: Projectile):
	if not is_walkable(p.pos):
		var target_entity = entities_dict.get(p.pos)
		if target_entity and target_entity is Foe:
			target_entity.take_damage(p.damage)
			if not target_entity.is_alive():
				remove_entity(target_entity)
		projectiles.erase(p)
		p.queue_free()
	

func cast_spell(sr: SpellResource, caster: GridEntity):
	if not sr.spell_cast: return;
	var ps = get_projectiles(sr, caster)
	for p in ps:
		p.reparent(projectiles_container)
		p.position += player.global_position
		projectiles.append(p)
		
func get_projectiles(sr: SpellResource, caster: GridEntity)->Array[Projectile]:
	var ps : Array[Projectile]
	var sc = sr.spell_cast.instantiate() as SpellCast
	for p in sc.get_children():
		p = p as Projectile
		if not p: continue;
		if caster.direction != Vector2i.ZERO and sc.direction_oriented:
			p.position = p.position.rotated(atan2(caster.direction.y, caster.direction.x))
			p.direction = Vector2(p.direction).rotated(atan2(caster.direction.y, caster.direction.x))
			p.sprite_2d.rotation = atan2(p.direction.y, p.direction.x)
		ps.append(p)
	return ps

func is_walkable(pos: Vector2i)->bool:
	var cell = tile_map_layer.get_cell_tile_data(pos)
	if not cell: return false
	if entities_dict.has(pos): return false
	if pos == player.pos: return false
	return true
