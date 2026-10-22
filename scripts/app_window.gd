extends PanelContainer
## Lightweight in-game window (never creates or changes real OS windows).

const EDGE_RIGHT := 1
const EDGE_BOTTOM := 2
const EDGE_LEFT := 4
const EDGE_TOP := 8

var _dragging := false
var _drag_offset := Vector2.ZERO
var _is_maximized := false
var _restore_position := Vector2.ZERO
var _restore_size := Vector2.ZERO
var _snap_mode := ""
var _snap_layout_panel: PanelContainer
var _maximize_button: Button
var _resizing := false
var _resize_edges := 0
var _resize_start_mouse := Vector2.ZERO
var _resize_start_position := Vector2.ZERO
var _resize_start_size := Vector2.ZERO
var _drag_start_mouse := Vector2.ZERO
var _minimize_tween: Tween
var _resize_overlay: Control

func configure(title: String, message: String, window_size := Vector2(520, 300)) -> void:
	custom_minimum_size = window_size
	size = window_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var window_style := _panel_style(Color("f7f9fc"), Color("c8d2e2"))
	window_style.set_corner_radius_all(14)
	window_style.border_color = Color("d5ddeb")
	window_style.set_border_width_all(1)
	window_style.shadow_color = Color(0.02, 0.04, 0.10, 0.28)
	window_style.shadow_size = 20
	window_style.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("panel", window_style)
	z_index = 30

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 0)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(layout)

	# Keep resize hit areas in a dedicated overlay. Adding them directly to this
	# PanelContainer makes the container stretch each handle across the content.
	_resize_overlay = Control.new()
	_resize_overlay.name = "ResizeOverlay"
	_resize_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resize_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_resize_overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resize_overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_resize_overlay)

	var titlebar := PanelContainer.new()
	titlebar.name = "TitleBar"
	var titlebar_style := _panel_style(Color("eef3fa"), Color("d8e1ee"))
	titlebar_style.set_border_width_all(1)
	titlebar_style.border_width_bottom = 1
	titlebar_style.set_corner_radius_all(14)
	titlebar_style.corner_radius_bottom_left = 0
	titlebar_style.corner_radius_bottom_right = 0
	titlebar.add_theme_stylebox_override("panel", titlebar_style)
	titlebar.custom_minimum_size.y = 44
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

	var app_icon := PanelContainer.new()
	app_icon.custom_minimum_size = Vector2(24, 24)
	var icon_background := Color("0878d1")
	var icon_glyph := "▣"
	var normalized_title := title.to_lower()
	if normalized_title.contains("fichier") or normalized_title.contains("explorateur"):
		icon_background = Color("e6b43c")
		icon_glyph = "▰"
	elif normalized_title.contains("paramètre"):
		icon_background = Color("65758b")
		icon_glyph = "⚙"
	elif normalized_title.contains("ai"):
		icon_background = Color("7868d8")
		icon_glyph = "✧"
	elif normalized_title.contains("navigateur") or normalized_title.contains("browser"):
		icon_background = Color("2879d0")
		icon_glyph = "◎"
	elif normalized_title.contains("corbeille"):
		icon_background = Color("5a9fd8")
		icon_glyph = "▤"
	var app_icon_style := _panel_style(icon_background, icon_background)
	app_icon_style.set_corner_radius_all(6)
	app_icon_style.set_border_width_all(1)
	app_icon_style.border_color = Color(1, 1, 1, 0.42)
	app_icon.add_theme_stylebox_override("panel", app_icon_style)
	title_row.add_child(app_icon)
	var app_icon_glyph := Label.new()
	app_icon_glyph.text = icon_glyph
	app_icon_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_icon_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	app_icon_glyph.add_theme_color_override("font_color", Color.WHITE)
	app_icon.add_child(app_icon_glyph)

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
	minimize_button.custom_minimum_size = Vector2(44, 34)
	minimize_button.add_theme_color_override("font_color", Color("24344d"))
	minimize_button.add_theme_stylebox_override("normal", _panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
	minimize_button.add_theme_stylebox_override("hover", _panel_style(Color("dce6f4"), Color(0, 0, 0, 0)))
	minimize_button.add_theme_stylebox_override("pressed", _panel_style(Color("c8d8ec"), Color(0, 0, 0, 0)))
	minimize_button.pressed.connect(_animate_minimize)
	minimize_button.focus_mode = Control.FOCUS_NONE
	title_row.add_child(minimize_button)

	var maximize_button := Button.new()
	maximize_button.text = "□"
	maximize_button.tooltip_text = "Agrandir"
	maximize_button.custom_minimum_size = Vector2(44, 34)
	maximize_button.add_theme_color_override("font_color", Color("24344d"))
	maximize_button.add_theme_stylebox_override("normal", _panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
	maximize_button.add_theme_stylebox_override("hover", _panel_style(Color("dce6f4"), Color(0, 0, 0, 0)))
	maximize_button.add_theme_stylebox_override("pressed", _panel_style(Color("c8d8ec"), Color(0, 0, 0, 0)))
	_maximize_button = maximize_button
	maximize_button.pressed.connect(func():
		_toggle_maximize(maximize_button)
	)
	maximize_button.mouse_entered.connect(func():
		_show_snap_layouts(maximize_button)
	)
	maximize_button.mouse_exited.connect(_schedule_snap_layout_hide)
	maximize_button.focus_mode = Control.FOCUS_NONE
	title_row.add_child(maximize_button)

	var close_button := Button.new()
	close_button.text = "✕"
	close_button.tooltip_text = "Fermer"
	close_button.custom_minimum_size = Vector2(48, 34)
	close_button.add_theme_color_override("font_color", Color("24344d"))
	close_button.add_theme_stylebox_override("normal", _panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
	close_button.add_theme_stylebox_override("pressed", _panel_style(Color("a91f14"), Color(0, 0, 0, 0)))
	var close_hover := _panel_style(Color("c42b1c"), Color(0, 0, 0, 0))
	close_hover.set_corner_radius_all(5)
	close_button.add_theme_stylebox_override("hover", close_hover)
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
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART	text.add_theme_color_override("font_color", Color("263247"))
	content.add_child(text)

	_add_resize_handle(EDGE_LEFT, Control.CURSOR_HSIZE, Vector2(0, 48), Vector2(6, -6))
	_add_resize_handle(EDGE_RIGHT, Control.CURSOR_HSIZE, Vector2(0, 48), Vector2(6, -6))
	_add_resize_handle(EDGE_TOP, Control.CURSOR_VSIZE, Vector2(0, 0), Vector2(-6, 6))
	_add_resize_handle(EDGE_BOTTOM, Control.CURSOR_VSIZE, Vector2(0, 0), Vector2(-6, 6))
	_add_resize_handle(EDGE_LEFT | EDGE_TOP, Control.CURSOR_FDIAGSIZE, Vector2.ZERO, Vector2(14, 14))
	_add_resize_handle(EDGE_RIGHT | EDGE_TOP, Control.CURSOR_BDIAGSIZE, Vector2.ZERO, Vector2(14, 14))
	_add_resize_handle(EDGE_LEFT | EDGE_BOTTOM, Control.CURSOR_BDIAGSIZE, Vector2.ZERO, Vector2(14, 14))
	_add_resize_handle(EDGE_RIGHT | EDGE_BOTTOM, Control.CURSOR_FDIAGSIZE, Vector2(-14, -14), Vector2.ZERO)

func _add_resize_handle(edges: int, cursor_shape: Control.CursorShape, top_left: Vector2, bottom_right: Vector2) -> void:
	var handle := Control.new()
	handle.name = "ResizeHandle_%d" % edges
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	handle.mouse_default_cursor_shape = cursor_shape
	if (edges & EDGE_LEFT) != 0:
		handle.anchor_left = 0.0
		handle.anchor_right = 0.0
		handle.offset_left = 0.0
		handle.offset_right = 6.0
	elif (edges & EDGE_RIGHT) != 0:
		handle.anchor_left = 1.0
		handle.anchor_right = 1.0
		handle.offset_left = -6.0
		handle.offset_right = 0.0
	else:
		handle.anchor_left = 0.0
		handle.anchor_right = 1.0
		handle.offset_left = 6.0
		handle.offset_right = -6.0
	if (edges & EDGE_TOP) != 0:
		handle.anchor_top = 0.0
		handle.anchor_bottom = 0.0
		handle.offset_top = 0.0
		handle.offset_bottom = 6.0
	elif (edges & EDGE_BOTTOM) != 0:
		handle.anchor_top = 1.0
		handle.anchor_bottom = 1.0
		handle.offset_top = -6.0
		handle.offset_bottom = 0.0
	else:
		handle.anchor_top = 0.0
		handle.anchor_bottom = 1.0
		handle.offset_top = 48.0
		handle.offset_bottom = -6.0
	if (edges & (EDGE_LEFT | EDGE_RIGHT)) != 0 and (edges & (EDGE_TOP | EDGE_BOTTOM)) != 0:
		if (edges & EDGE_LEFT) != 0:
			handle.offset_left = 0.0
			handle.offset_right = 14.0
		else:
			handle.offset_left = -14.0
			handle.offset_right = 0.0
		if (edges & EDGE_TOP) != 0:
			handle.offset_top = 0.0
			handle.offset_bottom = 14.0
		else:
			handle.offset_top = -14.0
			handle.offset_bottom = 0.0
	handle.gui_input.connect(_on_resize_handle_input.bind(edges))
	_resize_overlay.add_child(handle)

func _on_resize_handle_input(event: InputEvent, edges: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_resizing = true
			_resize_edges = edges
			_resize_start_mouse = get_global_mouse_position()
			_resize_start_position = position
			_resize_start_size = size
			_restore_size = size
			_restore_position = position
			_is_maximized = false
			_snap_mode = ""
			move_to_front()
		else:
			_resizing = false
	elif event is InputEventMouseMotion and _resizing:
		var delta := get_global_mouse_position() - _resize_start_mouse
		var new_size := _resize_start_size
		var new_position := _resize_start_position
		if (_resize_edges & EDGE_RIGHT) != 0:
			new_size.x = maxf(280.0, _resize_start_size.x + delta.x)
		elif (_resize_edges & EDGE_LEFT) != 0:
			new_size.x = maxf(280.0, _resize_start_size.x - delta.x)
			new_position.x = _resize_start_position.x + _resize_start_size.x - new_size.x
		if (_resize_edges & EDGE_BOTTOM) != 0:
			new_size.y = maxf(180.0, _resize_start_size.y + delta.y)
		elif (_resize_edges & EDGE_TOP) != 0:
			new_size.y = maxf(180.0, _resize_start_size.y - delta.y)
			new_position.y = _resize_start_position.y + _resize_start_size.y - new_size.y
		var viewport_size := get_viewport_rect().size
		new_size.x = minf(new_size.x, maxf(280.0, viewport_size.x - maxf(0.0, new_position.x)))
		new_size.y = minf(new_size.y, maxf(180.0, viewport_size.y - maxf(0.0, new_position.y)))
		if (_resize_edges & EDGE_LEFT) != 0:
			new_position.x = _resize_start_position.x + _resize_start_size.x - new_size.x
		if (_resize_edges & EDGE_TOP) != 0:
			new_position.y = _resize_start_position.y + _resize_start_size.y - new_size.y
		position = new_position
		size = new_size

func _show_snap_layouts(button: Button) -> void:
	if not is_instance_valid(button) or not is_instance_valid(get_parent()):
		return
	if not is_instance_valid(_snap_layout_panel):
		_snap_layout_panel = PanelContainer.new()
		_snap_layout_panel.name = "SnapLayouts"
		_snap_layout_panel.z_index = 100
		var panel_style := _panel_style(Color(0.96, 0.97, 0.99, 0.99), Color("cbd5e3"))
		panel_style.set_corner_radius_all(10)
		panel_style.shadow_size = 16
		_snap_layout_panel.add_theme_stylebox_override("panel", panel_style)
		var margin := MarginContainer.new()
		for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
			margin.add_theme_constant_override(side, 6)
		_snap_layout_panel.add_child(margin)
		var layouts := GridContainer.new()
		layouts.columns = 2
		layouts.add_theme_constant_override("h_separation", 5)
		layouts.add_theme_constant_override("v_separation", 5)
		margin.add_child(layouts)
		_add_snap_option(layouts, "½ gauche", "left")
		_add_snap_option(layouts, "½ droite", "right")
		_add_snap_option(layouts, "¼ haut G", "top_left")
		_add_snap_option(layouts, "¼ haut D", "top_right")
		_add_snap_option(layouts, "¼ bas G", "bottom_left")
		_add_snap_option(layouts, "¼ bas D", "bottom_right")
		_add_snap_option(layouts, "⅔ gauche", "two_thirds_left")
		_add_snap_option(layouts, "⅓ droite", "one_third_right")
		_add_snap_option(layouts, "⅓ gauche", "one_third_left")
		_add_snap_option(layouts, "⅔ droite", "two_thirds_right")
		get_parent().add_child(_snap_layout_panel)
		_snap_layout_panel.mouse_exited.connect(_schedule_snap_layout_hide)
	_snap_layout_panel.visible = true
	var button_rect := button.get_global_rect()
	var viewport_size := get_viewport_rect().size
	var popup_size := _snap_layout_panel.get_combined_minimum_size()
	_snap_layout_panel.position = Vector2(
		clampf(button_rect.position.x + button_rect.size.x / 2.0 - popup_size.x / 2.0, 6.0, maxf(6.0, viewport_size.x - popup_size.x - 6.0)),
		clampf(button_rect.position.y + button_rect.size.y + 6.0, 6.0, maxf(6.0, viewport_size.y - popup_size.y - 6.0))
	)

func _add_snap_option(parent: GridContainer, caption: String, mode: String) -> void:
	var option := Button.new()
	option.text = caption
	option.custom_minimum_size = Vector2(96, 36)
	option.add_theme_font_size_override("font_size", 12)
	option.add_theme_color_override("font_color", Color("24344d"))
	option.add_theme_stylebox_override("normal", _panel_style(Color("edf2f8"), Color("d5dfec")))
	option.add_theme_stylebox_override("hover", _panel_style(Color("cfe2fa"), Color("8bb7e8")))
	option.focus_mode = Control.FOCUS_NONE
	option.pressed.connect(func():
		_apply_snap_layout(mode)
		if is_instance_valid(_snap_layout_panel):
			_snap_layout_panel.queue_free()
			_snap_layout_panel = null
	)
	parent.add_child(option)

func _schedule_snap_layout_hide() -> void:
	_hide_snap_layouts_if_outside()

func _hide_snap_layouts_if_outside() -> void:
	await get_tree().create_timer(0.35).timeout
	if not is_instance_valid(_snap_layout_panel):
		return
	var pointer := get_global_mouse_position()
	var over_button := is_instance_valid(_maximize_button) and _maximize_button.get_global_rect().has_point(pointer)
	var over_panel := _snap_layout_panel.get_global_rect().has_point(pointer)
	if not over_button and not over_panel:
		_snap_layout_panel.queue_free()
		_snap_layout_panel = null

func _apply_snap_layout(mode: String) -> void:
	var viewport_size := get_viewport_rect().size
	var full_width := viewport_size.x
	var full_height := viewport_size.y
	var left_width := full_width / 2.0
	var third_width := full_width / 3.0	_restore_size = size
	_restore_position = position
	_is_maximized = false
	_snap_mode = mode
	match mode:
		"left":
			position = Vector2.ZERO
			size = Vector2(left_width, full_height)
		"right":
			position = Vector2(left_width, 0)
			size = Vector2(left_width, full_height)
		"two_thirds_left":
			position = Vector2.ZERO
			size = Vector2(full_width * 2.0 / 3.0, full_height)
		"one_third_right":
			position = Vector2(full_width * 2.0 / 3.0, 0)
			size = Vector2(third_width, full_height)
		"one_third_left":
			position = Vector2.ZERO
			size = Vector2(third_width, full_height)
		"two_thirds_right":
			position = Vector2(third_width, 0)
			size = Vector2(full_width * 2.0 / 3.0, full_height)
		"top_left":
			position = Vector2.ZERO
			size = Vector2(left_width, full_height / 2.0)
		"top_right":
			position = Vector2(left_width, 0)
			size = Vector2(left_width, full_height / 2.0)
		"bottom_left":
			position = Vector2(0, full_height / 2.0)
			size = Vector2(left_width, full_height / 2.0)
		"bottom_right":
			position = Vector2(left_width, full_height / 2.0)
			size = Vector2(left_width, full_height / 2.0)
	if is_instance_valid(_maximize_button):
		_maximize_button.text = "□"
		_maximize_button.tooltip_text = "Dispositions Snap"

func _toggle_maximize(button: Button = null) -> void:
	if _is_maximized or _snap_mode != "":
		if _snap_mode == "maximized" or _is_maximized:
			size = _restore_size
			position = _restore_position
			_is_maximized = false
			_snap_mode = ""
		else:
			_snap_mode = ""
			_restore_size = size
			_restore_position = position
			size = get_viewport_rect().size
			position = Vector2.ZERO
			_is_maximized = true
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
		if event.pressed:
			_dragging = true
			_drag_start_mouse = get_global_mouse_position()
			_drag_offset = _drag_start_mouse - global_position
			move_to_front()
		else:
			var was_dragging := _dragging
			_dragging = false
			if was_dragging:
				_snap_to_edge(get_global_mouse_position())
	elif event is InputEventMouseMotion and _dragging:
		var pointer := get_global_mouse_position()
		if _is_maximized and pointer.distance_to(_drag_start_mouse) > 8.0:
			var restore_width := maxf(280.0, _restore_size.x)
			var horizontal_ratio := clampf(_drag_offset.x / maxf(size.x, 1.0), 0.1, 0.9)
			_is_maximized = false
			_snap_mode = ""
			size = _restore_size if _restore_size != Vector2.ZERO else Vector2(520, 300)
			_drag_offset = Vector2(restore_width * horizontal_ratio, 22.0)
			position = pointer - _drag_offset
		global_position = pointer - _drag_offset
		var viewport_size := get_viewport_rect().size
		position.x = clampf(position.x, -size.x + 120.0, viewport_size.x - 120.0)
		position.y = clampf(position.y, 0.0, viewport_size.y - 48.0)

func _snap_to_edge(pointer: Vector2) -> void:
	var viewport_size := get_viewport_rect().size
	const SNAP_MARGIN := 14.0
	var near_left := pointer.x <= SNAP_MARGIN
	var near_right := pointer.x >= viewport_size.x - SNAP_MARGIN
	var near_top := pointer.y <= SNAP_MARGIN
	var near_bottom := pointer.y >= viewport_size.y - SNAP_MARGIN
	if near_top and (near_left or near_right):
		if not _is_maximized and _snap_mode == "":
			_restore_size = size
			_restore_position = position
		size = viewport_size / 2.0
		position = Vector2.ZERO if near_left else Vector2(viewport_size.x / 2.0, 0.0)
		if not near_left:
			position.x = viewport_size.x / 2.0
		_is_maximized = false
		_snap_mode = "top_left" if near_left else "top_right"
	elif near_bottom and (near_left or near_right):
		if not _is_maximized and _snap_mode == "":
			_restore_size = size
			_restore_position = position
		size = viewport_size / 2.0
		position = Vector2(0.0, viewport_size.y / 2.0) if near_left else Vector2(viewport_size.x / 2.0, viewport_size.y / 2.0)
		_is_maximized = false
		_snap_mode = "bottom_left" if near_left else "bottom_right"
	elif near_top:
		if not _is_maximized and _snap_mode == "":
			_restore_size = size
			_restore_position = position
		size = viewport_size
		position = Vector2.ZERO
		_is_maximized = true
		_snap_mode = "maximized"
	elif near_left or near_right:
		if not _is_maximized and _snap_mode == "":
			_restore_size = size
			_restore_position = position
		size = Vector2(viewport_size.x / 2.0, viewport_size.y)
		position = Vector2.ZERO if near_left else Vector2(viewport_size.x / 2.0, 0.0)
		_is_maximized = false
		_snap_mode = "left" if near_left else "right"
	else:
		_snap_mode = ""

func _animate_minimize() -> void:
	if _minimize_tween and _minimize_tween.is_running():
		_minimize_tween.kill()
	_minimize_tween = create_tween().set_parallel(true)
	_minimize_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_minimize_tween.tween_property(self, "modulate:a", 0.0, 0.12)
	_minimize_tween.tween_property(self, "scale", Vector2(0.97, 0.97), 0.12)
	_minimize_tween.chain().tween_callback(func():
		hide()
		modulate.a = 1.0
		scale = Vector2.ONE
	)

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