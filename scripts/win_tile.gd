class_name WinTile
extends Control
# A colored tile drawn on top of a cell during the "puzzle solved" wave.
# It's a rounded green square with the cell's number in white. The cell that
# owns it handles the animation (fading, and the slight crooked rotation).

# --- What the tile shows (set by the cell before the animation starts) ---
var tile_color := Color("#568503")
var text := ""
var text_color := Color.WHITE
var font: Font
var font_size := 32
var corner_radius := 3

var _tile_box := StyleBoxFlat.new()


func _draw() -> void:
	# Background: a rounded rectangle filling this control.
	_tile_box.bg_color = tile_color
	_tile_box.set_corner_radius_all(corner_radius)
	_tile_box.anti_aliasing = true
	draw_style_box(_tile_box, Rect2(Vector2.ZERO, size))

	# Number: centered on the tile.
	if font and text != "":
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		# draw_string places text by its baseline, so start at the top of the
		# centered text block and move down by the font's ascent.
		var top_left := (size - text_size) / 2.0
		var baseline := Vector2(top_left.x, top_left.y + font.get_ascent(font_size))
		draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
