extends RefCounted

static func apply_panel(panel: Control, color: Color = Color("10151ee8"), border: Color = Color("667184")) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	panel.add_theme_stylebox_override("panel", style)

static func apply_button(button: Button, accent: bool = false) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("b98b54") if accent else Color("273140")
	normal.border_color = Color("e1b978") if accent else Color("566174")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	normal.content_margin_top = 9.0
	normal.content_margin_bottom = 9.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("d2a96e") if accent else Color("394659")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("8f693f") if accent else Color("1c2531")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("fff8ed"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("f4e8d5"))
	button.focus_mode = Control.FOCUS_ALL
