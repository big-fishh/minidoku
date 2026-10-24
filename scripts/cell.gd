class_name Cell
extends Button

# TODO: Write a function that will take the entry color from board

# CONSTANTS
const ENTRY_FONT := preload("res://assets/fonts/figtree-latin-400-normal.ttf")
const GIVEN_FONT := preload("res://assets/fonts/figtree-latin-500-normal.ttf")
const NOTE_FONT := preload("res://assets/fonts/Caveat-Regular.ttf")
const GIVEN_COLOR := Color("#1A1A1A")
const ERROR_COLOR := Color("#d23f3f")
const NOTE_COLOR := Color("#2B2B2B")
const DEFAULT_BG := Color("ffffff")

# GLOBALS
var DEFAULT_ENTRY_COLOR := Color("#568503") # just declare this as a color then write a function that will take the color from board
var SELECTED_ENTRY_COLOR := Color("#568503")


func show_value(n: int, is_given: bool, has_conflict: bool, label_color: Color) -> void:
	$CellValue.text = str(n) if n != 0 else ""
	$CellValue.add_theme_font_override("font", GIVEN_FONT if is_given else ENTRY_FONT) # the first argument is what this attribute is called in the editor. theme override->font
	if is_given:
		$CellValue.add_theme_color_override("font_color", GIVEN_COLOR)
	elif has_conflict:
		$CellValue.add_theme_color_override("font_color", ERROR_COLOR)
	else:
		$CellValue.add_theme_color_override("font_color", label_color)

# We're going to use a bitmask for the notes. To show the right notes, we'll: check which bits are set, go to the right note in our CellNotes container, and then write the right number to its text attribute
func show_notes(mask: int) -> void:
	for i in 6:
		var note: Label = $CellNotes.get_child(i)
		if mask & (1 << i):
			note.text = str(i + 1) # since everything is 0 based indexing
		else:
			note.text = ""

func set_bg_color(color: Color) -> void:
	$CellBgColor.color = color
	
func set_selection_border_color(color: Color) -> void:
	$SelectionBorder.color = color

func setup_cell_colors(default_entry_color: Color, selected_entry_color: Color) -> void:
	DEFAULT_ENTRY_COLOR = default_entry_color
	SELECTED_ENTRY_COLOR = selected_entry_color

# Called when the node enters the scene tree for the first time.
# Set everything to empty so we don't see the default look of the cell
func _ready() -> void:
	$CellBgColor.color = DEFAULT_BG
	#show_value(0, false, false)
	show_value(0, false, false, DEFAULT_ENTRY_COLOR)
	show_notes(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
