extends CanvasLayer

####### GLOBALS
var BUTTON_COLOR := Color("#A5C883") ## TODO: Replace with stuff from main
var BUTTON_PRESSED_COLOR := Color("#436318")
var button_style := StyleBoxFlat.new()
var button_pressed_style := StyleBoxFlat.new()

const HINT_ICON := preload("res://assets/icons/hint.svg")
const NOTES_ICON := preload("res://assets/icons/notes.svg")
const UNDO_ICON := preload("res://assets/icons/undo.svg")
const RESET_ICON := preload("res://assets/icons/reset.svg")
const ERASE_ICON := preload("res://assets/icons/erase.svg")
const FONT_COLOR := Color("#2B2B2B")

####### SIGNALS
signal number_entered(value: int)
signal number_erased()
signal board_reset()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_style.bg_color = BUTTON_COLOR
	button_style.set_corner_radius_all(22)
	button_style.corner_detail = 12
	button_style.content_margin_bottom = 12
	button_style.content_margin_left = 35
	button_style.content_margin_right = 35
	button_style.content_margin_top = 12
	
	button_pressed_style.bg_color = BUTTON_PRESSED_COLOR
	button_pressed_style.set_corner_radius_all(22)
	button_pressed_style.corner_detail = 12
	button_pressed_style.content_margin_bottom = 12
	button_pressed_style.content_margin_left = 35
	button_pressed_style.content_margin_right = 35
	button_pressed_style.content_margin_top = 12
	
	var hint_button_icon: TextureRect = $BottomMarginContainer/BottomUI/tools/HintButton/HBoxContainer/TextureRect
	var hint_button_label: Label = $BottomMarginContainer/BottomUI/tools/HintButton/HBoxContainer/Label
	hint_button_icon.texture = HINT_ICON
	hint_button_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	hint_button_label.text = "Hint"
	
	var notes_button_icon: TextureRect = $BottomMarginContainer/BottomUI/tools/NotesButton/HBoxContainer/TextureRect
	var notes_button_label: Label = $BottomMarginContainer/BottomUI/tools/NotesButton/HBoxContainer/Label
	notes_button_icon.texture = NOTES_ICON
	notes_button_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	notes_button_label.text = "Notes"
	
	var erase_button_icon: TextureRect = $BottomMarginContainer/BottomUI/tools/EraseButton/HBoxContainer/TextureRect
	var erase_button_label: Label = $BottomMarginContainer/BottomUI/tools/EraseButton/HBoxContainer/Label
	erase_button_icon.texture = ERASE_ICON
	erase_button_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	erase_button_label.text = "Erase"
	
	var undo_button_icon: TextureRect = $BottomMarginContainer/BottomUI/keypadAndTools/tools/UndoButton/VBoxContainer/TextureRect
	var undo_button_label: Label = $BottomMarginContainer/BottomUI/keypadAndTools/tools/UndoButton/VBoxContainer/Label
	undo_button_icon.texture = UNDO_ICON
	undo_button_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	undo_button_label.text = "Undo"
	
	var reset_button_icon: TextureRect = $BottomMarginContainer/BottomUI/keypadAndTools/tools/ResetButton/VBoxContainer/TextureRect
	var reset_button_label: Label = $BottomMarginContainer/BottomUI/keypadAndTools/tools/ResetButton/VBoxContainer/Label
	reset_button_icon.texture = RESET_ICON
	reset_button_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	reset_button_label.text = "Reset"
	
	var view_timer_button: Button = $TopMarginContainer/TopUI/InfoBtnsContainer/RightGroup/TimerGroup/ViewTimerBtn
	view_timer_button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	var sudoku_icon: TextureRect = $TopMarginContainer/TopUI/InfoBtnsContainer/IconAndPuzzle/SudokuIcon
	sudoku_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	var keypad_ui_array := $BottomMarginContainer/BottomUI/keypadAndTools/keypad.get_children()
	for i in keypad_ui_array.size():
		var key_button: Button = keypad_ui_array[i]
		key_button.text = str(i+1)
		key_button.add_theme_stylebox_override("normal", button_style)
		key_button.add_theme_stylebox_override("hover", button_style)
		key_button.add_theme_stylebox_override("focus", button_style)
		key_button.add_theme_stylebox_override("pressed", button_pressed_style)
		key_button.add_theme_color_override("font_focus_color", FONT_COLOR)
		key_button.add_theme_color_override("font_hover_color", FONT_COLOR)
		key_button.pressed.connect(_accept_puzzle_entry.bind(key_button.text))
		
	#### CALLBACKS
	var erase_button: Button = $BottomMarginContainer/BottomUI/tools/EraseButton/Button
	erase_button.pressed.connect(_erase_puzzle_entry)
	
	var undo_button: Button = $BottomMarginContainer/BottomUI/keypadAndTools/tools/UndoButton/Button
	# TODO
	
	var reset_button: Button = $BottomMarginContainer/BottomUI/keypadAndTools/tools/ResetButton/Button
	reset_button.pressed.connect(_reset_board)
	
## User Input Functions
func _accept_puzzle_entry(value: String) -> void:
	number_entered.emit(int(value))

func _erase_puzzle_entry() -> void:
	number_erased.emit()
	
func _reset_board() -> void:
	board_reset.emit()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
