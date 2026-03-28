extends Sprite2D
class_name Card2D

# --- Static tracking ---
static var hovered_card : Card2D = null

# --- Properties ---
@export_group("Movement Settings")
@export var speed: float = 20.0
@export var bounce: bool = true
@export var smooth_movement_enabled: bool = true

# --- State Variables ---
var mover : Node # SmoothMovement instance
var mouse_touching : bool = false
var is_dragging : bool = false
var area : Area2D
@export var hand : CardHand

# Signals from the original dragging script
signal object_picked_up
signal object_placed

func _ready() -> void:
	# Initialize Mover (assuming SmoothMovement.init returns the instance)
	mover = await SmoothMovement.init(self)
	mover.speed = speed
	mover.bounce = bounce
	if !hand:
		if get_parent() is CardHand:
			hand = get_parent();
	
	_setup_collision()

func _setup_collision() -> void:
	if texture == null:
		push_warning("No texture found on Sprite2D. Area2D size cannot be set.")
		return

	area = Area2D.new()
	add_child(area)
	
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	
	# Use region_rect if used, otherwise fallback to texture size
	rect_shape.size = region_rect.size if region_enabled else texture.get_size()
	collision.shape = rect_shape
	
	area.add_child(collision)
	area.input_pickable = true
	
	# Connect signals
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	area.input_event.connect(_on_input_event)

func _process(_delta: float) -> void:
	if is_dragging:
		var target_pos = get_global_mouse_position()
		
		if smooth_movement_enabled and mover:
			# Updating the SmoothMovement target
			mover.global_target_position = target_pos
		else:
			global_position = target_pos

func _on_mouse_entered() -> void:
	mouse_touching = true
	hovered_card = self
	print("Mouse is over the card!")

func _on_mouse_exited() -> void:
	mouse_touching = false
	if hovered_card == self:
		hovered_card = null
	print("Mouse left the card.")

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_dragging()
			else:
				_stop_dragging()

# This handles the case where the mouse is released outside the card area
func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_stop_dragging()

func _start_dragging() -> void:
	if not is_dragging:
		var old_position = global_position
		hand.remove_child(self)
		hand.use_hover_lift = false;
		hand.use_z_index_hover = false;
		hand.use_horizontal_spread = false;
		global_position = old_position
		hand.get_parent().add_child(self)
		is_dragging = true
		emit_signal("object_picked_up")
		print("Card grabbed!")

func _stop_dragging() -> void:
	if is_dragging:
		var drop_pos = global_position
		get_parent().remove_child(self)
		hand.use_hover_lift = true
		hand.use_z_index_hover = true
		hand.use_horizontal_spread = true
		hand.add_child(self)
		var new_index = hand.get_index_at_position(drop_pos)
		hand.move_child(self, new_index)
		global_position = drop_pos
		is_dragging = false
		emit_signal("object_placed")
		print("Card sorted into index: ", new_index)
