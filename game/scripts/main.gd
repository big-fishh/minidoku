extends Node

const PUZZLE_SERVER_URL := "http://127.0.0.1:8000/"

@onready var game_board := $BoardStack/Board
@onready var start_overlay := $BoardStack/StartOverlay
@onready var hud := $HUD
@onready var http_request = $ResourceDownloader
var current_mode = GameMode.Mode.DAILY

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	http_request.request_completed.connect(_on_puzzle_downloaded)
	download_puzzle()

	hud.number_entered.connect(game_board.mark_cell)
	hud.number_erased.connect(game_board.erase_cell)
	hud.board_reset.connect(game_board.reset_board)
	hud.notes_toggled.connect(game_board.toggle_notes)
	hud.mode_requested.connect(_on_mode_requested)
	hud.show_mode(current_mode)
	hud.undo_pressed.connect(game_board.undo)
	start_overlay.start_pressed.connect(_on_start_pressed)
	game_board.puzzle_solved.connect(_on_puzzle_solved)
	game_board.puzzle_solved.connect(hud.stop_clock)

# The player pressed START GAME. The overlay has already hidden itself,
# so the board (filled by setup_game) is now visible; just start the clock.
func _on_start_pressed() -> void:
	hud.start_clock()

func _on_puzzle_solved() -> void:
	print("Solved!")

func _on_mode_requested(mode: GameMode.Mode) -> void:
	if mode == current_mode:
		return
	current_mode = mode
	hud.show_mode(current_mode)


####### PUZZLE DOWNLOAD ########
func download_puzzle() -> void:
	var error = http_request.request(PUZZLE_SERVER_URL)
	if error != OK:
		print("Couldn't start the puzzle request. Error code: ", error)
		_use_backup_puzzle()

# Runs when the server answers (or the request fails).
func _on_puzzle_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("Puzzle download failed. Result: ", result, ", HTTP code: ", response_code)
		_use_backup_puzzle()
		return

	var server_data = JSON.parse_string(body.get_string_from_utf8())
	if not (server_data is Dictionary and server_data.has("puzzle") and server_data.has("solution")):
		print("Server sent unexpected data: ", server_data)
		_use_backup_puzzle()
		return

	# Rename the server's keys to the ones the board expects.
	var puzzle: Dictionary[String, String] = {
		"grid": str(server_data["puzzle"]),
		"solution": str(server_data["solution"]),
	}
	game_board.setup_game(puzzle)

# If the server can't be reached, play the puzzle built into board.gd, so
# pressing Start always reveals something.
# TODO: Remove it: if a failed download should really look like a failure, replace the three _use_backup_puzzle() calls with something that shows an error message on the overlay, such as “Couldn’t load today’s puzzle”. You may also want to disable the Start button, because right now Start would reveal an empty board.
func _use_backup_puzzle() -> void:
	game_board.setup_game(game_board.game)
