extends Control

@onready var slot_scene = preload("res://Slot.tscn")
@onready var item_scene = preload("res://Item.tscn")

@onready var grid_container = $Inventory/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var scroll_container = $Inventory/MarginContainer/VBoxContainer/ScrollContainer
@onready var col_count = grid_container.columns # save column number

@onready var grid_container_chest = $Chest/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var scroll_container_chest = $Chest/MarginContainer/VBoxContainer/ScrollContainer
@onready var col_count_chest = grid_container_chest.columns # save column number

var grid_array := []
var grid_array_chest := []

var item_held = null
var current_slot = null
var can_place := false
var icon_anchor : Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(16):
		create_slot()
		create_slot_chest()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if item_held:
		if Input.is_action_just_pressed("mouse_rightclick"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				rotate_item()
			elif scroll_container_chest.get_global_rect().has_point(get_global_mouse_position()):
				rotate_item_chest()
		
		if Input.is_action_just_pressed("mouse_leftclick"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				place_item()
			elif scroll_container_chest.get_global_rect().has_point(get_global_mouse_position()):
				place_item_chest()
			
	else:
		if Input.is_action_just_pressed("mouse_leftclick"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				pick_item()
			elif scroll_container_chest.get_global_rect().has_point(get_global_mouse_position()):
				pick_item_chest()
	
	
func create_slot():
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()
	grid_container.add_child(new_slot)
	grid_array.push_back(new_slot)
	new_slot.slot_entered.connect(_on_slot_mouse_entered)
	new_slot.slot_exited.connect(_on_slot_mouse_exited)
	pass

func create_slot_chest():
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array_chest.size()
	grid_container_chest.add_child(new_slot)
	grid_array_chest.push_back(new_slot)
	new_slot.slot_entered.connect(_on_slot_mouse_entered_chest)
	new_slot.slot_exited.connect(_on_slot_mouse_exited_chest)
	pass

func _on_slot_mouse_entered(a_Slot):
	icon_anchor = Vector2(10000,100000)
	current_slot = a_Slot
	if item_held:
		check_slot_availability(current_slot)
		set_grids.call_deferred(current_slot)
		
func _on_slot_mouse_entered_chest(a_Slot):
	icon_anchor = Vector2(10000,100000)
	current_slot = a_Slot
	if item_held:
		check_slot_availability_chest(current_slot)
		set_grids_chest.call_deferred(current_slot)
	
func _on_slot_mouse_exited(a_Slot):
	clear_grid()
	
	if not grid_container.get_global_rect().has_point(get_global_mouse_position()):
		current_slot = null

func _on_slot_mouse_exited_chest(a_Slot):
	clear_grid_chest()
	
	if not grid_container_chest.get_global_rect().has_point(get_global_mouse_position()):
		current_slot = null

func _on_button_spawn_pressed():
	var new_item = item_scene.instantiate()
	add_child(new_item)
	new_item.load_item(randi_range(1,4))    # Randomize this for different items to spawn
	new_item.selected = true
	item_held = new_item

func _on_loot_button_pressed():
	var item_held = item_scene.instantiate()
	add_child(item_held)
	item_held.load_item(randi_range(1, 4))  # Randomize this for different items to spawn
	item_held.selected = true
	
	# Définir les dimensions de la grille
	var grid_width = 4  # Nombre de colonnes dans la grille
	var grid_height = 4  # Nombre de lignes dans la grille

	# Calculer l'ID de la grille en utilisant des coordonnées flottantes
	var calculated_grid_id = (6 + int(icon_anchor.x) * grid_width + int(icon_anchor.y)) % (grid_width * grid_height)
	
	# Vérifiez si calculated_grid_id est dans les limites du tableau
	if calculated_grid_id >= 0 and calculated_grid_id < grid_array_chest.size():
		item_held._snap_to(grid_array_chest[calculated_grid_id].global_position)
		item_held.grid_anchor = grid_array_chest[calculated_grid_id]
	else:
		print("calculated_grid_id out of bounds:", calculated_grid_id)
		item_held.queue_free()  # Détruire l'objet s'il est hors des limites
		return
	
	for grid in item_held.item_grids:
		# Calculer l'ID de la grille pour chaque élément de la grille en utilisant des coordonnées flottantes
		var grid_to_check = (6 + int(grid[0] + icon_anchor.x) + int(grid[1] + icon_anchor.y) * grid_width) % (grid_width * grid_height)
		
	# Vérifiez si grid_to_check est dans les limites du tableau
		if grid_to_check >= 0 and grid_to_check < grid_array_chest.size():
			grid_array_chest[grid_to_check].state = grid_array_chest[grid_to_check].States.TAKEN 
			grid_array_chest[grid_to_check].item_stored = item_held
		else:
			print("grid_to_check out of bounds:", grid_to_check)
			item_held.queue_free()  # Détruire l'objet s'il est hors des limites
			return
	
	grid_container_chest.add_child(item_held)
	clear_grid_chest()

func check_slot_availability(a_Slot):
	for grid in item_held.item_grids:
		var grid_to_check = a_Slot.slot_ID + grid[0] + grid[1] * col_count
		var line_switch_check = a_Slot.slot_ID % col_count + grid[0]
		if line_switch_check < 0 or line_switch_check >= col_count:
			can_place = false
			return
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			can_place = false
			return
		if grid_array[grid_to_check].state == grid_array[grid_to_check].States.TAKEN:
			can_place = false
			return
		
	can_place = true
	
func check_slot_availability_chest(a_Slot):
	for grid in item_held.item_grids:
		var grid_to_check = a_Slot.slot_ID + grid[0] + grid[1] * col_count_chest
		var line_switch_check = a_Slot.slot_ID % col_count_chest + grid[0]
		if line_switch_check < 0 or line_switch_check >= col_count_chest:
			can_place = false
			return
		if grid_to_check < 0 or grid_to_check >= grid_array_chest.size():
			can_place = false
			return
		if grid_array_chest[grid_to_check].state == grid_array_chest[grid_to_check].States.TAKEN:
			can_place = false
			return
		
	can_place = true
	
func set_grids(a_Slot):
	for grid in item_held.item_grids:
		var grid_to_check = a_Slot.slot_ID + grid[0] + grid[1] * col_count
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			continue
		#make sure the check don't wrap around boarders
		var line_switch_check = a_Slot.slot_ID % col_count + grid[0]
		if line_switch_check <0 or line_switch_check >= col_count:
			continue
		
		if can_place:
			grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.FREE)
			#save anchor for snapping
			if grid[1] < icon_anchor.x: icon_anchor.x = grid[1]
			if grid[0] < icon_anchor.y: icon_anchor.y = grid[0]
				
		else:
			grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.TAKEN)

func set_grids_chest(a_Slot):
	for grid in item_held.item_grids:
		var grid_to_check = a_Slot.slot_ID + grid[0] + grid[1] * col_count_chest
		if grid_to_check < 0 or grid_to_check >= grid_array_chest.size():
			continue
		#make sure the check don't wrap around boarders
		var line_switch_check = a_Slot.slot_ID % col_count_chest + grid[0]
		if line_switch_check <0 or line_switch_check >= col_count_chest:
			continue
		
		if can_place:
			grid_array_chest[grid_to_check].set_color(grid_array_chest[grid_to_check].States.FREE)
			#save anchor for snapping
			if grid[1] < icon_anchor.x: icon_anchor.x = grid[1]
			if grid[0] < icon_anchor.y: icon_anchor.y = grid[0]
				
		else:
			grid_array_chest[grid_to_check].set_color(grid_array_chest[grid_to_check].States.TAKEN)

func clear_grid():
	for grid in grid_array:
		grid.set_color(grid.States.DEFAULT)
		
func clear_grid_chest():
	for grid in grid_array_chest:
		grid.set_color(grid.States.DEFAULT)

func rotate_item():
	item_held.rotate_item()
	clear_grid()
	if current_slot:
		_on_slot_mouse_entered(current_slot)
		
func rotate_item_chest():
	item_held.rotate_item()
	clear_grid_chest()
	if current_slot:
		_on_slot_mouse_entered_chest(current_slot)

func place_item():
	if not can_place or not current_slot: 
		return #put indication of placement failed, sound or visual here
		
	#for changing scene tree
	item_held.get_parent().remove_child(item_held)
	grid_container.add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	####
	var calculated_grid_id = current_slot.slot_ID + icon_anchor.x * col_count + icon_anchor.y
	item_held._snap_to(grid_array[calculated_grid_id].global_position)
	print(calculated_grid_id)
	item_held.grid_anchor = current_slot
	for grid in item_held.item_grids:
		var grid_to_check = current_slot.slot_ID + grid[0] + grid[1] * col_count
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.TAKEN 
		grid_array[grid_to_check].item_stored = item_held
	
	#put item into a data storage here
	
	item_held = null
	clear_grid()

func place_item_chest():
	if not can_place or not current_slot: 
		return #put indication of placement failed, sound or visual here
		
	#for changing scene tree
	item_held.get_parent().remove_child(item_held)
	grid_container_chest.add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	####
	var calculated_grid_id = current_slot.slot_ID + icon_anchor.x * col_count_chest + icon_anchor.y
	item_held._snap_to(grid_array_chest[calculated_grid_id].global_position)
	print(calculated_grid_id)
	item_held.grid_anchor = current_slot
	for grid in item_held.item_grids:
		var grid_to_check = current_slot.slot_ID + grid[0] + grid[1] * col_count_chest
		grid_array_chest[grid_to_check].state = grid_array_chest[grid_to_check].States.TAKEN 
		grid_array_chest[grid_to_check].item_stored = item_held
	
	#put item into a data storage here
	
	item_held = null
	clear_grid_chest()

func pick_item():
	if not current_slot or not current_slot.item_stored: 
		return
	item_held = current_slot.item_stored
	item_held.selected = true
	#move node in the scene tree
	item_held.get_parent().remove_child(item_held)
	add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	####
	
	for grid in item_held.item_grids:
		var grid_to_check = item_held.grid_anchor.slot_ID + grid[0] + grid[1] * col_count # use grid anchor instead of current slot to prevent bug
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.FREE 
		grid_array[grid_to_check].item_stored = null
	
	check_slot_availability(current_slot)
	set_grids.call_deferred(current_slot)

func pick_item_chest():
	if not current_slot or not current_slot.item_stored: 
		return
	item_held = current_slot.item_stored
	item_held.selected = true
	#move node in the scene tree
	item_held.get_parent().remove_child(item_held)
	add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	####
	
	for grid in item_held.item_grids:
		var grid_to_check = item_held.grid_anchor.slot_ID + grid[0] + grid[1] * col_count_chest # use grid anchor instead of current slot to prevent bug
		grid_array_chest[grid_to_check].state = grid_array_chest[grid_to_check].States.FREE 
		grid_array_chest[grid_to_check].item_stored = null
	
	check_slot_availability_chest(current_slot)
	set_grids_chest.call_deferred(current_slot)

func _on_add_slot_pressed():
	create_slot()
