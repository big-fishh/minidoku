extends CanvasLayer

####### GLOBALS
var BUTTON_COLOR := Color("#A5C883") ## TODO: Replace with stuff from main
var BUTTON_PRESSED_COLOR := Color("#436318")
var button_style := StyleBoxFlat.new()
var button_pressed_style := StyleBoxFlat.new()
var total_time = 0
var show_time = true
var clock_state = true

const HINT_ICON := preload("res://assets/icons/hint.svg")
const NOTES_ICON := preload("res://assets/icons/notes.svg")
const UNDO_ICON := preload("res://assets/icons/undo.svg")
const RESET_ICON := preload("res://assets/icons/reset.svg")
const ERASE_ICON := preload("res://assets/icons/erase.svg")
const TIMER_VISIBLE_ICON := preload("res://assets/icons/open_eye.svg")
const TIMER_INVISIBLE_ICON := preload("res://assets/icons/closed_eye.svg")
const FONT_COLOR := Color("#2B2B2B")

# Keypad fonts: normal digits vs. handwritten digits while Notes mode is on
const KEYPAD_NORMAL_FONT := preload("res://assets/fonts/figtree-latin-700-normal.ttf")
const KEYPAD_NOTES_FONT := preload("res://assets/fonts/Caveat-Regular.ttf")

# Undo/Reset flash: fades in to this color, then back to invisible
const FLASH_COLOR := Color("#bcae9284")
const FLASH_IN_TIME := 0.08    # seconds to reach the flash color
const FLASH_OUT_TIME := 0.25   # seconds to fade back to nothing
const FLASH_CORNER_RADIUS := 5

@onready var keypad_buttons := $BottomMarginContainer/BottomUI/keypadAndTools/keypad.get_children()
@onready var notes_badge: Control = $BottomMarginContainer/BottomUI/tools/NotesButton/Button/Badge

# Each flashing button gets its own stylebox (so one button's flash doesn't
# affect another) and its own tween (so a quick double-tap restarts cleanly).
var flash_styles := {}   # Button -> StyleBoxFlat
var flash_tweens := {}   # Button -> Tween

####### SIGNALS
signal number_entered(value: int)
signal number_erased()
signal board_reset()
signal notes_toggled()
signal mode_requested(mode: GameMode.Mode)
signal undo_pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Configure keypad button node
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

	for i in keypad_buttons.size():
		var key_button: Button = keypad_buttons[i]
		key_button.text = str(i+1)
		key_button.add_theme_stylebox_override("normal", button_style)
		key_button.add_theme_stylebox_override("hover", button_style)
		key_button.add_theme_stylebox_override("focus", button_style)
		key_button.add_theme_stylebox_override("pressed", button_pressed_style)
		key_button.add_theme_color_override("font_focus_color", FONT_COLOR)
		key_button.add_theme_color_override("font_hover_color", FONT_COLOR)
		key_button.pressed.connect(_accept_puzzle_entry.bind(key_button.text))
	_set_keypad_font(KEYPAD_NORMAL_FONT)

	# Configure tool buttons
	var hint_button_icon: TextureRect = $BottomMarginContainer/BottomUI/tools/HintButton/HBoxContainer/TextureRect
	var hint_button_label: Label = $BottomMarginContainer/BottomUI/tools/HintButton/HBoxContainer/Label
	hint_button_icon.texture = HINT_ICON
	hint_button_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	hint_button_label.text = "Hint"
	var hint_badge: PanelContainer = $BottomMarginContainer/BottomUI/tools/HintButton/Button/Badge
	_place_badge(hint_badge, 0.80)
	hint_badge.hide()

	var notes_button_icon: TextureRect = $BottomMarginContainer/BottomUI/tools/NotesButton/HBoxContainer/TextureRect
	var notes_button_label: Label = $BottomMarginContainer/BottomUI/tools/NotesButton/HBoxContainer/Label
	notes_button_icon.texture = NOTES_ICON
	notes_button_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	notes_button_label.text = "Notes"
	_place_badge(notes_badge, 0.70)
	notes_badge.hide()

	var erase_button_icon: TextureRect = $BottomMarginContainer/BottomUI/tools/EraseButton/HBoxContainer/TextureRect
	var erase_button_label: Label = $BottomMarginContainer/BottomUI/tools/EraseButton/HBoxContainer/Label
	erase_button_icon.texture = ERASE_ICON
	erase_button_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	erase_button_label.text = "Erase"
	var erase_badge: PanelContainer = $BottomMarginContainer/BottomUI/tools/EraseButton/Button/Badge
	_place_badge(erase_badge, 0.75)
	erase_badge.hide()

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

	var daily_challenge_button: Button = $TopMarginContainer/TopUI/GameModesContainer/DailyChallengeBtn
	daily_challenge_button.pressed.connect(func(): mode_requested.emit(GameMode.Mode.DAILY))

	var unlimited_button: Button = $TopMarginContainer/TopUI/GameModesContainer/UnlimitedBtn
	unlimited_button.pressed.connect(func(): mode_requested.emit(GameMode.Mode.UNLIMITED))

	var view_timer_button: Button = $TopMarginContainer/TopUI/InfoBtnsContainer/RightGroup/TimerGroup/ViewTimerBtn
	view_timer_button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	var timer := $TopMarginContainer/TopUI/InfoBtnsContainer/RightGroup/TimerGroup/Timer
	#timer.start()

	#### CALLBACKS
	var erase_button: Button = $BottomMarginContainer/BottomUI/tools/EraseButton/Button
	erase_button.pressed.connect(_erase_puzzle_entry)

	var undo_button: Button = $BottomMarginContainer/BottomUI/keypadAndTools/tools/UndoButton/Button
	_setup_flash(undo_button)
	undo_button.pressed.connect(func():
		_flash(undo_button)
		undo_pressed.emit())

	var reset_button: Button = $BottomMarginContainer/BottomUI/keypadAndTools/tools/ResetButton/Button
	_setup_flash(reset_button)
	reset_button.pressed.connect(func():
		_flash(reset_button)
		_reset_board())

	var notes_button: Button = $BottomMarginContainer/BottomUI/tools/NotesButton/Button
	notes_button.pressed.connect(_toggle_notes)

	var hint_button: Button = $BottomMarginContainer/BottomUI/tools/HintButton/Button
	#hint_button.pressed.connect(get_hint) TODO: implement hints
	hint_button.pressed.connect(_toggle_badge.bind(hint_badge))

	var play_pause_button: Button = $TopMarginContainer/TopUI/InfoBtnsContainer/RightGroup/PlayPauseBtn
	play_pause_button.pressed.connect(_toggle_stopwatch)

	timer.timeout.connect(_on_timer_timeout)
	view_timer_button.pressed.connect(_toggle_time_label)

## User Input Functions
func _accept_puzzle_entry(value: String) -> void:
	number_entered.emit(int(value))

func _erase_puzzle_entry() -> void:
	number_erased.emit()

func _reset_board() -> void:
	board_reset.emit()

# Notes on  -> badge shows, keypad switches to the handwritten font.
# Notes off -> badge hides, keypad goes back to the normal font.
func _toggle_notes() -> void:
	_toggle_badge(notes_badge)
	var notes_mode_on := notes_badge.visible
	_set_keypad_font(KEYPAD_NOTES_FONT if notes_mode_on else KEYPAD_NORMAL_FONT)
	notes_toggled.emit()

### HELPERS
func _on_timer_timeout() -> void:
	total_time += 1
	_update_time_label()

func _update_time_label():
	var label := $TopMarginContainer/TopUI/InfoBtnsContainer/RightGroup/TimerGroup/Time
	@warning_ignore("integer_division")
	var minutes = total_time / 60
	var minutes_string = "0"+str(minutes) if minutes < 10 else str(minutes)
	var seconds = total_time % 60
	var seconds_string = "0"+str(seconds) if seconds < 10 else str(seconds)
	label.text = "{0}:{1}".format([minutes_string, seconds_string])

func show_mode(mode: GameMode.Mode):
	var daily_challenge_button: Button = $TopMarginContainer/TopUI/GameModesContainer/DailyChallengeBtn
	var unlimited_button: Button = $TopMarginContainer/TopUI/GameModesContainer/UnlimitedBtn
	if mode == GameMode.Mode.DAILY:
		unlimited_button.turn_off()
		daily_challenge_button.turn_on()
	elif mode == GameMode.Mode.UNLIMITED:
		daily_challenge_button.turn_off()
		unlimited_button.turn_on()

func _toggle_time_label() -> void:
	var view_timer_button: Button = $TopMarginContainer/TopUI/InfoBtnsContainer/RightGroup/TimerGroup/ViewTimerBtn
	var time_label := $TopMarginContainer/TopUI/InfoBtnsContainer/RightGroup/TimerGroup/Time
	show_time = not show_time
	if not show_time:
		view_timer_button.icon = TIMER_INVISIBLE_ICON
		time_label.hide()
	else:
		view_timer_button.icon = TIMER_VISIBLE_ICON
		time_label.show()

func _toggle_stopwatch() -> void:
	var timer := $TopMarginContainer/TopUI/InfoBtnsContainer/RightGroup/TimerGroup/Timer
	clock_state = not clock_state
	if not clock_state:
		timer.paused = true
	else:
		timer.paused = false

#### UI Stuff
func _place_badge(badge: Control, anchor_x: float) -> void:
	badge.anchor_left = anchor_x
	badge.anchor_right = anchor_x
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0

func _toggle_badge(badge: Control) -> void:
	if badge.visible:
		badge.hide()
	else:
		badge.show()

func stop_clock() -> void:
	var timer := $TopMarginContainer/TopUI/InfoBtnsContainer/RightGroup/TimerGroup/Timer
	timer.stop()

func start_clock() -> void:
	var timer := $TopMarginContainer/TopUI/InfoBtnsContainer/RightGroup/TimerGroup/Timer
	timer.start()

# Sets the digit font on all six keypad buttons.
func _set_keypad_font(font: Font) -> void:
	for key_button in keypad_buttons:
		key_button.add_theme_font_override("font", font)

# Gives a button its own see-through stylebox for every state.
# The flash works by animating this stylebox's transparency.
func _setup_flash(button: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(FLASH_COLOR, 0.0)   # start invisible
	style.set_corner_radius_all(FLASH_CORNER_RADIUS)
	style.corner_detail = 4
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	flash_styles[button] = style

# Fades the button's background up to FLASH_COLOR, then back to invisible.
func _flash(button: Button) -> void:
	var style: StyleBoxFlat = flash_styles[button]
	var old_tween: Tween = flash_tweens.get(button)
	if old_tween and old_tween.is_valid():
		old_tween.kill()

	var tween := create_tween()
	tween.tween_property(style, "bg_color:a", FLASH_COLOR.a, FLASH_IN_TIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(style, "bg_color:a", 0.0, FLASH_OUT_TIME).set_ease(Tween.EASE_IN)
	flash_tweens[button] = tween
