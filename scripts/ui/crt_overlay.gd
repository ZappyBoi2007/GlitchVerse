class_name CRTOverlay
extends Control

## Lightweight procedural CRT scanline and vignette overlay for GlitchVerse.
## Uses zero GPU shaders, runs effortlessly on Intel HD 620.

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		w = 1280.0
		h = 720.0

	# 1. Subtle horizontal scanline raster (every 3 pixels, faint 0.07 alpha)
	var scanline_color := Color(0.0, 0.0, 0.0, 0.07)
	for y in range(0, int(h), 3):
		draw_line(Vector2(0, y), Vector2(w, y), scanline_color, 1.0)

	# 2. Subtle corner crop ticks (clinical laboratory framing)
	var tick_color := Color(0.09, 0.22, 0.239, 0.45)
	# Top-Left
	draw_line(Vector2(24, 24), Vector2(60, 24), tick_color, 1.0)
	draw_line(Vector2(24, 24), Vector2(24, 60), tick_color, 1.0)
	# Top-Right
	draw_line(Vector2(w - 60, 24), Vector2(w - 24, 24), tick_color, 1.0)
	draw_line(Vector2(w - 24, 24), Vector2(w - 24, 60), tick_color, 1.0)
	# Bottom-Left
	draw_line(Vector2(24, h - 24), Vector2(60, h - 24), tick_color, 1.0)
	draw_line(Vector2(24, h - 24), Vector2(24, h - 60), tick_color, 1.0)
	# Bottom-Right
	draw_line(Vector2(w - 60, h - 24), Vector2(w - 24, h - 24), tick_color, 1.0)
	draw_line(Vector2(w - 24, h - 24), Vector2(w - 24, h - 60), tick_color, 1.0)
