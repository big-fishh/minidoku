extends Button

const ON_BG := Color("2B2B2B")
const ON_TEXT := Color("#ffffff")
const OFF_TEXT := Color("2B2B2B")
const FADE_TIME := 0.15   # seconds; try 0.1–0.15

const STYLE_STATES := ["normal", "hover", "pressed", "hover_pressed", "focus"]
const FONT_COLORS := ["font_color", "font_hover_color", "font_pressed_color",
		"font_hover_pressed_color", "font_focus_color"]

var on_style := StyleBoxFlat.new()
var off_style := StyleBoxEmpty.new()
var fade_tween: Tween

func _ready() -> void:
	on_style.bg_color = ON_BG
	on_style.set_corner_radius_all(5)
	on_style.corner_detail = 4
	on_style.content_margin_left = 10
	on_style.content_margin_right = 10
	off_style.content_margin_left = 10
	off_style.content_margin_right = 10
	turn_off()

func turn_on() -> void:
	_kill_fade()
	on_style.bg_color = Color(ON_BG, 0.0)        # start fully transparent
	_set_look(on_style, OFF_TEXT)                # start with the "off" text color

	fade_tween = create_tween().set_parallel()   # run both animations at once
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(on_style, "bg_color:a", 1.0, FADE_TIME)
	fade_tween.tween_method(_set_text_color, OFF_TEXT, ON_TEXT, FADE_TIME)

func turn_off() -> void:
	_kill_fade()                                 # stop a fade-in that's still running
	_set_look(off_style, OFF_TEXT)               # switch instantly

func _set_look(style: StyleBox, text_color: Color) -> void:
	for state in STYLE_STATES:
		add_theme_stylebox_override(state, style)
	_set_text_color(text_color)

func _set_text_color(color: Color) -> void:
	for c in FONT_COLORS:
		add_theme_color_override(c, color)

func _kill_fade() -> void:
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
