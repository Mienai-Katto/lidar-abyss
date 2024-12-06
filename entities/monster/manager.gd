# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4:

extends CharacterBody3D

@export var velocity_component: Node3D
@export var camera_component: Camera3D
@export var sfx_jumpscare: AudioStream

@onready var enemy_collision = get_node("CollisionShape3D")

var player_detected: Node3D = null 

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

	velocity_component.move(self)

func _on_enemy_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_trigger_jumpscare(body)

func _trigger_jumpscare(player: Node3D) -> void:
	player_detected = player
	
	var audio_player = AudioStreamPlayer3D.new()
	add_child(audio_player)
	audio_player.stream = sfx_jumpscare
	audio_player.play()
	audio_player.connect("finished", Callable(self, "_on_audio_finished"))
	
func _on_audio_finished() -> void:
	if is_instance_valid(player_detected):
		player_detected.queue_free()
	player_detected = null
