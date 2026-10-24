extends Button

@export var is_on := true
var on_style := StyleBoxFlat.new()
var off_style := StyleBoxEmpty.new()
const STYLE_STATES := ["normal", "hover", "pressed", "hover_pressed", "focus"]
const FONT_COLORS := ["font_color", "font_hover_color", "font_pressed_color",
		"font_hover_pressed_color", "font_focus_color"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	on_style.bg_color = Color("2B2B2B")
	on_style.set_corner_radius_all(5)
	on_style.corner_detail = 4
	on_style.content_margin_left = 10
	on_style.content_margin_right = 10
	off_style.content_margin_left = 10
	off_style.content_margin_right = 10

	if is_on:
		turn_on()
	else:
		turn_off()

func turn_on() -> void:
	is_on = true
	_set_look(on_style, Color("#ffffff"))

func turn_off() -> void:
	is_on = false
	_set_look(off_style, Color("2B2B2B"))

func _set_look(style: StyleBox, text_color: Color) -> void:
	for state in STYLE_STATES:
		add_theme_stylebox_override(state, style)
	for c in FONT_COLORS:
		add_theme_color_override(c, text_color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
