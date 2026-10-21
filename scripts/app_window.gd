extends PanelContainer
## Lightweight in-game window (never creates or changes real OS windows).

var _dragging := false
var _drag_offset := Vector2.ZERO

func configure(title: String, message: String, window_size := Vector2(520, 300)) -> void:
	custom_minimum_size = window_size
	size = window_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", _panel_style(Color("f5f6f8"), Color("aeb7c4")))

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 0)
	add_child(layout)

	var titlebar := PanelContainer.new()
	titlebar.add_theme_stylebox_override("panel", _panel_style(Color("e3e8f0"), Color("c4ccd8")))
	titlebar.custom_minimum_size.y = 38
	titlebar.mouse_filter = Control.MOUSE_FILTER_STOP
	layout.add_child(titlebar)
	titlebar.gui_input.connect(_on_titlebar_input.bind(titlebar))

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	titlebar.add_child(title_row)

	var title_label := Label.new()
	title_label.text = title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color("182235"))
	title_label.add_theme_font_size_override("font_size", 14)
	title_row.add_child(title_label)

	var close_button := Button.new()
	close_button.text = "✕"
	close_button.tooltip_text = "Fermer"
	close_button.custom_minimum_size = Vector2(36, 28)
	close_button.pressed.connect(queue_free)
	title_row.add_child(close_button)

	var body := MarginContainer.new()
	body.add_theme_constant_override("margin_left", 18)
	body.add_theme_constant_override("margin_right", 18)
	body.add_theme_constant_override("margin_top", 16)
	body.add_theme_constant_override("margin_bottom", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	body.add_child(content)

	var text := Label.new()
	text.text = message
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_color_override("font_color", Color("263247"))
	content.add_child(text)

func _on_titlebar_input(event: InputEvent, _titlebar: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_drag_offset = get_global_mouse_position() - global_position
			move_to_front()
	elif event is InputEventMouseMotion and _dragging:
		global_position = get_global_mouse_position() - _drag_offset

func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
