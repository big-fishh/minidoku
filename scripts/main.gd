extends Node

@onready var game_board := $Board
@onready var hud := $HUD
@onready var http_request = $ResourceDownloader

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# http_request.request_completed.connect(_on_resource_downloaded)
	# download_game_resource()
	hud.number_entered.connect(game_board.mark_cell)
	hud.number_erased.connect(game_board.erase_cell)
	hud.board_reset.connect(game_board.reset_board)
	hud.notes_toggled.connect(game_board.toggle_notes)
	

func download_game_resource() -> void:
	var url = "http://127.0.0.1:8000/"
	var error = http_request.request(url)
	if error != OK:
		print("An error occurred while initiating the HTTP request.")

func _on_resource_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if hud.has_method("show_loading_screen"):
		hud.show_loading_screen(false)

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("Failed to download resource.")
		return

	# Example: Parse an image payload downloaded over HTTP
	var json_string = body.get_string_from_utf8()
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		var server_data = json.get_data()
		
		# Ensure the dictionary contains the expected keys
		if server_data is Dictionary and server_data.has("puzzle") and server_data.has("solution"):
			var puzzle_givens = server_data["puzzle"]
			var puzzle_solution = server_data["solution"]
			
			print("Successfully loaded puzzle: ", puzzle_givens)
			
			# Pass the data along to your game board scene/script
			if game_board.has_method("setup_normal_game"):
				game_board.setup_normal_game(puzzle_givens, puzzle_solution)
		else:
			print("JSON data was valid, but missing 'puzzle' or 'solution' keys.")
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
