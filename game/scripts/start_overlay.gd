class_name StartOverlay
extends PanelContainer
# A fake, empty board that covers the real one until the player presses START GAME.
# It rebuilds the board's look in code -- dark frame, six boxes of blank cells --
# and makes the cells shimmer. It knows nothing about the real board: it just has
# to look like it. Pressing the button hides this overlay and emits start_pressed.

signal start_pressed

####### LOOK -- set in the Inspector, or from code for server themes ########
@export_group("Board look (match the real board's values)")
@export var cell_size := Vector2(66, 66)       # the Cell scene's custom minimum size
@export var cell_gap := 1                      # the Cells grid's separation
@export var box_gap := 3                       # the Boxes grid's separation
@export var board_padding := 6                 # BoardPadding's margins
@export var frame_color := Color("#1A1A1A")    # board background; shows through the gaps as grid lines
@export var frame_corner_radius := 6

@export_group("Shimmer")
@export var cell_color := Color.WHITE          # the cells' resting color
@export var shimmer_color := Color("#CEE3BA")  # light color the cells drift toward

@export_group("Button")
@export var button_color := Color("#A5C883")
@export var button_pressed_color := Color("#8FB86A")
@export var button_text_color := Color("#1A1A1A")
@export var button_outline_color := Color("#1A1A1A")   # also used for the hard shadow
@export var play_icon: Texture2D               # drag your play-triangle SVG here

####### FIXED LAYOUT (6x6 board, 3x2-cell boxes, 2 box columns) ########
const BOX_COLUMNS := 2         # boxes across the board
const BOXES_TOTAL := 6
const CELL_COLUMNS_PER_BOX := 3
const CELLS_PER_BOX := 6

const BUTTON_TEXT := "START GAME"
const BUTTON_FONT := preload("res://assets/fonts/figtree-latin-700-normal.ttf")
const BUTTON_FONT_SIZE := 15
const BUTTON_OUTLINE_WIDTH := 2
const BUTTON_CORNER_RADIUS := 8
const BUTTON_SHADOW_OFFSET := Vector2(4, 4)           # hard shadow, down-right
const BUTTON_PRESSED_SHADOW_OFFSET := Vector2(1, 1)   # shadow shrinks when pressed, like it's pushed in
const BUTTON_ICON_SIZE := 12

const SHIMMER_MIN_TIME := 0.5    # seconds per color change, shortest
const SHIMMER_MAX_TIME := 1.4    # seconds per color change, longest

var shimmer_tiles: Array[ColorRect] = []
var tile_tweens := {}            # ColorRect -> its current Tween
var start_button: Button


func _ready() -> void:
	_build_fake_board()
	_build_button()
	_style_frame()
	_style_button()
	_start_shimmer()


# Call this to bring the overlay back later (e.g. before a new game).
func show_overlay() -> void:
	show()
	_start_shimmer()

# Call after changing any of the exported colors from code (e.g. a server theme).
func refresh_look() -> void:
	_style_frame()
	_style_button()


####### BUILDING (runs once, in _ready) ########
# Fake board: this panel is the dark frame, and the white tiles sit on top of it
# with small gaps, so the frame color shows through as the grid lines --
# the same trick the real board uses.
func _build_fake_board() -> void:
	var padding := MarginContainer.new()
	padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		padding.add_theme_constant_override(side, board_padding)
	add_child(padding)

	var boxes := GridContainer.new()
	boxes.columns = BOX_COLUMNS
	boxes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boxes.add_theme_constant_override("h_separation", box_gap)
	boxes.add_theme_constant_override("v_separation", box_gap)
	padding.add_child(boxes)

	for b in BOXES_TOTAL:
		var cells := GridContainer.new()
		cells.columns = CELL_COLUMNS_PER_BOX
		cells.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cells.add_theme_constant_override("h_separation", cell_gap)
		cells.add_theme_constant_override("v_separation", cell_gap)
		boxes.add_child(cells)
		for i in CELLS_PER_BOX:
			var tile := ColorRect.new()
			tile.color = cell_color
			tile.custom_minimum_size = cell_size
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cells.add_child(tile)
			shimmer_tiles.append(tile)

# The button layer: a PanelContainer stacks its children, so this CenterContainer
# covers the grid and floats the button in the middle of it.
func _build_button() -> void:
	var button_layer := CenterContainer.new()
	button_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE   # only the button catches taps
	add_child(button_layer)

	start_button = Button.new()
	start_button.text = BUTTON_TEXT
	start_button.focus_mode = Control.FOCUS_NONE              # no focus outline after tapping
	start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if play_icon:
		start_button.icon = play_icon
		start_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		start_button.add_theme_constant_override("icon_max_width", BUTTON_ICON_SIZE)
		start_button.add_theme_constant_override("h_separation", 8)
	start_button.pressed.connect(_on_start_button_pressed)
	button_layer.add_child(start_button)


####### STYLING ########
func _style_frame() -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = frame_color
	frame.set_corner_radius_all(frame_corner_radius)
	frame.anti_aliasing = true
	add_theme_stylebox_override("panel", frame)

func _style_button() -> void:
	var normal_style := _make_button_box(button_color, BUTTON_SHADOW_OFFSET)
	var pressed_style := _make_button_box(button_pressed_color, BUTTON_PRESSED_SHADOW_OFFSET)
	for state in ["normal", "hover"]:
		start_button.add_theme_stylebox_override(state, normal_style)
	for state in ["pressed", "hover_pressed"]:
		start_button.add_theme_stylebox_override(state, pressed_style)
	start_button.add_theme_font_override("font", BUTTON_FONT)
	start_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color",
			"font_hover_pressed_color", "font_focus_color"]:
		start_button.add_theme_color_override(color_name, button_text_color)

# One rounded, outlined box with a nearly hard-edged shadow.
func _make_button_box(fill_color: Color, shadow_offset: Vector2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill_color
	box.set_corner_radius_all(BUTTON_CORNER_RADIUS)
	box.set_border_width_all(BUTTON_OUTLINE_WIDTH)
	box.border_color = button_outline_color
	box.shadow_color = button_outline_color
	box.shadow_size = 1                 # 1 keeps the shadow almost hard-edged
	box.shadow_offset = shadow_offset
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	box.anti_aliasing = true
	return box


####### SHIMMER ########
func _start_shimmer() -> void:
	_stop_shimmer()
	for tile in shimmer_tiles:
		tile.color = _random_shimmer_shade()
		_shimmer_tile(tile)

# Fades one tile to a new random shade, then calls itself again when done (a loop).
# Every tile picks its own shades and speeds, so the board twinkles unevenly.
func _shimmer_tile(tile: ColorRect) -> void:
	var fade_seconds := randf_range(SHIMMER_MIN_TIME, SHIMMER_MAX_TIME)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(tile, "color", _random_shimmer_shade(), fade_seconds)
	tween.tween_callback(_shimmer_tile.bind(tile))
	tile_tweens[tile] = tween

func _stop_shimmer() -> void:
	for tween in tile_tweens.values():
		if tween.is_valid():
			tween.kill()
	tile_tweens.clear()

# A color somewhere between the resting color and shimmer_color. Squaring the
# random number makes pale shades more common than strong ones, which looks calmer.
func _random_shimmer_shade() -> Color:
	var strength := pow(randf(), 2.0)
	return cell_color.lerp(shimmer_color, strength)


####### BUTTON PRESS ########
func _on_start_button_pressed() -> void:
	_stop_shimmer()
	hide()
	start_pressed.emit()
