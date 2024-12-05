extends Node3D

const Player = preload("res://entities/player/player.tscn")
const Monster = preload("res://entities/monster/monster.tscn")

const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		enet_peer.create_server(PORT)
		multiplayer.multiplayer_peer = enet_peer

		multiplayer.peer_connected.connect(create_player)
		multiplayer.peer_disconnected.connect(disconnect_player)

	print("Server started")
  else:
	host_game()

func host_game():
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer

	multiplayer.peer_connected.connect(create_player)
	multiplayer.peer_disconnected.connect(disconnect_player)

	create_player(multiplayer.get_unique_id())

func create_player(peer_id: int):
  var player = Player.instantiate()
  # var player = Monster.instantiate()
  player.name = str(peer_id)
  spawn_player(player)
  print("Adding player: %s" % player.name)
  call_deferred("add_child", player)
  print("Created player: %s" % player.name)
  print(player.position)

func spawn_player(player: Node3D):
	player.position = Vector3(0, 10, 0)


func disconnect_player(peer_id: int):
	var player = get_node_or_null(str(peer_id))
	print("Disconnected player: %s" % player.name)
	if player:
		player.queue_free()
