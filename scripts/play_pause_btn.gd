extends Button

var is_paused := false
var empty_style := StyleBoxEmpty.new()

var base_color := Color("#bcae9284")
var bg_style := StyleBoxFlat.new()
var fade_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bg_style.bg_color = Color(base_color, 0.0)  # start invisible
	bg_style.corner_detail = 4
	bg_style.set_corner_radius_all(5)
	
	var play_icon: TextureRect = $PlayBtn/PlayIcon
	play_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	var pause_icon: TextureRect = $PauseBtn/PauseIcon
	pause_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	# Same stylebox for every state; its alpha decides what's visible
	add_theme_stylebox_override("normal", bg_style)
	add_theme_stylebox_override("hover", bg_style)
	add_theme_stylebox_override("pressed", bg_style)
	add_theme_stylebox_override("focus", empty_style)

	$PlayBtn.hide()
	pressed.connect(_toggle_pause)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _toggle_pause() -> void:
	is_paused = not is_paused
	if is_paused:
		$PauseBtn.hide()
		$PlayBtn.show()
	else:
		$PlayBtn.hide()
		$PauseBtn.show()
	
func _on_button_down() -> void:
	if fade_tween:
		fade_tween.kill()          # stop a fade already in progress
	bg_style.bg_color = base_color

func _on_button_up() -> void:
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(bg_style, "bg_color:a", 0.0, 0.3)  # fade over 0.3 s

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
