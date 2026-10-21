extends PanelContainer
## Lightweight in-game window (never creates or changes real OS windows).

var _dragging := false
var _drag_offset := Vector2.ZERO
var _is_maximized := false
var _restore_position := Vector2.ZERO
var _restore_size := Vector2.ZERO

func configure(title: String, message: String, window_size := Vector2(520, 300)) -> void:
	custom_minimum_size = window_size
	size = window_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var window_style := _panel_style(Color("f7f9fc"), Color("c8d2e2"))
	window_style.set_corner_radius_all(12)
	window_style.border_color = Color("d5ddeb")
	window_style.set_border_width_all(1)
	window_style.shadow_color = Color(0.02, 0.04, 0.10, 0.28)
	window_style.shadow_size = 18
	window_style.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("panel", window_style)
	z_index = 30

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 0)
	add_child(layout)

	var titlebar := PanelContainer.new()
	titlebar.name = "TitleBar"
	var titlebar_style := _panel_style(Color("eef3fa"), Color("eef3fa"))
	titlebar_style.set_corner_radius_all(12)
	titlebar_style.corner_radius_bottom_left = 0
	titlebar_style.corner_radius_bottom_right = 0
	titlebar.add_theme_stylebox_override("panel", titlebar_style)
	titlebar.custom_minimum_size.y = 42
	titlebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titlebar.mouse_filter = Control.MOUSE_FILTER_STOP
	layout.add_child(titlebar)
	titlebar.gui_input.connect(_on_titlebar_input.bind(titlebar))
	gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			move_to_front()
	)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	titlebar.add_child(title_row)

	var title_label := Label.new()
	title_label.text = title
	title_label.clip_text = true
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color("24344d"))
	title_label.add_theme_font_size_override("font_size", 13)
	title_row.add_child(title_label)

	var minimize_button := Button.new()
	minimize_button.text = "—"
	minimize_button.tooltip_text = "Réduire"
	minimize_button.custom_minimum_size = Vector2(36, 28)
	minimize_button.add_theme_color_override("font_color", Color("24344d"))
	minimize_button.add_theme_stylebox_override("normal", _panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
	minimize_button.add_theme_stylebox_override("hover", _panel_style(Color("dce6f4"), Color(0, 0, 0, 0)))
	minimize_button.pressed.connect(func(): hide())
	minimize_button.focus_mode = Control.FOCUS_NONE
	title_row.add_child(minimize_button)

	var maximize_button := Button.new()
	maximize_button.text = "□"
	maximize_button.tooltip_text = "Agrandir"
	maximize_button.custom_minimum_size = Vector2(36, 28)
	maximize_button.add_theme_color_override("font_color", Color("24344d"))
	maximize_button.add_theme_stylebox_override("normal", _panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
	maximize_button.add_theme_stylebox_override("hover", _panel_style(Color("dce6f4"), Color(0, 0, 0, 0)))
	maximize_button.pressed.connect(func():
		_toggle_maximize(maximize_button)
	)
	maximize_button.focus_mode = Control.FOCUS_NONE
	title_row.add_child(maximize_button)

	var close_button := Button.new()
	close_button.text = "✕"
	close_button.tooltip_text = "Fermer"
	close_button.custom_minimum_size = Vector2(44, 28)
	close_button.add_theme_color_override("font_color", Color("24344d"))
	close_button.add_theme_stylebox_override("normal", _panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
	close_button.add_theme_stylebox_override("hover", _panel_style(Color("c42b1c"), Color(0, 0, 0, 0)))
	close_button.add_theme_color_override("font_hover_color", Color.WHITE)
	close_button.pressed.connect(queue_free)
	close_button.focus_mode = Control.FOCUS_NONE
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

func _toggle_maximize(button: Button = null) -> void:
	if _is_maximized:
		size = _restore_size
		position = _restore_position
		_is_maximized = false
	else:
		_restore_size = size
		_restore_position = position
		size = get_viewport_rect().size
		position = Vector2.ZERO
		_is_maximized = true
	if is_instance_valid(button):
		button.text = "❐" if _is_maximized else "□"
		button.tooltip_text = "Restaurer" if _is_maximized else "Agrandir"

func _on_titlebar_input(event: InputEvent, _titlebar: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		_dragging = false
		_toggle_maximize()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_drag_offset = get_global_mouse_position() - global_position
			move_to_front()
	elif event is InputEventMouseMotion and _dragging:
		global_position = get_global_mouse_position() - _drag_offset
		var viewport_size := get_viewport_rect().size
		position.x = clampf(position.x, -size.x + 120.0, viewport_size.x - 120.0)
		position.y = clampf(position.y, 0.0, viewport_size.y - 48.0)

func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.02, 0.04, 0.08, 0.22)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
