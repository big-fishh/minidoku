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

# Win animation (timings measured from minisudoku.com's win effect)
const WIN_TILE_OVERHANG := 4          # px the win tile extends past the cell on every side
const WIN_TILE_TEXT_COLOR := Color.WHITE
const WIN_TILE_MAX_TILT := 4.0        # degrees; each tile gets a random tilt up to this, either direction
const WIN_TILE_MIN_TILT := 1.5        # degrees; keeps every tile at least a little crooked
const WIN_TILE_FADE_IN := 0.08        # seconds to go from invisible to solid green
const WIN_TILE_HOLD := 0.04           # seconds it stays solid
const WIN_TILE_FADE_OUT := 0.22       # seconds to fade back out

# GLOBALS
var DEFAULT_ENTRY_COLOR := Color("#568503") # just declare this as a color then write a function that will take the color from board
var SELECTED_ENTRY_COLOR := Color("#568503")

var bg_tween: Tween
var win_tile: WinTile
var win_tween: Tween


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
		note.add_theme_font_override("font", NOTE_FONT)
		if mask & (1 << i):
			note.text = str(i + 1) # since everything is 0 based indexing
		else:
			note.text = ""

func set_bg_color(color: Color) -> void:
	_kill_bg_tween()
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
	show_value(0, false, false, DEFAULT_ENTRY_COLOR)
	show_notes(0)
	_create_win_tile()

func fade_bg_color(color: Color, duration := 0.06) -> void:
	if $CellBgColor.color == color:
		return                      # already there, nothing to animate
	_kill_bg_tween()
	bg_tween = create_tween()
	bg_tween.set_ease(Tween.EASE_OUT)
	bg_tween.tween_property($CellBgColor, "color", color, duration)

func _kill_bg_tween() -> void:
	if bg_tween and bg_tween.is_valid():
		bg_tween.kill()


####### WIN ANIMATION ########
# Builds the hidden tile that sits on top of this cell during the win wave.
func _create_win_tile() -> void:
	win_tile = WinTile.new()
	win_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE   # never blocks taps
	win_tile.z_index = 1                                  # draw above neighboring cells
	win_tile.hide()
	add_child(win_tile)

	# Fill the cell, plus a few pixels on every side so the tile looks slightly bigger.
	win_tile.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_tile.offset_left = -WIN_TILE_OVERHANG
	win_tile.offset_top = -WIN_TILE_OVERHANG
	win_tile.offset_right = WIN_TILE_OVERHANG
	win_tile.offset_bottom = WIN_TILE_OVERHANG

# Pops a slightly crooked green tile over this cell, then fades it away.
#   value       – the number shown on the tile
#   tile_color  – the tile's background color
#   start_delay – seconds to wait before this tile starts (creates the wave)
func play_win_tile(value: int, tile_color: Color, start_delay: float) -> void:
	if win_tween and win_tween.is_valid():
		win_tween.kill()

	win_tile.text = str(value)
	win_tile.tile_color = tile_color
	win_tile.text_color = WIN_TILE_TEXT_COLOR
	win_tile.font = $CellValue.get_theme_font("font")
	win_tile.font_size = $CellValue.get_theme_font_size("font_size")

	# Random crooked angle, leaning left or right, rotating around the tile's center.
	var tilt_degrees := randf_range(WIN_TILE_MIN_TILT, WIN_TILE_MAX_TILT)
	if randf() < 0.5:
		tilt_degrees = -tilt_degrees
	win_tile.pivot_offset = win_tile.size / 2.0
	win_tile.rotation_degrees = tilt_degrees

	win_tile.modulate.a = 0.0
	win_tile.show()
	win_tile.queue_redraw()

	win_tween = create_tween()
	win_tween.tween_interval(start_delay)
	win_tween.tween_property(win_tile, "modulate:a", 1.0, WIN_TILE_FADE_IN).set_ease(Tween.EASE_OUT)
	win_tween.tween_interval(WIN_TILE_HOLD)
	win_tween.tween_property(win_tile, "modulate:a", 0.0, WIN_TILE_FADE_OUT).set_ease(Tween.EASE_IN)
	win_tween.tween_callback(win_tile.hide)
