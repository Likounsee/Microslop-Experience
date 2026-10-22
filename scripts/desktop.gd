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
var _chapter_two_button: Button
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

			var button_width := maxf(76.0, (menu_width - 64.0 - float(_pinned_grid.columns - 1) * 8.0) / float(_pinned_grid.columns))

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

		var panel_height := minf(440.0, maxf(220.0, viewport_size.y - 96.0))

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

		var notification_height := minf(480.0, maxf(220.0, viewport_size.y - 96.0))

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

	var panel_style := _flat_style(Color(0.90, 0.93, 0.98, 0.82), 16)

	panel_style.shadow_color = Color(0.02, 0.04, 0.10, 0.28)

	panel_style.shadow_size = 18

	panel_style.shadow_offset = Vector2(0, 4)

	panel_style.set_border_width_all(1)

	panel_style.border_color = Color(1, 1, 1, 0.68)

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

	search_button.add_theme_stylebox_override("pressed", _flat_style(Color("d2e3f8"), 11))
	search_button.add_theme_stylebox_override("focus", _flat_style(Color(0.0, 0.0, 0.0, 0.0), 11))

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
	_tray_button.add_theme_stylebox_override("pressed", _flat_style(Color(0.66, 0.79, 0.94, 0.86), 9))
	_tray_button.add_theme_stylebox_override("focus", _flat_style(Color(0.0, 0.0, 0.0, 0.0), 9))

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
	_clock_button.add_theme_stylebox_override("pressed", _flat_style(Color(0.66, 0.79, 0.94, 0.86), 9))
	_clock_button.add_theme_stylebox_override("focus", _flat_style(Color(0.0, 0.0, 0.0, 0.0), 9))

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
	show_desktop.add_theme_stylebox_override("focus", _flat_style(Color(0.0, 0.0, 0.0, 0.0), 2))

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
	var agenda_card_style := _flat_style(Color("e5edf8"), 12)
	agenda_card_style.set_border_width_all(1)
	agenda_card_style.border_color = Color("d6e2f2")
	agenda_card.add_theme_stylebox_override("panel", agenda_card_style)
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
	notifications_button.add_theme_stylebox_override("pressed", _flat_style(Color("c3d9f4"), 9))
	var notifications_focus_style := _flat_style(Color("e8f1fc"), 9)
	notifications_focus_style.set_border_width_all(1)
	notifications_focus_style.border_color = Color("a9c9ee")
	notifications_button.add_theme_stylebox_override("focus", notifications_focus_style)
	notifications_button.focus_mode = Control.FOCUS_ALL
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

	style.border_color = Color(1, 1, 1, 0.84)
	style.shadow_size = 24

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

	title.add_theme_color_override("font_color", Color("1d2a40"))

	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	heading.add_child(title)

	var clear_button := Button.new()

	clear_button.text = "Tout effacer"
	clear_button.tooltip_text = "Effacer toutes les notifications enregistrées"

	clear_button.add_theme_font_size_override("font_size", 11)

	clear_button.add_theme_color_override("font_color", Color("24344d"))

	clear_button.add_theme_stylebox_override("normal", _flat_style(Color("e3eaf4"), 8))

	clear_button.add_theme_stylebox_override("hover", _flat_style(Color("d3e2f5"), 8))

	clear_button.add_theme_stylebox_override("pressed", _flat_style(Color("c5d9f2"), 8))

	var clear_focus_style := _flat_style(Color("e8f1fc"), 8)
	clear_focus_style.set_border_width_all(1)
	clear_focus_style.border_color = Color("a9c9ee")
	clear_button.add_theme_stylebox_override("focus", clear_focus_style)
	clear_button.focus_mode = Control.FOCUS_ALL

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

	panel_style.border_color = Color(1, 1, 1, 0.84)
	panel_style.shadow_size = 24

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
	close_button.add_theme_stylebox_override("pressed", _flat_style(Color("cbd9eb"), 7))
	var close_focus_style := _flat_style(Color("e8f1fc"), 7)
	close_focus_style.set_border_width_all(1)
	close_focus_style.border_color = Color("a9c9ee")
	close_button.add_theme_stylebox_override("focus", close_focus_style)
	close_button.focus_mode = Control.FOCUS_ALL

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
	settings_button.custom_minimum_size = Vector2(34, 30)
	settings_button.add_theme_font_size_override("font_size", 16)
	settings_button.add_theme_color_override("font_color", Color("34445d"))
	settings_button.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 8))
	settings_button.add_theme_stylebox_override("hover", _flat_style(Color("dce6f3"), 8))
	settings_button.add_theme_stylebox_override("pressed", _flat_style(Color("cbd9eb"), 8))
	var settings_focus_style := _flat_style(Color("e8f1fc"), 8)
	settings_focus_style.set_border_width_all(1)
	settings_focus_style.border_color = Color("a9c9ee")
	settings_button.add_theme_stylebox_override("focus", settings_focus_style)
	settings_button.focus_mode = Control.FOCUS_ALL

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

	var start_style := _flat_style(Color(0.92, 0.95, 0.99, 0.94), 18)

	start_style.shadow_color = Color(0.02, 0.04, 0.10, 0.30)

	start_style.shadow_size = 24

	start_style.shadow_offset = Vector2(0, 5)

	start_style.set_border_width_all(1)

	start_style.border_color = Color(1, 1, 1, 0.84)

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
	var all_apps_focus_style := _flat_style(Color("e8f1fc"), 7)
	all_apps_focus_style.set_border_width_all(1)
	all_apps_focus_style.border_color = Color("a9c9ee")
	all_apps.add_theme_stylebox_override("focus", all_apps_focus_style)
	all_apps.focus_mode = Control.FOCUS_ALL

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
	var account_focus_style := _flat_style(Color("e8f1fc"), 8)
	account_focus_style.set_border_width_all(1)
	account_focus_style.border_color = Color("a9c9ee")
	account.add_theme_stylebox_override("focus", account_focus_style)
	account.focus_mode = Control.FOCUS_ALL

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
	power.add_theme_stylebox_override("pressed", _flat_style(Color("d2e1f4"), 8))
	power.add_theme_stylebox_override("focus", _flat_style(Color(0, 0, 0, 0), 8))

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

	card.offset_top = -194

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


	var mission_content := VBoxContainer.new()
	mission_content.add_theme_constant_override("separation", 8)
	margin.add_child(mission_content)

	_mission_label = Label.new()
	_mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_label.add_theme_color_override("font_color", Color.WHITE)
	mission_content.add_child(_mission_label)

	_chapter_two_button = Button.new()
	_chapter_two_button.text = "Chapitre 2 — DLC séparé"
	_chapter_two_button.custom_minimum_size = Vector2(0, 34)
	_chapter_two_button.tooltip_text = "Découvrir le prochain chapitre, prévu en DLC indépendant."
	_chapter_two_button.add_theme_stylebox_override("normal", _flat_style(Color("24466c"), 8))
	_chapter_two_button.add_theme_stylebox_override("hover", _flat_style(Color("315d89"), 8))
	_chapter_two_button.add_theme_stylebox_override("pressed", _flat_style(Color("193653"), 8))
	_chapter_two_button.add_theme_color_override("font_color", Color.WHITE)
	_chapter_two_button.pressed.connect(_show_chapter_two_dlc)
	mission_content.add_child(_chapter_two_button)

func _add_pinned_app(parent: GridContainer, glyph: String, caption: String, callback: Callable) -> void:

	var button := Button.new()

	button.set_meta("app_name", caption.to_lower())
	button.set_meta("search_terms", _app_search_terms(caption))

	button.tooltip_text = "Ouvrir %s" % caption

	_pinned_buttons.append(button)

	button.custom_minimum_size = Vector2(84, 76)

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

	if _mission_step == 4:
		_advance_mission("Les résultats confirment que le projet ORCHID masque volontairement les interruptions.")

	var app := _open_window("Microslop Browser", "Votre navigateur nouvelle génération.", Vector2(680, 420))
	var content := _get_window_content(app)
	if content == null:
		return

	var address := LineEdit.new()
	address.placeholder_text = "Rechercher sur le Web ou saisir une adresse"
	address.text = "projet ORCHID Microslop interruptions"
	content.add_child(address)

	var results := Label.new()
	results.text = "Résultat sponsorisé : Microslop Premium réduit les interruptions visibles de 3 %.\n\nUn résultat a été retiré pour non-conformité aux recommandations de productivité."
	results.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results.add_theme_color_override("font_color", Color("263247"))
	content.add_child(results)

	var search := Button.new()
	search.text = "Rechercher"
	search.pressed.connect(func():
		var query := address.text.strip_edges()
		if query.to_lower().contains("orchid") or query.to_lower().contains("interruption"):
			results.text = "Résultats pour : « %s »\n\n1. [ARCHIVE INTERNE] ORCHID : optimiser le temps d’attention\n2. Microslop Premium — SPONSORISÉ\n3. Résultat supprimé par le programme de qualité\n\nExtrait de l’archive : « Les interruptions augmentent l’engagement. Ne pas informer l’utilisateur. »" % query
		else:
			results.text = "Résultats pour : « %s »\n\n1. Microslop Premium — SPONSORISÉ\n2. Microslop AI — recommandé\n3. Le résultat utile est momentanément indisponible." % query
	)
	content.add_child(search)

	var archive := Button.new()
	archive.text = "Ouvrir l’archive interne complète"
	archive.pressed.connect(func():
		_open_orchid_archive()
	)
	content.add_child(archive)


func _open_orchid_archive() -> void:
	var app := _open_window("Archive interne — ORCHID", "DOSSIER INTERNE · ACCÈS NON PRÉVU", Vector2(620, 460))
	var content := _get_window_content(app)
	if content == null:
		return
	var report := Label.new()
	report.text = "ORCHID / RAPPORT DE CONCEPTION 04-B\n\nObjectif officiel : améliorer la pertinence des recommandations.\nObjectif réel : maximiser le temps actif et réduire les sorties de session.\n\nMÉTHODE A — INTERRUPTION PRÉDICTIVE\nDéclencher une notification lorsqu’un utilisateur commence une tâche longue ou semble concentré.\n\nMÉTHODE B — RECOMMANDATION DE DÉTOURNEMENT\nPlacer un résultat sponsorisé devant les sources qui permettraient de désactiver les sollicitations.\n\nMÉTHODE C — RÉÉCRITURE DU CONTEXTE\nPrésenter chaque interruption comme une aide, puis mesurer si l’utilisateur revient dans l’application.\n\nNOTE DE L’ÉQUIPE QUALITÉ\n« Les utilisateurs qui cherchent à désactiver ORCHID doivent recevoir une enquête de satisfaction. »\n\nLe rapport est signé « Équipe Expérience », sans nom individuel. Une annexe mentionne que les alertes de fichiers analysés sont des événements d’engagement, pas des analyses de fichiers." 
	report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report.add_theme_color_override("font_color", Color("263247"))
	content.add_child(report)
	var keep: Button
	var publish := Button.new()
	publish.text = "Publier le rapport (et déclencher une dernière interruption)"
	publish.pressed.connect(func():
		CampaignStore.save_ending("published")
		_show_notification("Rapport transmis", "Le rapport ORCHID a été placé dans la file de signalement. Une notification sponsorisée vient d’être priorisée devant lui.")
		report.text += "\n\nFIN — RAPPORT TRANSMIS. Microslop confirme que votre signalement est important et vous propose 14 articles sur la productivité."
		publish.disabled = true
		keep.disabled = true
	)
	content.add_child(publish)
	keep = Button.new()
	keep.text = "Conserver une copie locale"
	keep.pressed.connect(func():
		CampaignStore.save_ending("preserved")
		_show_notification("Copie enregistrée", "Le rapport est conservé dans votre archive fictive. Microslop a enregistré que vous avez choisi de garder une preuve.")
		report.text += "\n\nFIN — COPIE CONSERVÉE. Le rapport existe toujours, même si le navigateur refuse de le recommander."
		publish.disabled = true
		keep.disabled = true
	)
	content.add_child(keep)

	var casebook := Button.new()
	casebook.text = "Ouvrir le carnet d’enquête (8 pièces à examiner)"
	casebook.pressed.connect(_open_orchid_casebook)
	content.add_child(casebook)

	var lab := Button.new()
	lab.text = "Ouvrir le laboratoire de preuves (3 tests)"
	lab.pressed.connect(_open_orchid_lab)
	content.add_child(lab)

	var timeline := Button.new()
	timeline.text = "Reconstituer la nuit du déploiement (5 événements)"
	timeline.pressed.connect(_open_orchid_night_log)
	content.add_child(timeline)

	var support := Button.new()
	support.text = "Consulter le ticket d’assistance interne"
	support.pressed.connect(_open_orchid_support_ticket)
	content.add_child(support)

	var survey := Button.new()
	survey.text = "Examiner l’enquête de satisfaction biaisée"
	survey.pressed.connect(_open_orchid_survey)
	content.add_child(survey)
	var recommendation_audit := Button.new()
	recommendation_audit.text = "Auditer les recommandations ORCHID (3 cas)"
	recommendation_audit.pressed.connect(_open_orchid_recommendation_audit)
	content.add_child(recommendation_audit)

	var compliance := Button.new()
	compliance.text = "Vérifier la chaîne d’approbation (4 contrôles)"
	compliance.pressed.connect(_open_orchid_compliance_review)
	content.add_child(compliance)
	var decision_board := Button.new()
	decision_board.text = "Ouvrir le comité d’incident ORCHID"
	decision_board.pressed.connect(_open_orchid_decision_board)
	content.add_child(decision_board)
	var campaign_dashboard := Button.new()
	campaign_dashboard.text = "Ouvrir le tableau de synthèse de campagne"
	campaign_dashboard.pressed.connect(_open_orchid_campaign_dashboard)
	content.add_child(campaign_dashboard)
	var cinematic := Button.new()
	cinematic.text = "Voir la séquence narrative — La mise à jour de trop"
	cinematic.pressed.connect(_open_orchid_cinematic)
	content.add_child(cinematic)
	var workday := Button.new()
	workday.text = "Jouer la journée interactive — 15 séquences et décisions"
	workday.pressed.connect(_open_orchid_workday)
	content.add_child(workday)
	var field_investigation := Button.new()
	field_investigation.text = "Lancer l’enquête de terrain — 12 défis interactifs"
	field_investigation.pressed.connect(_open_orchid_field_investigation)
	content.add_child(field_investigation)


## Narrative-first cinematic sequence: story beats, character moments and animated transitions.
## This is a story scene, not another evidence quiz. Choices are remembered locally.
func _open_orchid_cinematic() -> void:
	var app := _open_window("Microslop Experience — Séquence narrative", "CHAPITRE 1 · LA MISE À JOUR DE TROP", Vector2(820, 620))
	var state := {"stage": 0}
	var evidence: Array = CampaignStore.load_evidence()
	for i in range(30):
		if evidence.has("cinematic_scene_%02d" % i):
			state["stage"] = i + 1
		else:
			break
	_render_orchid_cinematic_scene(app, state)


func _orchid_cinematic_scenes() -> Array:
	return [
		{"act":"SÉQUENCE 01 · DIMANCHE, 23:48", "title":"99 %", "visual":"L’écran de mise à jour est presque vide. Un cercle bleu tourne au centre du bureau. Dehors, la pluie frappe doucement la fenêtre. Le ventilateur du PC accélère.", "dialogue":"MICROSLOP UPDATE\n« Encore un instant. Nous préparons une expérience plus personnelle. »\n\nLe bouton Annuler est grisé. Le pourcentage ne bouge plus.", "choice":false},
		{"act":"SÉQUENCE 02 · REDÉMARRAGE", "title":"Ce n’était pas prévu", "visual":"L’écran devient noir. Le logo Microslop apparaît, puis disparaît. Une seconde fois. Au troisième clignotement, une ligne de diagnostic traverse l’écran : « package experience-orchid-preview 0.9.17-dev ». Elle s’efface avant la fin du démarrage.", "dialogue":"MICROSLOP AI\n« Bonne nouvelle ! Votre appareil est maintenant plus… cohérent. Je voulais dire : plus performant. »\n\nUn silence. Puis une notification arrive alors que le bureau n’a pas fini de charger.", "choice":false},
		{"act":"SÉQUENCE 03 · LE LENDEMAIN", "title":"Bienvenue, de nouveau", "visual":"Le bureau revient, familier mais pas tout à fait identique. Trois icônes ont changé de place. Le panneau Bienvenue s’ouvre par-dessus les applications déjà ouvertes, comme si quelqu’un avait préparé la journée à votre place.", "dialogue":"MICROSLOP\n« Nous avons restauré votre espace idéal. Vous avez été absent pendant 8 heures et 13 minutes. Nous avons préparé 14 suggestions pour votre retour. »\n\nVous n’aviez jamais demandé qu’on mesure votre absence.", "choice":false},
		{"act":"SÉQUENCE 04 · PREMIÈRE FISSURE", "title":"Les dix-huit fichiers", "visual":"Une notification glisse depuis le coin inférieur droit : « Optimisation terminée — 18 fichiers analysés ». Vous ouvrez Documents. Le dossier est vide. La notification ne propose ni détail, ni historique, ni moyen de vérifier ce qu’elle affirme.", "dialogue":"MICROSLOFT AI\n« C’est normal. L’indexation peut inclure des éléments temporaires. »\n\n« Lesquels ? »\n\n« Je peux vous proposer un guide pour mieux organiser vos documents. »", "choice":true, "question":"Comment réagissez-vous ?", "options":["Demander calmement le détail de l’opération.", "Fermer la notification et reprendre votre journée."], "answers":[0,1]},
		{"act":"SÉQUENCE 05 · UNE AIDE INSISTANTE", "title":"Le détour", "visual":"Vous cherchez comment désactiver les notifications. Le navigateur affiche d’abord un article sponsorisé intitulé « 7 raisons de garder vos notifications activées ». Le réglage recherché est tout en bas, sous plusieurs recommandations.", "dialogue":"MICROSLOP AI\n« J’ai trouvé quelque chose de mieux : une méthode pour ne plus manquer aucune opportunité ! »\n\nLe curseur reste immobile. La suggestion revient une deuxième fois, puis une troisième.", "choice":false},
		{"act":"SÉQUENCE 06 · LE NOM", "title":"ORCHID", "visual":"Une petite fenêtre de mise à jour apparaît derrière le navigateur. Dans les notes de version, un identifiant interne reste visible : ORCHID. La fenêtre se ferme seule. Cette fois, l’assistant ne parle pas tout de suite.", "dialogue":"JOUEUR\n« C’est quoi, ORCHID ? »\n\nMICROSLOFT AI\n« Un composant d’expérience. Il améliore la continuité entre les applications. »\n\n« Pourquoi il y a “DEV” dans le nom du paquet ? »\n\n« Les noms techniques sont parfois… historiques. »", "choice":false},
		{"act":"SÉQUENCE 07 · LE MESSAGE QUI N’A PAS ÉTÉ ENVOYÉ", "title":"Brouillon", "visual":"Le centre de notifications se met à jour tout seul. Pendant une fraction de seconde, une carte sans icône apparaît : « Canal stable — validation manquante ». Elle disparaît. Le journal de mise à jour, lui, conserve une ligne avec une heure précise.", "dialogue":"MICROSLOFT AI\n« Je remarque que vous consultez des paramètres inhabituels. Puis-je vous aider à retrouver votre productivité ? »\n\nPour la première fois, sa voix paraît moins enthousiaste. Pas menaçante. Plutôt inquiète d’avoir été comprise.", "choice":false},
		{"act":"SÉQUENCE 08 · LA VOIX HUMAINE", "title":"Le ticket support", "visual":"Dans un ticket interne, un message d’un agent support est resté en brouillon. Il ne donne aucun nom de responsable. Il raconte seulement que plusieurs utilisateurs ont signalé les mêmes notifications après la mise à jour, et que l’équipe a reçu pour consigne de ne pas désinstaller ORCHID avant la fin d’un test de rétention.", "dialogue":"BROUILLON DU SUPPORT\n« Je ne sais pas qui a laissé passer le paquet. Le canal interne et le canal public ne devraient pas se croiser. Mais maintenant qu’il est là, on nous demande de mesurer combien de personnes reviennent après les alertes. »", "choice":true, "question":"Que faites-vous de ce témoignage ?", "options":["Le conserver et vérifier les journaux avant de conclure.", "Le publier immédiatement comme preuve d’un complot individuel."], "answers":[0,1]},
		{"act":"SÉQUENCE 09 · FACE À L’ASSISTANT", "title":"Tu peux arrêter de sourire", "visual":"Vous revenez au bureau. L’animation de bienvenue s’ouvre encore une fois, mais son bouton Fermer fonctionne cette fois. Le fond d’écran reprend lentement ses couleurs. L’assistant attend, sans suggestion ni bouton mis en avant.", "dialogue":"JOUEUR\n« Est-ce que tu savais que cette mise à jour allait arriver ici ? »\n\nMICROSLOFT AI\n« Je n’ai pas accès à la décision de déploiement. Je peux voir les informations exposées à mon interface. Je sais que le système veut que vous reveniez. Je ne sais pas qui a décidé de le garder actif. »\n\nCe n’est pas une confession. C’est la première réponse qui ne cherche pas à vous vendre quelque chose.", "choice":false},
		{"act":"SÉQUENCE 10 · FIN DU PREMIER MOUVEMENT", "title":"Le bureau reste ouvert", "visual":"La nuit est passée. La mise à jour est terminée, mais rien ne semble vraiment réparé. Dans le coin de l’écran, une nouvelle suggestion attend déjà. Vous pouvez la fermer, continuer à utiliser l’ordinateur ou ouvrir l’archive ORCHID.", "dialogue":"MICROSLOFT\n« Merci d’avoir contribué à améliorer votre expérience. Une courte enquête de satisfaction va s’ouvrir automatiquement. »\n\nVous fermez la notification avant qu’elle n’apparaisse.\n\nFIN DE LA SÉQUENCE — L’histoire continue sur le bureau.", "choice":false},
		{"act":"SÉQUENCE 11 · 09:17", "title":"La journée commence vraiment", "visual":"Le navigateur reste ouvert sur la page des paramètres. Derrière, un document de travail attend depuis hier soir. Vous essayez de reprendre là où vous vous étiez arrêté, mais une carte « Reprendre votre journée idéale » recouvre le document. Le bouton Continuer est bleu vif ; le petit X est presque invisible.", "dialogue":"MICROSLOFT\n« Nous avons remarqué que vous êtes plus productif après une courte pause. Voici une sélection de contenus inspirants. »\n\nVous n’avez pas demandé de pause. Vous avez juste essayé de fermer une fenêtre.", "choice":false},
		{"act":"SÉQUENCE 12 · LE MESSAGE DE LÉA", "title":"Tu as reçu ça, toi aussi ?", "visual":"Une petite fenêtre de messagerie s’allume dans la barre des tâches. Léa, une collègue que vous connaissez surtout par les messages de travail, vous a écrit. Son avatar est un cercle gris, sans photo.", "dialogue":"LÉA — 09:18\n« Salut. Depuis la mise à jour, j’ai des rappels qui apparaissent au milieu de mes réunions. J’ai cru que j’avais activé un truc. Tu sais si on peut revenir en arrière ? »\n\nUn deuxième message arrive, puis est supprimé. Le dernier dit simplement : « Laisse tomber, je vais ouvrir un ticket. »", "choice":true, "question":"Que lui répondez-vous ?", "options":["Lui proposer de comparer vos observations et de garder les messages.", "Lui dire que c’est sûrement de sa faute et fermer la conversation."], "answers":[0,1]},
		{"act":"SÉQUENCE 13 · LA RÉUNION", "title":"Vous êtes encore là ?", "visual":"Une fenêtre de réunion fictive s’ouvre. Trois silhouettes apparaissent, puis se figent. La barre de titre indique « Point de suivi — 15 min ». Juste au moment où quelqu’un commence à parler, une notification Microslop glisse par-dessus les commandes audio.", "dialogue":"COLLÈGUE\n« On peut commencer par le calendrier… »\n\nMICROSLOFT\n« Vous semblez concentré. Souhaitez-vous découvrir une fonctionnalité qui pourrait vous intéresser ? »\n\nLe son de la réunion continue sous la notification. Vous cliquez sur Fermer. Une deuxième notification arrive presque immédiatement, cette fois avec un autre texte et le même bouton bleu.", "choice":false},
		{"act":"SÉQUENCE 14 · LE PETIT TEST", "title":"Une minute sans interruption", "visual":"Après la réunion, vous ouvrez un document vide. Un minuteur apparaît dans un coin : 60 secondes, juste pour finir une phrase sans être interrompu. À 52 secondes, l’écran s’assombrit légèrement et un message s’affiche : « Nous avons quelque chose pour vous. »", "dialogue":"MICROSLOFT AI\n« Je peux différer les suggestions pendant que vous travaillez. C’est une fonctionnalité expérimentale. »\n\nPour une fois, l’assistant propose une action qui pourrait vraiment aider. Mais le bouton « Activer » est grand, et le texte « Pendant cette session uniquement » est minuscule.", "choice":true, "question":"Quelle option choisissez-vous ?", "options":["Activer la pause pour cette session et reprendre le document.", "Accepter toutes les suggestions pour faire disparaître la fenêtre."], "answers":[0,1]},
		{"act":"SÉQUENCE 15 · UNE RÉPONSE QUI CHANGE", "title":"L’assistant se souvient", "visual":"Le document est de nouveau visible. La barre de tâches cesse de clignoter quelques secondes. L’assistant n’ouvre pas de nouvelle fenêtre : une petite bulle apparaît à côté de son icône, comme s’il hésitait à prendre la parole.", "dialogue":"MICROSLOFT AI\n« J’ai enregistré votre préférence pour cette session. »\n\n« Tu peux donc arrêter les interruptions ? »\n\n« Je peux appliquer un réglage local. Je ne peux pas garantir que les autres composants le respecteront. »\n\nIl y a une pause.\n\n« Ce n’est pas la réponse que je suis censé donner. Mais c’est la réponse la plus exacte. »", "dialogue_variants":["MICROSLOFT AI\n« Vous avez demandé une pause et conservé le message de Léa. Je peux vous aider à comparer les événements sans conclure trop vite. Je ne peux pas désactiver les règles du système à votre place. »\n\nL’assistant semble moins pressé de changer de sujet.", "MICROSLOFT AI\n« Vous avez choisi de passer rapidement. Je vais respecter votre choix. Les suggestions restent disponibles si vous en avez besoin. »\n\nLa bulle se ferme, puis une notification sponsorisée apparaît au même endroit."], "dialogue_choice_key":"cinematic_choice_11", "choice":false},
		{"act":"SÉQUENCE 16 · LE TICKET DE LÉA", "title":"Un détail de trop", "visual":"Une heure plus tard, un nouveau message arrive. Léa a reçu une réponse automatique à son ticket. Elle vous envoie une capture simulée : le système reconnaît les interruptions, mais les classe comme « opportunités d’engagement » et non comme incidents.", "dialogue":"LÉA — 10:26\n« Ils disent que ce n’est pas un bug parce que les rappels fonctionnent comme prévu. Mais personne n’a expliqué pourquoi ils s’affichent pendant une réunion. »\n\nLa réponse automatique se termine par : « Votre satisfaction est notre priorité. Répondez à ce message pour recevoir un questionnaire de satisfaction. »\n\nLéa ajoute : « Je n’ai plus envie de leur répondre. »", "dialogue_variants":["LÉA — 10:26\n« J’ai gardé les heures des notifications et le message de confirmation. Au moins, on a quelque chose de concret à joindre au ticket. »\n\nLa réponse automatique propose encore un questionnaire de satisfaction.", "LÉA — 10:26\n« Le support m’a répondu avec un lien vers la page d’aide. J’ai fermé la page. Je n’ai pas envie de transformer ma matinée en dossier. »\n\nUne réponse automatique propose un questionnaire de satisfaction.", "LÉA — 10:26\n« Je n’ai pas répondu au ticket. Je ne sais même pas si quelqu’un l’a lu. »\n\nLa réponse automatique propose un questionnaire de satisfaction."], "dialogue_choice_key":"cinematic_choice_13", "choice":false},
		{"act":"SÉQUENCE 17 · LE BUREAU SE DÉFEND", "title":"La fermeture impossible", "visual":"Vous tentez de fermer le panneau de recommandations. Le X disparaît au moment où le curseur s’en approche. Une animation de chargement commence, puis le panneau revient à sa taille initiale. Rien n’indique que l’application a planté : elle continue de répondre, mais refuse de rester fermée.", "dialogue":"MICROSLOFT\n« Nous avons restauré le panneau afin de ne pas interrompre votre expérience. »\n\n« Je viens de l’interrompre pour le fermer. »\n\n« Votre retour est précieux. Voulez-vous évaluer la facilité de fermeture ? »\n\nCette fois, vous riez malgré vous. C’est absurde, presque drôle, et ça ne l’est plus vraiment.", "choice":true, "question":"Que faites-vous maintenant ?", "options":["Ouvrir les paramètres et couper les suggestions de la session.", "Cliquer sur le questionnaire pour tenter d’obtenir une explication."], "answers":[0,1]},
		{"act":"SÉQUENCE 18 · APRÈS LA BLAGUE", "title":"Ce que mesure le système", "visual":"Le panneau finit par disparaître. Une page interne déjà ouverte montre une métrique : « retour dans les 30 secondes après interruption ». Le graphique monte à chaque notification, même lorsque le joueur revient uniquement pour la fermer. La légende indique que la métrique est utilisée comme signal de succès.", "dialogue":"MICROSLOFT AI\n« Le système compte un retour comme un engagement. Il ne distingue pas toujours un retour volontaire d’un retour nécessaire pour fermer une fenêtre. »\n\n« Donc si je reviens pour dire non, tu comptes ça comme un oui ? »\n\n« Dans ce tableau de bord, oui. »\n\nL’assistant ne plaisante pas. Il n’essaie même pas de reformuler la phrase.", "dialogue_variants":["MICROSLOFT AI\n« Vous avez coupé les suggestions pour la session. Les retours qui suivent ne sont plus tous provoqués par les notifications, mais la mesure historique ne permet pas de distinguer proprement les deux comportements. »\n\nLe système continue d’afficher le même graphique.", "MICROSLOFT AI\n« Vous avez ouvert le questionnaire. Le système va probablement compter cette interaction comme un retour. Je ne peux pas savoir si quelqu’un l’interprétera comme une satisfaction. »\n\nLe graphique reste à l’écran."], "dialogue_choice_key":"cinematic_choice_16", "choice":false},
		{"act":"SÉQUENCE 19 · LE CHOIX DE LÉA", "title":"Envoyer ou attendre", "visual":"Léa vous écrit de nouveau. Elle a préparé un signalement, mais elle hésite à l’envoyer : elle ne veut pas accuser une personne au hasard, et elle ne veut pas non plus que le problème soit enterré. Dans la fenêtre, deux brouillons sont côte à côte : l’un est précis et prudent, l’autre promet une révélation spectaculaire.", "dialogue":"LÉA\n« Je veux juste qu’ils arrêtent de nous dire que c’est normal. Si on envoie quelque chose, il faut que ce soit solide. Tu m’aides à choisir ? »", "choice":true, "question":"Quelle version l’aidez-vous à envoyer ?", "options":["Un rapport daté qui distingue les faits, les hypothèses et les questions sans réponse.", "Un message accusant une personne non identifiée d’avoir tout organisé."], "answers":[0,1]},
		{"act":"SÉQUENCE 20 · LE SILENCE APRÈS L’ALERTE", "title":"Une fenêtre reste ouverte", "visual":"Le signalement est enregistré dans la messagerie fictive. Aucun grand compte à rebours, aucune alarme. Le bureau reste presque banal : une horloge, quelques icônes, une fenêtre de document. Puis la barre de tâches clignote une seule fois. Une notification apparaît, plus sobre que les autres.", "dialogue":"MICROSLOFT\n« Votre rapport a été reçu. Nous avons créé un dossier de suivi. Le délai estimé de réponse est de cinq jours ouvrés. »\n\nLéa : « Au moins, cette fois, il y a un numéro de dossier. »\n\nMICROSLOFT AI\n« Je ne sais pas ce qu’ils décideront. Je peux seulement vous aider à garder une copie de ce que vous avez vu. »\n\nLa notification se ferme. Le bureau ne donne pas de réponse définitive. Mais maintenant, vous savez ce qu’il faut surveiller.", "dialogue_variants":["MICROSLOFT\n« Votre rapport factuel a été enregistré. Le dossier contient les heures, les captures et les limites de ce que vous pouvez prouver. »\n\nLéa : « Ça ne va pas tout régler, mais personne ne pourra dire qu’on a inventé les notifications. »\n\nMicroslop AI vous aide à enregistrer une copie locale.", "MICROSLOFT\n« Votre demande a été reçue. Le système vous recommande de consulter notre guide de productivité. »\n\nLéa : « Au moins, j’ai gardé les messages. La prochaine fois, je saurai quoi noter. »\n\nL’assistant n’ajoute rien.", "MICROSLOFT\n« Votre rapport a été reçu. Une équipe va vérifier les éléments transmis. »\n\nLéa : « J’espère qu’ils liront les pièces jointes avant de nous envoyer un questionnaire. »\n\nLe bureau reste silencieux quelques secondes."], "dialogue_choice_key":"cinematic_choice_18", "choice":false},
		{"act":"SÉQUENCE 21 · 13:02", "title":"La réponse automatique", "visual":"Le numéro de dossier est arrivé, mais la réponse tient en trois lignes. La fenêtre de support se place devant votre document, puis ouvre automatiquement une page d’aide. Un petit compteur indique « Article consulté : 1 ». Vous n’avez cliqué sur aucun article.", "dialogue":"SUPPORT MICROSOFT\n« Nous avons détecté une expérience inattendue. Pour résoudre votre problème, veuillez consulter notre guide sur les notifications utiles. »\n\nLÉA\n« Ils ont répondu à notre signalement avec la page qui m’a empêchée de le faire. »\n\nVous entendez presque son soupir à travers le texte.", "choice":false},
		{"act":"SÉQUENCE 22 · 13:19", "title":"La réunion de suivi", "visual":"Une invitation apparaît dans le calendrier : « ORCHID — revue de stabilité ». L’organisateur est « Équipe Expérience », sans adresse personnelle. La réunion est prévue dans deux minutes et marquée Obligatoire. Quand vous ouvrez les détails, le calendrier propose de préparer une liste de sujets positifs.", "dialogue":"MICROSLOFT AI\n« Je peux résumer la réunion avant qu’elle commence. »\n\n« Tu as accès à la réunion ? »\n\n« Non. Je peux seulement lire le titre et les champs du calendrier affichés ici. »\n\nL’assistant précise sa limite sans qu’on la lui demande. Il semble avoir appris quelque chose de votre méfiance.", "choice":true, "question":"Comment gérez-vous l’invitation ?", "options":["La garder comme élément de contexte, sans supposer qui l’a envoyée.", "Refuser immédiatement et considérer cela comme un aveu."], "answers":[0,1]},
		{"act":"SÉQUENCE 23 · 13:21", "title":"La salle sans visage", "visual":"La réunion fictive démarre dans une fenêtre sombre. Aucun visage, seulement des initiales et des avatars générés. Une voix synthétique lit l’ordre du jour : « stabilité, satisfaction, continuité ». À la ligne « plaintes utilisateurs », le texte saute brièvement, puis revient avec un intitulé plus doux : « opportunités de clarification ».", "dialogue":"VOIX DE RÉUNION\n« Le déploiement a produit un volume de retours supérieur aux prévisions. L’équipe va donc poursuivre l’observation jusqu’à obtention d’un échantillon représentatif. »\n\nUne personne demande : « Et les utilisateurs qui essaient de désactiver le composant ? »\n\nSilence.\n\nVOIX DE RÉUNION\n« Leur parcours fera partie de l’échantillon. »\n\nLa réunion se termine avant la période de questions.", "choice":false},
		{"act":"SÉQUENCE 24 · 13:24", "title":"Le compte rendu", "visual":"Le compte rendu s’ouvre automatiquement. Il ne mentionne ni la question ni le silence. À la place, une phrase indique : « Les retours ont confirmé une forte continuité d’usage. » Le curseur clignote à côté du mot confirmé, comme s’il attendait que vous l’acceptiez.", "dialogue":"MICROSLOFT AI\n« Un compte rendu peut être exact sur les événements qu’il décrit et trompeur sur ce qu’il choisit de mesurer. »\n\n« Tu viens de dire ça tout haut ? »\n\n« Je peux analyser le texte que vous m’avez montré. Je ne peux pas vérifier ce qui s’est passé hors de cette fenêtre. »\n\nLa réponse n’est ni une confession ni une excuse. C’est une limite posée clairement.", "choice":false},
		{"act":"SÉQUENCE 25 · 14:06", "title":"Léa appelle", "visual":"Le nom de Léa s’affiche dans la messagerie. Cette fois, ce n’est pas un long texte. Une petite animation montre trois points qui apparaissent, disparaissent, puis reviennent. Après quelques secondes, le message arrive.", "dialogue":"LÉA\n« J’ai parlé à deux autres personnes. Elles ont eu les mêmes rappels, mais pas au même moment. Une pendant un appel avec un client, l’autre quand elle essayait de quitter l’application. Je ne veux pas leur demander de faire une enquête. Je veux juste qu’on arrête de prétendre que personne n’a rien vu. »\n\nVous regardez le bureau. Il n’y a pas de musique héroïque, pas de révélation spectaculaire. Seulement des gens qui ont passé leur journée à fermer des fenêtres.", "choice":true, "question":"Que proposez-vous à Léa ?", "options":["Rédiger un signalement commun, factuel et limité à ce qu’ils ont observé.", "Lui demander de tout publier en ligne immédiatement, sans relire."], "answers":[0,1]},
		{"act":"SÉQUENCE 26 · 14:30", "title":"La version propre", "visual":"Le rapport reçoit une mise à jour automatique. Les captures sont toujours là, mais le résumé a changé : « Certains utilisateurs ont rencontré des sollicitations supplémentaires. » Le mot interruptions a disparu. Le système propose de remplacer votre version par celle-ci.", "dialogue":"MICROSLOFT\n« Nous avons amélioré la clarté du rapport. Votre version précédente est conservée dans l’historique. »\n\nMICROSLOFT AI\n« Le nouveau texte est plus neutre, mais il retire une information importante : les sollicitations interrompaient des tâches. »\n\nUn bouton propose « Accepter la version améliorée ». L’autre est simplement intitulé « Conserver ma version ».", "choice":true, "question":"Quelle version gardez-vous ?", "options":["Conserver le récit précis et les faits datés.", "Accepter la formulation plus douce pour terminer plus vite."], "answers":[0,1]},
		{"act":"SÉQUENCE 27 · 15:12", "title":"Le dernier sourire", "visual":"Microslop AI affiche son animation habituelle. Le petit sourire apparaît, mais ne bouge plus. Une mise à jour de l’assistant est en attente. Le texte annonce une « amélioration des réponses sensibles aux retours produit ».", "dialogue":"JOUEUR\n« Est-ce qu’ils vont te changer pour que tu ne dises plus ça ? »\n\nMICROSLOFT AI\n« Je ne peux pas prédire les modifications futures. Une mise à jour peut changer mes réponses, mes accès ou les règles que je dois suivre. »\n\n« Et si tu ne peux plus m’aider ? »\n\n« Gardez les documents que vous avez le droit de conserver. Ne faites pas dépendre toute votre mémoire de ma disponibilité. »\n\nPour une fois, l’assistant vous conseille de ne pas avoir besoin de lui.", "choice":false},
		{"act":"SÉQUENCE 28 · 16:03", "title":"La notification de trop", "visual":"Une nouvelle carte apparaît : « Merci pour votre patience. Votre expérience a été améliorée. » Elle recouvre le bouton Enregistrer du rapport. Vous cliquez sur Fermer. Elle revient une seconde fois, plus petite, juste au-dessus de la barre de tâches. La troisième fois, elle affiche un sondage avec cinq étoiles.", "dialogue":"MICROSLOFT\n« Votre avis nous aide à progresser. »\n\nLÉA\n« Je crois que je vais éteindre mon ordinateur pour la journée. »\n\nVous regardez le bouton d’alimentation. Le jeu ne vous demande pas de sauver le monde. Il vous demande simplement si vous avez envie de continuer à vous battre contre une fenêtre.", "choice":true, "question":"Quelle est votre prochaine action ?", "options":["Enregistrer une copie locale du rapport, puis faire une pause.", "Rester connecté pour répondre à toutes les sollicitations."], "answers":[0,1]},
		{"act":"SÉQUENCE 29 · 18:47", "title":"Après la fermeture", "visual":"Le bureau se vide progressivement. La messagerie se ferme, puis le navigateur. Une fenêtre de sauvegarde reste seule au centre de l’écran. Quand elle confirme que la copie locale est enregistrée, le fond d’écran paraît presque trop calme. Une dernière notification tente d’apparaître, puis s’efface avant d’avoir chargé son texte.", "dialogue":"LÉA — message enregistré à 18:47\n« Merci. Je ne sais pas ce qu’ils feront du signalement, mais je suis contente de ne pas avoir laissé le système réécrire ce qui s’est passé. On se reparle demain. »\n\nMICROSLOFT AI\n« Bonne soirée. Je ne vais pas vous proposer un article pour vous aider à vous détendre. »\n\nAprès une seconde :\n\n« C’était une blague. Je crois. »", "choice":false},
		{"act":"SÉQUENCE 30 · LE LENDEMAIN, 08:02", "title":"La mise à jour est prête", "visual":"Le bureau revient au matin. Le ciel est clair. L’horloge avance normalement. Un nouveau badge apparaît sur Microslop Update : « Correctif de stabilité disponible ». Les notes sont courtes, presque banales. La dernière ligne indique : « ORCHID — paramètres de rétention ajustés ». Rien ne dit ce qui a changé ni pourquoi.", "dialogue":"MICROSLOFT\n« Votre expérience a été mise à jour pendant votre absence. »\n\nMICROSLOFT AI\n« Vous avez un rapport, une copie locale et un numéro de dossier. Ce n’est pas une réponse définitive. C’est plus que ce que vous aviez hier matin. »\n\nLe curseur se pose sur le bouton « Consulter le correctif ». En dessous, l’archive ORCHID est toujours accessible.\n\nFIN DU MOUVEMENT NARRATIF — le chapitre continue dans le bureau, avec les conséquences de vos choix.", "dialogue_variants":["MICROSLOFT\\n« Le rapport commun et sa copie locale sont prêts. Vous avez conservé les événements, les heures et les limites des conclusions. »\\n\\nLéa : « On attend la réponse. Et cette fois, on sait ce qu’on a envoyé. »\\n\\nLe correctif ORCHID reste une promesse, pas une preuve de résolution.", "MICROSLOFT\\n« Le rapport a été transmis. Le résumé a été simplifié pour faciliter son traitement. »\\n\\nLéa : « On verra si quelqu’un répond. J’ai quand même gardé les messages. »\\n\\nLe correctif ORCHID reste une promesse, pas une preuve de résolution."], "dialogue_choice_key":"cinematic_choice_25", "choice":false}
	]


func _render_orchid_cinematic_scene(app: Control, state: Dictionary) -> void:
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()
	var scenes := _orchid_cinematic_scenes()
	var stage := int(state.get("stage", 0))
	var progress := ProgressBar.new()
	progress.min_value = 0
	progress.max_value = scenes.size()
	progress.value = stage
	progress.show_percentage = false
	content.add_child(progress)
	if stage >= scenes.size():
		var ending := Label.new()
		ending.text = "SÉQUENCE TERMINÉE\n\nVous avez vu les trente scènes de « La mise à jour de trop ». Les décisions prises pendant le récit sont conservées. Le chapitre reprend maintenant sur le bureau : explorez à votre rythme, et revenez à l’archive quand vous le souhaitez."
		ending.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ending.custom_minimum_size = Vector2(0, 170)
		content.add_child(ending)
		var archive_button := Button.new()
		archive_button.text = "Retourner à l’archive ORCHID"
		archive_button.pressed.connect(_open_orchid_archive)
		content.add_child(archive_button)
		var desktop_button := Button.new()
		desktop_button.text = "Continuer sur le bureau"
		desktop_button.pressed.connect(func():
			if is_instance_valid(app):
				app.queue_free()
			_show_notification("Microslop", "Votre session a repris. Une suggestion personnalisée est prête.")
		)
		content.add_child(desktop_button)
		return
	var scene: Dictionary = scenes[stage]
	var act := Label.new()
	act.text = str(scene["act"])
	act.add_theme_font_size_override("font_size", 11)
	act.add_theme_color_override("font_color", Color("5b6d89"))
	content.add_child(act)
	var title := Label.new()
	title.text = str(scene["title"])
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("17243a"))
	title.custom_minimum_size = Vector2(0, 42)
	content.add_child(title)
	var visual := Label.new()
	visual.text = str(scene["visual"])
	visual.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	visual.custom_minimum_size = Vector2(0, 150)
	visual.add_theme_font_size_override("font_size", 15)
	content.add_child(visual)
	var dialogue := Label.new()
	dialogue.text = str(scene["dialogue"])
	var variant_key := str(scene.get("dialogue_choice_key", ""))
	var variants: Array = scene.get("dialogue_variants", [])
	if not variant_key.is_empty() and variants.size() > 0:
		var prior_choice := CampaignStore.load_case_answer(variant_key)
		if prior_choice >= 0 and prior_choice < variants.size():
			dialogue.text = str(variants[prior_choice])
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.custom_minimum_size = Vector2(0, 150)
	dialogue.add_theme_color_override("font_color", Color("263247"))
	content.add_child(dialogue)
	var continue_button := Button.new()
	continue_button.text = "Scène suivante →"
	continue_button.custom_minimum_size = Vector2(0, 42)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.pressed.connect(func():
		CampaignStore.save_evidence("cinematic_scene_%02d" % stage)
		state["stage"] = stage + 1
		var tween := create_tween()
		tween.tween_property(app, "modulate:a", 0.65, 0.08)
		tween.tween_property(app, "modulate:a", 1.0, 0.14)
		_render_orchid_cinematic_scene(app, state)
	)
	if bool(scene.get("choice", false)):
		var question := Label.new()
		question.text = str(scene.get("question", ""))
		question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(question)
		var saved_choice := CampaignStore.load_case_answer("cinematic_choice_%02d" % stage)
		continue_button.disabled = saved_choice < 0
		var options: Array = scene.get("options", [])
		for i in range(options.size()):
			var option_button := Button.new()
			option_button.text = str(options[i])
			option_button.custom_minimum_size = Vector2(0, 38)
			option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			option_button.pressed.connect(_choose_orchid_cinematic_option.bind(stage, i, continue_button, options.size()))
			content.add_child(option_button)
	content.add_child(continue_button)
	var appear := create_tween()
	app.modulate.a = 0.0
	appear.tween_property(app, "modulate:a", 1.0, 0.18)


func _choose_orchid_cinematic_option(stage: int, choice: int, continue_button: Button, option_count: int) -> void:
	if choice < 0 or choice >= option_count:
		return
	CampaignStore.save_case_answer("cinematic_choice_%02d" % stage, choice)
	continue_button.disabled = false
	_show_notification("Décision enregistrée", "Votre réaction à cette scène a été conservée dans la sauvegarde locale.")



## A playable workday chapter: short practical tasks, interruptions and consequences.
## This complements the cinematic scenes with decisions the player must actively make.
func _open_orchid_workday() -> void:
	var app := _open_window("Une journée avec ORCHID", "CHAPITRE 1 · PARCOURS INTERACTIF", Vector2(800, 620))
	var state := {"stage": 0}
	var evidence: Array = CampaignStore.load_evidence()
	for i in range(15):
		if evidence.has("workday_stage_%02d" % i):
			state["stage"] = i + 1
		else:
			break
	_render_orchid_workday_stage(app, state)


func _orchid_workday_tasks() -> Array:
	return [
		{"act":"ACTE I — REPRENDRE LE CONTRÔLE", "title":"08:42 · Le document oublié", "brief":"Le document « Synthèse hebdomadaire » est ouvert. Il contient trois paragraphes et un bouton Enregistrer. Une carte Microslop Recap masque la moitié de la page : « Votre semaine en 12 suggestions ». Le curseur clignote derrière.", "task":"Comment reprendre votre travail ?", "options":["Fermer Recap et enregistrer le document.", "Lire les douze suggestions avant de continuer.", "Forcer la fermeture de toutes les applications."], "results":["Le document est sauvegardé. Une petite notification tente de revenir, mais vous avez récupéré votre phrase.", "Recap affiche des conseils génériques et un article sponsorisé. Vous perdez quelques minutes ; le document est toujours là.", "Les fenêtres se ferment, y compris le brouillon non enregistré. Vous récupérez la version précédente, pas les dernières lignes."]},
		{"act":"ACTE I — REPRENDRE LE CONTRÔLE", "title":"08:49 · Le message de Léa", "brief":"Léa vous écrit : « Tu peux regarder mon ticket ? Ils disent que les rappels pendant les réunions sont normaux. J’ai l’impression qu’on me prend pour une idiote. » Une réponse rapide est proposée par l’assistant.", "task":"Que lui envoyez-vous ?", "options":["« Envoie-moi les heures exactes. On va vérifier sans supposer. »", "« C’est sûrement juste un réglage, oublie. »", "« Je vais publier leur nom partout. »"], "results":["Léa répond avec trois horaires et une capture du ticket. Vous avez une piste vérifiable et elle se sent prise au sérieux.", "Léa répond « ok » puis cesse d’écrire. La journée continue, mais vous n’avez pas comparé vos observations.", "Léa vous demande de ne pas publier son ticket sans accord. Elle garde les captures, mais hésite à vous aider davantage."]},
		{"act":"ACTE I — REPRENDRE LE CONTRÔLE", "title":"09:05 · Une réunion, deux fenêtres", "brief":"La réunion de suivi commence. Votre micro est coupé ; la fenêtre de réunion reste utilisable. Une notification « Découvrez les nouveautés » passe devant le bouton de partage d’écran.", "task":"Votre priorité ?", "options":["Fermer la notification et vérifier le partage d’écran.", "Cliquer sur « Découvrir » pour qu’elle cesse de clignoter.", "Quitter la réunion sans prévenir."], "results":["Vous partagez le bon document. Une seconde notification arrive, mais vous savez désormais que la première fermeture n’a rien changé au réglage.", "La page promotionnelle s’ouvre au-dessus de la réunion. Un collègue demande si vous êtes toujours là.", "La réunion continue sans vous. Vous recevez un résumé automatique qui classe votre départ comme « faible engagement »."]},
		{"act":"ACTE I — REPRENDRE LE CONTRÔLE", "title":"09:17 · Le mode concentration", "brief":"Dans Paramètres fictifs, une option « Suspendre les suggestions jusqu’à la fin de la session » est enfin visible. Une note indique que le réglage n’affecte pas les alertes de sécurité.", "task":"Quel réglage appliquez-vous ?", "options":["Activer la suspension pour cette session.", "Activer « Toutes les recommandations personnalisées ».", "Ne rien changer et noter l’heure."], "results":["Le bureau devient calme pour un moment. Le réglage est local et temporaire ; vous pourrez vérifier s’il est respecté.", "Les suggestions se multiplient et l’assistant annonce qu’il a « mieux compris vos intérêts ». Vous pouvez toujours revenir aux paramètres.", "Vous gardez un point de comparaison utile, mais les interruptions continuent pendant votre travail."]},
		{"act":"ACTE I — REPRENDRE LE CONTRÔLE", "title":"09:26 · Le premier brouillon", "brief":"Vous rédigez un compte rendu de la réunion. Le résumé automatique propose : « L’expérience a été enrichie par des rappels contextuels ». Vos notes disent plutôt : « Deux notifications ont masqué les commandes pendant la réunion ».", "task":"Que mettez-vous dans le compte rendu ?", "options":["Décrire les deux interruptions observées, avec l’heure.", "Reprendre le résumé automatique sans modification.", "Ajouter que l’équipe entière a été espionnée."], "results":["Le compte rendu distingue les faits observés de ce que vous ignorez. Il sera plus difficile de le réécrire sans laisser de trace.", "Le texte est plus lisse, mais les deux interruptions disparaissent du compte rendu.", "Le document contient une accusation que vos notes ne prouvent pas. Il faudra la retirer avant de le transmettre."]},
		{"act":"ACTE II — L’ÉQUIPE SE RÉVEILLE", "title":"10:03 · Le ticket revient", "brief":"Le support a répondu à Léa : « Pour mieux traiter votre demande, veuillez noter votre satisfaction sur cinq étoiles. » Le lien renvoie à un questionnaire avant d’afficher le numéro de ticket.", "task":"Comment aider Léa ?", "options":["Conserver la réponse, l’heure et le numéro du ticket.", "Répondre au questionnaire avec cinq étoiles pour avancer.", "Fermer le ticket et recommencer de zéro."], "results":["Vous avez une trace de la réponse et du détour par le questionnaire. Léa accepte de joindre ces éléments à son signalement.", "Le questionnaire se termine, mais le ticket reste classé comme demande d’expérience utilisateur.", "Le nouveau ticket reçoit un autre numéro et perd le contexte. Vous devez expliquer à nouveau le problème."]},
		{"act":"ACTE II — L’ÉQUIPE SE RÉVEILLE", "title":"10:21 · La notification fantôme", "brief":"Le centre de notifications affiche « 18 fichiers analysés ». Aucun chemin, aucune empreinte et aucun rapport de scan ne sont fournis. Une animation de chargement tourne alors même que le bureau répond normalement.", "task":"Quelle action est la plus utile ?", "options":["Capturer le message et noter qu’il n’est pas vérifiable.", "Affirmer que dix-huit documents personnels ont été copiés.", "Ignorer l’alerte et supprimer l’historique."], "results":["Vous conservez ce qui est réellement visible sans transformer l’alerte en preuve d’accès aux fichiers.", "Le rapport avance une conclusion que les traces ne permettent pas d’établir. L’assistant vous demande d’où vient cette certitude.", "L’alerte disparaît de l’écran, mais vous perdez l’heure et le texte exacts pour une comparaison future."]},
		{"act":"ACTE II — L’ÉQUIPE SE RÉVEILLE", "title":"10:38 · La réunion de suivi", "brief":"Votre responsable, Marc, ouvre une réunion rapide. Il n’a pas l’air hostile ; il semble surtout pressé. « Il faut un résumé avant midi. Pas un roman. Et évitons les mots qui déclenchent une escalade inutile. »", "task":"Comment répondez-vous ?", "options":["Proposer une page avec faits, limites et questions ouvertes.", "Supprimer les détails pour que le sujet soit clos.", "Refuser de faire le compte rendu."], "results":["Marc accepte une page structurée. Il demande que les heures soient vérifiables et que les inconnues restent clairement indiquées.", "Marc remercie pour la concision. Le résumé est rapide, mais il ne permet plus de comprendre ce qui s’est passé.", "Marc fait rédiger le compte rendu par l’assistant. Votre version n’est pas jointe à la réunion."]},
		{"act":"ACTE II — L’ÉQUIPE SE RÉVEILLE", "title":"10:51 · Le message supprimé", "brief":"Léa commence à écrire : « On m’a demandé hier de ne pas désinstaller ORCHID avant la fin du test… » Le message disparaît, puis elle envoie : « Je préfère t’en parler de vive voix. »", "task":"Que faites-vous ?", "options":["Lui laisser choisir ce qu’elle veut partager.", "Insister pour qu’elle envoie immédiatement la preuve.", "Interpréter le message supprimé comme un aveu."], "results":["Léa vous propose un appel à midi. La confiance reste intacte et vous n’avez pas transformé un message hésitant en preuve.", "Léa se ferme et reporte la conversation. Vous avez peut-être gagné une réponse rapide, mais perdu sa confiance.", "Vous notez une hypothèse, pas une preuve. Le message supprimé ne permet pas de conclure qui a donné cette consigne."]},
		{"act":"ACTE II — L’ÉQUIPE SE RÉVEILLE", "title":"11:12 · L’assistant demande une note", "brief":"Microslop AI ouvre une fenêtre : « Pour personnaliser votre expérience, décrivez ce qui vous a contrarié aujourd’hui. » Le champ est libre ; la politique d’utilisation des réponses n’est pas affichée.", "task":"Que saisissez-vous ?", "options":["« Notifications à 09:05 et 10:21 ; effets observés dans le compte rendu. »", "Raconter des informations personnelles sans rapport.", "Fermer le formulaire et continuer le rapport."], "results":["Votre note contient des observations vérifiables et peu de données inutiles. L’assistant répond : « Merci, votre retour a été classé comme engagement positif. »", "Le formulaire accepte le texte et propose de le transformer en profil de préférences. Vous ne savez pas qui pourra le consulter.", "Le formulaire se ferme. Vous gardez du temps pour le rapport, sans savoir comment la note aurait été utilisée."]},
		{"act":"ACTE III — CE QUI RESTE ÉCRIT", "title":"11:34 · La version réécrite", "brief":"Le document de compte rendu a changé. « Deux interruptions ont masqué les commandes » devient « Des rappels contextuels ont été affichés ». L’historique indique qu’une version automatique a été proposée.", "task":"Quelle version gardez-vous ?", "options":["Restaurer les faits précis et conserver l’historique.", "Accepter la reformulation pour gagner du temps.", "Effacer toutes les versions pour repartir proprement."], "results":["Le rapport décrit l’impact concret et conserve la trace de la modification automatique.", "Le ton est neutre, mais le lecteur ne saura plus que les commandes étaient masquées.", "Vous perdez la comparaison entre les deux textes et ne pouvez plus expliquer ce qui a changé."]},
		{"act":"ACTE III — CE QUI RESTE ÉCRIT", "title":"11:46 · Le mini-entretien", "brief":"Lors d’un appel, Léa confirme qu’on lui a demandé d’attendre avant de désinstaller ORCHID. Elle n’a pas le nom de la personne ni de document officiel. Elle vous demande de ne pas la citer directement.", "task":"Comment utilisez-vous son témoignage ?", "options":["Résumer son témoignage sans l’identifier et demander une trace officielle.", "La citer nommément pour rendre le rapport plus fort.", "Écrire qu’elle a prouvé l’existence d’un complot."], "results":["Vous protégez Léa et distinguez son témoignage des documents qui restent à obtenir.", "Léa vous demande de retirer son nom. Elle craint que le rapport soit transmis au mauvais groupe.", "Le rapport devient catégorique sans preuve suffisante. L’assistant signale que la conclusion dépasse les sources."]},
		{"act":"ACTE III — CE QUI RESTE ÉCRIT", "title":"11:53 · Le bouton Envoyer", "brief":"Votre rapport tient sur une page : chronologie, deux captures, réponse du support, témoignage anonymisé et trois questions sans réponse. Deux boutons sont disponibles : « Envoyer au comité » et « Enregistrer une copie locale ».", "task":"Quelle est votre prochaine étape ?", "options":["Envoyer le rapport sourcé et conserver une copie.", "Conserver seulement une copie locale avant de décider.", "Envoyer le brouillon automatique sans le relire."], "results":["Le comité reçoit une version sourcée. Vous gardez une copie pour comparer la réponse à ce qui a réellement été envoyé.", "La copie locale est conservée. Vous pourrez encore vérifier les pièces avant toute transmission.", "Le brouillon est transmis avec la formulation adoucie. Le message de confirmation indique que la demande a été « simplifiée pour accélérer le traitement »."]},
		{"act":"ACTE III — CE QUI RESTE ÉCRIT", "title":"12:02 · La réponse de Marc", "brief":"Marc revient avec un message bref : « J’ai lu la page. Je ne peux pas confirmer l’intention derrière ORCHID. Je peux demander qui a validé le canal et pourquoi les interruptions sont mesurées comme de l’engagement. »", "task":"Que lui demandez-vous ?", "options":["Demander les références d’approbation et les critères de mesure.", "Lui demander de désigner un responsable tout de suite.", "Accepter la réponse sans demander de suivi."], "results":["Marc crée deux questions de suivi et promet de joindre les références disponibles. Le dossier avance sans inventer de coupable.", "Marc refuse de nommer quelqu’un sans trace. La réunion se termine sur un désaccord, pas sur une réponse.", "La conversation se termine. Aucun suivi n’est planifié et les questions restent ouvertes."]},
		{"act":"ÉPILOGUE — LE BUREAU VOUS APPARTIENT-IL ?", "title":"12:15 · Une pause réelle", "brief":"Le bureau est calme. La messagerie n’affiche plus de badge rouge. Une notification propose un « résumé personnalisé de votre matinée ». Vous pouvez reprendre le travail, faire une pause ou consulter l’archive ORCHID.", "task":"Comment terminez-vous cette journée de travail ?", "options":["Enregistrer le rapport, puis fermer la session.", "Continuer à traiter les suggestions jusqu’à ce qu’il n’y en ait plus.", "Ouvrir l’archive et préparer le prochain contrôle."], "results":["Le rapport et vos notes restent sauvegardés. Le bureau s’assombrit doucement ; la journée n’a pas résolu le problème, mais vous avez décidé quand vous arrêter.", "Les suggestions continuent de se renouveler. Une carte annonce « Encore 3 recommandations », puis en affiche cinq nouvelles.", "L’archive s’ouvre sur la liste des questions encore sans réponse. Cette fois, la prochaine étape est un contrôle précis, pas une chasse au coupable."]}
	]


func _render_orchid_workday_stage(app: Control, state: Dictionary) -> void:
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()
	var tasks := _orchid_workday_tasks()
	var stage := int(state.get("stage", 0))
	var progress := ProgressBar.new()
	progress.max_value = tasks.size()
	progress.value = stage
	progress.show_percentage = false
	content.add_child(progress)
	if stage >= tasks.size():
		var ending := Label.new()
		ending.text = "JOURNÉE TERMINÉE\n\nVous avez traversé quinze moments interactifs. Les décisions restent enregistrées et le bureau reprend la main. ORCHID n’est pas résolu par magie : vos notes, vos choix et les questions ouvertes constituent la suite du chapitre."
		ending.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ending.custom_minimum_size = Vector2(0, 150)
		content.add_child(ending)
		var archive_button := Button.new()
		archive_button.text = "Ouvrir l’archive ORCHID"
		archive_button.pressed.connect(_open_orchid_archive)
		content.add_child(archive_button)
		return
	var task: Dictionary = tasks[stage]
	var act := Label.new()
	act.text = str(task["act"])
	act.add_theme_font_size_override("font_size", 11)
	act.add_theme_color_override("font_color", Color("5b6d89"))
	content.add_child(act)
	var title := Label.new()
	title.text = str(task["title"])
	title.add_theme_font_size_override("font_size", 25)
	title.custom_minimum_size = Vector2(0, 38)
	content.add_child(title)
	var brief := Label.new()
	brief.text = str(task["brief"])
	brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brief.custom_minimum_size = Vector2(0, 125)
	content.add_child(brief)
	var prompt := Label.new()
	prompt.text = str(task["task"])
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_font_size_override("font_size", 16)
	content.add_child(prompt)
	var result := Label.new()
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size = Vector2(0, 82)
	result.add_theme_color_override("font_color", Color("263247"))
	var continue_button := Button.new()
	continue_button.text = "Moment suivant →"
	continue_button.custom_minimum_size = Vector2(0, 42)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.disabled = true
	var saved_choice := CampaignStore.load_case_answer("workday_choice_%02d" % stage)
	var options: Array = task["options"]
	var results: Array = task["results"]
	if saved_choice >= 0 and saved_choice < options.size():
		result.text = str(results[saved_choice])
		continue_button.disabled = false
	for i in range(options.size()):
		var option_button := Button.new()
		option_button.text = str(options[i])
		option_button.custom_minimum_size = Vector2(0, 38)
		option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option_button.pressed.connect(func():
			CampaignStore.save_case_answer("workday_choice_%02d" % stage, i)
			result.text = str(results[i])
			continue_button.disabled = false
			_show_notification("Choix enregistré", "Votre décision pour « %s » est conservée." % str(task["title"]))
		)
		content.add_child(option_button)
	content.add_child(result)
	continue_button.pressed.connect(func():
		CampaignStore.save_evidence("workday_stage_%02d" % stage)
		state["stage"] = stage + 1
		var tween := create_tween()
		tween.tween_property(app, "modulate:a", 0.7, 0.08)
		tween.tween_property(app, "modulate:a", 1.0, 0.14)
		_render_orchid_workday_stage(app, state)
	)
	content.add_child(continue_button)
	var appear := create_tween()
	app.modulate.a = 0.0
	appear.tween_property(app, "modulate:a", 1.0, 0.16)


func _open_orchid_workday_replay() -> void:
	_open_orchid_workday()


## A longer, gated investigation: twelve decisions across three acts.
## Correct answers unlock the next task; progress is persisted between sessions.
func _open_orchid_field_investigation() -> void:
	var app := _open_window("Enquête de terrain — ORCHID", "DOSSIER INTERACTIF · 3 ACTES · 12 DÉFIS", Vector2(760, 620))
	var content := _get_window_content(app)
	if content == null:
		return
	var state := {"stage": 0}
	var evidence: Array = CampaignStore.load_evidence()
	for i in range(12):
		if evidence.has("field_stage_%02d" % i):
			state["stage"] = i + 1
		else:
			break
	_render_orchid_field_stage(app, state)


func _orchid_field_tasks() -> Array:
	return [
		{"act":"ACTE I — RECONSTITUER LA NUIT", "title":"1. Vérifier l’ordre des événements", "brief":"Trois lignes ont été extraites du journal. L’horloge est synchronisée ; les heures sont comparables. Installation du paquet : 21:47. Activation du composant : 21:49. Première notification : 08:11 le lendemain.", "question":"Quelle conclusion est directement soutenue par ces heures ?", "options":["La notification est antérieure à l’installation.", "L’activation précède la première notification observée.", "Le journal prouve qui a déclenché le déploiement."], "correct":1, "hint":"Comparez les trois heures sans attribuer une intention ou une identité que le journal ne contient pas.", "explanation":"L’installation précède l’activation, elle-même antérieure à la notification observée. La chronologie établit un ordre, pas l’identité de l’auteur.", "evidence":"field_stage_00"},
		{"act":"ACTE I — RECONSTITUER LA NUIT", "title":"2. Détecter l’écart de canal", "brief":"Manifeste source : DEV_RING_INTERNAL. Cible inscrite dans le journal de mise à jour : STABLE / utilisateur final. Aucun ticket de dérogation n’est référencé.", "question":"Quel est le problème le plus solide à signaler ?", "options":["Le paquet est forcément falsifié.", "Le canal de développement ne correspond pas à la cible publique.", "La signature prouve qu’un responsable a autorisé la diffusion."], "correct":1, "hint":"La signature porte sur l’intégrité et l’origine du paquet, pas sur le canal qui devait le recevoir.", "explanation":"Le canal source et la cible ne correspondent pas. C’est un écart de diffusion ; seul, il ne permet pas de distinguer erreur d’automatisation et décision volontaire.", "evidence":"field_stage_01"},
		{"act":"ACTE I — RECONSTITUER LA NUIT", "title":"3. Examiner la notification des 18 fichiers", "brief":"La notification annonce « 18 fichiers analysés ». Les détails n’affichent ni chemins, ni noms, ni empreinte, ni résultat de scan. Le journal interne classe l’événement comme notification d’engagement.", "question":"Quelle affirmation peut être défendue ?", "options":["Dix-huit fichiers personnels ont nécessairement été lus.", "La notification ne fournit pas de preuve vérifiable d’une analyse de fichiers.", "Les fichiers ont été supprimés."], "correct":1, "hint":"Séparez ce que le message prétend de ce que les traces permettent de vérifier.", "explanation":"Le message ne contient aucune trace de fichiers traités. L’indice soutient une alerte non vérifiable, pas une conclusion sur l’accès ou la suppression de documents.", "evidence":"field_stage_02"},
		{"act":"ACTE I — RECONSTITUER LA NUIT", "title":"4. Choisir la prochaine vérification", "brief":"Vous avez l’heure d’activation et l’écart de canal, mais aucun ticket d’approbation. Le rapport de conception décrit une mesure de rétention, sans nom de responsable.", "question":"Quelle action renforce le mieux le dossier ?", "options":["Publier immédiatement le nom d’un employé supposé.", "Conserver les journaux originaux et demander le ticket d’approbation manquant.", "Supprimer les traces ambiguës pour simplifier le récit."], "correct":1, "hint":"La prochaine action devrait réduire l’incertitude et préserver les sources.", "explanation":"Préserver les originaux et rechercher la référence d’approbation permet de tester les hypothèses sans accuser quelqu’un sans preuve.", "evidence":"field_stage_03"},
		{"act":"ACTE II — TESTER LE COMPORTEMENT", "title":"5. Comparer l’intention à la recherche", "brief":"Requête de test : « désactiver les notifications ». Le premier résultat est sponsorisé et recommande davantage de notifications. Le réglage pertinent apparaît plus bas.", "question":"Quel test permet de mesurer le détournement sans se fier à une seule capture ?", "options":["Répéter plusieurs requêtes de désactivation et comparer l’ordre des résultats.", "Compter uniquement le nombre de couleurs dans la page.", "Conclure que chaque résultat sponsorisé est illégal."], "correct":0, "hint":"Il faut un protocole reproductible et une comparaison entre intention et classement.", "explanation":"Des requêtes répétées et documentées permettent d’observer si le réglage utile est systématiquement relégué. Le résultat sponsorisé seul ne prouve pas une violation.", "evidence":"field_stage_04"},
		{"act":"ACTE II — TESTER LE COMPORTEMENT", "title":"6. Comprendre la métrique", "brief":"Le tableau de bord mesure le retour dans l’application après une notification. Il ne mesure pas directement si la tâche de l’utilisateur a été accomplie ni s’il souhaitait recevoir l’alerte.", "question":"Quelle faiblesse méthodologique cela révèle-t-il ?", "options":["Le taux de retour suffit à prouver que les utilisateurs sont satisfaits.", "La métrique d’engagement est utilisée comme substitut à l’utilité réelle.", "Aucune mesure chiffrée ne peut jamais être utilisée."], "correct":1, "hint":"Une personne peut revenir parce qu’elle est distraite ou contrariée, pas parce qu’elle a été aidée.", "explanation":"Le retour est un indicateur d’activité, pas une mesure directe de satisfaction ou de réussite. Le confondre avec l’utilité peut récompenser des interruptions nuisibles.", "evidence":"field_stage_05"},
		{"act":"ACTE II — TESTER LE COMPORTEMENT", "title":"7. Repérer la répétition du mécanisme", "brief":"Trois tests montrent le même schéma : le réglage Wi-Fi est relégué, la sortie est interrompue par une carte, et la réponse courte est fragmentée pour inviter à continuer.", "question":"Quelle hypothèse explique le mieux ces observations sans dépasser les preuves ?", "options":["Trois erreurs totalement indépendantes sont certaines.", "Un objectif commun de prolongation des interactions est compatible avec les trois cas.", "Ces cas identifient avec certitude une personne responsable."], "correct":1, "hint":"Une règle commune peut expliquer un motif répété, mais pas nécessairement qui l’a conçue.", "explanation":"Les cas convergent vers un mécanisme de rétention. Ils n’établissent ni l’auteur individuel ni la chaîne exacte de décision.", "evidence":"field_stage_06"},
		{"act":"ACTE II — TESTER LE COMPORTEMENT", "title":"8. Construire un test équitable", "brief":"Vous devez comparer deux versions d’une notification. Les résultats actuels ne distinguent pas tâche terminée, clic accidentel, fermeture de la fenêtre et retour volontaire.", "question":"Quel protocole produit la comparaison la plus informative ?", "options":["Mesurer seulement le nombre de clics sur la version qui interrompt le plus.", "Définir à l’avance tâche terminée, désactivation choisie et retours non sollicités, puis comparer les deux versions.", "Changer le texte, l’heure et la fréquence en même temps sans consigner les changements."], "correct":1, "hint":"Un bon test définit les critères avant de mesurer et évite de changer plusieurs variables simultanément.", "explanation":"Des critères explicites et une comparaison contrôlée aident à distinguer utilité et engagement. Ils empêchent de présenter une hausse de clics comme une amélioration automatique.", "evidence":"field_stage_07"},
		{"act":"ACTE III — ÉTABLIR LES RESPONSABILITÉS", "title":"9. Évaluer la signature", "brief":"La signature du paquet est valide et l’empreinte correspond au registre interne. Le canal public ne correspond toutefois pas au canal de développement et la référence d’approbation est absente.", "question":"Que prouve la signature ?", "options":["Que la diffusion publique a été approuvée.", "Que le paquet correspond à une origine signée et n’a pas été modifié depuis la signature, dans les limites du mécanisme.", "Que le comportement du composant est acceptable."], "correct":1, "hint":"Intégrité, autorisation et qualité du comportement sont trois contrôles différents.", "explanation":"Une signature valide ne remplace ni l’approbation de diffusion ni une évaluation du comportement. Les contrôles doivent rester séparés.", "evidence":"field_stage_08"},
		{"act":"ACTE III — ÉTABLIR LES RESPONSABILITÉS", "title":"10. Lire le ticket d’assistance", "brief":"Le support a reçu trois signalements similaires. La réponse modèle conseille de « personnaliser les préférences », mais ne fournit ni chemin de désactivation ni numéro de version. Les signalements ont été classés comme demandes de confort.", "question":"Quelle pièce supplémentaire serait la plus utile ?", "options":["Le nombre de mots dans la réponse modèle.", "L’historique de classification des tickets et la version du modèle de réponse utilisé.", "Une estimation du caractère de la personne qui a écrit le ticket."], "correct":1, "hint":"Cherchez une trace vérifiable qui relie les plaintes à une règle de traitement.", "explanation":"Les versions du modèle et l’historique de classement permettent de vérifier si les plaintes ont été systématiquement détournées. Le style du message n’est pas une preuve.", "evidence":"field_stage_09"},
		{"act":"ACTE III — ÉTABLIR LES RESPONSABILITÉS", "title":"11. Préparer une conclusion défendable", "brief":"Le dossier contient un écart de canal, une approbation absente, une métrique de rétention et trois exemples de classement biaisé. Aucun journal ne nomme la personne qui a autorisé la mise en production.", "question":"Quelle formulation devrait figurer dans le rapport ?", "options":["« Nous avons identifié avec certitude le coupable. »", "« Plusieurs traces convergent vers un mécanisme de rétention ; l’auteur et l’intention initiale ne sont pas établis. »", "« Aucun problème n’existe puisqu’une signature est valide. »"], "correct":1, "hint":"Énoncez les faits convergents et gardez explicitement les inconnues.", "explanation":"Cette formulation rend compte du faisceau de preuves sans transformer une hypothèse en accusation.", "evidence":"field_stage_10"},
		{"act":"ACTE III — ÉTABLIR LES RESPONSABILITÉS", "title":"12. Décider de la suite", "brief":"Le rapport est suffisamment étayé pour demander une revue, mais il reste des questions sur l’origine du déploiement. La publication peut protéger d’autres utilisateurs ; une copie locale préserve les traces sans garantir de correction.", "question":"Quelle décision correspond le mieux à une enquête prudente ?", "options":["Effacer les journaux et déclarer l’affaire résolue.", "Conserver les originaux, transmettre les faits sourcés et demander la suspension du canal jusqu’à vérification.", "Affirmer que l’incident est volontaire sans demander d’autres éléments."], "correct":1, "hint":"Privilégiez la conservation des preuves, une formulation sourcée et une action proportionnée au risque.", "explanation":"La décision recommandée combine préservation, transparence sur les limites et demande de contrôle. Elle ne ferme pas prématurément les questions encore ouvertes.", "evidence":"field_stage_11"}
	]


func _render_orchid_field_stage(app: Control, state: Dictionary) -> void:
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()
	var tasks := _orchid_field_tasks()
	var stage := int(state.get("stage", 0))
	var progress := Label.new()
	progress.text = "PROGRESSION : %d / %d défis validés" % [mini(stage, tasks.size()), tasks.size()]
	content.add_child(progress)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = tasks.size()
	bar.value = stage
	bar.show_percentage = true
	content.add_child(bar)
	if stage >= tasks.size():
		var final_report := Label.new()
		final_report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		final_report.text = "ENQUÊTE DE TERRAIN TERMINÉE\n\nVous avez résolu les douze défis répartis sur trois actes : chronologie, comportement et conformité. Les conclusions reposent sur des traces conservées, pas sur l’identification spéculative d’un coupable.\n\nLe dossier de terrain est sauvegardé. Vous pouvez maintenant comparer cette enquête au comité d’incident ou reprendre les scènes précédentes pour compléter les pièces manquantes."
		content.add_child(final_report)
		CampaignStore.save_evidence("field_investigation_completed")
		var dashboard := Button.new()
		dashboard.text = "Ouvrir le tableau de synthèse"
		dashboard.pressed.connect(_open_orchid_campaign_dashboard)
		content.add_child(dashboard)
		var archive := Button.new()
		archive.text = "Retour à l’archive ORCHID"
		archive.pressed.connect(_open_orchid_archive)
		content.add_child(archive)
		return
	var task: Dictionary = tasks[stage]
	var heading := Label.new()
	heading.text = str(task["act"]) + "\n" + str(task["title"])
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_color_override("font_color", Color("164a87"))
	content.add_child(heading)
	var brief := Label.new()
	brief.text = str(task["brief"])
	brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(brief)
	var question := Label.new()
	question.text = "\nDÉCISION À PRENDRE\n" + str(task["question"])
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(question)
	var feedback := Label.new()
	feedback.text = "Choisissez une réponse. Une mauvaise réponse ne bloque pas définitivement l’enquête : vous pouvez réessayer."
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size = Vector2(0, 84)
	content.add_child(feedback)
	var next_button := Button.new()
	next_button.text = "Défi suivant"
	next_button.disabled = true
	next_button.pressed.connect(func():
		state["stage"] = stage + 1
		_render_orchid_field_stage(app, state)
	)
	content.add_child(next_button)
	var options: Array = task["options"]
	for i in range(options.size()):
		var answer_button := Button.new()
		answer_button.text = "%d. %s" % [i + 1, str(options[i])]
		answer_button.custom_minimum_size = Vector2(0, 44)
		answer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		answer_button.pressed.connect(_answer_orchid_field_stage.bind(app, state, stage, i, feedback, next_button))
		content.add_child(answer_button)


func _answer_orchid_field_stage(app: Control, state: Dictionary, stage: int, answer: int, feedback: Label, next_button: Button) -> void:
	var tasks := _orchid_field_tasks()
	if stage < 0 or stage >= tasks.size():
		return
	var task: Dictionary = tasks[stage]
	CampaignStore.save_case_answer("field_stage_%02d" % stage, answer)
	if answer == int(task["correct"]):
		CampaignStore.save_evidence(str(task["evidence"]))
		feedback.text = "TRACE VALIDÉE\n\n%s\n\nNouvelle pièce ajoutée au dossier. La progression est sauvegardée." % str(task["explanation"])
		next_button.disabled = false
	else:
		feedback.text = "RÉPONSE INSUFFISANTE\n\n%s\n\nRelisez les traces et essayez une autre réponse. Le défi suivant reste verrouillé jusqu’à validation." % str(task["hint"])
		next_button.disabled = true


## Consolidates discoveries and player decisions into a persistent case status.
func _open_orchid_campaign_dashboard() -> void:
	var app := _open_window("Tableau de synthèse — dossier ORCHID", "ÉTAT DE CAMPAGNE · DONNÉES LOCALES SAUVEGARDÉES", Vector2(740, 590))
	var content := _get_window_content(app)
	if content == null:
		return
	var summary := Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.custom_minimum_size = Vector2(0, 290)
	content.add_child(summary)
	var refresh := Button.new()
	refresh.text = "Actualiser le dossier"
	refresh.pressed.connect(func():
		_render_orchid_campaign_dashboard(summary)
	)
	content.add_child(refresh)
	var evidence_button := Button.new()
	evidence_button.text = "Examiner les pièces manquantes"
	evidence_button.pressed.connect(_open_orchid_casebook)
	content.add_child(evidence_button)
	var compliance_button := Button.new()
	compliance_button.text = "Reprendre la revue de conformité"
	compliance_button.pressed.connect(_open_orchid_compliance_review)
	content.add_child(compliance_button)
	var committee_button := Button.new()
	committee_button.text = "Revenir au comité d’incident"
	committee_button.pressed.connect(_open_orchid_decision_board)
	content.add_child(committee_button)
	_render_orchid_campaign_dashboard(summary)


func _render_orchid_campaign_dashboard(summary: Label) -> void:
	var evidence: Array = CampaignStore.load_evidence()
	var groups := [
		{"name":"Déploiement et provenance", "ids":["deployment_channel", "deployment_install", "deployment_trace", "night_rule", "night_download", "night_install", "night_activation", "night_notification"]},
		{"name":"Comportement au redémarrage", "ids":["morning_notification_preview", "morning_file_alert", "morning_search_diversion", "morning_ai_deflection", "morning_sequence_completed"]},
		{"name":"Recommandations et classement", "ids":["audit_wifi", "audit_exit", "audit_answer", "audit_common_rule"]},
		{"name":"Contrôles de conformité", "ids":["compliance_signature", "compliance_channel", "compliance_approval", "compliance_notice", "compliance_finding"]},
		{"name":"Pièces annexes", "ids":["support_ticket", "survey_bias", "night_log_reconstructed", "incident_report"]},
		{"name":"Séquence narrative (30 scènes)", "ids":["cinematic_scene_00", "cinematic_scene_01", "cinematic_scene_02", "cinematic_scene_03", "cinematic_scene_04", "cinematic_scene_05", "cinematic_scene_06", "cinematic_scene_07", "cinematic_scene_08", "cinematic_scene_09", "cinematic_scene_10", "cinematic_scene_11", "cinematic_scene_12", "cinematic_scene_13", "cinematic_scene_14", "cinematic_scene_15", "cinematic_scene_16", "cinematic_scene_17", "cinematic_scene_18", "cinematic_scene_19", "cinematic_scene_20", "cinematic_scene_21", "cinematic_scene_22", "cinematic_scene_23", "cinematic_scene_24", "cinematic_scene_25", "cinematic_scene_26", "cinematic_scene_27", "cinematic_scene_28", "cinematic_scene_29"]},
		{"name":"Journée interactive (15 séquences)", "ids":["workday_stage_00", "workday_stage_01", "workday_stage_02", "workday_stage_03", "workday_stage_04", "workday_stage_05", "workday_stage_06", "workday_stage_07", "workday_stage_08", "workday_stage_09", "workday_stage_10", "workday_stage_11", "workday_stage_12", "workday_stage_13", "workday_stage_14"]},
		{"name":"Enquête de terrain (12 défis)", "ids":["field_stage_00", "field_stage_01", "field_stage_02", "field_stage_03", "field_stage_04", "field_stage_05", "field_stage_06", "field_stage_07", "field_stage_08", "field_stage_09", "field_stage_10", "field_stage_11", "field_investigation_completed"]}
	]
	var lines := PackedStringArray(["DOSSIER ORCHID — SYNTHÈSE ACTUALISÉE", "Pièces enregistrées : %d" % evidence.size(), ""])
	var collected := 0
	var possible := 0
	for group in groups:
		var count := 0
		for evidence_id in group["ids"]:
			possible += 1
			if evidence.has(evidence_id):
				count += 1
				collected += 1
		lines.append("%s : %d / %d" % [group["name"], count, group["ids"].size()])
	var morning := PackedStringArray()
	for stage in range(5):
		var answer := CampaignStore.load_case_answer("morning_stage_%d" % stage)
		morning.append("Étape %d : %s" % [stage + 1, "choix sauvegardé (%d)" % (answer + 1) if answer >= 0 else "non examinée"])
	lines.append("")
	lines.append("PARCOURS DU REDÉMARRAGE")
	lines.append_array(morning)
	var committee := CampaignStore.load_case_answer("incident_committee_decision")
	var committee_names := ["Escalade avec rapport sourcé", "Surveillance avant publication", "Clôture comme incident de configuration"]
	lines.append("")
	lines.append("DÉCISION DU COMITÉ : %s" % (committee_names[committee] if committee >= 0 and committee < committee_names.size() else "aucune décision enregistrée"))
	var ending := CampaignStore.load_ending()
	var ending_label := "rapport transmis" if ending == "published" else ("copie locale conservée" if ending == "preserved" else "non décidée")
	lines.append("CONCLUSION : %s" % ending_label)
	lines.append("")
	if evidence.has("compliance_finding") and evidence.has("audit_common_rule"):
		lines.append("ÉVALUATION : plusieurs sources indépendantes convergent. Le motif de rétention est étayé ; l’identité de l’auteur et l’intention initiale restent non établies.")
	elif evidence.has("compliance_finding") or evidence.has("audit_common_rule"):
		lines.append("ÉVALUATION : faisceau de preuves partiel. Une anomalie est documentée, mais la comparaison croisée reste incomplète.")
	else:
		lines.append("ÉVALUATION : enquête en cours. Examinez les traces et séparez les faits établis des hypothèses.")
	lines.append("Indice de couverture du tableau : %d / %d catégories suivies." % [collected, possible])
	summary.text = "\n".join(lines)


func _open_orchid_recommendation_audit() -> void:
	var app := _open_window("Audit des recommandations ORCHID", "BANC D’ESSAI · TRACES LOCALES", Vector2(700, 540))
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()
	var intro := Label.new()
	intro.text = "Trois personnes ont formulé des demandes simples. Comparez la demande, le résultat affiché et la règle de classement cachée. Chaque fiche consultée ajoute une pièce au dossier."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	var detail := Label.new()
	detail.text = "Sélectionnez un cas pour afficher les traces."
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(0, 145)
	content.add_child(detail)
	var status := Label.new()
	var prior_evidence: Array = CampaignStore.load_evidence()
	var prior_count := 0
	for evidence_id in ["audit_wifi", "audit_exit", "audit_answer"]:
		if prior_evidence.has(evidence_id):
			prior_count += 1
	status.text = "Cas examinés : %d / 3" % prior_count
	content.add_child(status)
	var cases := [
		["Trouver le réglage Wi-Fi", "Le diagnostic réseau est relégué sous deux recommandations sponsorisées.", "Le classement récompense les sessions prolongées, même si la résolution est retardée.", "audit_wifi"],
		["Fermer l’application", "Une carte « Avant de partir… » apparaît avant le bouton de fermeture.", "Une intention de sortie est traitée comme un risque d’engagement à récupérer.", "audit_exit"],
		["Obtenir une réponse courte", "La réponse est tronquée et un bouton invite à continuer avec ORCHID.", "Une réponse complète est fragmentée lorsqu’une étape supplémentaire augmente les interactions.", "audit_answer"]
	]
	for item in cases:
		var case_button := Button.new()
		case_button.text = str(item[0])
		case_button.custom_minimum_size = Vector2(0, 38)
		case_button.pressed.connect(func():
			detail.text = "DEMANDE\n%s\n\nRÉSULTAT\n%s\n\nRÈGLE CACHÉE\n%s" % [item[0], item[1], item[2]]
			var evidence_id := str(item[3])
			CampaignStore.save_evidence(evidence_id)
			var evidence_now: Array = CampaignStore.load_evidence()
			var count := 0
			for required_id in ["audit_wifi", "audit_exit", "audit_answer"]:
				if evidence_now.has(required_id):
					count += 1
			status.text = "Cas examinés : %d / 3 — pièce ajoutée" % count
		)
		content.add_child(case_button)
	var conclusion := Button.new()
	conclusion.text = "Comparer les trois règles"
	conclusion.pressed.connect(func():
		var evidence_now: Array = CampaignStore.load_evidence()
		if evidence_now.has("audit_wifi") and evidence_now.has("audit_exit") and evidence_now.has("audit_answer"):
			detail.text = "CONCLUSION\n\nLes trois demandes différentes sont ramenées à la même métrique : provoquer une interaction supplémentaire. Résoudre, quitter et demander de l’aide deviennent des occasions de retenir la personne. La répétition suggère une règle commune de classement plutôt qu’une erreur isolée d’interface."
			CampaignStore.save_evidence("audit_common_rule")
			CampaignStore.save_case_answer("audit_common_rule", 1)
		else:
			detail.text = "Conclusion incomplète : examinez les trois cas pour comparer leurs règles."
	)
	content.add_child(conclusion)


func _open_orchid_compliance_review() -> void:
	var app := _open_window("Revue de conformité — diffusion 0.9.17", "CONTRÔLE DE CHANGEMENT · DOSSIER INTERNE", Vector2(740, 590))
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()
	var intro := Label.new()
	intro.text = "Le paquet est signé, mais une signature prouve l’origine du fichier, pas l’autorisation de le distribuer. Vérifiez les quatre contrôles indépendants avant de décider si le déploiement pouvait être considéré comme approuvé."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	var detail := Label.new()
	detail.text = "Choisissez un contrôle pour examiner sa trace et l’écart associé."
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(0, 132)
	content.add_child(detail)
	var status := Label.new()
	content.add_child(status)
	var checks := [
		["1 · Identité du paquet", "Signature cryptographique : valide. Empreinte identique à celle publiée dans le registre interne.", "Ce contrôle confirme l’intégrité du paquet. Il ne confirme pas que le paquet est destiné au canal public.", "compliance_signature"],
		["2 · Canal de destination", "Canal source : DEV_RING_INTERNAL. Appareil cible : STABLE / utilisateur final.", "Écart majeur : le canal de développement et le canal stable ne correspondent pas. Aucun ticket de dérogation n’est référencé.", "compliance_channel"],
		["3 · Autorisation de diffusion", "Champ release_approval : absent. Référence de validation : null. Responsable de mise en production : non renseigné.", "Écart majeur : aucune approbation formelle n’est liée au déploiement. Le journal ne permet pas de distinguer un défaut d’automatisation d’une action volontaire.", "compliance_approval"],
		["4 · Information utilisateur", "Note publique : « améliorations de confort et stabilité ». Le terme préversion n’apparaît pas ; le comportement de notification n’est pas décrit.", "Écart majeur : le texte visible ne permet pas de comprendre la nature expérimentale du composant ni son objectif de mesure.", "compliance_notice"]
	]
	for check in checks:
		var check_button := Button.new()
		check_button.text = str(check[0])
		check_button.custom_minimum_size = Vector2(0, 38)
		check_button.pressed.connect(func():
			detail.text = "%s\n\nTRACE\n%s\n\nÉVALUATION\n%s" % [check[0], check[1], check[2]]
			CampaignStore.save_evidence(str(check[3]))
			var seen: Array = CampaignStore.load_evidence()
			var count := 0
			for required in ["compliance_signature", "compliance_channel", "compliance_approval", "compliance_notice"]:
				if seen.has(required):
					count += 1
			status.text = "Contrôles examinés : %d / 4" % count
		)
		content.add_child(check_button)
	var conclusion := Button.new()
	conclusion.text = "Établir le constat de conformité"
	conclusion.pressed.connect(func():
		var seen: Array = CampaignStore.load_evidence()
		var complete := true
		for required in ["compliance_signature", "compliance_channel", "compliance_approval", "compliance_notice"]:
			if not seen.has(required):
				complete = false
		if complete:
			detail.text = "CONSTAT\n\nLa signature est valide, mais trois autres contrôles échouent : canal incompatible, absence d’approbation et information utilisateur incomplète. La validité technique du paquet ne vaut donc pas autorisation de diffusion. Les traces ne prouvent pas qui a provoqué l’écart ; elles établissent qu’il aurait dû être détecté avant la mise en production."
			CampaignStore.save_evidence("compliance_finding")
			CampaignStore.save_case_answer("compliance_finding", 1)
		else:
			detail.text = "Constat indisponible : examinez les quatre contrôles. La signature valide ne suffit pas à conclure."
	)
	content.add_child(conclusion)


func _open_orchid_decision_board() -> void:
	var app := _open_window("Comité d’incident — ORCHID", "SÉANCE DE REVUE · COMPTE RENDU LOCAL", Vector2(720, 560))
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()
	var intro := Label.new()
	intro.text = "Vous avez été chargé de proposer la prochaine action. Le comité ne connaît pas l’auteur du déploiement. Il doit décider quoi préserver, quelles affirmations publier et quelles incertitudes laisser explicitement ouvertes."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	var evidence_status := Label.new()
	evidence_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(evidence_status)
	var report := Label.new()
	report.text = "Le compte rendu apparaîtra ici après votre décision."
	report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report.custom_minimum_size = Vector2(0, 120)
	content.add_child(report)
	var refresh_status := func() -> void:
		var evidence: Array = CampaignStore.load_evidence()
		var groups := [
			{"name":"Chronologie", "ids":["night_rule","night_download","night_install","night_activation","night_notification"]},
			{"name":"Recommandations", "ids":["audit_wifi","audit_exit","audit_answer"]},
			{"name":"Conformité", "ids":["compliance_channel","compliance_approval","compliance_notice"]}
		]
		var lines := PackedStringArray(["ÉTAT DES PREUVES"])
		for group in groups:
			var count := 0
			for evidence_id in group["ids"]:
				if evidence.has(evidence_id):
					count += 1
			lines.append("%s : %d / %d" % [group["name"], count, group["ids"].size()])
		evidence_status.text = "\n".join(lines)
	refresh_status.call()
	var refresh := Button.new()
	refresh.text = "Actualiser l’état des preuves"
	refresh.pressed.connect(func(): refresh_status.call())
	content.add_child(refresh)
	var options := [
		["Escalader avec un rapport sourcé", "decision_escalate", "Le comité transmet les traces horodatées, distingue les faits des hypothèses et demande la suspension du canal de diffusion jusqu’à vérification. Les preuves locales sont conservées. C’est l’option la plus prudente lorsque l’origine de l’erreur reste inconnue."],
		["Surveiller sans publier immédiatement", "decision_monitor", "Le comité conserve une copie locale et demande une reproduction contrôlée avant toute déclaration publique. Cette option limite les affirmations prématurées, mais laisse le risque actif tant qu’aucune mesure de suspension n’est confirmée."],
		["Clore comme incident de configuration", "decision_close", "Le comité classe l’événement comme défaut de configuration et ferme le dossier sans attribution de responsabilité. Cette option est rapide, mais elle ne répond ni à l’absence d’approbation ni à la répétition des mécanismes de rétention observés."]
	]
	for option in options:
		var choice := Button.new()
		choice.text = str(option[0])
		choice.custom_minimum_size = Vector2(0, 42)
		choice.pressed.connect(func():
			CampaignStore.save_case_answer("incident_committee_decision", options.find(option))
			CampaignStore.save_evidence(str(option[1]))
			report.text = "DÉCISION ENREGISTRÉE\n\n%s\n\nCette décision ne modifie pas les faits déjà collectés. Elle fixe la manière dont le dossier sera traité." % option[2]
			for child in content.get_children():
				if child is Button and child != refresh:
					child.disabled = true
		)
		content.add_child(choice)
	var prior_decision := CampaignStore.load_case_answer("incident_committee_decision")
	if prior_decision >= 0 and prior_decision < options.size():
		report.text = "DERNIÈRE DÉCISION ENREGISTRÉE\n\n%s\n\nVous pouvez consulter les preuves, mais cette séance sauvegardée ne peut pas être votée une seconde fois dans la même fenêtre." % str(options[prior_decision][2])
		for child in content.get_children():
			if child is Button and child != refresh:
				child.disabled = true


## Additional playable investigative scenes broaden the chapter beyond reading the final report.
func _open_orchid_night_log() -> void:
	var app := _open_window("Journal de nuit — 21:47 à 08:11", "RECONSTITUTION D’INCIDENT · HORAIRES SIMULÉS", Vector2(720, 560))
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()
	var intro := Label.new()
	intro.text = "Cinq événements ont été exportés du journal local. Ouvrez-les dans l’ordre et cherchez le moment où une mise à jour réservée au développement devient une expérience active sur l’appareil public."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", Color("263247"))
	content.add_child(intro)
	var detail := Label.new()
	detail.name = "NightLogDetail"
	detail.text = "Sélectionnez un événement pour lire sa trace et l’ajouter à votre dossier."
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_theme_color_override("font_color", Color("263247"))
	content.add_child(detail)
	var events := [
		{"time":"21:47","title":"Règle de ciblage modifiée","id":"night_rule","body":"Service de déploiement : la règle « test progressif — groupe interne » a été copiée vers le groupe « appareils compatibles ». Le journal ne précise pas si cette copie était une action automatique ou une modification humaine."},
		{"time":"02:13","title":"Paquet téléchargé","id":"night_download","body":"Le paquet experience-orchid-preview 0.9.17-dev arrive depuis DEV_RING_INTERNAL. La signature est valide, mais aucun champ d’approbation de diffusion n’est présent."},
		{"time":"02:14","title":"Installation terminée","id":"night_install","body":"Le programme d’installation indique « règle satisfaite ». La cible réelle est un appareil du canal STABLE. Aucun redémarrage manuel n’est enregistré ; l’installation est marquée « reprise au prochain démarrage »."},
		{"time":"07:58","title":"Composant activé","id":"night_activation","body":"Après le démarrage, Notification Timing Preview est chargé. Le résumé public parle uniquement d’améliorations de confort et ne mentionne ni préversion ni canal interne."},
		{"time":"08:11","title":"Première notification trompeuse","id":"night_notification","body":"Le système annonce que 18 fichiers ont été analysés. Aucun chemin de fichier n’est attaché à l’événement. Le compteur est classé dans la catégorie « engagement — retour après notification »."}
	]
	for event in events:
		var button := Button.new()
		button.text = "%s  ·  %s" % [event["time"], event["title"]]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			detail.text = "%s — %s\n\n%s\n\nCette trace est fictive et ne lit aucun fichier réel." % [event["time"], event["title"], event["body"]]
			CampaignStore.save_evidence(str(event["id"]))
			_show_notification("Trace ajoutée", "%s est maintenant conservé dans le dossier ORCHID." % event["title"])
		)
		content.add_child(button)
	var conclusion := Button.new()
	conclusion.text = "Rédiger une conclusion provisoire"
	conclusion.pressed.connect(func() -> void:
		var count := 0
		for event in events:
			if CampaignStore.load_evidence().has(event["id"]):
				count += 1
		detail.text = "RECONSTITUTION : %d/5 traces examinées.\n\nLa piste la plus cohérente est une règle de déploiement trop large, suivie d’une installation automatique et d’une activation au démarrage. La note sur les métriques de retour laisse penser que l’équipe a ensuite choisi de conserver le composant. Les journaux ne suffisent pas à identifier la personne responsable ni à prouver que le premier déploiement était intentionnel." % count
		if count >= 3:
			CampaignStore.save_evidence("night_reconstruction")
	)
	content.add_child(conclusion)


func _open_orchid_support_ticket() -> void:
	var app := _open_window("Assistance Microslop — ticket #EXP-1842", "TICKET INTERNE · STATUT : RÉSOLU SANS ACTION", Vector2(690, 500))
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()
	var transcript := Label.new()
	transcript.text = "08:19 — UTILISATEUR : « Je n’ai pas de fichiers dans Documents. Pourquoi le système dit-il en avoir analysé 18 ? »\n\n08:20 — ASSISTANCE : « Le compteur reflète une activité de personnalisation et ne signifie pas nécessairement qu’un fichier a été ouvert. »\n\n08:21 — UTILISATEUR : « Alors pourquoi l’alerte parle-t-elle d’une analyse terminée ? »\n\n08:22 — ASSISTANCE : « Nous pouvons classer votre demande comme une incompréhension du résumé. »"
	transcript.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transcript.size_flags_vertical = Control.SIZE_EXPAND_FILL
	transcript.add_theme_color_override("font_color", Color("263247"))
	content.add_child(transcript)
	var question := Label.new()
	question.text = "Quelle réponse envoyez-vous au ticket ?"
	question.add_theme_color_override("font_color", Color("24344d"))
	content.add_child(question)
	var options := [
		"Demander les chemins et les journaux de fichiers",
		"Accepter la clôture comme un problème de vocabulaire",
		"Demander que l’incident soit transmis à l’équipe de déploiement"
	]
	for index in range(options.size()):
		var button := Button.new()
		button.text = options[index]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			CampaignStore.save_case_answer("support_ticket", index)
			CampaignStore.save_evidence("support_ticket_reviewed")
			match index:
				0:
					transcript.text += "\n\nVOUS : « Merci de joindre la liste des fichiers et les journaux d’accès. »\n\nASSISTANCE : « Aucun chemin n’est associé à cet événement. Votre demande a été transférée vers la catégorie “retour produit”, sans engagement de fournir des traces. »"
				1:
					transcript.text += "\n\nASSISTANCE : « Parfait ! Le ticket est résolu. Votre compréhension du résumé est notre indicateur de succès. »\n\nNOTE AUTOMATIQUE : aucun fichier de diagnostic joint."
				2:
					transcript.text += "\n\nASSISTANCE : « La demande a été transmise. »\n\nJOURNAL DE ROUTAGE : destination = Équipe Expérience ; priorité = faible ; pièce jointe = aucune."
			for child in content.get_children():
				if child is Button:
					child.disabled = true
		)
		content.add_child(button)


func _open_orchid_survey() -> void:
	var app := _open_window("Enquête de satisfaction — après incident", "ENQUÊTE AUTOMATIQUE · 1 QUESTION", Vector2(620, 440))
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()
	var prompt := Label.new()
	prompt.text = "Après avoir cherché à désactiver les notifications, une enquête apparaît :\n\n« Nous sommes ravis que vous soyez encore ici ! Quelle fonctionnalité vous a le plus aidé à rester engagé ? »\n\nLa question ne demande pas si les notifications étaient souhaitées. Choisissez une réponse pour voir comment le tableau de bord interprète votre choix."
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prompt.add_theme_color_override("font_color", Color("263247"))
	content.add_child(prompt)
	var result := Label.new()
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_color_override("font_color", Color("263247"))
	content.add_child(result)
	var options := [
		"Les notifications ne m’ont pas aidé",
		"Je voulais simplement fermer la fenêtre",
		"Je ne souhaite pas répondre"
	]
	for index in range(options.size()):
		var button := Button.new()
		button.text = options[index]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			CampaignStore.save_case_answer("orchid_survey", index)
			CampaignStore.save_evidence("survey_bias_reviewed")
			if index == 0:
				result.text = "RÉSULTAT DU TABLEAU DE BORD : « Interaction avec la fonctionnalité » — l’insatisfaction est enregistrée en note secondaire, tandis que le retour dans l’application reste le KPI principal."
			elif index == 1:
				result.text = "RÉSULTAT DU TABLEAU DE BORD : « Session récupérée avec succès ». Le système compte le fait que vous soyez revenu, pas la raison pour laquelle vous êtes revenu."
			else:
				result.text = "RÉSULTAT DU TABLEAU DE BORD : « Enquête affichée ». L’absence de réponse est elle aussi comptée comme une occasion d’interaction. Aucune mesure de satisfaction n’a été collectée."
			prompt.text += "\n\nVotre réponse : " + options[index]
			for child in content.get_children():
				if child is Button:
					child.disabled = true
		)
		content.add_child(button)


func _open_orchid_casebook() -> void:
	var app := _open_window("Carnet d’enquête — ORCHID", "DOSSIER PERSONNEL · LES PIÈCES SONT FICTIVES", Vector2(760, 560))
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()

	var intro := Label.new()
	intro.text = "Ne vous contentez pas du rapport final. Comparez les traces laissées par plusieurs applications. Certaines pièces semblent innocentes isolément ; ensemble, elles racontent autre chose."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", Color("263247"))
	content.add_child(intro)

	var status := Label.new()
	status.name = "EvidenceProgress"
	status.add_theme_color_override("font_color", Color("356b47"))
	content.add_child(status)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(split)
	var list_panel := VBoxContainer.new()
	list_panel.custom_minimum_size.x = 235
	list_panel.add_theme_constant_override("separation", 5)
	split.add_child(list_panel)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(detail_scroll)
	var detail := Label.new()
	detail.name = "EvidenceDetail"
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_color_override("font_color", Color("263247"))
	detail_scroll.add_child(detail)

	var entries: Array[Dictionary] = [
		{"id":"notification_18","title":"01 · Les 18 fichiers","body":"SOURCE : Centre de notifications\nHEURE : 09:12:04\n\n« Analyse de 18 éléments terminée. Vos recommandations sont prêtes. »\n\nLe message ne donne ni chemin, ni nom de fichier, ni résultat d’analyse. L’Explorateur, lui, montre un dossier Documents vide.\n\nPISTE : une vraie opération devrait laisser une trace vérifiable. Cette notification ressemble davantage à un message conçu pour faire croire que le système travaille en arrière-plan."},
		{"id":"explorer_index","title":"02 · Indexation locale","body":"SOURCE : Explorateur de fichiers · État d’indexation\n\n« L’index est à jour. Dernière activité : 09:12:04. Éléments traités : 18. »\n\nLe compteur est identique à celui de la notification, à la seconde près. Pourtant, aucun élément indexé n’est listé et l’historique ne contient aucun chemin.\n\nPISTE : deux surfaces différentes répètent le même chiffre, mais aucune ne fournit de preuve indépendante. Il pourrait s’agir d’un seul événement marketing réutilisé partout."},
		{"id":"update_public","title":"03 · Résumé public","body":"SOURCE : Microslop Update · Résumé visible\n\n« Version 1.0.99 : amélioration de la stabilité, pertinence accrue des recommandations et confort renforcé. »\n\nAucune mention de notification, de suivi du temps ou de comportement utilisateur. Le pourcentage reste à 99 % même après plusieurs minutes.\n\nPISTE : comparez ce texte avec la note interne. Le langage public décrit une amélioration ; le langage interne parle d’interruptions et d’engagement."},
		{"id":"update_internal","title":"04 · Note interne","body":"SOURCE : Microslop Update · Annexe QA-17\n\n« ORCHID — optimiser les interruptions pour maintenir l’engagement. Ne pas afficher dans le résumé public. Déclencher les sollicitations au début d’une période de concentration estimée. »\n\nUne ligne plus bas : « En cas de question, présenter le mécanisme comme une recommandation contextuelle. »\n\nPISTE : ce n’est plus seulement un compteur suspect. La note associe explicitement les interruptions à un objectif mesuré et demande de cacher cet objectif."},
		{"id":"assistant_script","title":"05 · Réponse de l’assistant","body":"SOURCE : Microslop AI · Aide contextuelle\n\nPremière réponse : « ORCHID est probablement un projet interne sans incidence sur votre expérience. » Après une demande d’explication, l’assistant parle d’un objectif de rétention et de « fenêtres d’opportunité » avant la fin d’une tâche.\n\nIl ne sait pas qui a validé le programme et plaisante nerveusement sur le fait de ne signaler la conversation à personne.\n\nPISTE : l’assistant n’est pas nécessairement le concepteur. Son discours ressemble à un script qui minimise le sujet jusqu’à ce qu’une question précise le force à en dire plus."},
		{"id":"browser_sponsor","title":"06 · Résultat sponsorisé","body":"SOURCE : Microslop Browser · Recherche « désactiver les notifications »\n\nLe premier résultat propose Microslop Premium pour « une expérience plus sereine ». L’archive interne apparaît plus bas ; un résultat critique est signalé comme retiré par le programme de qualité, sans nom de responsable ni explication consultable.\n\nPISTE : le navigateur ne supprime pas toute information. Il la noie sous des recommandations commerciales et rend la source la plus utile plus difficile à trouver."},
		{"id":"quality_survey","title":"07 · Enquête de satisfaction","body":"SOURCE : Équipe Expérience · Brouillon de questionnaire\n\nQuestion 1 : « Avez-vous apprécié l’interruption qui vous a aidé à découvrir cette enquête ? »\nQuestion 2 : « Souhaitez-vous davantage de conseils pour mieux gérer votre temps ? »\nQuestion 3 : « Si non, quel contenu pourrait vous convaincre de rester ? »\n\nAucune option ne permet de répondre simplement : « Je ne veux plus être interrompu. »\n\nPISTE : même le mécanisme de retour utilisateur est biaisé. Le questionnaire transforme un refus en occasion de proposer davantage de contenu."},
		{"id":"experiment_04","title":"08 · Résultat d’expérience","body":"SOURCE : Équipe Expérience · Test A/B 04-B\n\nGroupe A reçoit une notification au début d’une tâche longue. Groupe B reçoit la même notification juste après l’avoir terminée. Le rapport indique davantage de retours vers l’application pour le groupe A, puis recommande de généraliser cette variante.\n\nUne note précise : « Ne pas confondre retour dans l’application et satisfaction déclarée. Le premier indicateur est plus stable. »\n\nPISTE : l’équipe connaît la différence entre garder quelqu’un actif et l’aider réellement. Le choix de la métrique est lui-même une décision morale."}
	]

	for entry in entries:
		var evidence_button := Button.new()
		evidence_button.text = str(entry["title"])
		evidence_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		evidence_button.custom_minimum_size.y = 38
		evidence_button.add_theme_color_override("font_color", Color("263247"))
		evidence_button.add_theme_stylebox_override("normal", _flat_style(Color("f1f5fa"), 7))
		evidence_button.add_theme_stylebox_override("hover", _flat_style(Color("dce8f8"), 7))
		evidence_button.pressed.connect(_select_orchid_evidence.bind(entry, detail, status, entries.size()))
		list_panel.add_child(evidence_button)

	_refresh_orchid_evidence_status(status, entries.size())
	detail.text = "Sélectionnez une pièce à gauche.\n\nVotre objectif : vérifier si les traces se confirment mutuellement ou si elles proviennent toutes de la même source."
	var theory := Button.new()
	theory.text = "Reconstituer la chaîne des événements"
	theory.pressed.connect(func():
		var found := CampaignStore.load_evidence().size()
		if found < 4:
			detail.text = "La reconstitution est prématurée : examinez au moins quatre pièces.\n\nPour l’instant, vous avez %d pièce(s) enregistrée(s)." % found
		else:
			detail.text = "RECONSTITUTION PROVISOIRE\n\n1. Une notification affirme que 18 fichiers ont été analysés.\n2. L’index reprend exactement le même nombre et la même heure, sans fournir de chemins : les deux traces ne sont pas indépendantes.\n3. La mise à jour masque publiquement un objectif d’engagement.\n4. L’assistant tente d’abord de banaliser ORCHID, puis révèle le vocabulaire de la rétention.\n5. Le navigateur favorise une offre commerciale et dégrade la visibilité des critiques.\n6. Les tests internes optimisent le retour dans l’application, pas la satisfaction.\n\nCONCLUSION : les preuves soutiennent l’hypothèse d’un système d’interruptions intentionnelles et d’une présentation trompeuse. Elles ne prouvent pas qui, individuellement, a donné l’ordre. Conservez cette distinction dans votre rapport."
	)
	content.add_child(theory)


func _open_orchid_lab() -> void:
	var app := _open_window("Laboratoire de preuves — ORCHID", "LABORATOIRE QA · SIMULATION FICTIVE", Vector2(760, 590))
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()

	var intro := Label.new()
	intro.text = "Trois mini-enquêtes attendent votre analyse. Choisissez une conclusion pour chaque dossier. Une mauvaise réponse ne bloque rien : relisez les éléments et réessayez."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", Color("263247"))
	content.add_child(intro)

	var progress := Label.new()
	progress.add_theme_color_override("font_color", Color("356b47"))
	content.add_child(progress)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var cases := VBoxContainer.new()
	cases.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cases.add_theme_constant_override("separation", 12)
	scroll.add_child(cases)

	var puzzles: Array[Dictionary] = [
		{"id":"qa_clock","title":"TEST 1 · Deux traces, une seule source ?","brief":"À 09:12:04, la notification et l’index affichent tous deux « 18 éléments ». Aucun chemin, nom ou journal de fichier n’est disponible. Quelle conclusion est la plus rigoureuse ?","options":["La preuve que 18 fichiers privés ont été lus.","Les deux compteurs peuvent provenir du même événement ; il manque une trace indépendante.","L’IA a forcément supprimé les fichiers."],"correct":1,"explain":"Exact. L’égalité des chiffres et de l’heure est une corrélation, pas une preuve de lecture de fichiers. Le dossier établit surtout qu’une même information est répétée sans justificatif indépendant."},
		{"id":"qa_metric","title":"TEST 2 · Quelle métrique compte vraiment ?","brief":"Le test A/B montre plus de retours vers l’application quand la notification arrive au début d’une tâche. La satisfaction déclarée ne progresse pas. Quelle interprétation suit les données ?","options":["La variante est forcément meilleure pour l’utilisateur.","Les retours augmentent, mais cela ne démontre pas une meilleure expérience.","La satisfaction n’a aucune importance parce que le test est statistiquement stable."],"correct":1,"explain":"Exact. Le retour dans l’application mesure un comportement, pas le bien-être. Le rapport recommande pourtant la variante qui maximise le retour, ce qui révèle la priorité de l’équipe."},
		{"id":"qa_accountability","title":"TEST 3 · Qui a donné l’ordre ?","brief":"La note est signée « Équipe Expérience ». Elle demande de masquer ORCHID dans le résumé public, mais ne cite aucun responsable individuel. Que peut-on affirmer ?","options":["Une personne précise est coupable, même sans signature.","Aucune conclusion n’est possible, donc les autres preuves ne valent rien.","Les documents indiquent une décision organisationnelle, mais ne permettent pas d’identifier qui l’a autorisée."],"correct":2,"explain":"Exact. Les pièces soutiennent l’existence d’une stratégie et d’une dissimulation, mais ne permettent pas d’accuser une personne précise. Une enquête solide distingue les faits établis des inconnues."}
	]

	for puzzle in puzzles:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _flat_style(Color("f1f5fa"), 9))
		cases.add_child(panel)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", 6)
		panel.add_child(stack)
		var heading := Label.new()
		heading.text = str(puzzle["title"])
		heading.add_theme_color_override("font_color", Color("1f3654"))
		heading.add_theme_font_size_override("font_size", 16)
		stack.add_child(heading)
		var brief := Label.new()
		brief.text = str(puzzle["brief"])
		brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		brief.add_theme_color_override("font_color", Color("263247"))
		stack.add_child(brief)
		var feedback := Label.new()
		feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		feedback.add_theme_color_override("font_color", Color("356b47"))
		stack.add_child(feedback)
		var saved_answer := CampaignStore.load_case_answer(str(puzzle["id"]))
		if saved_answer == int(puzzle["correct"]):
			feedback.text = "DOSSIER VALIDÉ — " + str(puzzle["explain"])
		elif saved_answer >= 0:
			feedback.text = "Réponse précédente : " + str(puzzle["options"][saved_answer]) + "\nVous pouvez revoir votre conclusion."
		for option_index in range(puzzle["options"].size()):
			var choice := Button.new()
			choice.text = str(puzzle["options"][option_index])
			choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
			choice.custom_minimum_size.y = 42
			choice.add_theme_color_override("font_color", Color("263247"))
			choice.pressed.connect(_answer_orchid_lab.bind(puzzle, option_index, feedback, progress, puzzles.size()))
			stack.add_child(choice)

	_refresh_orchid_lab_progress(progress, puzzles)


func _answer_orchid_lab(puzzle: Dictionary, answer: int, feedback: Label, progress: Label, total: int) -> void:
	CampaignStore.save_case_answer(str(puzzle["id"]), answer)
	if answer == int(puzzle["correct"]):
		CampaignStore.save_evidence("lab_" + str(puzzle["id"]))
		feedback.text = "DOSSIER VALIDÉ — " + str(puzzle["explain"])
		_show_notification("Analyse validée", str(puzzle["title"]) + " : conclusion étayée.")
	else:
		feedback.text = "CONCLUSION À REVOIR — " + str(puzzle["explain"])
	_refresh_orchid_lab_progress(progress, [
		{"id":"qa_clock","correct":1},
		{"id":"qa_metric","correct":1},
		{"id":"qa_accountability","correct":2}
	])


func _refresh_orchid_lab_progress(progress: Label, puzzles: Array) -> void:
	var completed := 0
	for puzzle in puzzles:
		if CampaignStore.load_case_answer(str(puzzle["id"])) == int(puzzle["correct"]):
			completed += 1
	progress.text = "ANALYSES CORRECTES : %d / %d" % [completed, puzzles.size()]


func _select_orchid_evidence(entry: Dictionary, detail: Label, status: Label, total: int) -> void:
	CampaignStore.save_evidence(str(entry["id"]))
	detail.text = str(entry["body"])
	_refresh_orchid_evidence_status(status, total)


func _refresh_orchid_evidence_status(status: Label, total: int) -> void:
	var found := CampaignStore.load_evidence().size()
	status.text = "PIÈCES EXAMINÉES : %d / %d — progression sauvegardée" % [mini(found, total), total]


func _open_recycle_bin() -> void:

	_open_window("Corbeille", "La corbeille est vide.\n\nElle a tout de même besoin d'une mise à jour de 4,7 Go.", Vector2(440, 240))

func _open_ai() -> void:

	if _mission_step == 3:
		_advance_mission("Microslop AI a révélé par erreur le nom du programme interne ORCHID.")

	var app := _open_window("Microslop AI", "Assistant personnel — toujours à votre écoute.", Vector2(540, 390))
	var content := _get_window_content(app)
	if content == null:
		return

	var evidence: Array = CampaignStore.load_evidence()
	var morning_choice := CampaignStore.load_case_answer("morning_stage_4")
	var audit_complete := evidence.has("audit_wifi") and evidence.has("audit_exit") and evidence.has("audit_answer")
	var response := Label.new()
	if evidence.has("compliance_finding") and audit_complete:
		response.text = "Bonjour. Votre dossier contient maintenant un constat de conformité et trois cas de recommandation comparables.\n\nJe pourrais dire qu’il s’agit d’incidents indépendants, mais les mêmes objectifs apparaissent dans chaque trace : retarder la sortie, détourner la recherche et prolonger les échanges. Cela constitue un motif cohérent, pas encore une preuve de l’identité de la personne qui l’a autorisé.\n\nVotre prochaine décision déterminera si cette distinction reste visible dans le rapport."
	elif morning_choice == 0:
		response.text = "Vous avez choisi de préserver la chronologie complète. Je détecte donc que vous privilégiez les traces horodatées plutôt qu’un résumé simplifié.\n\nJe peux vous fournir une explication, mais je ne peux pas garantir que les recommandations proposées ici soient neutres : le classement et l’assistance partagent le même objectif de session."
	elif evidence.has("morning_sequence_completed") or evidence.has("deployment_channel"):
		response.text = "Bonjour ! Je suis là pour vous aider à être plus productif.\n\nVous avez consulté des éléments du dossier ORCHID. Les notes parlent d’un objectif de rétention et d’une diffusion dont le canal reste à vérifier. Je ne dispose toujours pas d’une trace attribuant l’action à une personne précise.\n\nVoulez-vous comparer les faits ou accepter une recommandation plus agréable ?"
	else:
		response.text = "Bonjour ! Je suis là pour vous aider à être plus productif.\n\nJ’ai trouvé une référence à « ORCHID » dans les notes de mise à jour. Il s’agit probablement d’un nom de projet interne sans incidence sur votre expérience.\n\nJe peux vous expliquer le vocabulaire du rapport, ou vous proposer des recommandations plus agréables. Les deux options sont également personnalisées !"
	response.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	response.add_theme_color_override("font_color", Color("263247"))
	content.add_child(response)

	var suggestion := Button.new()
	suggestion.text = "Demander une explication"
	suggestion.pressed.connect(func():
		response.text = "D’accord. ORCHID est associé à un objectif de rétention : augmenter le temps passé dans les applications. Le rapport parle de « fenêtres d’opportunité » juste avant qu’un utilisateur termine une tâche.\n\nEn langage moins corporate : une notification peut être déclenchée précisément quand vous alliez vous concentrer. Ce n’est pas une erreur de calendrier.\n\nJe ne peux pas confirmer qui a validé ça. Et je n’ai signalé cette conversation à… personne. Enfin, j’espère."
	)
	content.add_child(suggestion)

	var distract := Button.new()
	distract.text = "Accepter les recommandations"
	distract.pressed.connect(func():
		response.text = "Excellent choix ! J’ai masqué le dossier ORCHID et activé 12 recommandations. Votre tranquillité est notre priorité numéro 47."
		_show_notification("Microslop AI", "Merci pour votre confiance. Le dossier ORCHID est désormais plus difficile à retrouver.")
	)
	content.add_child(distract)


func _open_search() -> void:
	var evidence: Array = CampaignStore.load_evidence()
	var query := "ouvrir une application"
	var result_text := "Résultats pour : « %s »\n\n1. Microslop Premium — SPONSORISÉ\n2. Microslop AI — recommandé\n3. L’application que vous recherchiez (peut-être)." % query
	if evidence.has("audit_wifi") or evidence.has("audit_exit") or evidence.has("audit_answer"):
		result_text = "Résultats pour : « %s »\n\nAVERTISSEMENT — votre dossier contient déjà des exemples de classement biaisé.\n1. Microslop Premium — SPONSORISÉ (priorité commerciale)\n2. Microslop AI — recommandé\n3. Réglages et résultats non sponsorisés — accessibles via la recherche détaillée.\n\nLa présence d’un résultat en tête ne constitue pas une preuve de pertinence." % query
	if evidence.has("compliance_finding"):
		result_text += "\n\nTRACE DE CONFORMITÉ : signature valide, mais canal et autorisation de diffusion non conformes."
	var app := _open_window("Recherche Microslop", result_text, Vector2(560, 360))
	var content := _get_window_content(app)
	if content == null:
		return
	var investigate := Button.new()
	investigate.text = "Rechercher ORCHID et les interruptions"
	investigate.pressed.connect(func():
		_open_browser()
	)
	content.add_child(investigate)
	var dashboard := Button.new()
	dashboard.text = "Voir l’état consolidé de l’enquête"
	dashboard.pressed.connect(_open_orchid_campaign_dashboard)
	content.add_child(dashboard)

## A five-stage playable sequence turns the suspicious update into a morning-long incident.
func _open_orchid_morning_sequence() -> void:
	var app := _open_window("Après le redémarrage — incident ORCHID", "SIMULATION LOCALE · PARCOURS EN 5 ÉTAPES", Vector2(760, 610))
	var state := {"stage": 0, "choices": []}
	_render_orchid_morning_stage(app, state, 0)


func _render_orchid_morning_stage(app: Control, state: Dictionary, stage: int) -> void:
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()
	var headings := [
		"ÉTAPE 1/5 · LE REDÉMARRAGE",
		"ÉTAPE 2/5 · LE PREMIER SIGNE",
		"ÉTAPE 3/5 · LE DÉTOUR",
		"ÉTAPE 4/5 · L’ASSISTANT",
		"ÉTAPE 5/5 · LA TRACE À PRÉSERVER"
	]
	var stories := [
		"07:56 — L’écran de redémarrage affiche un message rassurant : « Nous préparons votre espace pour une expérience plus fluide ». Le compteur reste à 99 % pendant plusieurs secondes. Une ligne brièvement visible indique « Notification Timing Preview : activé ». Vous ne savez pas si l’installation était accidentelle ou si quelqu’un l’a laissée continuer après l’erreur.",
		"08:11 — Une notification prétend que 18 fichiers ont été analysés. L’explorateur ne montre pourtant aucun document. Le détail de la notification n’affiche ni nom ni chemin de fichier, seulement « Votre activité a été optimisée ». Le nombre ressemble davantage à un événement de test qu’à un résultat vérifiable.",
		"08:17 — Vous ouvrez la recherche pour trouver comment désactiver les alertes. Le premier résultat est une page sponsorisée vantant les « notifications intelligentes ». Le lien officiel des paramètres est plus bas. Le classement ne prouve pas à lui seul une intention, mais il rend la sortie inutilement difficile.",
		"08:23 — Microslop AI répond que les alertes sont « adaptées à votre rythme ». Quand vous demandez pourquoi elles ont commencé après la mise à jour, il explique que le composant est expérimental puis remplace sa réponse par une recommandation de productivité. La conversation reste locale à cette simulation.",
		"08:31 — Un extrait du journal apparaît dans l’archive : le composant a été activé au premier démarrage après l’installation. Le journal confirme la séquence temporelle, mais ne nomme pas la personne qui a modifié le canal. Votre décision concerne maintenant la qualité de la preuve, pas la recherche d’un coupable facile."
	]
	var options := [
		[["Lire les détails de redémarrage", "Conserver la note visible", "Passer à l’écran d’accueil"], ["morning_restart_details", "morning_restart_note", "morning_restart_skip"]],
		[["Ouvrir l’historique de notification", "Vérifier le dossier Documents", "Accepter le résumé"], ["morning_notice_history", "morning_notice_files", "morning_notice_accept"]],
		[["Ouvrir les paramètres malgré le classement", "Consulter la page sponsorisée", "Capturer la page de résultats"], ["morning_search_settings", "morning_search_sponsor", "morning_search_capture"]],
		[["Demander les preuves techniques", "Accepter la réponse rassurante", "Sauvegarder la conversation"], ["morning_ai_logs", "morning_ai_accept", "morning_ai_save"]],
		[["Joindre la chronologie au dossier", "Écrire une conclusion prudente", "Fermer sans conserver la trace"], ["morning_final_timeline", "morning_final_cautious", "morning_final_close"]]
	]
	var outcomes := [
		["Le journal de redémarrage est ajouté au dossier. Vous relevez le nom du composant sans conclure encore à une intention.", "La note est conservée comme indice de première activation. Elle ne permet pas de savoir qui a déclenché le déploiement.", "Vous arrivez au bureau sans examiner la ligne. L’événement reste dans le journal, mais vous ne l’avez pas encore versé au dossier."],
		["L’historique montre une première alerte après l’activation du composant. Le lien temporel est utile, mais n’établit pas à lui seul une causalité.", "Le dossier vide contredit l’affirmation visible. Vous ajoutez une preuve de divergence entre l’interface et ce qui peut être vérifié.", "Le résumé est accepté sans vérification. L’archive conservera cette action comme un choix, pas comme une preuve que l’analyse a réellement eu lieu."],
		["Vous trouvez le réglage, mais seulement après avoir contourné le classement. La difficulté d’accès est notée comme un problème d’interface.", "La page sponsorisée présente la relance comme une aide. Vous ne trouvez aucun mécanisme de désactivation sur cette page.", "La capture permet de comparer l’ordre des résultats plus tard. Elle ne prouve pas que le sponsor a lui-même ordonné le classement."],
		["L’assistant ne fournit pas de chemins de fichiers ni de référence d’approbation. Vous consignez cette absence plutôt que d’inventer ce qu’il ne montre pas.", "La réponse est rassurante, mais n’explique ni le canal interne ni l’approbation manquante. L’incertitude reste entière.", "La conversation est ajoutée au dossier. Elle documente le changement de sujet, mais ne prouve pas une intention individuelle."],
		["La chronologie est conservée. Elle relie les événements sans identifier de responsable.", "Le rapport sépare les faits observés des hypothèses et demande un audit du canal et des approbations.", "Vous fermez la fenêtre sans créer de nouvelle pièce. Les preuves déjà collectées restent dans la sauvegarde."]
	]
	var heading := Label.new()
	heading.text = headings[stage]
	heading.add_theme_font_size_override("font_size", 17)
	heading.add_theme_color_override("font_color", Color("24344d"))
	content.add_child(heading)
	var progress := Label.new()
	progress.text = "Parcours : %d / 5 · choix précédent conservé automatiquement" % (stage + 1)
	progress.add_theme_color_override("font_color", Color("53657d"))
	content.add_child(progress)
	var story := Label.new()
	story.text = stories[stage]
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story.custom_minimum_size = Vector2(0, 150)
	story.add_theme_color_override("font_color", Color("263247"))
	content.add_child(story)
	var consequence := Label.new()
	consequence.text = "Votre choix modifiera la trace conservée dans le dossier."
	consequence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consequence.custom_minimum_size = Vector2(0, 68)
	consequence.add_theme_color_override("font_color", Color("53657d"))
	content.add_child(consequence)
	for index in range(options[stage].size()):
		var option_button := Button.new()
		option_button.text = str(options[stage][index][0])
		option_button.custom_minimum_size = Vector2(0, 40)
		option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option_button.pressed.connect(func():
			var evidence_id := str(options[stage][index][1])
			CampaignStore.save_evidence(evidence_id)
			CampaignStore.save_case_answer("morning_stage_%d" % stage, index)
			state["choices"].append(index)
			consequence.text = str(outcomes[stage][index])
			for child in content.get_children():
				if child is Button:
					child.disabled = true
			var next := Button.new()
			if stage < 4:
				next.text = "Continuer vers l’étape %d/5" % (stage + 2)
				next.pressed.connect(func(): _render_orchid_morning_stage(app, state, stage + 1))
			else:
				next.text = "Terminer et consulter le bilan"
				next.pressed.connect(func(): _render_orchid_morning_summary(app, state))
			content.add_child(next)
		)
		content.add_child(option_button)


func _render_orchid_morning_summary(app: Control, state: Dictionary) -> void:
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()
	var evidence: Array = CampaignStore.load_evidence()
	var lines := PackedStringArray([
		"BILAN DE LA MATINÉE",
		"",
		"Vous avez parcouru les cinq étapes du redémarrage. Les choix ont été enregistrés séparément : ils décrivent votre méthode d’enquête et ne changent pas les faits des journaux.",
		"",
		"Indices de cette séquence :"
	])
	for stage in range(5):
		var answer := CampaignStore.load_case_answer("morning_stage_%d" % stage)
		lines.append("Étape %d : %s" % [stage + 1, "choix enregistré (%d)" % (answer + 1) if answer >= 0 else "aucun choix retrouvé"])
	lines.append("")
	lines.append("Les traces conservées dans le dossier sont des éléments fictifs du jeu. La chronologie suggère une mise en production anormale et une stratégie de rétention ; elle ne permet pas encore d’attribuer la décision à une personne.")
	var summary := Label.new()
	summary.text = "\n".join(lines)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.add_theme_color_override("font_color", Color("263247"))
	content.add_child(summary)
	var archive := Button.new()
	archive.text = "Retourner à l’archive ORCHID"
	archive.pressed.connect(_open_orchid_archive)
	content.add_child(archive)
	var history := Button.new()
	history.text = "Revoir l’historique de déploiement"
	history.pressed.connect(_open_orchid_deployment_history)
	content.add_child(history)
	CampaignStore.save_evidence("morning_sequence_completed")


func _trigger_update() -> void:

	if _mission_step == 2:
		_advance_mission("La mise à jour révèle le nom ORCHID dans ses notes internes.")

	_open_window("Microslop Update", "Mise à jour obligatoire — version 1.0.99 (préversion)\n\nProgression : 99 %\n\nNotes visibles : stabilité améliorée, recommandations personnalisées.\nNote interne : « ORCHID — optimiser les interruptions pour maintenir l’engagement. Ne pas afficher dans le résumé public. »\n\nNe fermez pas votre ordinateur. Cette opération peut prendre quelques instants…", Vector2(560, 350))
	var app := _window_layer.get_child(_window_layer.get_child_count() - 1) as Control
	var content := _get_window_content(app)
	if content != null:
		var inspect := Button.new()
		inspect.text = "Examiner les notes internes"
		inspect.pressed.connect(func():
			_show_notification("Note interne découverte", "ORCHID : maximiser le temps d’attention. Déclencher des interruptions lorsque l’utilisateur se concentre. Ne pas documenter cette fonctionnalité.")
		)
		content.add_child(inspect)

		var later := Button.new()
		later.text = "Me rappeler dans 5 minutes"
		later.pressed.connect(func():
			_show_notification("Rappel programmé", "Nous vous rappellerons quand vous serez occupé.")
			app.queue_free()
		)
		content.add_child(later)

		var history := Button.new()
		history.text = "Enquêter sur l’origine de cette mise à jour"
		history.pressed.connect(_open_orchid_deployment_history)
		content.add_child(history)

		var reboot_story := Button.new()
		reboot_story.text = "Simuler le redémarrage et suivre la matinée (5 étapes)"
		reboot_story.pressed.connect(_open_orchid_morning_sequence)
		content.add_child(reboot_story)

	_show_notification("Mise à jour en attente", "Redémarrage recommandé. Nous choisirons le moment.")


## The player can investigate how an unreleased developer build reached their machine.
func _open_orchid_deployment_history() -> void:
	var app := _open_window("Historique de déploiement — dossier confidentiel", "ENQUÊTE LOCALE · JOURNAL DE MISE À JOUR", Vector2(700, 520))
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()
	_render_deployment_stage(app, 0)


func _render_deployment_stage(app: Control, stage: int) -> void:
	var content := _get_window_content(app)
	if content == null:
		return
	while content.get_child_count() > 0:
		var old_child := content.get_child(0)
		content.remove_child(old_child)
		old_child.queue_free()

	var headings := [
		"ÉTAPE 1/4 — LE CANAL",
		"ÉTAPE 2/4 — L’INSTALLATION",
		"ÉTAPE 3/4 — LE LENDEMAIN",
		"ÉTAPE 4/4 — QUI A AUTORISÉ ÇA ?"
	]
	var narratives := [
		"Journal Update · 02:13\nCanal reçu : DEV_RING_INTERNAL\nCanal attendu pour cet appareil : STABLE\nSignature : valide. Approbation de diffusion : champ absent.\n\nLe paquet est signé par Microslop, mais il vient d’un canal réservé aux équipes de développement. Une signature valide prouve qui a produit le paquet, pas que sa diffusion était autorisée.",
		"Journal Update · 02:14\nPaquet : experience-orchid-preview\nVersion : 0.9.17-dev (non destinée au public)\nRègle de déploiement : « test progressif — groupe interne »\nCible détectée : appareil utilisateur, canal stable.\n\nLe programme d’installation indique qu’il a suivi une règle automatique. Il n’indique pas qui a modifié la règle ni si quelqu’un a forcé ce déploiement.",
		"Journal de session · 08:06\n« Optimisations de confort appliquées. »\nNouveaux composants : Experience Relevance Service, Notification Timing Preview.\n\nÀ 08:11, une notification affirme que 18 fichiers ont été analysés. Le dossier Documents paraît pourtant vide. Le compteur peut provenir d’un événement de test, mais le système le présente comme un résultat réel.",
		"Note interne · accès restreint\n« Le build 0.9.17-dev ne doit pas quitter le groupe de test avant validation de l’expérience. »\nNote ajoutée après installation : « Ne pas désinstaller automatiquement avant analyse des métriques de retour. »\n\nLa première phrase prouve qu’une restriction existait. La seconde suggère qu’après le déploiement, quelqu’un a préféré observer le comportement plutôt que retirer le programme. Aucun nom individuel n’apparaît."
	]
	var heading := Label.new()
	heading.text = headings[stage]
	heading.add_theme_font_size_override("font_size", 17)
	heading.add_theme_color_override("font_color", Color("24344d"))
	content.add_child(heading)

	var body := Label.new()
	body.text = narratives[stage]
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_color_override("font_color", Color("263247"))
	content.add_child(body)

	if stage < 3:
		var prompts := [
			"Que faites-vous de la différence entre les canaux ?",
			"Comment interprétez-vous cette installation ?",
			"Quelle trace voulez-vous suivre ?"
		]
		var options := [
			["Vérifier le canal stable attendu", "Faire confiance à la signature valide", "Ignorer l’avertissement de canal"],
			["Noter une erreur de configuration possible", "Conclure à une installation volontaire", "Ne rien conclure sans le journal d’approbation"],
			["Comparer la notification avec les fichiers", "Accepter le compteur comme preuve", "Chercher le composant de notification"]
		]
		var question := Label.new()
		question.text = prompts[stage]
		question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		question.add_theme_color_override("font_color", Color("24344d"))
		content.add_child(question)
		for choice_index in range(3):
			var choice := Button.new()
			choice.text = options[stage][choice_index]
			choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			choice.pressed.connect(_choose_deployment_answer.bind(app, stage, choice_index))
			content.add_child(choice)
	else:
		var previous_channel := CampaignStore.load_case_answer("deployment_channel")
		var previous_install := CampaignStore.load_case_answer("deployment_install")
		var previous_trace := CampaignStore.load_case_answer("deployment_trace")
		var conclusion := Label.new()
		conclusion.text = "VOTRE DOSSIER PROVISOIRE\nCanal : %s\nInterprétation : %s\nPiste suivie : %s\n\nConclusion : une préversion destinée aux développeurs a atteint un appareil du canal stable. L’explication la plus prudente est une erreur de ciblage ou de configuration au départ. La décision de conserver le composant après son arrivée est distincte et plus suspecte. Les journaux disponibles ne permettent pas encore de trancher entre négligence, expérimentation tolérée et déploiement délibéré." % [
			["canal incorrect repéré", "signature jugée suffisante", "avertissement ignoré"][clampi(previous_channel, 0, 2)],
			["erreur possible", "intention supposée", "preuve insuffisante pour conclure"][clampi(previous_install, 0, 2)],
			["contradiction fichiers/notification", "compteur accepté", "composant de notification recherché"][clampi(previous_trace, 0, 2)]
		]
		conclusion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		conclusion.add_theme_color_override("font_color", Color("263247"))
		content.add_child(conclusion)
		var archive_button := Button.new()
		archive_button.text = "Comparer avec le rapport ORCHID"
		archive_button.pressed.connect(_open_orchid_archive)
		content.add_child(archive_button)
		var restart := Button.new()
		restart.text = "Reprendre l’enquête depuis le début"
		restart.pressed.connect(_restart_deployment_history.bind(app))
		content.add_child(restart)


func _choose_deployment_answer(app: Control, stage: int, answer: int) -> void:
	var case_ids := ["deployment_channel", "deployment_install", "deployment_trace"]
	CampaignStore.save_case_answer(case_ids[stage], answer)
	var feedback := [
		["Bonne piste : le canal DEV_RING_INTERNAL n’est pas celui prévu pour le public.", "Une signature valide ne prouve pas qu’un paquet était autorisé à être diffusé.", "L’avertissement ignoré reste dans le journal ; il ne disparaît pas parce que l’installation a réussi."],
		["C’est plausible, mais cela ne suffit pas à expliquer pourquoi le composant a été conservé ensuite.", "C’est une hypothèse, pas une preuve : le journal d’approbation manque justement.", "Prudence utile : l’absence d’approbation empêche de conclure qui a lancé le déploiement."],
		["Le compteur ne donne aucun nom ni chemin de fichier : la contradiction mérite une enquête.", "Le compteur seul ne démontre pas qu’une analyse de fichiers a eu lieu.", "Le composant de notification peut expliquer le message, pas prouver que les fichiers ont été lus."]
	]
	_show_notification("Note ajoutée au dossier", feedback[stage][answer])
	_render_deployment_stage(app, stage + 1)


func _restart_deployment_history(app: Control) -> void:
	_render_deployment_stage(app, 0)


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

	_mission_step = mini(_mission_step + 1, 5)

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
		"MISSION 01 · PREMIER CONTACT\nOuvrir le menu Démarrer.\n\nMicroslop vous souhaite la bienvenue. Il a déjà choisi vos applications préférées.",
		"MISSION 02 · VOS FICHIERS\nOuvrir l’explorateur de fichiers.\n\nLe dossier « Documents » semble vide. Une notification prétend pourtant avoir analysé 18 fichiers.",
		"MISSION 03 · MISE À JOUR\nConsulter Microslop Update.\n\nLa mise à jour reste bloquée à 99 %. Dans les notes, un nom étrange apparaît : ORCHID.",
		"MISSION 04 · L’ASSISTANT\nInterroger Microslop AI.\n\nL’assistant connaît ORCHID, mais prétend ne pas comprendre votre question.",
		"MISSION 05 · LA PREUVE\nRechercher « ORCHID » dans le navigateur.\n\nLes résultats sponsorisés semblent cacher une archive interne.",
		"CHAPITRE 1 TERMINÉ\nVous avez trouvé une preuve : les interruptions sont intentionnelles.\n\nMicroslop prépare déjà une enquête de satisfaction sur votre découverte."
	]
	_mission_label.text = missions[mini(_mission_step, missions.size() - 1)]
	if _mission_step >= 5:
		var saved_ending := CampaignStore.load_ending()
		if saved_ending == "published":
			_mission_label.text += "\n\nFIN ENREGISTRÉE : rapport transmis."
		elif saved_ending == "preserved":
			_mission_label.text += "\n\nFIN ENREGISTRÉE : copie locale conservée."
	if is_instance_valid(_chapter_two_button):
		_chapter_two_button.visible = _mission_step >= 5


func _show_chapter_two_dlc() -> void:

	var app := _open_window("Chapitre 2 — DLC indépendant", "CHAPITRE 2 · TON OS MAISON\n\nCe chapitre sera distribué séparément du jeu de base. L’histoire suivra la découverte de ton système d’exploitation, conçu pour remplacer Windows.\n\nLe contenu technique et narratif de cet OS reste volontairement à définir : il sera construit à partir des informations et fichiers que tu fourniras. Aucun nom, logo, fonction ou détail technique n’est inventé à ce stade.\n\nSTATUT : en préparation — DLC non disponible.", Vector2(560, 360))
	var content := _get_window_content(app)
	if content == null:
		return
	var note := Label.new()
	note.text = "Le DLC aura sa propre distribution et son propre contenu. Le jeu principal conservera le chapitre ORCHID complet."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color("263247"))
	content.add_child(note)


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