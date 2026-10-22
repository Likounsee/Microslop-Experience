extends Control
## First playable shell for Microslop Experience.
## All windows and system behaviour are simulated inside the game.

# Load the simulated window script at runtime so a missing/corrupt local
# copy does not prevent the desktop shell itself from starting.
const APP_WINDOW_SCRIPT_PATH := "res://scripts/app_window.gd"
const TASKBAR_HEIGHT := 54

var _window_layer: Control
var _taskbar: PanelContainer
var _start_menu: PanelContainer
var _notification_layer: VBoxContainer
var _clock_label: Label
var _tray_button: Button
var _clock_button: Button
var _calendar_panel: PanelContainer
var _calendar_today_label: Label
var _calendar_short_date_label: Label
var _quick_settings_panel: PanelContainer
var _quick_status_label: Label
var _quick_toggle_states: Dictionary = {"Wi-Fi": true, "Bluetooth": true, "Mode avion": false, "Éclairage nocturne": false}
var _quick_toggle_buttons: Dictionary = {}
var _start_open := false
var _mission_label: Label
var _mission_step := 0
var _clock_refresh_elapsed := 0.0
var _start_menu_tween: Tween
var _quick_settings_tween: Tween
var _calendar_tween: Tween
var _notification_tween: Tween
var _wallpaper: TextureRect
var _wallpaper_brightness := 1.0
var _desktop_icons: VBoxContainer
var _desktop_context_menu: PanelContainer
var _desktop_icon_context_menu: PanelContainer
var _context_desktop_icon: Button
var _quick_link_menu: PanelContainer
var _task_view_panel: PanelContainer
var _taskbar_preview: PanelContainer
var _taskbar_preview_tween: Tween
var _taskbar_marker_tweens: Dictionary = {}
var _pinned_buttons: Array[Button] = []
var _pinned_empty_label: Label
var _pinned_heading_label: Label
var _all_apps_button: Button
var _start_search: LineEdit
var _all_apps_view := false
var _pinned_grid: GridContainer
var _all_apps_list: VBoxContainer
var _all_apps_entries: Array[Button] = []
var _all_apps_empty_label: Label
var _recommended_card: PanelContainer
var _recommended_heading: Label
var _recommended_recent_label: Label
var _recommended_recent_icon: Label
var _recent_app_title := ""
var _recent_app_message := ""
var _recent_app_size := Vector2(520, 300)
var _taskbar_app_buttons: Dictionary = {}
var _active_app_id := ""
var _notification_center: PanelContainer
var _notification_history: Array[Dictionary] = []
var _desktop_hidden_windows: Array[Control] = []
var _show_desktop_active := false

func _notification(what: int) -> void:

	if what == NOTIFICATION_RESIZED and is_instance_valid(_start_menu):

		_layout_shell_for_viewport()

func _layout_shell_for_viewport() -> void:

	var viewport_size := get_viewport_rect().size

	if is_instance_valid(_taskbar):

		var taskbar_width := minf(820.0, maxf(280.0, viewport_size.x - 24.0))

		# Keep the centered taskbar usable on compact windows instead of letting

		# the search pill collide with pinned apps and the system tray.

		var search_button := _taskbar.find_child("TaskbarSearchButton", true, false) as Button

		if is_instance_valid(search_button):

			search_button.visible = viewport_size.x >= 720.0

		# Prioritize the core pinned apps on narrow windows instead of letting
		# the centered app group collide with the system tray.
		var settings_button := _taskbar_app_buttons.get("settings") as Button
		if is_instance_valid(settings_button):
			settings_button.visible = viewport_size.x >= 600.0
		var update_button := _taskbar_app_buttons.get("update") as Button
		if is_instance_valid(update_button):
			update_button.visible = viewport_size.x >= 700.0

		var tray_row := _taskbar.find_child("SystemTray", true, false) as HBoxContainer
		if is_instance_valid(tray_row):
			var tray_button := _tray_button
			var clock_button := _clock_button
			var compact_tray := viewport_size.x < 440.0
			if is_instance_valid(tray_button):
				tray_button.custom_minimum_size.x = 48.0 if compact_tray else 66.0
				tray_button.text = "⌃  🔊" if compact_tray else "⌃  ◉  ◖  🔊"
			if is_instance_valid(clock_button):
				clock_button.custom_minimum_size.x = 76.0 if compact_tray else 92.0
			var show_desktop_button := tray_row.find_child("ShowDesktopButton", true, false) as Button
			if is_instance_valid(show_desktop_button):
				show_desktop_button.visible = viewport_size.x >= 440.0
			tray_row.offset_left = -132.0 if compact_tray else -202.0

		_taskbar.offset_left = -taskbar_width / 2.0

		_taskbar.offset_right = taskbar_width / 2.0

		_taskbar.offset_top = -70.0

		_taskbar.offset_bottom = -10.0

	if is_instance_valid(_start_menu):

		var menu_width := minf(620.0, maxf(260.0, viewport_size.x - 24.0))

		var menu_height := minf(520.0, maxf(220.0, viewport_size.y - 96.0))

		_start_menu.offset_left = -menu_width / 2.0

		_start_menu.offset_right = menu_width / 2.0

		_start_menu.offset_top = -(menu_height + TASKBAR_HEIGHT + 12.0)

		_start_menu.offset_bottom = -(TASKBAR_HEIGHT + 12.0)

		if is_instance_valid(_pinned_grid):

			# Windows 11 uses a dense pinned-app grid on full-size Start menus.
			# Keep a two-column layout only when the available width is compact.
			_pinned_grid.columns = 6 if menu_width >= 560.0 else 2

			var button_width := maxf(76.0, (menu_width - 64.0 - float(_pinned_grid.columns - 1) * 8.0) / float(_pinned_grid.columns)

			for pinned_button in _pinned_grid.get_children():

				if pinned_button is Control:

					pinned_button.custom_minimum_size.x = button_width

		if is_instance_valid(_all_apps_button):

			_all_apps_button.text = "Tous  ›"

	if is_instance_valid(_calendar_panel):

		var calendar_width := minf(340.0, maxf(260.0, viewport_size.x - 24.0))

		var calendar_height := minf(360.0, maxf(200.0, viewport_size.y - 96.0))

		_calendar_panel.offset_left = -calendar_width - 12.0

		_calendar_panel.offset_right = -12.0

		_calendar_panel.offset_top = -(calendar_height + 76.0)

		_calendar_panel.offset_bottom = -76.0

	if is_instance_valid(_quick_settings_panel):

		var panel_width := minf(336.0, maxf(260.0, viewport_size.x - 24.0))

		var panel_height := minf(420.0, maxf(220.0, viewport_size.y - 96.0))

		_quick_settings_panel.offset_left = -panel_width - 12.0

		_quick_settings_panel.offset_right = -12.0

		_quick_settings_panel.offset_top = -(panel_height + 76.0)

		_quick_settings_panel.offset_bottom = -76.0
		var quick_tiles := _quick_settings_panel.find_child("QuickSettingsTiles", true, false) as GridContainer
		if is_instance_valid(quick_tiles):
			var tile_width := maxf(100.0, (panel_width - 48.0) / 2.0)
			for quick_tile in quick_tiles.get_children():
				if quick_tile is Control:
					quick_tile.custom_minimum_size.x = tile_width

	if is_instance_valid(_task_view_panel):
		var task_view_width := minf(720.0, maxf(280.0, viewport_size.x - 24.0))
		var task_view_height := minf(440.0, maxf(220.0, viewport_size.y - 96.0))
		_task_view_panel.custom_minimum_size = Vector2(task_view_width, 0)
		_task_view_panel.offset_left = -task_view_width / 2.0
		_task_view_panel.offset_right = task_view_width / 2.0
		_task_view_panel.offset_top = -task_view_height / 2.0
		_task_view_panel.offset_bottom = task_view_height / 2.0
		var task_grid := _task_view_panel.find_child("TaskViewGrid", true, false) as GridContainer
		if is_instance_valid(task_grid):
			task_grid.columns = 2 if viewport_size.x >= 620.0 else 1
			for task_card in task_grid.get_children():
				if task_card is Control:
					task_card.custom_minimum_size.x = 245.0 if task_grid.columns == 2 else task_view_width - 64.0

	if is_instance_valid(_notification_center):

		var notification_width := minf(360.0, maxf(260.0, viewport_size.x - 24.0))

		var notification_height := minf(430.0, maxf(220.0, viewport_size.y - 96.0))

		_notification_center.offset_left = -notification_width - 12.0

		_notification_center.offset_right = -12.0

		_notification_center.offset_top = -(notification_height + 76.0)

		_notification_center.offset_bottom = -76.0

func _ready() -> void:

	_load_progress()

	_build_desktop()

	# Reflow shell panels whenever the game window or display resolution changes.
	get_viewport().size_changed.connect(_layout_shell_for_viewport)

	SettingsStore.apply_display_settings()

	SettingsStore.apply_audio_settings()

	_show_notification("Bienvenue", "Votre expérience Microslop est prête. Vous n'avez rien demandé, mais nous avons tout activé.")

	_update_mission()

func _build_desktop() -> void:

	# Use the wallpaper supplied in the repository instead of a generated placeholder.

	_wallpaper = TextureRect.new()

	var wallpaper := _wallpaper

	wallpaper.name = "DesktopWallpaper"

	wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	wallpaper.texture = load("res://assets/wallpaper.jpg") as Texture2D

	add_child(wallpaper)


	_desktop_icons = VBoxContainer.new()

	var desktop_icons := _desktop_icons

	desktop_icons.name = "DesktopIcons"

	desktop_icons.position = Vector2(24, 84)

	desktop_icons.add_theme_constant_override("separation", 14)

	add_child(desktop_icons)

	_add_desktop_icon(desktop_icons, "🗑", "Corbeille", _open_recycle_bin)

	_add_desktop_icon(desktop_icons, "🌐", "Microslop Browser", _open_browser)

	_add_desktop_icon(desktop_icons, "📁", "Fichiers", _open_files)


	_window_layer = Control.new()

	_window_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_window_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(_window_layer)


	_build_notification_layer()

	_build_taskbar()

	_build_notification_center()

	_build_start_menu()

	_build_quick_settings()

	_build_calendar_panel()

	_build_mission_hint()

	_layout_shell_for_viewport()

func _add_desktop_icon(parent: VBoxContainer, glyph: String, caption: String, callback: Callable) -> void:

	var button := Button.new()

	button.custom_minimum_size = Vector2(104, 92)

	button.tooltip_text = "%s — double-cliquez pour ouvrir" % caption
	button.set_meta("desktop_caption", caption)
	button.set_meta("desktop_open_callback", callback)

	button.add_theme_color_override("font_color", Color.WHITE)

	button.add_theme_stylebox_override("normal", _flat_style(Color(0.1, 0.2, 0.38, 0.0), 7))

	button.add_theme_stylebox_override("hover", _flat_style(Color(0.55, 0.7, 0.95, 0.22), 7))

	button.add_theme_stylebox_override("pressed", _flat_style(Color(0.35, 0.55, 0.88, 0.42), 7))

	button.focus_mode = Control.FOCUS_NONE

	var content := VBoxContainer.new()

	content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	content.alignment = BoxContainer.ALIGNMENT_CENTER

	content.add_theme_constant_override("separation", 5)

	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	button.add_child(content)

	var icon_tile := PanelContainer.new()

	icon_tile.custom_minimum_size = Vector2(40, 40)

	icon_tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var tile_color := Color("2879d0")
	var glyph_color := Color.WHITE

	match caption:
		"Corbeille":
			tile_color = Color("dceeff")
			glyph_color = Color("2879d0")
		"Fichiers":
			tile_color = Color("fff0c9")
			glyph_color = Color("a97810")
		"Paramètres":
			tile_color = Color("e8edf3")
			glyph_color = Color("65758b")
		"Microslop AI":
			tile_color = Color("eee8ff")
			glyph_color = Color("7860c8")

	var icon_style := _flat_style(tile_color, 10)
	icon_style.set_border_width_all(1)
	icon_style.border_color = Color(1, 1, 1, 0.78)
	icon_style.shadow_color = Color(0.02, 0.06, 0.14, 0.20)
	icon_style.shadow_size = 5
	icon_style.shadow_offset = Vector2(0, 2)
	icon_tile.add_theme_stylebox_override("panel", icon_style)

	button.mouse_entered.connect(func():
		var icon_tween := create_tween()
		icon_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		icon_tween.tween_property(icon_tile, "scale", Vector2(1.06, 1.06), 0.10)
	)
	button.mouse_exited.connect(func():
		var icon_tween := create_tween()
		icon_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		icon_tween.tween_property(icon_tile, "scale", Vector2.ONE, 0.12)
	)

	content.add_child(icon_tile)

	var icon_label := Label.new()

	icon_label.text = glyph

	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	icon_label.add_theme_font_size_override("font_size", 22)

	icon_label.add_theme_color_override("font_color", glyph_color)

	icon_tile.add_child(icon_label)

	var caption_label := Label.new()

	caption_label.text = caption

	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	caption_label.add_theme_font_size_override("font_size", 11)

	caption_label.add_theme_color_override("font_color", Color.WHITE)

	caption_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))

	caption_label.add_theme_constant_override("shadow_offset_x", 1)
	caption_label.add_theme_constant_override("shadow_offset_y", 1)

	content.add_child(caption_label)

	button.pressed.connect(func():

		for sibling in parent.get_children():

			if sibling is Button:
				sibling.add_theme_stylebox_override("normal", _flat_style(Color(0.1, 0.2, 0.38, 0.0), 7))
		button.add_theme_stylebox_override("normal", _flat_style(Color(0.35, 0.55, 0.88, 0.36), 7))

	)

	button.gui_input.connect(func(event: InputEvent):

		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:

			callback.call()

			button.accept_event()

	)

	parent.add_child(button)

func _build_taskbar() -> void:

	# Floating, centered taskbar inspired by Windows 11.

	_taskbar = PanelContainer.new()

	var taskbar := _taskbar

	taskbar.name = "FloatingTaskbar"

	taskbar.anchor_left = 0.5

	taskbar.anchor_top = 1.0

	taskbar.anchor_right = 0.5

	taskbar.anchor_bottom = 1.0

	taskbar.offset_left = -410

	taskbar.offset_right = 410

	taskbar.offset_top = -72

	taskbar.offset_bottom = -12

	var panel_style := _flat_style(Color(0.88, 0.92, 0.98, 0.76), 16)

	panel_style.shadow_color = Color(0.02, 0.04, 0.10, 0.28)

	panel_style.shadow_size = 18

	panel_style.shadow_offset = Vector2(0, 4)

	panel_style.set_border_width_all(1)

	panel_style.border_color = Color(1, 1, 1, 0.78)

	taskbar.add_theme_stylebox_override("panel", panel_style)

	add_child(taskbar)


	# Split the taskbar into a genuinely centered app group and a separate

	# right-aligned system tray, as in Windows 11. A single HBox shifts the

	# Start/search/pinned group left because the tray occupies extra width.

	var taskbar_content := Control.new()

	taskbar_content.name = "TaskbarContent"

	taskbar_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	taskbar_content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	taskbar.add_child(taskbar_content)


	var center_group := CenterContainer.new()

	center_group.name = "CenteredAppGroup"

	center_group.anchor_left = 0.5

	center_group.anchor_right = 0.5

	center_group.anchor_top = 0.0

	center_group.anchor_bottom = 1.0

	center_group.offset_left = -260

	center_group.offset_right = 260

	center_group.mouse_filter = Control.MOUSE_FILTER_IGNORE

	taskbar_content.add_child(center_group)


	var row := HBoxContainer.new()

	row.name = "CenteredTaskbarApps"

	row.add_theme_constant_override("separation", 5)

	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	center_group.add_child(row)


	var start_button := Button.new()

	start_button.text = ""

	start_button.tooltip_text = "Démarrer"

	start_button.custom_minimum_size = Vector2(42, 42)

	start_button.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 9))

	start_button.add_theme_stylebox_override("hover", _flat_style(Color(0.78, 0.86, 0.96, 0.72), 9))

	start_button.pressed.connect(_toggle_start_menu)

	start_button.focus_mode = Control.FOCUS_NONE

	var windows_logo := GridContainer.new()

	windows_logo.columns = 2

	windows_logo.add_theme_constant_override("h_separation", 2)

	windows_logo.add_theme_constant_override("v_separation", 2)

	windows_logo.anchor_left = 0.5

	windows_logo.anchor_top = 0.5

	windows_logo.anchor_right = 0.5

	windows_logo.anchor_bottom = 0.5

	windows_logo.offset_left = -9

	windows_logo.offset_top = -9

	windows_logo.offset_right = 9

	windows_logo.offset_bottom = 9

	windows_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for i in range(4):

		var pane := ColorRect.new()

		pane.color = Color("0878d1")

		pane.custom_minimum_size = Vector2(8, 8)

		pane.mouse_filter = Control.MOUSE_FILTER_IGNORE

		windows_logo.add_child(pane)

	start_button.add_child(windows_logo)

	start_button.mouse_entered.connect(func():

		var logo_tween := create_tween()

		logo_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		logo_tween.tween_property(windows_logo, "scale", Vector2(1.10, 1.10), 0.12)

	)

	start_button.mouse_exited.connect(func():

		var logo_tween := create_tween()

		logo_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		logo_tween.tween_property(windows_logo, "scale", Vector2.ONE, 0.14)

	)

	row.add_child(start_button)


	var search_button := Button.new()

	search_button.name = "TaskbarSearchButton"

	search_button.text = "⌕  Rechercher"

	search_button.tooltip_text = "Rechercher des applications et des paramètres"

	search_button.custom_minimum_size = Vector2(156, 42)

	search_button.add_theme_font_size_override("font_size", 13)

	search_button.add_theme_color_override("font_color", Color("24344d"))

	search_button.add_theme_stylebox_override("normal", _flat_style(Color(1, 1, 1, 0.72), 11))

	search_button.add_theme_stylebox_override("hover", _flat_style(Color(1, 1, 1, 0.98), 11))

	search_button.add_theme_stylebox_override("pressed", _flat_style(Color("dce9f8"), 11))

	search_button.pressed.connect(_open_search)

	search_button.focus_mode = Control.FOCUS_NONE

	row.add_child(search_button)


	_add_taskbar_app(row, "◎", "Microslop Browser", _open_browser, "browser")

	_add_taskbar_app(row, "▤", "Explorateur de fichiers", _open_files, "files")

	_add_taskbar_app(row, "⚙", "Paramètres", _open_settings, "settings")

	_add_taskbar_app(row, "↻", "Mise à jour", _trigger_update, "update")


	var tray_row := HBoxContainer.new()

	tray_row.name = "SystemTray"

	tray_row.anchor_left = 1.0

	tray_row.anchor_right = 1.0

	tray_row.anchor_top = 0.0

	tray_row.anchor_bottom = 1.0

	tray_row.offset_left = -202

	tray_row.offset_right = -4

	tray_row.add_theme_constant_override("separation", 2)

	tray_row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	taskbar_content.add_child(tray_row)


	_tray_button = Button.new()

	_tray_button.text = "⌃  ◉  ◖  🔊"

	_tray_button.tooltip_text = "Paramètres rapides"

	_tray_button.custom_minimum_size = Vector2(66, 48)

	_tray_button.add_theme_font_size_override("font_size", 11)

	_tray_button.add_theme_color_override("font_color", Color("24344d"))

	_tray_button.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 9))

	_tray_button.add_theme_stylebox_override("hover", _flat_style(Color(0.78, 0.86, 0.96, 0.72), 9))

	_tray_button.pressed.connect(_toggle_quick_settings)

	_tray_button.focus_mode = Control.FOCUS_NONE

	tray_row.add_child(_tray_button)


	_clock_button = Button.new()

	_clock_button.text = "%s\n%s" % [Time.get_time_string_from_system().substr(0, 5), _get_short_french_date()]

	_clock_button.tooltip_text = "Calendrier et notifications"

	_clock_button.custom_minimum_size = Vector2(92, 48)

	_clock_button.add_theme_font_size_override("font_size", 11)

	_clock_button.add_theme_color_override("font_color", Color("24344d"))

	_clock_button.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 9))

	_clock_button.add_theme_stylebox_override("hover", _flat_style(Color(0.78, 0.86, 0.96, 0.72), 9))

	_clock_button.pressed.connect(_toggle_calendar)

	_clock_button.focus_mode = Control.FOCUS_NONE

	tray_row.add_child(_clock_button)


	var show_desktop := Button.new()

	show_desktop.name = "ShowDesktopButton"

	show_desktop.tooltip_text = "Afficher le bureau"

	show_desktop.custom_minimum_size = Vector2(7, 42)

	show_desktop.add_theme_stylebox_override("normal", _flat_style(Color(0.20, 0.29, 0.42, 0.24), 2))

	show_desktop.add_theme_stylebox_override("hover", _flat_style(Color("8fb9eb"), 2))

	show_desktop.add_theme_stylebox_override("pressed", _flat_style(Color("4389d5"), 2))

	show_desktop.focus_mode = Control.FOCUS_NONE

	show_desktop.pressed.connect(_toggle_show_desktop)

	tray_row.add_child(show_desktop)

func _toggle_show_desktop() -> void:

	if not is_instance_valid(_window_layer):

		return

	if not _show_desktop_active:

		_desktop_hidden_windows.clear()

		for child in _window_layer.get_children():

			if child is Control and child.visible:

				_desktop_hidden_windows.append(child as Control)

				child.hide()

		_show_desktop_active = true

		_active_app_id = ""

	else:

		for app in _desktop_hidden_windows:

			if is_instance_valid(app):

				app.call("restore_from_taskbar")

		_desktop_hidden_windows.clear()

		_show_desktop_active = false

	_update_taskbar_indicators()

func _build_calendar_panel() -> void:

	_calendar_panel = PanelContainer.new()

	_calendar_panel.name = "CalendarPanel"

	_calendar_panel.anchor_left = 1.0

	_calendar_panel.anchor_right = 1.0

	_calendar_panel.anchor_top = 1.0

	_calendar_panel.anchor_bottom = 1.0

	_calendar_panel.offset_left = -340

	_calendar_panel.offset_right = -12

	_calendar_panel.offset_top = -420

	_calendar_panel.offset_bottom = -76

	_calendar_panel.visible = false

	var panel_style := _flat_style(Color(0.94, 0.96, 0.99, 0.98), 18)

	panel_style.shadow_color = Color(0.02, 0.04, 0.10, 0.30)

	panel_style.shadow_size = 20

	panel_style.shadow_offset = Vector2(0, 5)

	panel_style.set_border_width_all(1)

	panel_style.border_color = Color(1, 1, 1, 0.82)

	_calendar_panel.add_theme_stylebox_override("panel", panel_style)

	add_child(_calendar_panel)


	var margin := MarginContainer.new()

	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:

		margin.add_theme_constant_override(side, 18)

	_calendar_panel.add_child(margin)

	var layout := VBoxContainer.new()

	layout.add_theme_constant_override("separation", 12)

	margin.add_child(layout)


	var heading := Label.new()
	heading.text = "Calendrier"

	heading.add_theme_font_size_override("font_size", 18)

	heading.add_theme_color_override("font_color", Color("1d2a40"))

	layout.add_child(heading)

	_calendar_today_label = Label.new()
	_calendar_today_label.text = _get_french_long_date()
	_calendar_today_label.add_theme_font_size_override("font_size", 25)
	_calendar_today_label.add_theme_color_override("font_color", Color("1d2a40"))
	layout.add_child(_calendar_today_label)

	var divider := HSeparator.new()
	layout.add_child(divider)

	var agenda_heading := Label.new()
	agenda_heading.text = "Aujourd’hui"
	agenda_heading.add_theme_font_size_override("font_size", 14)
	agenda_heading.add_theme_color_override("font_color", Color("24344d"))
	layout.add_child(agenda_heading)

	var agenda_card := PanelContainer.new()
	agenda_card.add_theme_stylebox_override("panel", _flat_style(Color("e5edf8"), 12))
	var agenda_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		agenda_margin.add_theme_constant_override(side, 12)
	agenda_card.add_child(agenda_margin)
	var agenda_layout := VBoxContainer.new()
	agenda_layout.add_theme_constant_override("separation", 5)
	agenda_margin.add_child(agenda_layout)

	var agenda_icon := Label.new()
	agenda_icon.text = "☼  Agenda"
	agenda_icon.add_theme_font_size_override("font_size", 12)
	agenda_icon.add_theme_color_override("font_color", Color("365b8d"))
	agenda_layout.add_child(agenda_icon)

	var agenda := Label.new()
	agenda.text = "Aucun événement prévu.\nProfitez de ce moment sans réunion."
	agenda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	agenda.add_theme_color_override("font_color", Color("596780"))
	agenda_layout.add_child(agenda)
	layout.add_child(agenda_card)

	var calendar_footer := HBoxContainer.new()
	calendar_footer.add_theme_constant_override("separation", 8)
	_calendar_short_date_label = Label.new()
	_calendar_short_date_label.text = _get_short_french_date()
	_calendar_short_date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_calendar_short_date_label.add_theme_color_override("font_color", Color("596780"))
	_calendar_short_date_label.add_theme_font_size_override("font_size", 11)
	calendar_footer.add_child(_calendar_short_date_label)

	var notifications_button := Button.new()
	notifications_button.text = "Notifications  ›"
	notifications_button.custom_minimum_size.y = 34
	notifications_button.add_theme_color_override("font_color", Color("24344d"))
	notifications_button.add_theme_stylebox_override("normal", _flat_style(Color("e1eaf7"), 9))
	notifications_button.add_theme_stylebox_override("hover", _flat_style(Color("d1e2f7"), 9))
	notifications_button.pressed.connect(_toggle_notification_center)
	calendar_footer.add_child(notifications_button)
	layout.add_child(calendar_footer)

func _refresh_calendar_date() -> void:

	if is_instance_valid(_calendar_today_label):

		_calendar_today_label.text = _get_french_long_date()

	if is_instance_valid(_calendar_short_date_label):

		_calendar_short_date_label.text = _get_short_french_date()


func _get_short_french_date() -> String:

	var date := Time.get_date_dict_from_system()

	return "%02d/%02d/%04d" % [date.day, date.month, date.year]

func _get_french_long_date() -> String:

	var date := Time.get_date_dict_from_system()

	var weekdays := ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]

	var months := ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]

	var weekday_index := int(Time.get_datetime_dict_from_system().weekday) - 1

	weekday_index = posmod(weekday_index, weekdays.size())

	return "%s %d %s %d" % [weekdays[weekday_index], date.day, months[date.month - 1], date.year]

func _toggle_calendar() -> void:

	var should_open := not _calendar_panel.visible

	if should_open:

		_refresh_calendar_date()

		_start_menu.visible = false

		_start_open = false

		_quick_settings_panel.visible = false
		if is_instance_valid(_notification_center):
			_animate_flyout(_notification_center, false, true)

	_animate_flyout(_calendar_panel, should_open, true)

func _build_notification_center() -> void:

	_notification_center = PanelContainer.new()

	_notification_center.name = "NotificationCenter"

	_notification_center.anchor_left = 1.0

	_notification_center.anchor_top = 1.0

	_notification_center.anchor_right = 1.0

	_notification_center.anchor_bottom = 1.0

	_notification_center.offset_left = -384

	_notification_center.offset_right = -12

	_notification_center.offset_top = -520

	_notification_center.offset_bottom = -76

	_notification_center.visible = false

	var style := _flat_style(Color("edf2f9", 0.94), 18)

	style.shadow_color = Color(0.02, 0.04, 0.10, 0.32)

	style.shadow_size = 22

	style.shadow_offset = Vector2(0, 5)

	style.set_border_width_all(1)

	style.border_color = Color(1, 1, 1, 0.78)

	_notification_center.add_theme_stylebox_override("panel", style)

	add_child(_notification_center)

	var margin := MarginContainer.new()

	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:

		margin.add_theme_constant_override(side, 16)

	_notification_center.add_child(margin)

	var layout := VBoxContainer.new()

	layout.add_theme_constant_override("separation", 12)

	margin.add_child(layout)

	var heading := HBoxContainer.new()

	var title := Label.new()

	title.text = "Notifications"

	title.add_theme_font_size_override("font_size", 21)

	title.add_theme_color_override("font_color", Color("17243a"))

	title.add_theme_color_override("font_color", Color("1d2a40"))

	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	heading.add_child(title)

	var clear_button := Button.new()

	clear_button.text = "Tout effacer"
	clear_button.tooltip_text = "Effacer toutes les notifications enregistrées"

	clear_button.add_theme_font_size_override("font_size", 11)

	clear_button.add_theme_color_override("font_color", Color("24344d"))

	clear_button.add_theme_stylebox_override("normal", _flat_style(Color("e3eaf4"), 7))

	clear_button.add_theme_stylebox_override("hover", _flat_style(Color("d3e2f5"), 7))

	clear_button.pressed.connect(_clear_notification_history)

	heading.add_child(clear_button)

	layout.add_child(heading)

	var separator := HSeparator.new()

	layout.add_child(separator)

	var scroll := ScrollContainer.new()

	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	layout.add_child(scroll)

	var entries := VBoxContainer.new()

	entries.name = "NotificationEntries"

	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	entries.add_theme_constant_override("separation", 8)

	scroll.add_child(entries)

	var empty := Label.new()

	empty.name = "EmptyNotifications"

	empty.text = "✓\nVous êtes à jour.\nAucune nouvelle notification."

	empty.custom_minimum_size.y = 180

	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	empty.add_theme_font_size_override("font_size", 13)

	empty.add_theme_color_override("font_color", Color("596780"))

	entries.add_child(empty)

func _toggle_notification_center() -> void:

	if not is_instance_valid(_notification_center):

		return

	var should_open := not _notification_center.visible

	if should_open:

		_start_menu.visible = false

		_start_open = false

		_quick_settings_panel.visible = false

		_calendar_panel.visible = false

	_animate_flyout(_notification_center, should_open, true)

func _clear_notification_history() -> void:

	_notification_history.clear()

	if not is_instance_valid(_notification_center):

		return

	var entries := _notification_center.find_child("NotificationEntries", true, false) as VBoxContainer

	if not is_instance_valid(entries):

		return

	for child in entries.get_children():

		child.queue_free()

	var empty := Label.new()

	empty.name = "EmptyNotifications"

	empty.text = "✓\nVous êtes à jour.\nAucune nouvelle notification."

	empty.custom_minimum_size.y = 180

	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	empty.add_theme_font_size_override("font_size", 13)

	empty.add_theme_color_override("font_color", Color("596780"))

	entries.add_child(empty)

func _refresh_notification_center() -> void:

	if not is_instance_valid(_notification_center):

		return

	var entries := _notification_center.find_child("NotificationEntries", true, false) as VBoxContainer

	if not is_instance_valid(entries):

		return

	for child in entries.get_children():

		child.queue_free()

	if _notification_history.is_empty():

		var empty := Label.new()

		empty.name = "EmptyNotifications"

		empty.text = "✓\nVous êtes à jour.\nAucune nouvelle notification."

		empty.custom_minimum_size.y = 180

		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		empty.add_theme_font_size_override("font_size", 13)

		empty.add_theme_color_override("font_color", Color("596780"))

		entries.add_child(empty)

		return

	var section_heading := Label.new()
	section_heading.text = "Aujourd’hui"
	section_heading.add_theme_font_size_override("font_size", 12)
	section_heading.add_theme_color_override("font_color", Color("596780"))
	entries.add_child(section_heading)

	for i in range(_notification_history.size() - 1, -1, -1):

		var item: Dictionary = _notification_history[i]

		var card := PanelContainer.new()
		var card_style := _flat_style(Color("ffffff"), 10)
		card_style.set_border_width_all(1)
		card_style.border_color = Color("dce4ef")
		card.add_theme_stylebox_override("panel", card_style)

		var padding := MarginContainer.new()

		for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:

			padding.add_theme_constant_override(side, 10)

		card.add_child(padding)

		var content := VBoxContainer.new()

		content.add_theme_constant_override("separation", 4)

		padding.add_child(content)

		var heading_row := HBoxContainer.new()
		heading_row.add_theme_constant_override("separation", 8)

		var notification_title := str(item.get("title", "Notification"))
		var app_glyph := "●"
		var app_mark_background := Color("e5efff")
		var app_mark_foreground := Color("2879d0")
		if notification_title.to_lower().contains("paramètres"):
			app_glyph = "⚙"
			app_mark_background = Color("e8edf3")
			app_mark_foreground = Color("65758b")
		elif notification_title.to_lower().contains("fichier"):
			app_glyph = "▤"
			app_mark_background = Color("fff1cf")
			app_mark_foreground = Color("a97810")
		elif notification_title.to_lower().contains("mise à jour"):
			app_glyph = "↻"
			app_mark_background = Color("dff6e9")
			app_mark_foreground = Color("21875d")
		elif notification_title.to_lower().contains("mission"):
			app_glyph = "✧"
			app_mark_background = Color("eee8ff")
			app_mark_foreground = Color("7860c8")
		elif notification_title.to_lower().contains("bienvenue"):
			app_glyph = "▦"
			app_mark_background = Color("e5efff")
			app_mark_foreground = Color("2879d0")

		var app_mark := PanelContainer.new()
		app_mark.custom_minimum_size = Vector2(28, 28)
		app_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		app_mark.add_theme_stylebox_override("panel", _flat_style(app_mark_background, 7))
		var app_mark_label := Label.new()
		app_mark_label.text = app_glyph
		app_mark_label.custom_minimum_size = Vector2(28, 28)
		app_mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		app_mark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		app_mark_label.add_theme_font_size_override("font_size", 14)
		app_mark_label.add_theme_color_override("font_color", app_mark_foreground)
		app_mark.add_child(app_mark_label)
		heading_row.add_child(app_mark)

		var heading := Label.new()
		heading.text = notification_title

		heading.add_theme_font_size_override("font_size", 13)

		heading.add_theme_color_override("font_color", Color("1d2a40"))

		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		heading_row.add_child(heading)

		var timestamp := Label.new()

		timestamp.text = str(item.get("time", ""))
		timestamp.add_theme_font_size_override("font_size", 10)

		timestamp.add_theme_color_override("font_color", Color("697991"))
		heading_row.add_child(timestamp)

		content.add_child(heading_row)

		var body := Label.new()
		body.text = str(item.get("message", ""))

		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		body.add_theme_color_override("font_color", Color("4b5b73"))

		content.add_child(body)

		entries.add_child(card)

func _build_quick_settings() -> void:

	_quick_settings_panel = PanelContainer.new()

	_quick_settings_panel.name = "QuickSettingsPanel"

	_quick_settings_panel.anchor_left = 1.0

	_quick_settings_panel.anchor_top = 1.0

	_quick_settings_panel.anchor_right = 1.0

	_quick_settings_panel.anchor_bottom = 1.0

	_quick_settings_panel.offset_left = -356

	_quick_settings_panel.offset_right = -12

	_quick_settings_panel.offset_top = -370

	_quick_settings_panel.offset_bottom = -76

	_quick_settings_panel.visible = false

	var panel_style := _flat_style(Color(0.89, 0.93, 0.98, 0.93), 18)

	panel_style.shadow_color = Color(0.02, 0.04, 0.10, 0.32)

	panel_style.shadow_size = 22

	panel_style.shadow_offset = Vector2(0, 5)

	panel_style.set_border_width_all(1)

	panel_style.border_color = Color(1, 1, 1, 0.78)

	_quick_settings_panel.add_theme_stylebox_override("panel", panel_style)

	add_child(_quick_settings_panel)


	var margin := MarginContainer.new()

	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:

		margin.add_theme_constant_override(side, 14)

	_quick_settings_panel.add_child(margin)

	var layout := VBoxContainer.new()

	layout.add_theme_constant_override("separation", 10)

	margin.add_child(layout)


	var panel_header := HBoxContainer.new()

	panel_header.add_theme_constant_override("separation", 8)

	var panel_title := Label.new()

	panel_title.text = "Paramètres rapides"

	panel_title.add_theme_font_size_override("font_size", 16)

	panel_title.add_theme_color_override("font_color", Color("1d2a40"))

	panel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	panel_header.add_child(panel_title)

	var close_button := Button.new()

	close_button.text = "×"

	close_button.tooltip_text = "Fermer"

	close_button.custom_minimum_size = Vector2(28, 28)

	close_button.add_theme_font_size_override("font_size", 18)

	close_button.add_theme_color_override("font_color", Color("34445d"))

	close_button.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 7))

	close_button.add_theme_stylebox_override("hover", _flat_style(Color("dce6f3"), 7))

	close_button.pressed.connect(func(): _animate_flyout(_quick_settings_panel, false, true))

	panel_header.add_child(close_button)

	layout.add_child(panel_header)

	var separator := HSeparator.new()

	layout.add_child(separator)


	var tiles := GridContainer.new()
	tiles.name = "QuickSettingsTiles"

	tiles.columns = 2

	tiles.add_theme_constant_override("h_separation", 8)

	tiles.add_theme_constant_override("v_separation", 8)

	layout.add_child(tiles)

	_add_quick_toggle(tiles, "◉  Wi-Fi", true, "Wi-Fi")

	_add_quick_toggle(tiles, "ᛒ  Bluetooth", true, "Bluetooth")

	_add_quick_toggle(tiles, "✈  Mode avion", false, "Mode avion")

	_add_quick_toggle(tiles, "☾  Éclairage nocturne", false, "Éclairage nocturne")


	var volume_row := HBoxContainer.new()

	volume_row.add_theme_constant_override("separation", 8)

	layout.add_child(volume_row)

	var volume_icon := Label.new()

	volume_icon.text = "🔊"

	volume_icon.add_theme_color_override("font_color", Color("24344d"))

	volume_row.add_child(volume_icon)

	var volume := HSlider.new()

	volume.min_value = 0

	volume.max_value = 100

	volume.value = float(SettingsStore.values.get("master_volume", 0.8)) * 100.0

	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var volume_value := Label.new()

	volume_value.text = "%d%%" % int(volume.value)

	volume_value.custom_minimum_size.x = 34

	volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	volume_value.add_theme_font_size_override("font_size", 11)

	volume_value.add_theme_color_override("font_color", Color("596780"))

	volume.value_changed.connect(func(value: float):

		volume_value.text = "%d%%" % int(value)

		SettingsStore.values["master_volume"] = value / 100.0

		SettingsStore.apply_audio_settings()

		SettingsStore.save_settings()

	)

	volume_row.add_child(volume)

	volume_row.add_child(volume_value)


	var brightness_row := HBoxContainer.new()

	brightness_row.add_theme_constant_override("separation", 8)

	layout.add_child(brightness_row)

	var brightness_icon := Label.new()

	brightness_icon.text = "☼"

	brightness_icon.add_theme_font_size_override("font_size", 20)

	brightness_icon.add_theme_color_override("font_color", Color("24344d"))

	brightness_row.add_child(brightness_icon)

	var brightness := HSlider.new()

	brightness.min_value = 55

	brightness.max_value = 100

	brightness.step = 5

	brightness.value = 100

	brightness.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	brightness.tooltip_text = "Luminosité du bureau"

	var brightness_value := Label.new()

	brightness_value.text = "%d%%" % int(brightness.value)

	brightness_value.custom_minimum_size.x = 34

	brightness_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	brightness_value.add_theme_font_size_override("font_size", 11)

	brightness_value.add_theme_color_override("font_color", Color("596780"))

	brightness.value_changed.connect(func(value: float):

		brightness_value.text = "%d%%" % int(value)
		_wallpaper_brightness = value / 100.0
		_apply_wallpaper_effects()

	)

	brightness_row.add_child(brightness)

	brightness_row.add_child(brightness_value)


	var footer := HBoxContainer.new()

	layout.add_child(footer)

	var status := Label.new()

	status.name = "QuickSettingsStatus"
	status.text = "Wi-Fi connecté · Bluetooth activé"
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	status.add_theme_font_size_override("font_size", 11)

	status.add_theme_color_override("font_color", Color("596780"))

	footer.add_child(status)
	_quick_status_label = status
	_update_quick_settings_status()

	var settings_button := Button.new()

	settings_button.text = "⚙"

	settings_button.tooltip_text = "Ouvrir les paramètres"

	settings_button.pressed.connect(func():

		_quick_settings_panel.visible = false

		_open_settings()

	)

	footer.add_child(settings_button)

func _style_quick_toggle(toggle: Button, enabled: bool) -> void:
	var normal_style := _flat_style(Color("cfe3ff") if enabled else Color("e8edf4"), 12)
	normal_style.set_border_width_all(1)
	normal_style.border_color = Color("a9c9f0") if enabled else Color("d5deea")
	toggle.add_theme_stylebox_override("normal", normal_style)

	var hover_style := _flat_style(Color("bdd8fb") if enabled else Color("dce4ef"), 12)
	hover_style.set_border_width_all(1)
	hover_style.border_color = Color("83b5ec") if enabled else Color("c3cfdf")
	toggle.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := _flat_style(Color("a9cefb") if enabled else Color("d2dce9"), 12)
	pressed_style.set_border_width_all(1)
	pressed_style.border_color = Color("7eafe8") if enabled else Color("b7c5d8")
	toggle.add_theme_stylebox_override("pressed", pressed_style)


func _add_quick_toggle(parent: GridContainer, caption: String, initially_on: bool, feature_name: String) -> void:

	var toggle := Button.new()
	toggle.text = caption
	toggle.tooltip_text = feature_name
	toggle.toggle_mode = true
	toggle.button_pressed = initially_on
	_quick_toggle_states[feature_name] = initially_on
	_quick_toggle_buttons[feature_name] = toggle
	toggle.custom_minimum_size = Vector2(136, 56)
	toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.add_theme_font_size_override("font_size", 12)
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.add_theme_color_override("font_color", Color("1d2a40"))
	_style_quick_toggle(toggle, initially_on)


	toggle.toggled.connect(func(enabled: bool):
		_quick_toggle_states[feature_name] = enabled

		# Airplane mode suspends wireless radios; re-enabling either radio exits it.
		if feature_name == "Mode avion" and enabled:
			for radio_name in ["Wi-Fi", "Bluetooth"]:
				_quick_toggle_states[radio_name] = false
				var radio_button = _quick_toggle_buttons.get(radio_name)
				if is_instance_valid(radio_button):
					radio_button.set_pressed_no_signal(false)
					_style_quick_toggle(radio_button, false)
		elif (feature_name == "Wi-Fi" or feature_name == "Bluetooth") and enabled:
			_quick_toggle_states["Mode avion"] = false
			var airplane_button = _quick_toggle_buttons.get("Mode avion")
			if is_instance_valid(airplane_button):
				airplane_button.set_pressed_no_signal(false)
				_style_quick_toggle(airplane_button, false)

		_style_quick_toggle(toggle, enabled)
		if feature_name == "Éclairage nocturne":
			_apply_wallpaper_effects()
		_update_quick_settings_status()
		_show_notification(feature_name, "%s : %s." % [feature_name, "activé" if enabled else "désactivé"])
	)

	parent.add_child(toggle)

func _update_quick_settings_status() -> void:
	if not is_instance_valid(_quick_status_label):
		return

	var network_status := ""
	if bool(_quick_toggle_states.get("Mode avion", false)):
		network_status = "Mode avion activé · Radios désactivées"
	elif bool(_quick_toggle_states.get("Wi-Fi", false)):
		var bluetooth_text := "Bluetooth activé" if bool(_quick_toggle_states.get("Bluetooth", false)) else "Bluetooth désactivé"
		network_status = "Wi-Fi connecté · " + bluetooth_text
	else:
		var bluetooth_text := "Bluetooth activé" if bool(_quick_toggle_states.get("Bluetooth", false)) else "Bluetooth désactivé"
		network_status = "Wi-Fi désactivé · " + bluetooth_text

	if bool(_quick_toggle_states.get("Éclairage nocturne", false)):
		network_status += " · Éclairage nocturne"
	_quick_status_label.text = network_status


func _apply_wallpaper_effects() -> void:
	if not is_instance_valid(_wallpaper):
		return

	var level := clampf(_wallpaper_brightness, 0.0, 1.0)
	if bool(_quick_toggle_states.get("Éclairage nocturne", false)):
		# Warm tint approximates Windows Night light without replacing the wallpaper.
		_wallpaper.modulate = Color(level, level * 0.91, level * 0.76, 1.0)
	else:
		_wallpaper.modulate = Color(level, level, level, 1.0)

func _toggle_quick_settings() -> void:

	var should_open := not _quick_settings_panel.visible
	if should_open:
		_start_menu.visible = false

		_start_open = false

		_calendar_panel.visible = false
		if is_instance_valid(_notification_center):
			_animate_flyout(_notification_center, false, true)
	_animate_flyout(_quick_settings_panel, should_open, true)

func _add_taskbar_app(parent: HBoxContainer, glyph: String, tooltip: String, callback: Callable, app_id: String) -> void:

	var button := Button.new()

	button.text = ""

	button.tooltip_text = tooltip

	button.custom_minimum_size = Vector2(48, 46)

	var icon_color := Color("0878d1")

	match app_id:

		"files": icon_color = Color("e4b33f")

		"settings": icon_color = Color("68798e")

		"update": icon_color = Color("299b74")

	var icon_tile := PanelContainer.new()

	icon_tile.name = "TaskbarAppIcon"

	icon_tile.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	icon_tile.position = Vector2(-16, -16)

	icon_tile.custom_minimum_size = Vector2(32, 32)

	icon_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

	icon_tile.add_theme_stylebox_override("panel", _flat_style(icon_color, 7))

	var icon_glyph := Label.new()

	icon_glyph.text = glyph

	icon_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	icon_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	icon_glyph.add_theme_font_size_override("font_size", 17)

	icon_glyph.add_theme_color_override("font_color", Color.WHITE)

	icon_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE

	icon_tile.add_child(icon_glyph)

	button.add_child(icon_tile)

	# Subtle icon lift on hover mirrors the responsive taskbar feedback in Windows 11.
	button.mouse_entered.connect(func():
		_show_taskbar_preview(app_id, button, glyph)
		var hover_tween := create_tween()
		hover_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		hover_tween.tween_property(icon_tile, "scale", Vector2(1.07, 1.07), 0.10)
	)
	button.mouse_exited.connect(func():
		_hide_taskbar_preview()
		var hover_tween := create_tween()
		hover_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		hover_tween.tween_property(icon_tile, "scale", Vector2.ONE, 0.12)
	)

	button.add_theme_color_override("font_color", Color("24344d"))

	button.add_theme_stylebox_override("normal", _flat_style(Color(0.0, 0.0, 0.0, 0.0), 7))

	button.add_theme_stylebox_override("hover", _flat_style(Color(0.78, 0.86, 0.96, 0.84), 9))

	button.add_theme_stylebox_override("pressed", _flat_style(Color(0.66, 0.79, 0.94, 0.88), 8))

	button.focus_mode = Control.FOCUS_NONE

	button.set_meta("app_id", app_id)

	var active_marker := PanelContainer.new()

	active_marker.name = "ActiveMarker"

	active_marker.anchor_left = 0.5

	active_marker.anchor_right = 0.5

	active_marker.anchor_top = 1.0

	active_marker.anchor_bottom = 1.0

	active_marker.offset_left = -10

	active_marker.offset_right = 10

	active_marker.offset_top = -3

	active_marker.offset_bottom = 0

	active_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE

	active_marker.add_theme_stylebox_override("panel", _flat_style(Color("2679d8"), 3))

	active_marker.visible = false

	button.add_child(active_marker)

	button.set_meta("active_marker", active_marker)

	_taskbar_app_buttons[app_id] = button

	button.pressed.connect(func():

		var existing := _find_app_window(app_id)

		if is_instance_valid(existing):

			if existing.visible and _active_app_id == app_id:

				existing.call("_animate_minimize")

				_active_app_id = ""

				_update_taskbar_indicators()

			else:

				if existing.visible:

					existing.move_to_front()

				else:

					existing.call("restore_from_taskbar")

				_active_app_id = app_id

				_update_taskbar_indicators()

		else:

			callback.call()

	)

	parent.add_child(button)

func _show_taskbar_preview(app_id: String, source_button: Button, glyph: String) -> void:

	_hide_taskbar_preview()
	var app := _find_app_window(app_id)
	if not is_instance_valid(app):
		return

	_taskbar_preview = PanelContainer.new()
	_taskbar_preview.name = "TaskbarWindowPreview"
	_taskbar_preview.z_index = 105
	_taskbar_preview.custom_minimum_size = Vector2(244, 166)
	var preview_style := _flat_style(Color("f5f7fb"), 12)
	preview_style.border_color = Color("d4ddeb")
	preview_style.set_border_width_all(1)
	preview_style.shadow_color = Color(0.02, 0.04, 0.10, 0.28)
	preview_style.shadow_size = 18
	preview_style.shadow_offset = Vector2(0, 4)
	_taskbar_preview.add_theme_stylebox_override("panel", preview_style)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	layout.add_theme_constant_override("margin_left", 10)
	layout.add_theme_constant_override("margin_right", 10)
	layout.add_theme_constant_override("margin_top", 9)
	layout.add_theme_constant_override("margin_bottom", 9)
	_taskbar_preview.add_child(layout)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	var app_icon_tile := PanelContainer.new()
	app_icon_tile.custom_minimum_size = Vector2(28, 28)
	app_icon_tile.add_theme_stylebox_override("panel", _flat_style(Color("e0ecff"), 7))
	title_row.add_child(app_icon_tile)
	var app_icon_center := CenterContainer.new()
	app_icon_tile.add_child(app_icon_center)
	var app_icon := Label.new()
	app_icon.text = glyph
	app_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	app_icon.add_theme_color_override("font_color", Color("2679d8"))
	app_icon.add_theme_font_size_override("font_size", 17)
	app_icon_center.add_child(app_icon)
	var title_label := Label.new()
	title_label.text = str(app.get_meta("window_title", "Application"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.add_theme_color_override("font_color", Color("24344d"))
	title_label.add_theme_font_size_override("font_size", 12)
	title_row.add_child(title_label)
	layout.add_child(title_row)

	var thumbnail := PanelContainer.new()
	thumbnail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	thumbnail.custom_minimum_size = Vector2(0, 86)
	thumbnail.add_theme_stylebox_override("panel", _flat_style(Color("e5edf8"), 7))
	var thumbnail_content := CenterContainer.new()
	thumbnail.add_child(thumbnail_content)
	var thumbnail_label := Label.new()
	thumbnail_label.text = glyph + "\n" + str(app.get_meta("window_title", "Application"))
	thumbnail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thumbnail_label.add_theme_color_override("font_color", Color("526681"))
	thumbnail_label.add_theme_font_size_override("font_size", 11)
	thumbnail_content.add_child(thumbnail_label)
	layout.add_child(thumbnail)

	var preview_status := HBoxContainer.new()
	preview_status.add_theme_constant_override("separation", 6)
	var status_dot := Label.new()
	status_dot.text = "●"
	status_dot.add_theme_font_size_override("font_size", 9)
	status_dot.add_theme_color_override("font_color", Color("1683e8"))
	preview_status.add_child(status_dot)
	var status_label := Label.new()
	status_label.text = "Fenêtre ouverte"
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color("65758d"))
	preview_status.add_child(status_label)
	layout.add_child(preview_status)

	add_child(_taskbar_preview)
	var button_rect := source_button.get_global_rect()
	# The desktop Control fills the viewport, so global-rect coordinates map directly to its local space.
	var preview_position := button_rect.position + Vector2(button_rect.size.x / 2.0 - 122.0, -174.0)
	var viewport_size := get_viewport_rect().size
	preview_position.x = clampf(preview_position.x, 8.0, maxf(8.0, viewport_size.x - 252.0))
	preview_position.y = maxf(8.0, preview_position.y)
	_taskbar_preview.position = preview_position
	_taskbar_preview.modulate.a = 0.0
	_taskbar_preview.scale = Vector2(0.96, 0.96)
	_taskbar_preview.pivot_offset = Vector2(122, 83)
	_taskbar_preview_tween = create_tween()
	_taskbar_preview_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_taskbar_preview_tween.set_parallel(true)
	_taskbar_preview_tween.tween_property(_taskbar_preview, "modulate:a", 1.0, 0.13)
	_taskbar_preview_tween.tween_property(_taskbar_preview, "scale", Vector2.ONE, 0.13)


func _hide_taskbar_preview() -> void:

	if not is_instance_valid(_taskbar_preview):
		return
	if is_instance_valid(_taskbar_preview_tween):
		_taskbar_preview_tween.kill()
	_taskbar_preview.queue_free()
	_taskbar_preview = null
	_taskbar_preview_tween = null


func _find_app_window(app_id: String) -> Control:

	if not is_instance_valid(_window_layer):

		return null

	for child in _window_layer.get_children():

		if child is Control and child.has_meta("app_id") and str(child.get_meta("app_id")) == app_id:

			return child as Control

	return null

func _update_taskbar_indicators() -> void:

	for app_id in _taskbar_app_buttons:

		var button: Button = _taskbar_app_buttons[app_id]

		if not is_instance_valid(button):

			continue

		var app := _find_app_window(str(app_id))

		var running := is_instance_valid(app)

		var active := running and app.visible and str(_active_app_id) == str(app_id)

		var idle_style := _flat_style(Color(0.0, 0.0, 0.0, 0.0), 7)
		var active_style := _flat_style(Color(0.38, 0.60, 0.88, 0.22), 7)
		var hover_style := _flat_style(Color(0.78, 0.86, 0.96, 0.84), 9)
		var active_hover_style := _flat_style(Color(0.68, 0.81, 0.96, 0.92), 9)
		button.add_theme_stylebox_override("normal", active_style if active else idle_style)
		button.add_theme_stylebox_override("hover", active_hover_style if active else hover_style)
		button.add_theme_stylebox_override("pressed", _flat_style(Color(0.38, 0.60, 0.88, 0.42), 7))

		var marker = button.get_meta("active_marker", null)

		if is_instance_valid(marker):

			# Windows 11 uses a small dot for running apps and a longer pill
			# for the focused window. Cancel an in-flight transition before
			# starting another so rapid focus changes never stack competing tweens.
			marker.visible = running
			var previous_tween = _taskbar_marker_tweens.get(str(app_id))
			if previous_tween is Tween and previous_tween.is_running():
				previous_tween.kill()

			var target_left := -9.0 if active else -3.0
			var target_right := 9.0 if active else 3.0
			var target_top := -3.0 if active else -2.0
			var marker_tween := create_tween()
			_taskbar_marker_tweens[str(app_id)] = marker_tween
			marker_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			marker_tween.tween_property(marker, "offset_left", target_left, 0.12)
			marker_tween.parallel().tween_property(marker, "offset_right", target_right, 0.12)
			marker_tween.parallel().tween_property(marker, "offset_top", target_top, 0.12)
			marker.add_theme_stylebox_override("panel", _flat_style(Color("2679d8") if active else Color("6b7f99"), 3))

func _build_start_menu() -> void:

	_start_menu = PanelContainer.new()

	_start_menu.anchor_left = 0.5

	_start_menu.anchor_right = 0.5

	_start_menu.anchor_top = 1.0

	_start_menu.anchor_bottom = 1.0

	_start_menu.offset_left = -320

	_start_menu.offset_right = 320

	_start_menu.offset_top = -(TASKBAR_HEIGHT + 540)

	_start_menu.offset_bottom = -(TASKBAR_HEIGHT + 12)

	_start_menu.visible = false

	var start_style := _flat_style(Color(0.91, 0.94, 0.98, 0.92), 18)

	start_style.shadow_color = Color(0.02, 0.04, 0.10, 0.30)

	start_style.shadow_size = 24

	start_style.shadow_offset = Vector2(0, 5)

	start_style.set_border_width_all(1)

	start_style.border_color = Color(1, 1, 1, 0.78)

	_start_menu.add_theme_stylebox_override("panel", start_style)

	add_child(_start_menu)


	var margin := MarginContainer.new()

	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:

		margin.add_theme_constant_override(side, 16)

	_start_menu.add_child(margin)


	var layout := VBoxContainer.new()

	layout.add_theme_constant_override("separation", 10)

	margin.add_child(layout)


	var search := LineEdit.new()

	_start_search = search

	search.placeholder_text = "Rechercher des applications, paramètres et documents"

	search.clear_button_enabled = true

	search.custom_minimum_size.y = 40

	search.add_theme_font_size_override("font_size", 13)

	search.add_theme_color_override("caret_color", Color("0878d1"))

	search.add_theme_color_override("font_color", Color("1d2a40"))

	search.add_theme_stylebox_override("normal", _flat_style(Color.WHITE, 10))

	var search_focus_style := _flat_style(Color.WHITE, 10)

	search_focus_style.set_border_width_all(2)

	search_focus_style.border_color = Color("78afe9")

	search.add_theme_stylebox_override("focus", search_focus_style)

	search.text_changed.connect(_filter_pinned_apps)

	search.text_submitted.connect(func(query: String):

		_start_menu.visible = false

		_start_open = false

		_open_window("Recherche Microslop", "Résultats pour : « %s »\n\nMicroslop AI — recommandé\nMicroslop Premium — SPONSORISÉ\nLe résultat que vous cherchiez (peut-être)." % query, Vector2(560, 300))

	)

	layout.add_child(search)


	var pinned_header := HBoxContainer.new()

	pinned_header.add_theme_constant_override("separation", 8)

	layout.add_child(pinned_header)

	var heading := Label.new()

	_pinned_heading_label = heading

	heading.text = "Épinglé"

	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	heading.add_theme_font_size_override("font_size", 18)

	heading.add_theme_color_override("font_color", Color("1d2a40"))

	pinned_header.add_child(heading)

	var all_apps := Button.new()

	_all_apps_button = all_apps

	all_apps.text = "Tous  ›"

	all_apps.custom_minimum_size = Vector2(78, 30)

	all_apps.add_theme_font_size_override("font_size", 12)

	all_apps.add_theme_color_override("font_color", Color("263247"))

	all_apps.add_theme_stylebox_override("normal", _flat_style(Color("e5eaf3"), 7))

	all_apps.add_theme_stylebox_override("hover", _flat_style(Color("d6e4f8"), 7))

	all_apps.add_theme_stylebox_override("pressed", _flat_style(Color("c7dcf7"), 7))

	all_apps.focus_mode = Control.FOCUS_NONE

	all_apps.pressed.connect(_toggle_all_apps_view)

	pinned_header.add_child(all_apps)


	var pinned := GridContainer.new()

	_pinned_grid = pinned

	pinned.columns = 6

	pinned.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	pinned.add_theme_constant_override("h_separation", 8)

	pinned.add_theme_constant_override("v_separation", 8)

	layout.add_child(pinned)

	_add_pinned_app(pinned, "◎", "Browser", _open_browser)

	_add_pinned_app(pinned, "▤", "Fichiers", _open_files)
	_add_pinned_app(pinned, "⚙", "Paramètres", _open_settings)

	_add_pinned_app(pinned, "✧", "Microslop AI", _open_ai)

	_add_pinned_app(pinned, "↻", "Mise à jour", _trigger_update)
	_add_pinned_app(pinned, "▧", "Corbeille", _open_recycle_bin)

	var all_apps_scroll := ScrollContainer.new()

	all_apps_scroll.name = "AllAppsScroll"

	all_apps_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	all_apps_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	all_apps_scroll.custom_minimum_size.y = 240

	all_apps_scroll.visible = false

	layout.add_child(all_apps_scroll)

	_all_apps_list = VBoxContainer.new()

	_all_apps_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_all_apps_list.add_theme_constant_override("separation", 4)

	all_apps_scroll.add_child(_all_apps_list)

	_add_all_apps_entry("◎", "Microslop Browser", _open_browser)

	_add_all_apps_entry("▤", "Explorateur de fichiers", _open_files)

	_add_all_apps_entry("⚙", "Paramètres", _open_settings)

	_add_all_apps_entry("✧", "Microslop AI", _open_ai)

	_add_all_apps_entry("↻", "Mise à jour", _trigger_update)

	_add_all_apps_entry("▧", "Corbeille", _open_recycle_bin)

	_all_apps_empty_label = Label.new()

	_all_apps_empty_label.text = "Aucune application correspondante"

	_all_apps_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_all_apps_empty_label.add_theme_color_override("font_color", Color("596780"))

	_all_apps_empty_label.visible = false

	_all_apps_list.add_child(_all_apps_empty_label)


	_pinned_empty_label = Label.new()

	_pinned_empty_label.text = "Aucune application correspondante"

	_pinned_empty_label.add_theme_color_override("font_color", Color("596780"))

	_pinned_empty_label.visible = false

	layout.add_child(_pinned_empty_label)


	_recommended_heading = Label.new()

	_recommended_heading.text = "Recommandé"

	_recommended_heading.add_theme_font_size_override("font_size", 17)

	_recommended_heading.add_theme_color_override("font_color", Color("1d2a40"))

	layout.add_child(_recommended_heading)

	var recommended_divider := HSeparator.new()

	layout.add_child(recommended_divider)


	_recommended_card = PanelContainer.new()

	var recommended_card := _recommended_card

	var recommended_style := _flat_style(Color("eaf0f8"), 10)

	recommended_style.set_border_width_all(1)

	recommended_style.border_color = Color("dce4f0")

	recommended_card.add_theme_stylebox_override("panel", recommended_style)

	layout.add_child(recommended_card)

	var recommended_margin := MarginContainer.new()

	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:

		recommended_margin.add_theme_constant_override(side, 9)

	recommended_card.add_child(recommended_margin)

	var recommended_layout := HBoxContainer.new()

	recommended_layout.add_theme_constant_override("separation", 12)

	recommended_layout.alignment = BoxContainer.ALIGNMENT_CENTER

	recommended_margin.add_child(recommended_layout)

	var recent_icon_tile := PanelContainer.new()

	recent_icon_tile.custom_minimum_size = Vector2(48, 48)

	var recent_icon_style := _flat_style(Color("dceaff"), 10)

	recent_icon_style.set_border_width_all(1)

	recent_icon_style.border_color = Color("c6dcfa")

	recent_icon_tile.add_theme_stylebox_override("panel", recent_icon_style)

	recommended_layout.add_child(recent_icon_tile)

	var recent_icon_center := CenterContainer.new()

	recent_icon_tile.add_child(recent_icon_center)

	var recent_icon := Label.new()

	_recommended_recent_icon = recent_icon

	recent_icon.text = "◷"

	recent_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	recent_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	recent_icon.add_theme_font_size_override("font_size", 24)

	recent_icon.add_theme_color_override("font_color", Color("2679d8"))

	recent_icon_center.add_child(recent_icon)

	var recent_empty := Label.new()

	_recommended_recent_label = recent_empty

	recent_empty.text = "Vos fichiers récents apparaîtront ici."

	recent_empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	recent_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	recent_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	recent_empty.add_theme_font_size_override("font_size", 12)

	recent_empty.add_theme_color_override("font_color", Color("34445e"))

	recommended_layout.add_child(recent_empty)

	var reopen_button := Button.new()

	reopen_button.text = "Ouvrir à nouveau"

	reopen_button.custom_minimum_size = Vector2(108, 34)

	reopen_button.add_theme_font_size_override("font_size", 13)

	reopen_button.add_theme_color_override("font_color", Color("263247"))

	reopen_button.add_theme_stylebox_override("normal", _flat_style(Color("dce8f8"), 8))

	reopen_button.add_theme_stylebox_override("hover", _flat_style(Color("cbdcf3"), 8))

	reopen_button.add_theme_stylebox_override("pressed", _flat_style(Color("b9d2f3"), 8))

	reopen_button.focus_mode = Control.FOCUS_NONE

	reopen_button.pressed.connect(_reopen_recent_app)

	recommended_layout.add_child(reopen_button)


	var spacer := Control.new()

	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL

	layout.add_child(spacer)


	var profile_row := HBoxContainer.new()

	profile_row.add_theme_constant_override("separation", 8)

	layout.add_child(profile_row)

	var account := Button.new()

	account.text = "◉  Profil local  ▾"

	account.alignment = HORIZONTAL_ALIGNMENT_LEFT

	account.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	account.custom_minimum_size.y = 40

	account.add_theme_color_override("font_color", Color("263247"))

	account.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 8))

	account.add_theme_stylebox_override("hover", _flat_style(Color("e1e9f5"), 8))

	account.add_theme_stylebox_override("pressed", _flat_style(Color("d2e1f4"), 8))

	account.focus_mode = Control.FOCUS_NONE

	account.pressed.connect(func(): _show_account_menu(account))

	profile_row.add_child(account)

	var power := Button.new()

	power.text = "⏻"

	power.tooltip_text = "Options d’alimentation simulées"

	power.custom_minimum_size = Vector2(42, 40)

	power.add_theme_font_size_override("font_size", 19)

	power.add_theme_color_override("font_color", Color("263247"))

	power.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 8))

	power.add_theme_stylebox_override("hover", _flat_style(Color("e1e9f5"), 8))

	power.pressed.connect(func(): _show_power_menu(power))

	profile_row.add_child(power)

func _build_notification_layer() -> void:

	_notification_layer = VBoxContainer.new()

	_notification_layer.anchor_left = 1.0

	_notification_layer.anchor_right = 1.0

	_notification_layer.offset_left = -365

	_notification_layer.offset_right = -16

	_notification_layer.offset_top = 18

	_notification_layer.add_theme_constant_override("separation", 8)

	_notification_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(_notification_layer)

func _build_mission_hint() -> void:

	var card := PanelContainer.new()

	card.anchor_left = 1.0

	card.anchor_top = 1.0

	card.anchor_right = 1.0

	card.anchor_bottom = 1.0

	card.offset_left = -330

	card.offset_top = -145

	card.offset_right = -16

	card.offset_bottom = -TASKBAR_HEIGHT - 12

	var mission_style := _flat_style(Color(0.04, 0.07, 0.12, 0.78), 14)

	mission_style.shadow_color = Color(0.02, 0.04, 0.10, 0.24)

	mission_style.shadow_size = 12

	mission_style.shadow_offset = Vector2(0, 3)

	mission_style.set_border_width_all(1)

	mission_style.border_color = Color(1, 1, 1, 0.18)

	card.add_theme_stylebox_override("panel", mission_style)

	add_child(card)


	var margin := MarginContainer.new()

	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:

		margin.add_theme_constant_override(side, 12)

	card.add_child(margin)


	_mission_label = Label.new()

	_mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_mission_label.add_theme_color_override("font_color", Color.WHITE)

	margin.add_child(_mission_label)

func _add_pinned_app(parent: GridContainer, glyph: String, caption: String, callback: Callable) -> void:

	var button := Button.new()

	button.set_meta("app_name", caption.to_lower())
	button.set_meta("search_terms", _app_search_terms(caption))

	button.tooltip_text = "Ouvrir %s" % caption

	_pinned_buttons.append(button)

	button.custom_minimum_size = Vector2(168, 76)

	button.add_theme_color_override("font_color", Color("263247"))

	button.add_theme_stylebox_override("normal", _flat_style(Color(1, 1, 1, 0.0), 10))

	button.add_theme_stylebox_override("hover", _flat_style(Color("e0ebfa"), 10))

	button.add_theme_stylebox_override("pressed", _flat_style(Color("cddff7"), 10))

	var pinned_focus_style := _flat_style(Color("e8f1fc"), 10)

	pinned_focus_style.set_border_width_all(1)

	pinned_focus_style.border_color = Color("a9c9ee")

	button.add_theme_stylebox_override("focus", pinned_focus_style)

	button.focus_mode = Control.FOCUS_NONE

	var content := VBoxContainer.new()

	content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	content.add_theme_constant_override("separation", 5)

	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	content.add_theme_constant_override("margin_top", 5)

	button.add_child(content)

	var icon_tile := PanelContainer.new()

	icon_tile.custom_minimum_size = Vector2(44, 44)

	icon_tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var icon_color := Color("0878d1")

	var icon_glyph := glyph

	match caption:

		"Fichiers":

			icon_color = Color("e6b43c")

			icon_glyph = "▰"

		"Paramètres":

			icon_color = Color("65758b")
			icon_glyph = "⚙"

		"Microslop AI":

			icon_color = Color("7868d8")

			icon_glyph = "✧"

		"Mise à jour":
			icon_color = Color("2b9b73")
			icon_glyph = "↻"

		"Corbeille":

			icon_color = Color("5a9fd8")

			icon_glyph = "▤"

		"Navigateur":

			icon_color = Color("2879d0")

			icon_glyph = "◎"

	var icon_tile_style := _flat_style(icon_color, 10)

	icon_tile_style.set_border_width_all(1)

	icon_tile_style.border_color = Color(1, 1, 1, 0.64)

	icon_tile_style.shadow_color = Color(0.04, 0.08, 0.16, 0.20)

	icon_tile_style.shadow_size = 5

	icon_tile_style.shadow_offset = Vector2(0, 2)

	icon_tile.add_theme_stylebox_override("panel", icon_tile_style)

	button.mouse_entered.connect(func():

		var tile_tween := create_tween()

		tile_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		tile_tween.tween_property(icon_tile, "scale", Vector2(1.06, 1.06), 0.10)

	)

	button.mouse_exited.connect(func():

		var tile_tween := create_tween()

		tile_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		tile_tween.tween_property(icon_tile, "scale", Vector2.ONE, 0.12)

	)

	content.add_child(icon_tile)

	var icon_label := Label.new()

	icon_label.text = icon_glyph

	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	icon_label.add_theme_font_size_override("font_size", 20)

	icon_label.add_theme_color_override("font_color", Color.WHITE)

	icon_tile.add_child(icon_label)

	var title_label := Label.new()

	title_label.text = caption

	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	title_label.add_theme_font_size_override("font_size", 11)

	title_label.add_theme_color_override("font_color", Color("263247"))

	title_label.clip_text = true

	content.add_child(title_label)

	button.pressed.connect(callback)

	button.focus_mode = Control.FOCUS_NONE

	parent.add_child(button)

func _app_search_terms(caption: String) -> String:
	var aliases := ""
	match caption.to_lower():
		"browser", "microslop browser", "navigateur":
			aliases = " navigateur internet web chrome edge "
		"fichiers", "explorateur de fichiers":
			aliases = " explorateur fichiers file explorer dossier documents "
		"paramètres":
			aliases = " settings configuration systeme système options "
		"microslop ai":
			aliases = " ia intelligence artificielle assistant copilot "
		"mise à jour":
			aliases = " update windows update actualisation "
		"corbeille":
			aliases = " recycle bin supprimés suppression "
	return aliases

func _filter_pinned_apps(query: String) -> void:

	var normalized_query := query.strip_edges().to_lower()

	var visible_count := 0

	var all_apps_visible_count := 0

	for button in _pinned_buttons:

		if is_instance_valid(button):

			var app_name := str(button.get_meta("app_name", ""))
			var search_terms := str(button.get_meta("search_terms", ""))

			button.visible = normalized_query.is_empty() or app_name.contains(normalized_query) or search_terms.contains(normalized_query)

			if button.visible:

				visible_count += 1

	for button in _all_apps_entries:

		if is_instance_valid(button):

			var app_name := str(button.get_meta("app_name", ""))

			button.visible = normalized_query.is_empty() or app_name.contains(normalized_query)

			if button.visible:

				all_apps_visible_count += 1

	if is_instance_valid(_all_apps_empty_label):

		_all_apps_empty_label.visible = _all_apps_view and not normalized_query.is_empty() and all_apps_visible_count == 0

	if is_instance_valid(_pinned_empty_label):

		_pinned_empty_label.visible = not _all_apps_view and not normalized_query.is_empty() and visible_count == 0

	if is_instance_valid(_recommended_card):

		_recommended_card.visible = normalized_query.is_empty() and not _all_apps_view

	if is_instance_valid(_recommended_heading):

		_recommended_heading.visible = normalized_query.is_empty() and not _all_apps_view

func _toggle_all_apps_view() -> void:

	_all_apps_view = not _all_apps_view

	if is_instance_valid(_pinned_empty_label):

		_pinned_empty_label.visible = false

	if is_instance_valid(_pinned_heading_label):

		_pinned_heading_label.text = "Toutes les applications" if _all_apps_view else "Épinglé"

	if is_instance_valid(_all_apps_button):

		_all_apps_button.text = "Épinglé  ‹" if _all_apps_view else "Tous  ›"

	if is_instance_valid(_recommended_card):

		_recommended_card.visible = not _all_apps_view and _start_search.text.strip_edges().is_empty()

	if is_instance_valid(_recommended_heading):

		_recommended_heading.visible = not _all_apps_view and _start_search.text.strip_edges().is_empty()

	if is_instance_valid(_pinned_grid):

		_pinned_grid.visible = not _all_apps_view

	if is_instance_valid(_all_apps_list):

		_all_apps_list.get_parent().visible = _all_apps_view

	if _all_apps_view and is_instance_valid(_start_search):

		_start_search.grab_focus()

		_filter_pinned_apps(_start_search.text)

func _add_all_apps_entry(glyph: String, caption: String, callback: Callable) -> void:

	var button := Button.new()
	button.text = ""
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 42
	button.set_meta("app_name", caption.to_lower())
	button.set_meta("search_terms", _app_search_terms(caption))
	button.tooltip_text = "Ouvrir %s" % caption
	button.add_theme_color_override("font_color", Color("263247"))
	button.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 7))
	button.add_theme_stylebox_override("hover", _flat_style(Color("dce8f8"), 7))
	button.add_theme_stylebox_override("pressed", _flat_style(Color("cddff7"), 7))
	var app_entry_focus := _flat_style(Color("e8f1fc"), 7)
	app_entry_focus.set_border_width_all(1)
	app_entry_focus.border_color = Color("a9c9ee")
	button.add_theme_stylebox_override("focus", app_entry_focus)

	var padding := MarginContainer.new()
	padding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	padding.add_theme_constant_override("margin_left", 8)
	padding.add_theme_constant_override("margin_right", 8)
	padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(padding)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padding.add_child(row)

	var icon_color := Color("2879d0")
	match caption:
		"Explorateur de fichiers", "Corbeille":
			icon_color = Color("d5a32d") if caption == "Explorateur de fichiers" else Color("5a9fd8")
		"Paramètres":
			icon_color = Color("65758b")
		"Microslop AI":
			icon_color = Color("7868d8")
		"Mise à jour":
			icon_color = Color("2b9b73")

	var icon_tile := PanelContainer.new()
	icon_tile.custom_minimum_size = Vector2(28, 28)
	icon_tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_tile.add_theme_stylebox_override("panel", _flat_style(icon_color, 7))
	row.add_child(icon_tile)

	var icon_label := Label.new()
	icon_label.text = glyph
	icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 15)
	icon_label.add_theme_color_override("font_color", Color.WHITE)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_tile.add_child(icon_label)

	var title_label := Label.new()
	title_label.text = caption
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color("263247"))
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title_label)

	button.pressed.connect(callback)
	button.focus_mode = Control.FOCUS_NONE
	_all_apps_entries.append(button)
	_all_apps_list.add_child(button)

func _show_account_menu(anchor: Control) -> void:

	var popup := PopupMenu.new()

	popup.add_item("Profil local", 0)

	popup.add_separator()

	popup.add_item("Paramètres du compte", 1)

	popup.add_item("Verrouiller", 2)

	popup.id_pressed.connect(func(id: int):

		match id:

			0: _show_notification("Profil local", "Session locale Microslop.")

			1: _open_settings()

			2: _show_notification("Écran verrouillé", "Le verrouillage est simulé dans ce prototype.")

	)

	add_child(popup)

	popup.popup(Rect2i(Vector2i(anchor.get_global_rect().position), Vector2i(220, 120)))

	popup.popup_hide.connect(popup.queue_free)

func _show_power_menu(anchor: Control) -> void:

	var popup := PopupMenu.new()

	popup.add_item("Veille", 0)

	popup.add_item("Redémarrer", 1)

	popup.add_item("Arrêter", 2)

	popup.id_pressed.connect(func(id: int):

		match id:

			0: _show_notification("Veille", "La mise en veille est simulée.")

			1: _show_notification("Redémarrage", "Le redémarrage est simulé ; votre session reste ouverte.")

			2: _show_notification("Arrêt", "L’arrêt est simulé ; Microslop Experience reste en cours d’exécution.")

	)

	add_child(popup)

	popup.popup(Rect2i(Vector2i(anchor.get_global_rect().position), Vector2i(180, 100)))

	popup.popup_hide.connect(popup.queue_free)

func _add_menu_button(parent: VBoxContainer, caption: String, callback: Callable) -> void:

	var button := Button.new()

	button.text = caption

	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	button.custom_minimum_size.y = 40

	button.add_theme_color_override("font_color", Color("263247"))

	button.pressed.connect(callback)

	button.focus_mode = Control.FOCUS_NONE

	parent.add_child(button)

func _toggle_start_menu() -> void:

	_start_open = not _start_open

	_animate_flyout(_start_menu, _start_open, false)

	if _start_open:

		_quick_settings_panel.visible = false

		_calendar_panel.visible = false
		if is_instance_valid(_notification_center):
			_animate_flyout(_notification_center, false, true)

		# Win+Start opens the launcher ready for immediate keyboard search.
		if is_instance_valid(_start_search):
			_start_search.call_deferred("grab_focus")

		if _mission_step == 0:

			_advance_mission("Vous avez ouvert le menu Démarrer.")

func _animate_flyout(panel: Control, opening: bool, from_bottom: bool) -> void:

	if not is_instance_valid(panel):

		return

	var active_tween: Tween
	if panel == _start_menu:
		active_tween = _start_menu_tween
	elif panel == _quick_settings_panel:
		active_tween = _quick_settings_tween
	elif panel == _notification_center:
		active_tween = _notification_tween
	else:
		active_tween = _calendar_tween

	if active_tween and active_tween.is_running():

		active_tween.kill()

	if opening:

		panel.visible = true

		panel.pivot_offset = panel.size / 2.0

		panel.modulate.a = 0.0

		panel.scale = Vector2(0.96, 0.96)

		var start_y := 12.0 if from_bottom else 8.0

		var target_y := panel.position.y

		panel.position.y = target_y + start_y

		var tween := create_tween().set_parallel(true)

		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		tween.tween_property(panel, "modulate:a", 1.0, 0.16)

		tween.tween_property(panel, "scale", Vector2.ONE, 0.18)

		tween.tween_property(panel, "position:y", target_y, 0.18)

		if panel == _start_menu:

			_start_menu_tween = tween

		elif panel == _quick_settings_panel:

			_quick_settings_tween = tween

		elif panel == _notification_center:

			_notification_tween = tween

		else:

			_calendar_tween = tween

	else:

		var tween := create_tween().set_parallel(true)

		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

		tween.tween_property(panel, "modulate:a", 0.0, 0.10)

		tween.tween_property(panel, "scale", Vector2(0.97, 0.97), 0.10)

		tween.chain().tween_callback(func():

			if is_instance_valid(panel):

				panel.visible = false
				panel.modulate.a = 1.0

				panel.scale = Vector2.ONE

		)

		if panel == _start_menu:

			_start_menu_tween = tween

		elif panel == _quick_settings_panel:

			_quick_settings_tween = tween
		elif panel == _notification_center:
			_notification_tween = tween
		else:
			_calendar_tween = tween

func _open_window(title: String, message: String, window_size := Vector2(520, 300)) -> Control:

	_start_menu.visible = false

	_start_open = false

	# Opening an app from the desktop must not leave the Show Desktop state stale.

	if _show_desktop_active:

		for hidden_app in _desktop_hidden_windows:

			if is_instance_valid(hidden_app):

				hidden_app.show()

				hidden_app.move_to_front()

		_desktop_hidden_windows.clear()

		_show_desktop_active = false

	# Keep the simulated desktop bounded: opening apps repeatedly must not

	# accumulate an unlimited number of live Control trees.

	const MAX_OPEN_WINDOWS := 8

	while _window_layer.get_child_count() >= MAX_OPEN_WINDOWS:

		var oldest_window := _window_layer.get_child(0)

		_window_layer.remove_child(oldest_window)

		oldest_window.queue_free()

	var app_script := load(APP_WINDOW_SCRIPT_PATH) as GDScript
	if app_script == null:
		push_error("Impossible de charger %s. Vérifiez que le fichier existe et que le dépôt est complet." % APP_WINDOW_SCRIPT_PATH)
		_show_notification("Fichier manquant", "Impossible d’ouvrir une fenêtre : scripts/app_window.gd est absent ou contient une erreur.")
		return

	var app_instance: Object = app_script.new()
	if not app_instance is Control:
		push_error("%s doit hériter de Control." % APP_WINDOW_SCRIPT_PATH)
		return
	var app := app_instance as Control

	_window_layer.add_child(app)

	app.call("configure", title, message, window_size)

	var app_id := _app_id_for_title(title)

	app.set_meta("app_id", app_id)
	app.set_meta("window_title", title)

	_recent_app_title = title

	_recent_app_message = message

	_recent_app_size = window_size

	if is_instance_valid(_recommended_recent_label):

		_recommended_recent_label.text = "%s\nOuvert récemment" % title

	if is_instance_valid(_recommended_recent_icon):

		_recommended_recent_icon.text = _glyph_for_app_id(app_id)

	app.connect("window_activated", func():
		_active_app_id = app_id
		_update_taskbar_indicators()
	)
	app.visibility_changed.connect(_update_taskbar_indicators)

	app.tree_exited.connect(func():

		if _active_app_id == app_id:

			_active_app_id = ""

		_update_taskbar_indicators()

	)

	app.position = (get_viewport_rect().size - window_size) / 2.0

	app.pivot_offset = window_size / 2.0

	app.modulate.a = 0.0

	app.scale = Vector2(0.985, 0.985)

	app.z_index = 20 + _window_layer.get_child_count()

	var appear := create_tween().set_parallel(true)

	appear.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	appear.tween_property(app, "modulate:a", 1.0, 0.16)

	appear.tween_property(app, "scale", Vector2.ONE, 0.18)

	_active_app_id = app_id

	_update_taskbar_indicators()

	return app

func _reopen_recent_app() -> void:

	if _recent_app_title.is_empty():

		_show_notification("Recommandé", "Ouvrez une application pour la retrouver ici.")

		return

	_open_window(_recent_app_title, _recent_app_message, _recent_app_size)

func _glyph_for_app_id(app_id: String) -> String:

	match app_id:

		"browser":

			return "🌐"

		"files":

			return "📁"

		"settings":

			return "⚙"

		"update":

			return "↻"

		"recycle_bin":

			return "🗑"

		_:

			return "◷"

func _app_id_for_title(title: String) -> String:

	var normalized := title.to_lower()

	if normalized.contains("browser"):

		return "browser"

	if normalized.contains("explorateur") or normalized.contains("fichiers"):

		return "files"

	if normalized.contains("paramètres"):

		return "settings"

	if normalized.contains("update") or normalized.contains("mise à jour"):

		return "update"

	return normalized

func _open_files() -> void:

	if _mission_step == 1:

		_advance_mission("Explorateur ouvert. Vos fichiers restent fictifs.")

	var app := _open_window("Explorateur de fichiers", "Accueil", Vector2(820, 540))

	var content := _get_window_content(app)

	if content == null:

		return

	for child in content.get_children():

		child.queue_free()


	var toolbar := HBoxContainer.new()

	toolbar.add_theme_constant_override("separation", 6)

	content.add_child(toolbar)

	for caption in ["←", "→", "↑", "⟳"]:

		var nav := Button.new()

		match caption:

			"←": nav.name = "ExplorerBackButton"

			"→": nav.name = "ExplorerForwardButton"

			"↑": nav.name = "ExplorerUpButton"

			"⟳": nav.name = "ExplorerRefreshButton"

		nav.text = caption

		nav.custom_minimum_size = Vector2(36, 34)

		nav.add_theme_font_size_override("font_size", 17)

		nav.tooltip_text = {"←": "Précédent", "→": "Suivant", "↑": "Remonter", "⟳": "Actualiser"}[caption]

		nav.focus_mode = Control.FOCUS_NONE

		nav.add_theme_stylebox_override("normal", _flat_style(Color("edf2f8"), 8))

		nav.add_theme_stylebox_override("hover", _flat_style(Color("dce8f7"), 8))

		nav.add_theme_stylebox_override("disabled", _flat_style(Color("f5f7fa"), 8))

		nav.add_theme_color_override("font_disabled_color", Color("aab5c4"))

		nav.pressed.connect(_explorer_toolbar_action.bind(caption, content))

		toolbar.add_child(nav)

	var address := LineEdit.new()

	address.name = "ExplorerAddress"

	address.text = "Accueil"

	address.set_meta("explorer_history", ["Accueil"])

	address.set_meta("explorer_history_index", 0)

	address.placeholder_text = "Chemin d’accès"

	address.clear_button_enabled = true

	address.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	address.custom_minimum_size.y = 34

	address.add_theme_stylebox_override("normal", _flat_style(Color("ffffff"), 8))

	toolbar.add_child(address)

	_refresh_explorer_navigation_buttons(address)

	var search := LineEdit.new()

	search.name = "ExplorerSearch"

	search.placeholder_text = "Rechercher dans Accueil"

	search.clear_button_enabled = true

	search.custom_minimum_size = Vector2(190, 34)

	search.add_theme_stylebox_override("normal", _flat_style(Color("ffffff"), 8))

	toolbar.add_child(search)


	var separator := HSeparator.new()

	content.add_child(separator)

	var main_row := HBoxContainer.new()

	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL

	main_row.add_theme_constant_override("separation", 12)

	content.add_child(main_row)


	var sidebar := VBoxContainer.new()

	sidebar.custom_minimum_size.x = 150

	sidebar.add_theme_constant_override("separation", 5)

	main_row.add_child(sidebar)

	# Declare these before wiring navigation callbacks; their controls are built below.

	var quick_title: Label

	var empty_state: Label

	var nav_buttons: Array[Button] = []

	var folder_tiles: Array[Button] = []

	var nav_title := Label.new()

	nav_title.text = "Accueil"

	nav_title.add_theme_font_size_override("font_size", 14)

	nav_title.add_theme_color_override("font_color", Color("1c2738"))

	sidebar.add_child(nav_title)

	for caption in ["🏠  Accueil", "🖥  Bureau", "⬇  Téléchargements", "📄  Documents", "🖼  Images", "🎵  Musique", "🎬  Vidéos", "💾  Ce PC"]:

		var nav_item := Button.new()

		nav_item.text = caption

		nav_item.alignment = HORIZONTAL_ALIGNMENT_LEFT

		nav_item.custom_minimum_size.y = 32

		nav_item.add_theme_font_size_override("font_size", 12)

		nav_item.add_theme_color_override("font_color", Color("1f3048"))

		nav_item.set_meta("explorer_path", caption.replace("🏠  ", "").replace("🖥  ", "").replace("⬇  ", "").replace("📄  ", "").replace("🖼  ", "").replace("🎵  ", "").replace("🎬  ", "").replace("💾  ", "").strip_edges())

		nav_item.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 6))

		nav_item.add_theme_stylebox_override("hover", _flat_style(Color("e5edf8"), 6))

		nav_item.add_theme_stylebox_override("pressed", _flat_style(Color("d2e3f8"), 6))

		nav_item.focus_mode = Control.FOCUS_NONE

		nav_buttons.append(nav_item)

		sidebar.add_child(nav_item)

	address.set_meta("explorer_nav_buttons", nav_buttons)

	var right_pane := VBoxContainer.new()

	right_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	right_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL

	right_pane.add_theme_constant_override("separation", 10)

	main_row.add_child(right_pane)

	quick_title = Label.new()

	quick_title.name = "ExplorerHeading"

	quick_title.text = "Accès rapide"
	quick_title.add_theme_font_size_override("font_size", 20)

	quick_title.add_theme_color_override("font_color", Color("182235"))
	right_pane.add_child(quick_title)

	var quick_grid := GridContainer.new()

	quick_grid.columns = 2

	quick_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	quick_grid.add_theme_constant_override("h_separation", 10)

	quick_grid.add_theme_constant_override("v_separation", 8)

	right_pane.add_child(quick_grid)

	var folders := [

		{"name": "Bureau", "glyph": "🖥", "detail": "Raccourcis et éléments du bureau"},

		{"name": "Téléchargements", "glyph": "⬇", "detail": "Aucun fichier pour le moment"},

		{"name": "Documents", "glyph": "📄", "detail": "Vos documents simulés"},

		{"name": "Images", "glyph": "🖼", "detail": "Aucune image pour le moment"}

	]

	for folder in folders:

		var tile := Button.new()

		tile.custom_minimum_size = Vector2(220, 72)

		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		tile.alignment = HORIZONTAL_ALIGNMENT_LEFT

		tile.add_theme_stylebox_override("normal", _flat_style(Color("f5f8fc"), 9))

		tile.add_theme_stylebox_override("hover", _flat_style(Color("e4eefb"), 9))

		tile.add_theme_stylebox_override("pressed", _flat_style(Color("d5e5fa"), 9))

		tile.text = "%s   %s\n       %s" % [str(folder["glyph"]), str(folder["name"]), str(folder["detail"])]

		tile.add_theme_font_size_override("font_size", 12)

		tile.add_theme_color_override("font_color", Color("243249"))

		folder_tiles.append(tile)

		quick_grid.add_child(tile)

	var recent_title := Label.new()

	recent_title.text = "Fichiers récents"

	recent_title.add_theme_font_size_override("font_size", 16)

	recent_title.add_theme_color_override("font_color", Color("182235"))

	right_pane.add_child(recent_title)

	empty_state = Label.new()

	empty_state.name = "ExplorerStatus"

	empty_state.text = "Aucun fichier récent. Les fichiers personnels ne sont pas consultés."

	empty_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	empty_state.add_theme_color_override("font_color", Color("66758b"))

	right_pane.add_child(empty_state)

	# Connect after target controls exist: bind() captures values immediately.

	var nav_captions := ["🏠  Accueil", "🖥  Bureau", "⬇  Téléchargements", "📄  Documents", "🖼  Images", "🎵  Musique", "🎬  Vidéos", "💾  Ce PC"]

	for index in range(nav_buttons.size()):

		nav_buttons[index].pressed.connect(_set_explorer_location.bind(nav_captions[index], address, quick_title, empty_state))

	for index in range(folder_tiles.size()):

		folder_tiles[index].pressed.connect(_set_explorer_location.bind(str(folders[index]["name"]), address, quick_title, empty_state))

	address.text_submitted.connect(func(path: String):

		var normalized_path := path.strip_edges()

		if not normalized_path.is_empty():

			_set_explorer_location(normalized_path, address, quick_title, empty_state)

			search.placeholder_text = "Rechercher dans %s" % normalized_path

	)

	address.text_changed.connect(func(path: String):

		search.placeholder_text = "Rechercher dans %s" % (path if not path.strip_edges().is_empty() else "Accueil")

	)

	_set_explorer_location("Accueil", address, quick_title, empty_state, false)

	var footer := Label.new()

	footer.text = "4 dossiers   •   Cet explorateur utilise uniquement des données fictives"

	footer.add_theme_font_size_override("font_size", 11)

	footer.add_theme_color_override("font_color", Color("718096"))

	content.add_child(footer)


	search.text_changed.connect(func(query: String):

		var normalized := query.strip_edges().to_lower()

		for index in range(quick_grid.get_child_count()):

			var tile := quick_grid.get_child(index) as Button

			tile.visible = normalized.is_empty() or tile.text.to_lower().contains(normalized)

		empty_state.visible = normalized.is_empty() or quick_grid.get_child_count() == 0

		if not normalized.is_empty():

			var any_visible := false

			for child in quick_grid.get_children():

				if child.visible:

					any_visible = true

			empty_state.visible = not any_visible

			if not any_visible:

				empty_state.text = "Aucun dossier ne correspond à « %s »." % query

		else:

			empty_state.text = "Aucun fichier récent. Les fichiers personnels ne sont pas consultés."

	)

func _explorer_toolbar_action(action: String, content: VBoxContainer) -> void:

	var address := content.find_child("ExplorerAddress", true, false) as LineEdit

	var search := content.find_child("ExplorerSearch", true, false) as LineEdit

	var heading := content.find_child("ExplorerHeading", true, false) as Label

	var status := content.find_child("ExplorerStatus", true, false) as Label

	if address == null or search == null or heading == null or status == null:

		return

	var history: Array = address.get_meta("explorer_history", ["Accueil"])

	var history_index := int(address.get_meta("explorer_history_index", 0))

	match action:

		"←":

			if history_index > 0:

				history_index -= 1

				address.set_meta("explorer_history_index", history_index)

				_set_explorer_location(str(history[history_index]), address, heading, status, false)

		"→":

			if history_index + 1 < history.size():

				history_index += 1

				address.set_meta("explorer_history_index", history_index)

				_set_explorer_location(str(history[history_index]), address, heading, status, false)

		"↑":

			_set_explorer_location("Accueil", address, heading, status)

		"⟳":

			search.clear()

			_set_explorer_location(address.text, address, heading, status, false)

	search.placeholder_text = "Rechercher dans %s" % address.text

	_refresh_explorer_navigation_buttons(address)

func _refresh_explorer_navigation_buttons(address: LineEdit) -> void:

	var history: Array = address.get_meta("explorer_history", ["Accueil"])

	var history_index := int(address.get_meta("explorer_history_index", 0))

	var toolbar := address.get_parent()

	if toolbar == null:

		return

	var back := toolbar.get_node_or_null("ExplorerBackButton") as Button

	var forward := toolbar.get_node_or_null("ExplorerForwardButton") as Button

	if back != null:

		back.disabled = history_index <= 0

	if forward != null:

		forward.disabled = history_index >= history.size() - 1

func _set_explorer_location(path: String, address: LineEdit, heading: Label, status: Label, record_history: bool = true) -> void:

	var clean_path := path.replace("🏠  ", "").replace("🖥  ", "").replace("⬇  ", "").replace("📄  ", "").replace("🖼  ", "").replace("🎵  ", "").replace("🎬  ", "").replace("💾  ", "").strip_edges()

	if clean_path.is_empty():

		clean_path = "Accueil"

	if record_history:

		var history: Array = address.get_meta("explorer_history", ["Accueil"])

		var history_index := int(address.get_meta("explorer_history_index", history.size() - 1))

		while history.size() > history_index + 1:

			history.pop_back()

		if history.is_empty() or str(history.back()) != clean_path:

			history.append(clean_path)

		address.set_meta("explorer_history", history)

		address.set_meta("explorer_history_index", history.size() - 1)

	address.text = clean_path

	heading.text = clean_path

	status.text = "Aucun élément à afficher dans %s. Le contenu personnel reste inaccessible." % clean_path

	_refresh_explorer_navigation_buttons(address)

	var nav_buttons: Array = address.get_meta("explorer_nav_buttons", [])

	for nav_item in nav_buttons:

		if not is_instance_valid(nav_item):

			continue

		var selected := str(nav_item.get_meta("explorer_path", "")) == clean_path

		nav_item.add_theme_stylebox_override("normal", _flat_style(Color("dce9f8") if selected else Color(0, 0, 0, 0), 6))

		nav_item.add_theme_color_override("font_color", Color("075eb5") if selected else Color("1f3048"))

	var grid := heading.get_parent().get_node_or_null("GridContainer") as GridContainer

	if grid == null:

		return

	for child in grid.get_children():

		if child is Button:

			child.visible = clean_path == "Accueil" or child.text.to_lower().contains(clean_path.to_lower())

func _open_browser() -> void:

	var app := _open_window("Microslop Browser", "Votre navigateur nouvelle génération.", Vector2(680, 400))

	var content := _get_window_content(app)

	if content == null:

		return

	var address := LineEdit.new()

	address.placeholder_text = "Rechercher sur le Web ou saisir une adresse"

	address.text = "comment travailler sans être interrompu"

	content.add_child(address)

	var results := Label.new()

	results.text = "Résultat sponsorisé : Achetez Microslop Premium pour réduire les interruptions de 3 %."

	results.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	results.add_theme_color_override("font_color", Color("263247"))

	content.add_child(results)

	var search := Button.new()

	search.text = "Rechercher"

	search.pressed.connect(func():

		results.text = "Résultats pour : « %s »\\n\\n1. Microslop Premium — SPONSORISÉ\\n2. Microslop AI — recommandé\\n3. Résultat utile masqué par les annonces." % address.text

	)

	content.add_child(search)
func _open_recycle_bin() -> void:

	_open_window("Corbeille", "La corbeille est vide.\n\nElle a tout de même besoin d'une mise à jour de 4,7 Go.", Vector2(440, 240))

func _open_ai() -> void:

	var app := _open_window("Microslop AI", "Bonjour ! J'ai analysé votre demande et préparé 46 suggestions.", Vector2(500, 330))

	var content := _get_window_content(app)

	if content == null:

		return

	var response := Label.new()
	response.text = "Vous vouliez ouvrir le Bloc-notes ? Je peux plutôt vous proposer un abonnement."

	response.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	response.add_theme_color_override("font_color", Color("263247"))
	content.add_child(response)

	var suggestion := Button.new()

	suggestion.text = "Générer une autre suggestion"

	suggestion.pressed.connect(func():

		var suggestions := ["Avez-vous essayé de redémarrer votre redémarrage ?", "Votre productivité serait 2 % meilleure avec Premium.", "J'ai trouvé 18 solutions. Aucune ne répond à la question.", "Souhaitez-vous résumer ce bouton avec l'IA ?"]

		response.text = suggestions[randi() % suggestions.size()]

	)

	content.add_child(suggestion)

func _open_search() -> void:

	_open_window("Recherche Microslop", "Résultats pour : « ouvrir une application »\n\n1. Microslop Premium — SPONSORISÉ\n2. Microslop AI — recommandé\n3. L'application que vous recherchiez (peut-être).", Vector2(560, 300))

func _trigger_update() -> void:

	if _mission_step == 2:

		_advance_mission("Mise à jour consultée. Elle reste à 99 %, évidemment.")

	_open_window("Microslop Update", "Une mise à jour importante est disponible.\n\nMicroslop Experience Update 1.0.99 (préversion)\nProgression : 99 %\n\nNe fermez pas votre ordinateur. Cette opération peut prendre quelques instants…", Vector2(520, 280))

	var app := _window_layer.get_child(_window_layer.get_child_count() - 1) as Control

	var content := _get_window_content(app)

	if content != null:

		var later := Button.new()

		later.text = "Me rappeler dans 5 minutes"

		later.pressed.connect(func():

			_show_notification("Rappel programmé", "Nous vous rappellerons quand vous serez occupé.")

			app.queue_free()

		)

		content.add_child(later)

	_show_notification("Mise à jour en attente", "Redémarrage recommandé. Nous choisirons le moment.")

func _open_settings() -> void:

	_start_menu.visible = false

	_start_open = false

	_quick_settings_panel.visible = false

	var panel := _open_window("Paramètres", "Configurez l'affichage, le son, les performances et la langue.", Vector2(560, 620))

	var layout := panel.get_child(0) as VBoxContainer

	var body := layout.get_child(1) as MarginContainer

	var content := body.get_child(0) as VBoxContainer

	content.get_child(0).queue_free()

	var settings_scroll := ScrollContainer.new()

	settings_scroll.name = "SettingsScroll"

	settings_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	settings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	body.remove_child(content)

	body.add_child(settings_scroll)

	settings_scroll.add_child(content)

	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL


	_add_settings_section(content, "Système", "Affichage et comportement de la fenêtre")

	var display_label := Label.new()

	display_label.text = "Mode d'affichage"

	display_label.add_theme_color_override("font_color", Color("263247"))

	content.add_child(display_label)


	var display := OptionButton.new()

	var modes := ["Fenêtré", "Plein écran sans bordures", "Plein écran exclusif"]

	for mode_name in modes:

		display.add_item(mode_name)

	var current_mode := str(SettingsStore.values.get("display_mode", "Fenêtré"))

	for i in range(modes.size()):

		if modes[i] == current_mode:

			display.select(i)

	display.item_selected.connect(func(index: int):

		SettingsStore.values["display_mode"] = display.get_item_text(index)

		SettingsStore.apply_display_settings()

		SettingsStore.save_settings()

	)

	content.add_child(display)


	var resolution_label := Label.new()

	resolution_label.text = "Résolution (mode fenêtré)"

	resolution_label.add_theme_color_override("font_color", Color("263247"))

	content.add_child(resolution_label)


	var resolution := OptionButton.new()

	var resolutions := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

	for size in resolutions:

		resolution.add_item("%d × %d" % [size.x, size.y])

	var current_resolution: Vector2i = SettingsStore.values.get("resolution", Vector2i(1280, 720))

	for i in range(resolutions.size()):

		if resolutions[i] == current_resolution:

			resolution.select(i)

	resolution.item_selected.connect(func(index: int):

		SettingsStore.values["resolution"] = resolutions[index]

		SettingsStore.apply_display_settings()

		SettingsStore.save_settings()

	)

	content.add_child(resolution)


	var vsync := CheckBox.new()

	vsync.text = "Synchronisation verticale (V-Sync)"

	vsync.button_pressed = bool(SettingsStore.values.get("vsync", true))

	vsync.add_theme_color_override("font_color", Color("263247"))

	vsync.toggled.connect(func(enabled: bool):

		SettingsStore.values["vsync"] = enabled

		SettingsStore.apply_display_settings()

		SettingsStore.save_settings()

	)

	content.add_child(vsync)


	_add_settings_section(content, "Performances", "Ajustez la fluidité de l’expérience")

	var fps_label := Label.new()

	fps_label.text = "Limite d'images par seconde"

	fps_label.add_theme_color_override("font_color", Color("263247"))

	content.add_child(fps_label)


	var fps_limit := OptionButton.new()

	var fps_options := [0, 30, 60, 120, 144, 240]

	for fps in fps_options:

		fps_limit.add_item("Illimitée" if fps == 0 else "%d FPS" % fps)

	var current_fps := int(SettingsStore.values.get("fps_limit", 0))

	for i in range(fps_options.size()):

		if fps_options[i] == current_fps:

			fps_limit.select(i)

	fps_limit.item_selected.connect(func(index: int):

		SettingsStore.values["fps_limit"] = fps_options[index]

		SettingsStore.apply_display_settings()

		SettingsStore.save_settings()

	)

	content.add_child(fps_limit)


	_add_settings_section(content, "Audio", "Réglez le niveau sonore général")

	var volume_label := Label.new()

	volume_label.text = "Volume général"

	volume_label.add_theme_color_override("font_color", Color("263247"))

	content.add_child(volume_label)


	var volume := HSlider.new()

	volume.min_value = 0.0

	volume.max_value = 100.0

	volume.step = 1.0

	volume.value = float(SettingsStore.values.get("master_volume", 0.8)) * 100.0

	volume.custom_minimum_size.x = 220

	volume.value_changed.connect(func(value: float):

		SettingsStore.values["master_volume"] = value / 100.0

		SettingsStore.apply_audio_settings()

		SettingsStore.save_settings()

	)

	content.add_child(volume)


	_add_settings_section(content, "Préférences", "Personnalisez votre expérience")

	var language_label := Label.new()

	language_label.text = "Langue"

	language_label.add_theme_color_override("font_color", Color("263247"))

	content.add_child(language_label)


	var language := OptionButton.new()

	language.add_item("Français")

	language.add_item("English")

	language.select(0 if SettingsStore.values.get("language", "Français") == "Français" else 1)

	language.item_selected.connect(func(index: int):

		SettingsStore.values["language"] = language.get_item_text(index)

		SettingsStore.save_settings()

		_show_notification("Langue enregistrée", "La traduction complète sera ajoutée dans une phase ultérieure.")

	)

	content.add_child(language)


	var note := Label.new()

	note.text = "Les options sont enregistrées entre les sessions. Plus d'options arriveront pendant le développement."

	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	note.add_theme_color_override("font_color", Color("596780"))

	content.add_child(note)

func _add_settings_section(parent: VBoxContainer, heading_text: String, subtitle_text: String) -> void:

	var heading := Label.new()

	heading.text = heading_text

	heading.add_theme_font_size_override("font_size", 18)

	heading.add_theme_color_override("font_color", Color("17243a"))

	parent.add_child(heading)

	var subtitle := Label.new()
	subtitle.text = subtitle_text

	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	subtitle.add_theme_font_size_override("font_size", 11)

	subtitle.add_theme_color_override("font_color", Color("66758b"))

	parent.add_child(subtitle)

	var separator := HSeparator.new()

	parent.add_child(separator)

func _get_window_content(app: Control) -> VBoxContainer:

	if app.get_child_count() == 0:
		return null

	var layout := app.get_child(0) as VBoxContainer

	if layout == null or layout.get_child_count() < 2:

		return null
	var body := layout.get_child(1) as MarginContainer

	if body == null or body.get_child_count() == 0:

		return null

	return body.get_child(0) as VBoxContainer

func _show_notification(title: String, message: String) -> void:

	if not is_instance_valid(_notification_layer):

		return

	_notification_history.append({"title": title, "message": message, "time": Time.get_time_string_from_system().substr(0, 5)})

	while _notification_history.size() > 20:

		_notification_history.pop_front()

	_refresh_notification_center()

	var card := PanelContainer.new()

	var notification_style := _flat_style(Color(0.96, 0.97, 0.99, 0.97), 12)

	notification_style.shadow_color = Color(0.02, 0.04, 0.10, 0.20)

	notification_style.shadow_size = 10

	notification_style.shadow_offset = Vector2(0, 3)

	notification_style.set_border_width_all(1)

	notification_style.border_color = Color(1, 1, 1, 0.72)

	card.add_theme_stylebox_override("panel", notification_style)

	_notification_layer.add_child(card)

	var margin := MarginContainer.new()

	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:

		margin.add_theme_constant_override(side, 12)

	card.add_child(margin)

	var layout := VBoxContainer.new()

	layout.add_theme_constant_override("separation", 4)

	margin.add_child(layout)

	var heading := Label.new()

	heading.text = title

	heading.add_theme_color_override("font_color", Color("182235"))

	heading.add_theme_font_size_override("font_size", 14)

	layout.add_child(heading)

	var body := Label.new()

	body.text = message

	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	body.add_theme_color_override("font_color", Color("34425b"))

	layout.add_child(body)

	# Toasts use the same short, restrained motion as Windows 11 notifications.

	card.modulate.a = 0.0

	card.scale = Vector2(0.97, 0.97)

	var toast_tween := create_tween().set_parallel(true)

	toast_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	toast_tween.tween_property(card, "modulate:a", 1.0, 0.18)

	toast_tween.tween_property(card, "scale", Vector2.ONE, 0.20)

	# queue_free() is deferred until the end of the frame. Remove the node

	# from its parent first, otherwise the child count never decreases here

	# and this loop can freeze the entire game on the fourth notification.

	while _notification_layer.get_child_count() > 3:

		var oldest := _notification_layer.get_child(0)

		_notification_layer.remove_child(oldest)

		oldest.queue_free()

	# Windows 11 toast notifications disappear after a short period unless
	# the user opens the notification center to review the history.
	var dismiss_tween := create_tween()
	dismiss_tween.tween_interval(5.0)
	dismiss_tween.tween_property(card, "modulate:a", 0.0, 0.24)
	dismiss_tween.tween_callback(func():
		if is_instance_valid(card) and is_instance_valid(card.get_parent()):
			card.get_parent().remove_child(card)
			card.queue_free()
	)

func _advance_mission(reason: String) -> void:

	var previous_step := _mission_step

	_mission_step = mini(_mission_step + 1, 3)

	_save_progress()

	_update_mission()

	if _mission_step != previous_step:

		_show_notification("Mission accomplie", reason)

func _load_progress() -> void:

	_mission_step = CampaignStore.load_progress()

func _save_progress() -> void:

	CampaignStore.save_progress(_mission_step)

func _update_mission() -> void:

	if not is_instance_valid(_mission_label):

		return

	var missions := [

		"MISSION 01\nOuvrir le menu Démarrer.\n\nRécompense : une recommandation sponsorisée.",

		"MISSION 02\nOuvrir l'explorateur de fichiers.\n\nLe système respecte votre vie privée (promis).",

		"MISSION 03\nConsulter les mises à jour.\n\nProgression estimée : presque terminée.",

		"MISSION TERMINÉE\nVous avez utilisé votre ordinateur.\n\nUne enquête de satisfaction est disponible."

	]

	_mission_label.text = missions[mini(_mission_step, missions.size() - 1)]

func _dismiss_flyouts_on_outside_click(pointer_position: Vector2) -> void:

	if is_instance_valid(_start_menu) and _start_menu.visible and not _start_menu.get_global_rect().has_point(pointer_position):
		_start_open = false
		_animate_flyout(_start_menu, false, false)

	if is_instance_valid(_quick_settings_panel) and _quick_settings_panel.visible and not _quick_settings_panel.get_global_rect().has_point(pointer_position):
		_animate_flyout(_quick_settings_panel, false, true)

	if is_instance_valid(_calendar_panel) and _calendar_panel.visible and not _calendar_panel.get_global_rect().has_point(pointer_position):
		_animate_flyout(_calendar_panel, false, true)

	if is_instance_valid(_notification_center) and _notification_center.visible and not _notification_center.get_global_rect().has_point(pointer_position):
		_animate_flyout(_notification_center, false, true)


func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_dismiss_flyouts_on_outside_click(event.position)
		# A desktop context menu should close as soon as the user clicks elsewhere,
		# just like the native Windows shell. Keep it open when interacting inside it.
		if is_instance_valid(_desktop_context_menu) and _desktop_context_menu.visible:
			if not _desktop_context_menu.get_global_rect().has_point(event.position):
				_desktop_context_menu.hide()
		if is_instance_valid(_desktop_icon_context_menu) and _desktop_icon_context_menu.visible:
			if not _desktop_icon_context_menu.get_global_rect().has_point(event.position):
				_desktop_icon_context_menu.hide()
		if is_instance_valid(_desktop_icon_context_menu) and _desktop_icon_context_menu.visible:
			if not _desktop_icon_context_menu.get_global_rect().has_point(event.position):
				_desktop_icon_context_menu.hide()
				_context_desktop_icon = null
		# Clicking empty desktop space clears the icon selection.
		if is_instance_valid(_desktop_icons) and not _is_pointer_over_desktop_icon(event.position):
			_clear_desktop_icon_selection()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:

		if _is_pointer_over_window(event.position):

			return

		var clicked_desktop_icon := _get_desktop_icon_at(event.position)
		if is_instance_valid(clicked_desktop_icon):
			_show_desktop_icon_context_menu(event.position, clicked_desktop_icon)
			get_viewport().set_input_as_handled()
			return

		if _start_menu.visible or _quick_settings_panel.visible:

			_start_menu.visible = false

			_start_open = false

			_quick_settings_panel.visible = false

			return

		_show_desktop_context_menu(event.position)

	elif event is InputEventKey and event.pressed and not event.echo:

		if event.keycode == KEY_ESCAPE:

			var closed_flyout := false

			if is_instance_valid(_start_menu) and _start_menu.visible:

				_start_menu.visible = false

				_start_open = false

				closed_flyout = true

			if is_instance_valid(_quick_settings_panel) and _quick_settings_panel.visible:

				_quick_settings_panel.visible = false

				closed_flyout = true

			if is_instance_valid(_calendar_panel) and _calendar_panel.visible:

				_calendar_panel.visible = false

				closed_flyout = true

			if is_instance_valid(_notification_center) and _notification_center.visible:

				_notification_center.visible = false

				closed_flyout = true

			if is_instance_valid(_quick_link_menu) and _quick_link_menu.visible:

				_quick_link_menu.visible = false

				closed_flyout = true

			if is_instance_valid(_task_view_panel) and _task_view_panel.visible:

				_task_view_panel.queue_free()

				_task_view_panel = null

				closed_flyout = true

			if is_instance_valid(_desktop_context_menu) and is_instance_valid(_desktop_context_menu.get_parent()):

				_desktop_context_menu.queue_free()

				_desktop_context_menu = null

				closed_flyout = true

			if is_instance_valid(_desktop_icon_context_menu) and is_instance_valid(_desktop_icon_context_menu.get_parent()):
				_desktop_icon_context_menu.queue_free()
				_desktop_icon_context_menu = null
				_context_desktop_icon = null
				closed_flyout = true

			if closed_flyout:

				get_viewport().set_input_as_handled()

		elif event.meta_pressed and event.keycode == KEY_TAB:
			_toggle_task_view()
			get_viewport().set_input_as_handled()
		elif event.meta_pressed and event.keycode == KEY_LEFT:
			var active_window := _find_app_window(_active_app_id)
			if is_instance_valid(active_window):
				active_window.call("_apply_snap_layout", "left")
				get_viewport().set_input_as_handled()
		elif event.meta_pressed and event.keycode == KEY_RIGHT:
			var active_window := _find_app_window(_active_app_id)
			if is_instance_valid(active_window):
				active_window.call("_apply_snap_layout", "right")
				get_viewport().set_input_as_handled()
		elif event.meta_pressed and event.keycode == KEY_UP:
			var active_window := _find_app_window(_active_app_id)
			if is_instance_valid(active_window):
				active_window.call("_toggle_maximize")
				get_viewport().set_input_as_handled()
		elif event.meta_pressed and event.keycode == KEY_DOWN:
			var active_window := _find_app_window(_active_app_id)
			if is_instance_valid(active_window):
				if bool(active_window.get("_is_maximized")) or str(active_window.get("_snap_mode")) != "":
					active_window.call("_toggle_maximize")
				else:
					active_window.call("_animate_minimize")
					_active_app_id = ""
					_update_taskbar_indicators()
				get_viewport().set_input_as_handled()
		elif event.meta_pressed and event.keycode == KEY_X:

			_toggle_quick_link_menu()

			get_viewport().set_input_as_handled()

		elif event.meta_pressed and event.keycode == KEY_D:

			_toggle_show_desktop()

			get_viewport().set_input_as_handled()

		elif event.meta_pressed and event.keycode == KEY_E:

			_open_files()

			get_viewport().set_input_as_handled()

		elif event.meta_pressed and event.keycode == KEY_I:

			_open_settings()

			get_viewport().set_input_as_handled()

		elif event.meta_pressed and event.keycode == KEY_S:

			_open_search()

			get_viewport().set_input_as_handled()

		elif event.alt_pressed and event.keycode == KEY_F4:

			_close_active_window()

			get_viewport().set_input_as_handled()

		elif event.ctrl_pressed and event.keycode == KEY_W:

			_close_active_window()

			get_viewport().set_input_as_handled()

		elif event.ctrl_pressed and event.keycode == KEY_E:

			_open_files()

			get_viewport().set_input_as_handled()

		elif event.ctrl_pressed and event.keycode == KEY_I:

			_open_settings()

			get_viewport().set_input_as_handled()

		elif event.ctrl_pressed and event.keycode == KEY_A:

			_toggle_quick_settings()

			get_viewport().set_input_as_handled()

		elif event.ctrl_pressed and event.keycode == KEY_N:

			_toggle_notification_center()

			get_viewport().set_input_as_handled()

		elif event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_ESCAPE:

			_open_window("Gestionnaire des tâches", "Applications ouvertes : %d\n\nPerformances simulées · CPU : 7 % · Mémoire : 42 %." % _window_layer.get_child_count(), Vector2(500, 300))

			get_viewport().set_input_as_handled()

		elif event.keycode == KEY_F1:

			_open_settings()

		elif event.keycode == KEY_F2:

			_advance_mission("Progression de la campagne avancée manuellement pour le prototype.")

func _close_active_window() -> void:

	if not is_instance_valid(_window_layer):

		return

	for index in range(_window_layer.get_child_count() - 1, -1, -1):

		var window := _window_layer.get_child(index)

		if window is Control and window.visible:

			window.queue_free()

			return

func _is_pointer_over_window(pointer: Vector2) -> bool:

	if not is_instance_valid(_window_layer):

		return false

	for child in _window_layer.get_children():

		if child is Control and child.visible and child.get_global_rect().has_point(pointer):

			return true

	return false

func _get_desktop_icon_at(pointer: Vector2) -> Button:
	if not is_instance_valid(_desktop_icons):
		return null
	for child in _desktop_icons.get_children():
		if child is Button and child.visible and child.get_global_rect().has_point(pointer):
			return child
	return null

func _show_desktop_icon_context_menu(pointer: Vector2, icon_button: Button) -> void:
	if not is_instance_valid(icon_button):
		return
	_context_desktop_icon = icon_button
	_clear_desktop_icon_selection()
	icon_button.add_theme_stylebox_override("normal", _flat_style(Color(0.35, 0.55, 0.88, 0.36), 7))
	if is_instance_valid(_desktop_context_menu):
		_desktop_context_menu.hide()
	if not is_instance_valid(_desktop_icon_context_menu):
		_desktop_icon_context_menu = PanelContainer.new()
		_desktop_icon_context_menu.name = "DesktopIconContextMenu"
		_desktop_icon_context_menu.z_index = 101
		var menu_style := _flat_style(Color(0.96, 0.97, 0.99, 0.985), 12)
		menu_style.shadow_color = Color(0.02, 0.04, 0.10, 0.30)
		menu_style.shadow_size = 20
		menu_style.shadow_offset = Vector2(0, 4)
		menu_style.set_border_width_all(1)
		menu_style.border_color = Color(1, 1, 1, 0.78)
		_desktop_icon_context_menu.add_theme_stylebox_override("panel", menu_style)
		var margin := MarginContainer.new()
		for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
			margin.add_theme_constant_override(side, 6)
		_desktop_icon_context_menu.add_child(margin)
		var items := VBoxContainer.new()
		items.add_theme_constant_override("separation", 3)
		margin.add_child(items)
		_add_context_action(items, "Ouvrir", func():
			if is_instance_valid(_context_desktop_icon):
				var open_callback: Callable = _context_desktop_icon.get_meta("desktop_open_callback", Callable())
				if open_callback.is_valid():
					open_callback.call()
		)
		var separator := HSeparator.new()
		items.add_child(separator)
		_add_context_action(items, "Épingler à la barre des tâches", func():
			if is_instance_valid(_context_desktop_icon):
				_show_notification("Barre des tâches", "%s : l’épinglage sera disponible dans la personnalisation du shell." % str(_context_desktop_icon.get_meta("desktop_caption", "Application")))
		)
		_add_context_action(items, "Renommer", func():
			if is_instance_valid(_context_desktop_icon):
				_show_notification("Renommer", "Le renommage des raccourcis sera disponible avec la gestion des fichiers.")
		)
		_add_context_action(items, "Propriétés", func():
			if is_instance_valid(_context_desktop_icon):
				_show_notification("Propriétés", "%s\nRaccourci du bureau Microslop Experience." % str(_context_desktop_icon.get_meta("desktop_caption", "Application")))
		)
		add_child(_desktop_icon_context_menu)
	_desktop_icon_context_menu.visible = true
	var viewport_size := get_viewport_rect().size
	var menu_size := _desktop_icon_context_menu.get_combined_minimum_size()
	_desktop_icon_context_menu.position = Vector2(
		clampf(pointer.x, 8.0, maxf(8.0, viewport_size.x - menu_size.x - 8.0)),
		clampf(pointer.y, 8.0, maxf(8.0, viewport_size.y - menu_size.y - 8.0))
	)
	_desktop_icon_context_menu.pivot_offset = menu_size / 2.0
	_desktop_icon_context_menu.scale = Vector2(0.97, 0.97)
	_desktop_icon_context_menu.modulate.a = 0.0
	var menu_tween := create_tween()
	menu_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	menu_tween.set_parallel(true)
	menu_tween.tween_property(_desktop_icon_context_menu, "scale", Vector2.ONE, 0.15)
	menu_tween.tween_property(_desktop_icon_context_menu, "modulate:a", 1.0, 0.13)

func _is_pointer_over_desktop_icon(pointer: Vector2) -> bool:
	if not is_instance_valid(_desktop_icons):
		return false
	for child in _desktop_icons.get_children():
		if child is Control and child.visible and child.get_global_rect().has_point(pointer):
			return true
	return false

func _clear_desktop_icon_selection() -> void:
	if not is_instance_valid(_desktop_icons):
		return
	for child in _desktop_icons.get_children():
		if child is Button:
			child.add_theme_stylebox_override("normal", _flat_style(Color(0.1, 0.2, 0.38, 0.0), 7))

func _show_desktop_context_menu(pointer: Vector2) -> void:

	# Only one shell context menu can be open at a time, matching the desktop shell.
	if is_instance_valid(_desktop_icon_context_menu):
		_desktop_icon_context_menu.hide()
	_context_desktop_icon = null

	if not is_instance_valid(_desktop_context_menu):

		_desktop_context_menu = PanelContainer.new()

		_desktop_context_menu.name = "DesktopContextMenu"

		_desktop_context_menu.z_index = 100

		var menu_style := _flat_style(Color(0.96, 0.97, 0.99, 0.985), 12)

		menu_style.shadow_color = Color(0.02, 0.04, 0.10, 0.30)

		menu_style.shadow_size = 20

		menu_style.shadow_offset = Vector2(0, 4)

		menu_style.set_border_width_all(1)

		menu_style.border_color = Color(1, 1, 1, 0.78)

		_desktop_context_menu.add_theme_stylebox_override("panel", menu_style)

		var margin := MarginContainer.new()
		for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:

			margin.add_theme_constant_override(side, 6)

		_desktop_context_menu.add_child(margin)

		var items := VBoxContainer.new()

		items.add_theme_constant_override("separation", 3)

		margin.add_child(items)

		_add_context_action(items, "Afficher les icônes du bureau", func():

			if is_instance_valid(_desktop_icons):

				_desktop_icons.visible = not _desktop_icons.visible

		)

		_add_context_action(items, "Trier par  ›", func():
			_show_notification("Organisation", "Le tri sera disponible avec la gestion réelle des fichiers.")

		)

		_add_context_action(items, "Actualiser", func():

			_show_notification("Bureau actualisé", "Le bureau est déjà à jour. Aucun changement nécessaire.")

		)
		var separator := HSeparator.new()

		items.add_child(separator)

		_add_context_action(items, "Nouveau  ›", func():

			_show_notification("Nouveau", "La création de fichiers sera disponible dans l’explorateur.")

		)

		var separator_two := HSeparator.new()

		items.add_child(separator_two)

		_add_context_action(items, "Paramètres d’affichage", _open_settings)

		_add_context_action(items, "Personnaliser", func():

			_open_window("Personnalisation", "Arrière-plan\n\nLe bureau utilise le fond d’écran fourni avec Microslop Experience.\n\nCouleurs : bleu Windows · Mode : clair", Vector2(390, 240))

		)

		add_child(_desktop_context_menu)

	_desktop_context_menu.visible = true

	var viewport_size := get_viewport_rect().size

	var menu_size := _desktop_context_menu.size

	if menu_size == Vector2.ZERO:

		menu_size = _desktop_context_menu.get_combined_minimum_size()

	_desktop_context_menu.position = Vector2(

		clampf(pointer.x, 8.0, maxf(8.0, viewport_size.x - menu_size.x - 8.0)),

		clampf(pointer.y, 8.0, maxf(8.0, viewport_size.y - menu_size.y - 8.0))

	)

	# Windows 11 context menus appear with a subtle fade and scale, rather than
	# popping into place. Restart the entrance cleanly whenever the menu opens.
	_desktop_context_menu.pivot_offset = menu_size / 2.0
	_desktop_context_menu.scale = Vector2(0.97, 0.97)
	_desktop_context_menu.modulate.a = 0.0
	var menu_tween := create_tween()
	menu_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	menu_tween.set_parallel(true)
	menu_tween.tween_property(_desktop_context_menu, "scale", Vector2.ONE, 0.15)
	menu_tween.tween_property(_desktop_context_menu, "modulate:a", 1.0, 0.13)

func _add_context_action(parent: VBoxContainer, caption: String, callback: Callable) -> void:

	var button := Button.new()

	button.text = caption

	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	button.custom_minimum_size = Vector2(244, 38)

	button.add_theme_color_override("font_color", Color("24344d"))
	button.add_theme_font_size_override("font_size", 12)

	button.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 8))

	button.add_theme_stylebox_override("hover", _flat_style(Color("dce8f8"), 8))
	button.add_theme_stylebox_override("pressed", _flat_style(Color("cbdcf3"), 8))

	button.focus_mode = Control.FOCUS_NONE

	button.pressed.connect(func():

		if is_instance_valid(_desktop_context_menu):
			_desktop_context_menu.visible = false
		if is_instance_valid(_desktop_icon_context_menu):
			_desktop_icon_context_menu.visible = false

		callback.call()

	)

	parent.add_child(button)

func _toggle_task_view() -> void:

	if is_instance_valid(_task_view_panel):
		_task_view_panel.queue_free()
		_task_view_panel = null
		return

	_start_menu.visible = false
	_start_open = false
	_quick_settings_panel.visible = false
	_calendar_panel.visible = false
	if is_instance_valid(_notification_center):
		_notification_center.visible = false
	if is_instance_valid(_quick_link_menu):
		_quick_link_menu.queue_free()
		_quick_link_menu = null

	_task_view_panel = PanelContainer.new()
	_task_view_panel.name = "TaskViewPanel"
	_task_view_panel.z_index = 120
	var viewport_size := get_viewport_rect().size
	var panel_width := minf(720.0, maxf(280.0, viewport_size.x - 24.0))
	var panel_height := minf(440.0, maxf(220.0, viewport_size.y - 96.0))
	_task_view_panel.custom_minimum_size = Vector2(panel_width, 0)
	_task_view_panel.anchor_left = 0.5
	_task_view_panel.anchor_right = 0.5
	_task_view_panel.anchor_top = 0.5
	_task_view_panel.anchor_bottom = 0.5
	_task_view_panel.offset_left = -panel_width / 2.0
	_task_view_panel.offset_right = panel_width / 2.0
	_task_view_panel.offset_top = -panel_height / 2.0
	_task_view_panel.offset_bottom = panel_height / 2.0
	var panel_style := _flat_style(Color(0.94, 0.96, 0.99, 0.97), 16)
	panel_style.border_color = Color("d5deeb")
	panel_style.set_border_width_all(1)
	panel_style.shadow_color = Color(0.02, 0.04, 0.10, 0.28)
	panel_style.shadow_size = 24
	panel_style.shadow_offset = Vector2(0, 6)
	_task_view_panel.add_theme_stylebox_override("panel", panel_style)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	layout.add_theme_constant_override("margin_left", 20)
	layout.add_theme_constant_override("margin_right", 20)
	layout.add_theme_constant_override("margin_top", 18)
	layout.add_theme_constant_override("margin_bottom", 18)
	_task_view_panel.add_child(layout)

	var header := HBoxContainer.new()
	var heading := Label.new()
	heading.text = "Affichage des tâches"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_color_override("font_color", Color("24344d"))
	heading.add_theme_font_size_override("font_size", 20)
	header.add_child(heading)
	var close_button := Button.new()
	close_button.text = "✕"
	close_button.tooltip_text = "Fermer l’affichage des tâches"
	close_button.custom_minimum_size = Vector2(36, 32)
	close_button.add_theme_color_override("font_color", Color("24344d"))
	close_button.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 8))
	close_button.add_theme_stylebox_override("hover", _flat_style(Color("dce6f4"), 8))
	close_button.pressed.connect(func():
		if is_instance_valid(_task_view_panel):
			_task_view_panel.queue_free()
			_task_view_panel = null
	)
	header.add_child(close_button)
	layout.add_child(header)

	var subtitle := Label.new()
	subtitle.text = "Sélectionnez une fenêtre pour y revenir"
	subtitle.add_theme_color_override("font_color", Color("61718a"))
	subtitle.add_theme_font_size_override("font_size", 12)
	layout.add_child(subtitle)

	var grid := GridContainer.new()
	grid.name = "TaskViewGrid"
	grid.columns = 2 if viewport_size.x >= 620.0 else 1
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	layout.add_child(grid)

	var window_count := 0
	if is_instance_valid(_window_layer):
		for child in _window_layer.get_children():
			if not child is Control or not child.has_meta("app_id"):
				continue
			var app_window := child as Control
			var app_id := str(app_window.get_meta("app_id"))
			var title := str(app_window.get_meta("window_title", "Application"))
			var card := Button.new()
			card.custom_minimum_size = Vector2(245 if grid.columns == 2 else panel_width - 44.0, 92)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var window_state := "Fenêtre active" if app_id == _active_app_id else ("Réduite" if not app_window.visible else "Ouverte")
			card.text = "%s   %s\n%s" % [_glyph_for_app_id(app_id), title, window_state]
			card.tooltip_text = "%s — %s" % [title, window_state]
			card.add_theme_color_override("font_color", Color("24344d"))
			card.add_theme_font_size_override("font_size", 14)
			var card_normal := _flat_style(Color("eaf3ff") if app_id == _active_app_id else Color("ffffff"), 10)
			card_normal.set_border_width_all(1)
			card_normal.border_color = Color("6aa7ed") if app_id == _active_app_id else Color("dce4ef")
			card.add_theme_stylebox_override("normal", card_normal)
			card.add_theme_stylebox_override("hover", _flat_style(Color("e4efff"), 10))
			card.add_theme_stylebox_override("pressed", _flat_style(Color("d5e5fb"), 10))
			card.mouse_entered.connect(func():
				var hover_tween := create_tween()
				hover_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				hover_tween.tween_property(card, "scale", Vector2(1.015, 1.015), 0.10)
			)
			card.mouse_exited.connect(func():
				var hover_tween := create_tween()
				hover_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				hover_tween.tween_property(card, "scale", Vector2.ONE, 0.12)
			)
			card.pressed.connect(_focus_task_view_app.bind(app_window))
			grid.add_child(card)
			window_count += 1

	if window_count == 0:
		var empty_label := Label.new()
		empty_label.text = "Aucune fenêtre ouverte"
		empty_label.add_theme_color_override("font_color", Color("61718a"))
		layout.add_child(empty_label)

	add_child(_task_view_panel)
	_task_view_panel.pivot_offset = Vector2(panel_width / 2.0, panel_height / 2.0)
	_task_view_panel.scale = Vector2(0.985, 0.985)
	_task_view_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(_task_view_panel, "scale", Vector2.ONE, 0.18)
	tween.tween_property(_task_view_panel, "modulate:a", 1.0, 0.16)


func _focus_task_view_app(app_window: Control) -> void:

	if not is_instance_valid(app_window):
		return
	if not app_window.visible:
		if app_window.has_method("restore_from_taskbar"):
			app_window.call("restore_from_taskbar")
		else:
			app_window.show()
	app_window.move_to_front()
	_active_app_id = str(app_window.get_meta("app_id", ""))
	_update_taskbar_indicators()
	if is_instance_valid(_task_view_panel):
		_task_view_panel.queue_free()
		_task_view_panel = null


func _toggle_quick_link_menu() -> void:

	if is_instance_valid(_quick_link_menu):
		_quick_link_menu.queue_free()
		_quick_link_menu = null
		return

	_start_menu.visible = false
	_start_open = false
	_quick_settings_panel.visible = false
	_calendar_panel.visible = false
	if is_instance_valid(_notification_center):
		_notification_center.visible = false

	_quick_link_menu = PanelContainer.new()
	_quick_link_menu.name = "QuickLinkMenu"
	_quick_link_menu.z_index = 110
	_quick_link_menu.custom_minimum_size = Vector2(290, 0)
	var menu_style := _flat_style(Color(0.95, 0.97, 0.99, 0.98), 12)
	menu_style.shadow_color = Color(0.02, 0.04, 0.10, 0.30)
	menu_style.shadow_size = 20
	menu_style.shadow_offset = Vector2(0, 4)
	menu_style.set_border_width_all(1)
	menu_style.border_color = Color(1, 1, 1, 0.82)
	_quick_link_menu.add_theme_stylebox_override("panel", menu_style)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 7)
	_quick_link_menu.add_child(margin)

	var items := VBoxContainer.new()
	items.add_theme_constant_override("separation", 3)
	margin.add_child(items)

	var heading := Label.new()
	heading.text = "Accès rapides"
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", Color("64748b"))
	items.add_child(heading)

	_add_quick_link_action(items, "Applications et fonctionnalités", func():
		_open_window("Applications et fonctionnalités", "Applications installées\n\nMicroslop Experience\n\nLa gestion des applications est simulée.", Vector2(430, 300))
	)
	_add_quick_link_action(items, "Centre de mobilité", func():
		_open_window("Centre de mobilité", "Luminosité   ━━━━━━━━━\n\nVolume   ━━━━━━━━\n\nÉtat de la batterie : alimentation secteur", Vector2(380, 260))
	)
	_add_quick_link_action(items, "Options d’alimentation", func():
		_open_window("Alimentation", "Mode d’alimentation : Équilibré\n\nÉconomiseur de batterie : désactivé", Vector2(380, 230))
	)
	var separator := HSeparator.new()
	items.add_child(separator)
	_add_quick_link_action(items, "Gestionnaire des tâches", func():
		_open_window("Gestionnaire des tâches", "Processus\n\nMicroslop Experience     En cours d’exécution\nUtilisation CPU : —\nUtilisation mémoire : —", Vector2(500, 320))
	)
	_add_quick_link_action(items, "Paramètres", _open_settings)
	_add_quick_link_action(items, "Explorateur de fichiers", _open_files)
	_add_quick_link_action(items, "Bureau", _toggle_show_desktop)

	add_child(_quick_link_menu)
	var viewport_size := get_viewport_rect().size
	_quick_link_menu.reset_size()
	await get_tree().process_frame
	if not is_instance_valid(_quick_link_menu):
		return
	var menu_size := _quick_link_menu.get_combined_minimum_size()
	_quick_link_menu.position = Vector2(12, maxf(8.0, viewport_size.y - TASKBAR_HEIGHT - menu_size.y - 20))
	_quick_link_menu.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_quick_link_menu, "modulate:a", 1.0, 0.14)


func _add_quick_link_action(parent: VBoxContainer, caption: String, callback: Callable) -> void:

	var button := Button.new()
	button.text = caption
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(260, 34)
	button.add_theme_color_override("font_color", Color("24344d"))
	button.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 6))
	button.add_theme_stylebox_override("hover", _flat_style(Color("dce8f8"), 6))
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func():
		if is_instance_valid(_quick_link_menu):
			_quick_link_menu.queue_free()
			_quick_link_menu = null
		callback.call()
	)
	parent.add_child(button)


func _process(delta: float) -> void:

	_clock_refresh_elapsed += delta

	if _clock_refresh_elapsed >= 1.0:

		_clock_refresh_elapsed = 0.0

		if is_instance_valid(_clock_button):

			var current_time := Time.get_time_string_from_system().substr(0, 5)

			var current_date := _get_short_french_date()

			_clock_button.text = "%s\n%s" % [current_time, current_date]

			_clock_button.tooltip_text = "Calendrier et notifications — %s, %s" % [current_date, current_time]

		if is_instance_valid(_calendar_panel) and _calendar_panel.visible:

			_refresh_calendar_date()

		_update_taskbar_indicators()
func _flat_style(color: Color, radius := 10) -> StyleBoxFlat:

	var style := StyleBoxFlat.new()

	style.bg_color = color

	style.set_corner_radius_all(radius)

	style.content_margin_left = 8

	style.content_margin_right = 8

	style.content_margin_top = 6

	style.content_margin_bottom = 6

	return style