extends Node

@onready var player_entity = preload("res://entities/player/player.tscn")
@onready var monster_entity = preload("res://entities/monster/monster.tscn")

# func _ready() -> void:
#   # Wait until the multiplayer peer is fully connected
#   if multiplayer.get_multiplayer_peer().get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
#     Lobby.player_loaded.rpc_id(1)  # Notify the server this peer is ready
#   else:
#     await get_tree().create_timer(0.5).timeout
#     _ready()  # Retry _ready logic after ensuring connection

#   get_tree().paused = true

# func start_game(role: String):
#   get_tree().paused = false

#   if role == "MONSTER":
#     var monster = monster_entity.instantiate()
#     monster.position = Vector3(-9, 1.8, -13)
#     get_tree().current_scene.add_child(monster)
#     monster.position = Vector3(-9, 1.8, -13)
#     %Map.visible = true
#   else:
#     var player = player_entity.instantiate()
#     player.position = Vector3(-6, 1.8, -13)
#     get_tree().current_scene.add_child(player)
#     player.position = Vector3(-6, 1.8, -13)
#     %Map.visible = false
