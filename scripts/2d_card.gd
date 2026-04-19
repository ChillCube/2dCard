extends Sprite2D
class_name Card2D

# --- Static tracking ---
static var hovered_card : Card2D = null
static var dragging_card : Card2D = null 

# --- Properties ---

@export var _name : String;
@export_multiline var description : String;
@export var is_draggable : bool = true

@export_group("Movement Settings")
@export var speed: float = 15.0
@export var smooth_movement_enabled: bool = true
@export_subgroup("Bounce")
@export var bounce: bool = true
@export var disable_bounce_while_dragging:bool = true;
@export_subgroup("Tilt")
@export var movement_tilt : bool = true;
@export var disable_movement_tilt_while_dragging:bool = true;
@export_subgroup("Fake3D")
@export var fake_3d : bool = false;

@export_group("Scale Settings")
@export var default_scale : float = 1;
@export var grabbed_scale : float = 1.2;

@export_group("Grid Settings")
@export var allow_stacking : bool = false
## If true, the card will try to snap to a grid when dropped outside the hand
@export var use_grid_placement : bool = false
## Reference to the Grid node in your scene
@export var grid : Grid 

var poly_mesh : Polygon2D

# --- State Variables ---
var mover : SmoothMovement 
var mouse_touching : bool = false
var is_dragging : bool = false
var area : Area2D
@export var hand : CardHand

# This acts as our internal GridObject controller .
var grid_logic : GridObject = null

signal object_picked_up
signal hovering_over_card(Card2D)
signal object_placed

func _ready() -> void:
	
	_setup_collision()
	if fake_3d:
		_convert_to_polygon()
	
	mover = await SmoothMovement.init(self)
	mover.speed = speed
	mover.bounce = bounce
	#mover.skew_on = false;
	mover.tilt_on = false;
	#mover.perspective_on = fake_3d;
	
	
	if !hand and get_parent() is CardHand:
		hand = get_parent()
	
	if hand:
		if hand.grid:
			grid = hand.grid;
	
	_setup_grid_logic()


func _mouse_touching(): ## This is a stub that can be ued by other nodes to run code when the mouse is hovering over the card
	pass 

func _not_mouse_touching(): ## This is a stub that can be ued by other nodes to run code when the mouse is not hovering over the card
	pass 

func _convert_to_polygon() -> void:
	if not texture: return
	
	# 1. Determine the source area (The frame on the spritesheet)
	var region : Rect2
	if region_enabled:
		region = region_rect
	else:
		region = Rect2(Vector2.ZERO, texture.get_size())
	
	var size = region.size
	poly_mesh = Polygon2D.new()
	poly_mesh.texture = texture
	
	# 2. Define the 4 corners (The Shape)
	# We center them so the card rotates/tilts around its middle
	var offset = size / 2.0
	var points = PackedVector2Array([
		Vector2(-offset.x, -offset.y), # Top-Left
		Vector2(offset.x, -offset.y),  # Top-Right
		Vector2(offset.x, offset.y),   # Bottom-Right
		Vector2(-offset.x, offset.y)   # Bottom-Left
	])
	
	poly_mesh.polygon = points
	
	# 3. Define the UVs (The "Window" into the spritesheet)
	# Instead of 0 to Size, we go from Region.Position to Region.End
	poly_mesh.uv = PackedVector2Array([
		Vector2(region.position.x, region.position.y),           # Top-Left of frame
		Vector2(region.position.x + size.x, region.position.y),  # Top-Right of frame
		Vector2(region.position.x + size.x, region.position.y + size.y), # Bottom-Right
		Vector2(region.position.x, region.position.y + size.y)   # Bottom-Left
	])
	
	add_child(poly_mesh)
	self.texture = null # Hide the original sprite so they don't overlap

func _setup_grid_logic() -> void:
	if use_grid_placement:
		# We attach a GridObject dynamically so we don't have to 
		# change the inheritance of Card2D
		grid_logic = GridObject.new()
		grid_logic.grid = grid
		grid_logic.continous_movement = true
		add_child(grid_logic)

func _setup_collision() -> void:
	if texture == null:
		push_warning("No texture found on Card2D: " + name + ". Collision cannot be generated.")
		return

	area = Area2D.new()
	area.name = "CardMouseArea"
	add_child(area)
	
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	
	var size = region_rect.size if region_enabled else texture.get_size()
	rect_shape.size = size
	collision.shape = rect_shape
	
	area.add_child(collision)
	area.input_pickable = true
	collision.position = Vector2.ZERO if centered else size / 2.0

	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	area.input_event.connect(_on_input_event)

func _on_mouse_entered() -> void:
	mouse_touching = true
	if dragging_card == null: 
		hovered_card = self
		emit_signal("hovering_over_card", self);

func _on_mouse_exited() -> void:
	print("mouse exited card")
	mouse_touching = false
	if hovered_card == self: hovered_card = null

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not is_draggable: return 
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if dragging_card == null: _start_dragging()
		else:
			if dragging_card == self: _stop_dragging()

func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_stop_dragging()

func _process(_delta: float) -> void:
	
	if mouse_touching:
		_mouse_touching();
	else:
		_not_mouse_touching();
	
	mover.tilt_on = movement_tilt;
	mover.bounce = bounce;
	mover.global_target_scale = Vector2(default_scale, default_scale);
	if is_dragging:
		mover.global_target_scale = Vector2(grabbed_scale, grabbed_scale);
		if disable_bounce_while_dragging:
			mover.bounce = false;
		if disable_movement_tilt_while_dragging:
			mover.tilt_on = false;
		var target_pos = get_global_mouse_position()
		if smooth_movement_enabled and mover:
			mover.global_target_position = target_pos
		else:
			global_position = target_pos

func _start_dragging() -> void:
	if not is_dragging and dragging_card == null:
		dragging_card = self 
		is_dragging = true
		z_index = 2;
		
		# Disable grid logic while dragging so it doesn't fight the mouse
		if grid_logic: grid_logic.continous_movement = false
		
		var old_position = global_position
		if get_parent() == hand:
			hand.remove_child(self)
			# Restore hand state (logic from your original snippet)
			hand.use_hover_lift = false
			hand.use_z_index_hover = false
			hand.use_horizontal_spread = false
			hand.get_parent().add_child(self)
		
		global_position = old_position
		emit_signal("object_picked_up")

func _stop_dragging() -> void:
	if not is_dragging: return
	
	is_dragging = false
	dragging_card = null 
	z_index = 0;
	
	var drop_pos = global_position
	
	# --- Dynamic Logic: Is it hovering over the hand area? ---
	if hand.is_position_in_hand_zone(drop_pos):
		# Return to hand
		_return_to_hand(drop_pos)
		if grid_logic: grid_logic.continous_movement = false
		print("Dropped in hand zone.")
	
	elif use_grid_placement and grid:
		# Snap to Grid
		_snap_to_grid(drop_pos)
		
	else:
		# Check for specific placement areas (like a play board)
		var target_placement = _get_placement_under_mouse()
		if target_placement and not target_placement.is_full():
			target_placement.snap_object(self)
		else:
			# Fallback if dropped in "no man's land"
			_return_to_hand(drop_pos)

	emit_signal("object_placed")

func _snap_to_grid(pos: Vector2) -> void:
	# 1. Reparent so we aren't stuck in Hand space
	if get_parent() != grid.get_parent():
		var old_pos = global_position
		if get_parent(): get_parent().remove_child(self)
		grid.get_parent().add_child(self)
		global_position = old_pos

	# 2. Get the target grid coordinate and world position
	var grid_coord = grid.get_grid_coordinate(pos)
	var snapped_world_pos = grid.get_grid_position(grid_coord)

	# 3. OCCUPANCY CHECK (Toggleable)
	if _is_grid_position_occupied(snapped_world_pos):
		if not allow_stacking:
			print("Space occupied! Returning to hand.")
			_return_to_hand(pos)
			return
	
	# 4. Tell the mover where to go
	if mover:
		mover.global_target_position = snapped_world_pos
	else:
		global_position = snapped_world_pos
		
	mover.global_target_rotation = randf_range(-0.2, 0.2);
	print("Snapped to Grid Pos: ", snapped_world_pos)

## Helper function to detect if another card is already at the target snapped position
func _is_grid_position_occupied(target_world_pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	
	# We use a point query to see what is at the center of the target tile
	var query = PhysicsPointQueryParameters2D.new()
	query.position = target_world_pos
	query.collide_with_areas = true
	# Use the area's collision mask to find other cards
	query.collision_mask = area.collision_mask 
	
	var results = space_state.intersect_point(query)
	
	for result in results:
		var hit_area = result.collider
		# If the collider is an Area2D belonging to a DIFFERENT Card2D...
		if hit_area != area and hit_area.get_parent() is Card2D:
			# Only count it as "occupied" if that card isn't currently being dragged
			if not hit_area.get_parent().is_dragging:
				return true
	return false

func _get_placement_under_mouse() -> PlacementArea2D:
	var areas = area.get_overlapping_areas()
	for a in areas:
		if a is PlacementArea2D: return a
	return null

func _return_to_hand(drop_pos: Vector2) -> void:
	if get_parent(): get_parent().remove_child(self)
	
	hand.add_child(self)
	var new_index = hand.get_index_at_position(drop_pos)
	hand.move_child(self, new_index)
	
	global_position = drop_pos
	hand.use_hover_lift = true
	hand.use_z_index_hover = true
	hand.use_horizontal_spread = true
