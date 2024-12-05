# vim: set noexpandtab tabstop=2 shiftwidth=2 softtabstop=2:

extends Node3D

@export_subgroup("Attributes")
@export var sensitivity = 0.1
@export var jump_strength = 6

@export_subgroup("Components")
@export var velocity: Node3D
@export var camera: Camera3D
@export var body: CharacterBody3D

signal walking()
signal jumping()
signal landing()
signal idle()
signal sprint()
signal falling()
signal airbone()
signal crouching()

var is_jumping = false
var is_falling = false
var is_idle = false
var is_sprinting = false
var is_walking = false
var is_crouching = false

var previously_floored = false

func _unhandled_input(event):
	# if not body.is_multiplayer_authority(): return

	if Input.is_action_just_pressed('release'):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.is_action_just_pressed('capture'):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion:
		body.rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * sensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	# if not body.is_multiplayer_authority(): return

	is_idle = false
	is_sprinting = false
	is_walking = false
	is_crouching = false
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var input_vector = body.transform.basis * Vector3(input_dir.x, 0, input_dir.y).normalized()

	if body.is_on_floor() and velocity.get_gravity() > 1 and !previously_floored:
		emit_signal("landing")
		is_jumping = false
		is_falling = false

	previously_floored = body.is_on_floor()

	if Input.is_action_just_pressed("jump") and body.is_on_floor():
		velocity.upwards(jump_strength)
		emit_signal("jumping")
		is_jumping = true

	if body.is_on_floor():
		velocity.reset_gravity()

	velocity.accelerate_to_velocity(input_vector, delta)

	if body.is_on_floor() and velocity.is_accelerating_horizontally():
		if Input.is_action_pressed("sprint"):
			velocity.set_speed_multiplier(10)
			is_sprinting = true
		else:
			velocity.reset_speed_multiplier()
			is_walking = true

	elif body.is_on_floor():
		is_idle = true
	else:
		is_falling = true
	if body.is_on_floor() and Input.is_action_pressed("crouch"):
		velocity.set_speed_multiplier(0.7)
		is_crouching = true

	if !body.is_on_floor():
		emit_signal("airbone" if is_jumping else "falling")
	elif is_crouching and (is_sprinting or is_walking or is_idle):
		emit_signal("crouching")
	elif is_idle:
		emit_signal("idle")
	elif is_walking:
		emit_signal("walking")
	elif is_sprinting:
		emit_signal("sprint")
	else:
		emit_signal("idle")
