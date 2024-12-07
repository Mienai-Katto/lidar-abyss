extends Node

var rooms: Dictionary = {}

@rpc("any_peer", "call_remote", "reliable", 0)
func create_room(room_id: String, expected_players: int):
  if room_id not in rooms:
    rooms[room_id] = {
      "expected_players": expected_players,
      "connected_players": []
    }

    print("Room created with id: " + room_id)
    print("Expected players: " + str(expected_players))

func add_player_to_room(room_id: String, peer_id: int):
  if room_id in rooms and peer_id not in rooms[room_id]["connected_players"]:
    rooms[room_id]["connected_players"].append(peer_id)
    check_if_room_ready(room_id)

func remove_player_from_room(peer_id: int):
  for room_id in rooms:
    if peer_id in rooms[room_id]["connected_players"]:
      rooms[room_id]["connected_players"].erase(peer_id)
      break

func check_if_room_ready(room_id: String):
  if rooms[room_id]["expected_players"] == len(rooms[room_id]["connected_players"]):
    start_game_for_room(room_id)

func start_game_for_room(room_id: String):
  for peer_id in rooms[room_id]["connected_players"]:
    rpc_id(peer_id, "start_game")