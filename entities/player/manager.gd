# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4:

extends CharacterBody3D

@export var velocity_component: Node3D
@export var camera_component: Camera3D

@onready var player_collision = get_node("CollisionShape3D")

# @onready var Spawner = get_parent().get_node("Spawner")
# @onready var hud = get_node("HUD")

# signal respawn

func _ready():
  # if not is_multiplayer_authority(): return
  camera_component.make_current()

	# Set sprite invisible for the current camera
	# get_node("Sprite").visible = fals

func _enter_tree():
  set_multiplayer_authority(str(name).to_int())

func _physics_process(_delta):
  # if not is_multiplayer_authority(): return

  # if position.y < 0:
  #   position.y = 10
  pass
  # velocity_component.move(self)
