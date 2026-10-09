extends CharacterBody2D


const SPEED = 250.0
const JUMP_VELOCITY = -550.0
const MAX_JUMPS = 2

@onready var player_ui: AnimatedSprite2D = $AnimatedSprite2D

var jump_count := 0

func _physics_process(delta: float) -> void:
	
	# Reset jumlah lompatan saat menyentuh lantai.
	if is_on_floor():
		jump_count = 0
	
	if velocity.x > 0 or velocity.x < 0:
		player_ui.animation = "run"
	else:
		player_ui.animation = "idle"
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		player_ui.animation = "jump"

	# Handle jump (termasuk double jump).
	if Input.is_action_just_pressed("ui_accept") and jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		player_ui.flip_h = direction < 0
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
