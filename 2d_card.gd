extends Sprite2D
class_name Card2D

# Added: A shared variable to track the single top-most card
static var hovered_card : Card2D = null

var mover : SmoothMovement
@export var speed = 20.0
@export var bounce = true

var mouse_touching : bool = false;

func _ready() -> void:
	mover = await SmoothMovement.init(self)
	mover.speed = speed
	mover.bounce = bounce
	
	if texture == null:
		push_warning("No texture found on Sprite2D. Area2D size cannot be set.")
		return

	var area = Area2D.new()
	add_child(area)
	
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	
	# Keeping your original collision size logic
	rect_shape.size = region_rect.size
	collision.shape = rect_shape
	
	area.add_child(collision)
	# Connect the signals to functions in this script
	area.input_pickable = true
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	area.input_event.connect(_on_input_event)

func _on_mouse_entered() -> void:
	mouse_touching = true
	# Logic for highlighting the card (e.g., scale up or shader)
	print("Mouse is over the card!")

func _on_mouse_exited() -> void:
	mouse_touching = false
	# Reset visual state
	print("Mouse left the card.")

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				print("Card grabbed!")
				_start_dragging()
			else:
				print("Card released!")
				_stop_dragging()

func _start_dragging():
	# Set a flag or change state so the mover follows the mouse
	pass

func _stop_dragging():
	# Handle logic for dropping the card
	pass
