extends PanelContainer
# The Board is responsible keeping track of what's on it (its state) as well as enforcing the rules of the game

@export var cell_scene: PackedScene # Lets us instantiate a cell scene
# CONSTANTS
const N := 6
const BOX_HEIGHT := 2
const BOX_WIDTH := 3
const BOX_RADIX = N / BOX_WIDTH

## --- constants that i will get from main. right now hardcoding to green board
const ENTRY_COLOR := Color("#568503")
const SELECTED_ENTRY_COLOR := Color("#436318")
const SELECTED_BG := Color("#A5C883")
const MATCH_BG := Color("#CEE3BA")
const PEER_BG := Color("#F1F9EA")

const game: Dictionary[String, String] = {
	"id": "1",
	"difficulty": "Easy",
	"grid": "410620500130035002042563004351001240",
	"solution": "413625526134635412142563264351351246"
  }

# GLOBALS
var board: Array[Cell] = [] # Stores all the cells as a 1D array for faster accessing
var givens := PackedByteArray()
var solution := PackedByteArray()
var board_state := PackedByteArray() # Data representation of game board
var user_selected_cell := -1

###### INITIALIZE BOARD SCENE ########
func _ready() -> void:
	# Called when the node enters the scene tree for the first time.
	# When the Board scene enters the scene tree for the first time, need to graphically place all our cells as well as build up the 1D representation of board
	# First, allocate space
	board.resize(N * N)
	board_state.resize(N * N)
	
	# Then, populate the board with cell instances. Build it up box by box
	var boxes_array := $BoardPadding/Boxes.get_children()
	var num_boxes:= boxes_array.size()
	for b in num_boxes:
		var box: GridContainer = boxes_array[b].get_node("Cells")
		for i in N: # each box has N cells
			var cell: Cell = cell_scene.instantiate()
			# set the cell coloring values
			# cell.ENTRY_COLOR = ENTRY_COLOR
			cell.setup_cell_colors(ENTRY_COLOR, SELECTED_ENTRY_COLOR)
			# to place it at the right spot in the 1x36 grid, we need to get it's 2D coordinates. We use b and i to get the row and col index
			# flat_index = outer_direction * capacity of that direction + inner_direction
			# For row/col index, the outer direction is the box_row/box_col and the inner direction is the local_row/local_col
			@warning_ignore("integer_division")
			var box_row = b / BOX_RADIX # every box row holds 2 boxes. 2D coordinates => [r][c] = divmod(flat_index, radix)
			@warning_ignore("integer_division")
			var local_row = i / BOX_WIDTH
			var row_index = box_row * BOX_HEIGHT + local_row
			
			var box_col = b % BOX_RADIX # col number wraps around after 2 boxes
			var local_col = i % BOX_WIDTH
			var col_index = box_col * BOX_WIDTH + local_col
			
			var cell_index = row_index * N + col_index
			
			board[cell_index] = cell
			box.add_child(cell)
			# Last step is to connect the cell node's pressed signal to a function that will do something when a cell is selected. .bind() lets us pass the cell index to the function
			cell.pressed.connect(_select_cell.bind(cell_index))
			
	### REMOVE LATER
	setup_game(game)

func setup_game(puzzle: Dictionary[String, String]) -> void:
	# store the puzzle grid as the givens array and the puzzle solution array with what was taken from main,
	# update board state with givens value
	# then call update_board
	givens.resize(N * N)
	var board_size = N * N
	for i in board_size:
		var val := int(puzzle.grid[i])
		givens[i] = val
	
	solution.resize(N * N)
	for i in board_size:
		var val := int(puzzle.solution[i])
		solution[i] = val
		
	for i in board_state.size():
		board_state[i] = givens[i]
		
	_update_board()
		

####### HANDLE USER INPUT #############
func _select_cell(n: int) -> void:
	# A toggle for selecting a cell
	user_selected_cell = n if user_selected_cell != n else -1
	# print(user_selected_cell)
	_update_board()

func mark_cell(val: int) -> void:
	if user_selected_cell == -1 or _is_given(user_selected_cell):
		return
	board_state[user_selected_cell] = val
	_update_board()

func erase_cell() -> void:
	if user_selected_cell == -1 or _is_given(user_selected_cell):
		return
	board_state[user_selected_cell] = 0
	_update_board()

func reset_board() -> void:
	for i in board_state.size():
		board_state[i] = givens[i]
	_update_board()

######### HELPER FUNCTIONS ##############
func _cell_row(cell_idx: int) -> int:
	@warning_ignore("integer_division")
	return cell_idx / N

func _cell_col(cell_idx: int) -> int:
	return cell_idx % N
	
func _cell_box(cell_idx: int) -> int:
	@warning_ignore("integer_division")
	var box_row = _cell_row(cell_idx) / BOX_HEIGHT
	@warning_ignore("integer_division")
	var box_col = _cell_col(cell_idx) / BOX_WIDTH
	return box_row * BOX_RADIX + box_col
	
func _is_given(cell_idx: int) -> bool:
	return givens[cell_idx] != 0

func _has_conflict(cell_idx: int) -> bool:
	var cell_value = board_state[cell_idx]
	for board_cell in board_state.size():
		if board_cell == cell_idx:
			continue
		var other_cell_val = board_state[board_cell]
		if (other_cell_val == cell_value) and _are_peers(cell_idx, board_cell):
			return true
	return false

func _are_peers(cell_1: int, cell_2: int) -> bool:
	return _cell_row(cell_1) == _cell_row(cell_2) or _cell_col(cell_1) == _cell_col(cell_2) or _cell_box(cell_1) == _cell_box(cell_2)

func _are_match(val_1: int, val_2: int) -> bool:
	if val_1 !=0 and val_2 != 0:
		return val_1 == val_2
	else:
		return false

func _update_board() -> void:
	var selected_value := board_state[user_selected_cell]
	for i in board.size():
		var is_selected := i == user_selected_cell
		var cell := board[i]
		var cell_bg_color := cell.DEFAULT_BG
		if user_selected_cell >= 0:
			if i == user_selected_cell:
				cell_bg_color = SELECTED_BG
			elif _are_peers(i, user_selected_cell):
				cell_bg_color = PEER_BG
			elif _are_match(selected_value, board_state[i]):
				cell_bg_color = MATCH_BG
		cell.show_value(board_state[i], _is_given(i), _has_conflict(i), SELECTED_ENTRY_COLOR if is_selected else cell.DEFAULT_ENTRY_COLOR)
		cell.set_bg_color(cell_bg_color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
