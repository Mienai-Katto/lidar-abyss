# vim: set noexpandtab tabstop=2 shiftwidth=2 softtabstop=2:

extends Node3D

@export_subgroup("Velocity attributes")
@export var base_speed: float = 5.0
@export var max_speed: float = 5.0
@export var acceleration_coefficient: float = 10.0
@export var gravity_force = 20.0

var speed_multiplier: float = 1.0

var velocity: Vector3 = Vector3.ZERO
var gravity: float = 0.0

func _physics_process(delta):
	gravity += gravity_force * delta

func apply_forces():
	velocity = velocity.limit_length(max_speed)
	velocity.y = -gravity

func reset_gravity():
	if gravity > 0:
		gravity = 0

func get_gravity():
	return gravity

func upwards(strength: float):
	gravity = -strength

func accelerate_to_velocity(target_velocity: Vector3, delta: float = 1.0):
	velocity = velocity.lerp(target_velocity * (base_speed * speed_multiplier), acceleration_coefficient * delta)

func get_max_velocity(target_velocity: Vector3):
	return target_velocity * (base_speed * speed_multiplier)

func maximize_velocity(target_velocity: Vector3):
	accelerate_to_velocity(target_velocity)
	velocity = velocity.limit_length(get_max_velocity(target_velocity))

func decelerate():
	accelerate_to_velocity(Vector3.ZERO)

func move(character: CharacterBody3D):
	apply_forces()
	character.velocity = velocity
	character.move_and_slide()

func set_speed_multiplier(new_speed_multiplier: float):
	speed_multiplier = new_speed_multiplier

func reset_speed_multiplier():
	speed_multiplier = 1.0

func length():
	return velocity.length()

func set_max_speed(new_max_speed: float):
	max_speed = new_max_speed

func is_accelerating_horizontally():
	return abs(velocity.x) > 1 or abs(velocity.z) > 1
