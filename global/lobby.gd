extends Node

signal player_connected(room_id, peer_id, player_info)
signal player_disconnected(room_id, peer_id)
signal server_disconnected
signal game_started(room_id)

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_CONNECTIONS = 20

var rooms = {}
var players_loaded = {}

func _ready():
  multiplayer.peer_connected.connect(_on_player_connected)
  multiplayer.peer_disconnected.connect(_on_player_disconnected)
  multiplayer.connected_to_server.connect(_on_connected_ok)
  multiplayer.connection_failed.connect(_on_connected_fail)
  multiplayer.server_disconnected.connect(_on_server_disconnected)

func join_game(address: String, room_info: Dictionary, player_info: Dictionary):
  var peer = ENetMultiplayerPeer.new()
  var error = peer.create_client(address, PORT)

  if error:
    return error

  multiplayer.multiplayer_peer = peer
  await delay(0.1)
  _register_player.rpc_id(1, room_info, player_info)

func delay(seconds: float):
  await get_tree().create_timer(seconds).timeout

func remove_multiplayer_peer():
  multiplayer.multiplayer_peer = null

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
  get_tree().change_scene_to_file(game_scene_path)

@rpc("any_peer", "call_local", "reliable")
func player_loaded():
  if not multiplayer.is_server(): return

  var room_id = null
  var player_id = multiplayer.get_remote_sender_id()
  print("Looking for player %d" % player_id)
  print(str(rooms))

  for key in rooms.keys():
    print(str(rooms[key]["players"].keys()))
    if rooms[key]["players"].keys().has(player_id):
      room_id = key
      break

  if room_id == null:
    return

  rooms[room_id]["players_loaded"] += 1
  print("Currently " , rooms[room_id]["players_loaded"] , " players loaded in room " , room_id , "from a total of " , rooms[room_id]["capacity"])
  if rooms[room_id]["players_loaded"] == rooms[room_id]["capacity"]:
    for _player_id in rooms[room_id]["players"].keys():
      var role: String = rooms[room_id]["players"][_player_id]["role"]
      print("Spawning player with role: ", role)
      rpc_id(_player_id, "unpause_game", role)
    rooms[room_id]["players_loaded"] = 0

@rpc("any_peer", "reliable")
func unpause_game(role: String):
  $/root/Map_01.start_game(role)

func _on_player_connected(id):
  # This function will be called when a player connects to the server
  # The player will be registered in the appropriate room by the client
  print("Player connected with id: %d" % id)
  pass

@rpc("any_peer", "reliable")
func _register_player(room_info: Dictionary, new_player_info: Dictionary):
  print("Registering the player")
  var new_player_id = multiplayer.get_remote_sender_id()
  var room_id = room_info["id"]
  if not rooms.has(room_id):
    rooms[room_id] = {
      "room_data": room_info,
      "players": {},
      "players_loaded": 0,
      "capacity": room_info["players"].size()
    }
  rooms[room_id]["players"][new_player_id] = new_player_info
  emit_signal("player_connected", room_info["id"], new_player_id, new_player_info)

func _on_player_disconnected(id):
  for room_id in rooms.keys():
    if rooms[room_id]["players"].has(id):
      rooms[room_id]["players"].erase(id)
      emit_signal("player_disconnected", room_id, id)
      break

func _on_connected_ok():
  # This function will be called when the client successfully connects to the server
  pass

func _on_connected_fail():
  multiplayer.multiplayer_peer = null

func _on_server_disconnected():
  multiplayer.multiplayer_peer = null
  rooms.clear()
  emit_signal("server_disconnected")

# Server initialization function
func start_server():
  var peer = ENetMultiplayerPeer.new()
  var error = peer.create_server(PORT, MAX_CONNECTIONS)
  if error:
    return error
  multiplayer.multiplayer_peer = peer
  print("Server started on port %d" % PORT)
