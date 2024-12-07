extends Node

@onready var code_input = %CodeInput
@onready var enter_button = %EnterButton

@export var http: AwaitableHTTPRequest

var lobby_bgm = preload("res://sfx/lobby_bgm.mp3");

func _ready():
	enter_button.disabled = true
	$AudioStreamPlayer.bus = "menu_bus"
	$AudioStreamPlayer.stream = lobby_bgm
	$AudioStreamPlayer.play()

func _process(_delta: float) -> void:
	enter_button.disabled = code_input.text.length() != 12

func _on_enter_button_pressed():
	var code = code_input.text
	get_player_info(code)

func get_player_info(code: String) -> void:
	var url = "http://localhost:3000/api/game/" + code
	var headers = ["Content-Type: application/json"]
	var resp = await http.async_request(url, headers)
	if resp.success() and not resp.status_err():
		var player_data = resp.body_as_json()
		if player_data:
			connect_to_game_server(player_data)
		else:
			print("Failed to parse player data.")
	else:
		print("Failed to get data.")

func connect_to_game_server(room_data: Dictionary) -> void:
	await Lobby.join_game("127.0.0.1", room_data["room"], room_data["player"])
	Lobby.load_game("res://levels/map-01/map-01.tscn")
	# transition_to_lobby_ui(room_data)
