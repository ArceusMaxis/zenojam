extends CharacterBody2D

@export_category("Movement Settings")
@export var move_speed := 150.0
@export var move_acceleration := 10.0

@export_category("Jump Settings")
@export var jump_height := 50.0
@export var base_gravity := 980.0
@export var enable_coyote_time := true
@export var enable_long_input := true
@export_group("Jump Hold Settings")
@export var enable_jump_hold := true
@export var jump_time_to_peak := 0.25
@export var jump_time_to_descent := 0.2
@export_category("Baby Parameters")
@export var baby_scene : PackedScene
@export var baby_holder : Node2D

var jump_velocity : float
var jump_gravity : float
var fall_gravity : float

var can_jump := false
var pressed_jump := false
var mode := true
var horizontal := 0.0
var last_animation : String
var is_climbing = false

func _ready():
	calculate_jump_parameters()

func calculate_jump_parameters():
	jump_velocity = (-2.0 * jump_height / jump_time_to_peak)
	jump_gravity = (2.0 * jump_height / (jump_time_to_peak * jump_time_to_peak))
	fall_gravity = (2.0 * jump_height / (jump_time_to_descent * jump_time_to_descent))

func _physics_process(delta):
	apply_gravity(delta)
	handle_jump()
	climb()
	handle_movement(delta)
	update_animation()
	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += calculate_gravity() * delta

func calculate_gravity() -> float:
	if enable_jump_hold:
		return jump_gravity if velocity.y < 0.0 else fall_gravity
	else:
		return base_gravity

func handle_jump():
	if is_on_floor():
		can_jump = true
		if pressed_jump:
			pressed_jump = false
			jump()
	else:
		coyote_time()

	if Input.is_action_just_pressed("jump"):
		if can_jump:
			jump()
		elif enable_long_input:
			pressed_jump = true
			jump_press()

	if Input.is_action_just_released("jump") and velocity.y < 0 and enable_jump_hold:
		velocity.y = 0

func jump():
	calculate_jump_parameters()
	velocity.y = jump_velocity
	can_jump = false
	jump_animation()

func handle_movement(delta):
	var target_velocity = get_input_velocity() * move_speed
	velocity.x = move_toward(velocity.x, target_velocity, move_acceleration * delta * move_speed)

func get_input_velocity() -> float:
	return Input.get_axis("left", "right")

func update_animation():
	if is_on_floor():
		if last_animation in ["Jump", "Fall"]:
			land_animation()
	else:
		last_animation = "Fall"

func _input(event):
	if event.is_action_pressed("pause"):
		get_tree().quit()
	elif event.is_action_pressed("pickdrop"):
		mode = not mode
		if mode:
			baby_mode()
		else:
			girl_mode()

func coyote_time():
	if enable_coyote_time:
		get_tree().create_timer(0.1).timeout.connect(func(): can_jump = false)

func jump_press():
	if enable_long_input:
		get_tree().create_timer(0.75).timeout.connect(func(): pressed_jump = false)

func jump_animation():
	$"Player - Base/jump_sfx".play()
	$"Player - Base/AnimationPlayer".play("Jump")
	last_animation = "Jump"

func land_animation():
	$"Player - Base/AnimationPlayer".play("Squish")
	last_animation = "Land"

func baby_mode():
	if get_parent().has_node("Baby"):
		get_parent().get_node("Baby").queue_free()
	%Basket.visible = true
	move_speed = 150
	move_acceleration = 10
	jump_height = 50
	jump_time_to_peak = 0.25
	jump_time_to_descent = 0.2

func girl_mode():
	%Basket.visible = false
	var baby = baby_scene.instantiate()
	baby.freeze = false
	baby.position = %Basket.global_position + Vector2(-3,0)
	get_parent().add_child(baby)
	move_speed = 200
	move_acceleration = 10
	jump_height = 100
	jump_time_to_peak = 0.25
	jump_time_to_descent = 0.2

func climb():
	if is_climbing == true:
		if Input.is_action_pressed("climbup"):
			velocity.y = -move_speed
