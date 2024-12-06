extends Node

var room_name: String
var room_id: String
var current_player_name: String
var players_in_room: Array
var connected_players: Array = []

func _ready():
  # var room_data = Lobby.room_data
  # room_name = room_data["room"]["name"]
  # room_id = room_data["room"]["id"]
  # current_player_name = room_data["player"]["name"]
  # players_in_room = room_data["room"]["players"]

  update_lobby_ui()

  multiplayer.peer_connected.connect(on_peer_connected)
  multiplayer.peer_disconnected.connect(on_peer_disconnected)

func on_peer_connected(peer_id):
  connected_players.append(peer_id)
  update_lobby_ui()

func on_peer_disconnected(peer_id):
  connected_players.erase(peer_id)
  update_lobby_ui()

func update_lobby_ui():
  %RoomInfo.text = "Room: %s (%s)" % [room_name, room_id]
  %PlayerList.text = "Players in Room:\n" + "\n".join(players_in_room)

  # Highlight connected players
  var connected_names = []
  for player in players_in_room:
    if player["id"] in connected_players:
      connected_names.append(player["name"])
      %ConnectedPlayers.text = "Connected:\n" + "\n".join(connected_names)