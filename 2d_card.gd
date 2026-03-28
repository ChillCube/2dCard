extends Sprite2D
class_name Card2D

# --- Static tracking ---
static var hovered_card : Card2D = null
static var dragging_card : Card2D = null # Track the globally active dragged card

# --- Properties ---
@export_group("Movement Settings")
@export var speed: float = 20.0
@export var bounce: bool = true
@export var smooth_movement_enabled: bool = true

# --- State Variables ---
var mover : Node 
var mouse_touching : bool = false
var is_dragging : bool = false
var area : Area2D
@export var hand : CardHand

signal object_picked_up
signal object_placed

func _ready() -> void:
	mover = await SmoothMovement.init(self)
	mover.speed = speed
	mover.bounce = bounce
	if !hand and get_parent() is CardHand:
		hand = get_parent()
	
	_setup_collision()

func _setup_collision() -> void:
	if texture == null:
		push_warning("No texture found on Card2D: " + name + ". Collision cannot be generated.")
		return

	# 1. Create the Area2D
	area = Area2D.new()
	area.name = "CardMouseArea"
	add_child(area)
	
	# 2. Create the CollisionShape
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	
	# Determine size: use region if enabled, otherwise use full texture size
	var size = Vector2.ZERO
	if region_enabled:
		size = region_rect.size
	else:
		size = texture.get_size()
	
	rect_shape.size = size
	collision.shape = rect_shape
	
	# 3. Add shape to Area
	area.add_child(collision)
	
	# 4. Configure Area2D for Mouse Input
	area.input_pickable = true
	# Ensure the collision is centered on the Sprite's visual center
	# (Matches Sprite2D's 'Centered' property)
	if centered:
		collision.position = Vector2.ZERO
	else:
		collision.position = size / 2.0

	# 5. Connect Signals
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	area.input_event.connect(_on_input_event)

func _on_mouse_entered() -> void:
	mouse_touching = true
	# Only set this as the hovered card if we aren't already dragging something else
	if dragging_card == null:
		hovered_card = self
	
	# Optional: Add a visual highlight here
	# self.use_parent_material = false (if using shaders)
	print("Mouse entered: ", name)

func _on_mouse_exited() -> void:
	mouse_touching = false
	# Only clear the static reference if THIS card was the one being tracked
	if hovered_card == self:
		hovered_card = null
	
	print("Mouse exited: ", name)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# ONLY start if no other card is currently being dragged
			if dragging_card == null:
				_start_dragging()
		else:
			# ONLY stop if THIS is the card being dragged
			if dragging_card == self:
				_stop_dragging()

func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_stop_dragging()

func _process(_delta: float) -> void:
	if is_dragging:
		var target_pos = get_global_mouse_position()
		if smooth_movement_enabled and mover:
			mover.global_target_position = target_pos
		else:
			global_position = target_pos

func _start_dragging() -> void:
	# Double check: is_dragging is local, dragging_card is static/global
	if not is_dragging and dragging_card == null:
		dragging_card = self # Lock the global drag state
		is_dragging = true
		
		var old_position = global_position
		hand.remove_child(self)
		
		# Disable hand responsiveness while sorting/dragging
		hand.use_hover_lift = false
		hand.use_z_index_hover = false
		hand.use_horizontal_spread = false
		
		global_position = old_position
		hand.get_parent().add_child(self)
		
		emit_signal("object_picked_up")
		print("Card grabbed!")

func _stop_dragging() -> void:
	if is_dragging:
		var drop_pos = global_position
		get_parent().remove_child(self)
		
		# Restore hand features
		hand.use_hover_lift = true
		hand.use_z_index_hover = true
		hand.use_horizontal_spread = true
		
		hand.add_child(self)
		var new_index = hand.get_index_at_position(drop_pos)
		hand.move_child(self, new_index)
		
		global_position = drop_pos
		
		# Unlock the global drag state
		is_dragging = false
		dragging_card = null 
		
		emit_signal("object_placed")
		print("Card released at index: ", new_index)
