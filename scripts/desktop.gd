extends Control
## First playable shell for Microslop Experience.
## All windows and system behaviour are simulated inside the game.

const AppWindow = preload("res://scripts/app_window.gd")
const TASKBAR_HEIGHT := 54

var _window_layer: Control
var _taskbar: PanelContainer
var _start_menu: PanelContainer
var _notification_layer: VBoxContainer
var _clock_label: Label
var _tray_button: Button
var _quick_settings_panel: PanelContainer
var _start_open := false
var _mission_label: Label
var _mission_step := 0
var _event_elapsed := 0.0
var _event_index := 0
var _clock_refresh_elapsed := 0.0
var _start_menu_tween: Tween
var _quick_settings_tween: Tween
var _wallpaper: TextureRect

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_start_menu):
		_layout_shell_for_viewport()

func _layout_shell_for_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	if is_instance_valid(_taskbar):
		var taskbar_width := minf(780.0, maxf(440.0, viewport_size.x - 24.0))
		_taskbar.offset_left = -taskbar_width / 2.0
		_taskbar.offset_right = taskbar_width / 2.0
		_taskbar.offset_top = -70.0
		_taskbar.offset_bottom = -10.0
	if is_instance_valid(_start_menu):
		var menu_width := minf(620.0, maxf(300.0, viewport_size.x - 24.0))
		var menu_height := minf(520.0, maxf(360.0, viewport_size.y - 96.0))
		_start_menu.offset_left = -menu_width / 2.0
		_start_menu.offset_right = menu_width / 2.0
		_start_menu.offset_top = -(menu_height + TASKBAR_HEIGHT + 12.0)
		_start_menu.offset_bottom = -(TASKBAR_HEIGHT + 12.0)
	if is_instance_valid(_quick_settings_panel):
		var panel_width := minf(336.0, maxf(280.0, viewport_size.x - 24.0))
		var panel_height := minf(350.0, maxf(260.0, viewport_size.y - 96.0))
		_quick_settings_panel.offset_left = -panel_width - 12.0
		_quick_settings_panel.offset_right = -12.0
		_quick_settings_panel.offset_top = -(panel_height + 76.0)
		_quick_settings_panel.offset_bottom = -76.0

func _ready() -> void:
	_load_progress()
	_build_desktop()
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

	var desktop_icons := VBoxContainer.new()
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
	_build_start_menu()
	_build_quick_settings()
	_build_mission_hint()
	_layout_shell_for_viewport()

func _add_desktop_icon(parent: VBoxContainer, glyph: String, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(112, 76)
	button.text = "%s\n%s" % [glyph, caption]
	button.tooltip_text = caption
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _flat_style(Color(0.1, 0.2, 0.38, 0.08), 7))
	button.add_theme_stylebox_override("hover", _flat_style(Color(0.55, 0.7, 0.95, 0.28), 7))
	button.add_theme_stylebox_override("pressed", _flat_style(Color(0.55, 0.7, 0.95, 0.42), 7))
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
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
	taskbar.offset_left = -390
	taskbar.offset_right = 390
	taskbar.offset_top = -70
	taskbar.offset_bottom = -10
	var panel_style := _flat_style(Color(0.91, 0.94, 0.99, 0.90), 16)
	panel_style.shadow_color = Color(0.02, 0.04, 0.10, 0.28)
	panel_style.shadow_size = 18
	panel_style.shadow_offset = Vector2(0, 4)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(1, 1, 1, 0.62)
	taskbar.add_theme_stylebox_override("panel", panel_style)
	add_child(taskbar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	taskbar.add_child(row)
	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left_spacer)

	var start_button := Button.new()
	start_button.text = "⊞"
	start_button.tooltip_text = "Démarrer"
	start_button.custom_minimum_size = Vector2(44, 42)
	start_button.add_theme_font_size_override("font_size", 28)
	start_button.add_theme_color_override("font_color", Color("0878d1"))
	start_button.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 9))
	start_button.add_theme_stylebox_override("hover", _flat_style(Color(0.4, 0.58, 0.82, 0.18), 9))
	start_button.pressed.connect(_toggle_start_menu)
	start_button.focus_mode = Control.FOCUS_NONE
	row.add_child(start_button)

	var search_button := Button.new()
	search_button.text = "⌕  Rechercher"
	search_button.tooltip_text = "Rechercher"
	search_button.custom_minimum_size = Vector2(132, 42)
	search_button.add_theme_color_override("font_color", Color("24344d"))
	search_button.add_theme_stylebox_override("normal", _flat_style(Color(1, 1, 1, 0.66), 9))
	search_button.add_theme_stylebox_override("hover", _flat_style(Color(1, 1, 1, 0.96), 9))
	search_button.pressed.connect(_open_search)
	search_button.focus_mode = Control.FOCUS_NONE
	row.add_child(search_button)

	_add_taskbar_app(row, "◎", "Microslop Browser", _open_browser)
	_add_taskbar_app(row, "▤", "Explorateur de fichiers", _open_files)
	_add_taskbar_app(row, "⚙", "Paramètres", _open_settings)
	_add_taskbar_app(row, "↻", "Mise à jour", _trigger_update)

	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right_spacer)

	_tray_button = Button.new()
	_tray_button.text = "⌃  ◖  ◉  🔊  🔋\n%s  ·  %s" % [Time.get_time_string_from_system().substr(0, 5), Time.get_date_string_from_system().replace("-", "/")]
	_tray_button.tooltip_text = "Zone de notification"
	_tray_button.custom_minimum_size = Vector2(150, 48)
	_tray_button.add_theme_font_size_override("font_size", 11)
	_tray_button.add_theme_color_override("font_color", Color("24344d"))
	_tray_button.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 9))
	_tray_button.add_theme_stylebox_override("hover", _flat_style(Color(0.4, 0.58, 0.82, 0.18), 9))
	_tray_button.pressed.connect(_toggle_quick_settings)
	_tray_button.focus_mode = Control.FOCUS_NONE
	row.add_child(_tray_button)

func _build_quick_settings() -> void:
	_quick_settings_panel = PanelContainer.new()
	_quick_settings_panel.name = "QuickSettingsPanel"
	_quick_settings_panel.anchor_left = 1.0
	_quick_settings_panel.anchor_top = 1.0
	_quick_settings_panel.anchor_right = 1.0
	_quick_settings_panel.anchor_bottom = 1.0
	_quick_settings_panel.offset_left = -336
	_quick_settings_panel.offset_right = -12
	_quick_settings_panel.offset_top = -350
	_quick_settings_panel.offset_bottom = -76
	_quick_settings_panel.visible = false
	var panel_style := _flat_style(Color(0.92, 0.95, 0.99, 0.97), 18)
	panel_style.shadow_color = Color(0.02, 0.04, 0.10, 0.30)
	panel_style.shadow_size = 20
	panel_style.shadow_offset = Vector2(0, 5)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(1, 1, 1, 0.70)
	_quick_settings_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_quick_settings_panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	_quick_settings_panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var tiles := GridContainer.new()
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
	volume.value_changed.connect(func(value: float):
		SettingsStore.values["master_volume"] = value / 100.0
		SettingsStore.apply_audio_settings()
		SettingsStore.save_settings()
	)
	volume_row.add_child(volume)

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
	brightness.value_changed.connect(func(value: float):
		if is_instance_valid(_wallpaper):
			var level := value / 100.0
			_wallpaper.modulate = Color(level, level, level, 1.0)
	)
	brightness_row.add_child(brightness)

	var footer := HBoxContainer.new()
	layout.add_child(footer)
	var status := Label.new()
	status.text = "MicroslopNet · Batterie 100 %"
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_theme_font_size_override("font_size", 11)
	status.add_theme_color_override("font_color", Color("596780"))
	footer.add_child(status)
	var settings_button := Button.new()
	settings_button.text = "⚙"
	settings_button.tooltip_text = "Ouvrir les paramètres"
	settings_button.pressed.connect(func():
		_quick_settings_panel.visible = false
		_open_settings()
	)
	footer.add_child(settings_button)

func _add_quick_toggle(parent: GridContainer, caption: String, initially_on: bool, feature_name: String) -> void:
	var toggle := Button.new()
	toggle.text = caption
	toggle.toggle_mode = true
	toggle.button_pressed = initially_on
	toggle.custom_minimum_size = Vector2(138, 52)
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.add_theme_color_override("font_color", Color("1d2a40"))
	toggle.add_theme_stylebox_override("normal", _flat_style(Color("dce9fa") if initially_on else Color("e9edf4"), 10))
	toggle.add_theme_stylebox_override("hover", _flat_style(Color("d1e2fa") if initially_on else Color("dce3ee"), 10))
	toggle.add_theme_stylebox_override("pressed", _flat_style(Color("80b8f5"), 10))
	toggle.toggled.connect(func(enabled: bool):
		toggle.add_theme_stylebox_override("normal", _flat_style(Color("dce9fa") if enabled else Color("e9edf4"), 10))
		toggle.add_theme_stylebox_override("hover", _flat_style(Color("d1e2fa") if enabled else Color("dce3ee"), 10))
		_show_notification(feature_name, "%s : %s." % [feature_name, "activé" if enabled else "désactivé"])
	)
	parent.add_child(toggle)

func _toggle_quick_settings() -> void:
	var should_open := not _quick_settings_panel.visible
	if should_open:
		_start_menu.visible = false
		_start_open = false
	_animate_flyout(_quick_settings_panel, should_open, true)

func _add_taskbar_app(parent: HBoxContainer, glyph: String, tooltip: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = glyph
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(44, 42)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color("24344d"))
	button.add_theme_stylebox_override("normal", _flat_style(Color(0.0, 0.0, 0.0, 0.0), 7))
	button.add_theme_stylebox_override("hover", _flat_style(Color(0.4, 0.58, 0.82, 0.22), 7))
	button.add_theme_stylebox_override("pressed", _flat_style(Color(0.4, 0.58, 0.82, 0.36), 7))
	button.pressed.connect(callback)
	parent.add_child(button)

func _build_start_menu() -> void:
	_start_menu = PanelContainer.new()
	_start_menu.anchor_left = 0.5
	_start_menu.anchor_right = 0.5
	_start_menu.anchor_top = 1.0
	_start_menu.anchor_bottom = 1.0
	_start_menu.offset_left = -310
	_start_menu.offset_right = 310
	_start_menu.offset_top = -(TASKBAR_HEIGHT + 520)
	_start_menu.offset_bottom = -(TASKBAR_HEIGHT + 12)
	_start_menu.visible = false
	var start_style := _flat_style(Color(0.94, 0.96, 0.99, 0.97), 18)
	start_style.shadow_color = Color(0.02, 0.04, 0.10, 0.30)
	start_style.shadow_size = 22
	start_style.shadow_offset = Vector2(0, 5)
	start_style.set_border_width_all(1)
	start_style.border_color = Color(1, 1, 1, 0.68)
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
	search.placeholder_text = "Rechercher des applications, paramètres et documents"
	search.custom_minimum_size.y = 40
	search.add_theme_color_override("font_color", Color("1d2a40"))
	search.add_theme_stylebox_override("normal", _flat_style(Color.WHITE, 10))
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
	heading.text = "Épinglé"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color("1d2a40"))
	pinned_header.add_child(heading)
	var all_apps := Button.new()
	all_apps.text = "Tous  ›"
	all_apps.custom_minimum_size = Vector2(78, 30)
	all_apps.add_theme_font_size_override("font_size", 12)
	all_apps.add_theme_color_override("font_color", Color("263247"))
	all_apps.add_theme_stylebox_override("normal", _flat_style(Color("e5eaf3"), 7))
	all_apps.add_theme_stylebox_override("hover", _flat_style(Color("d6e4f8"), 7))
	all_apps.pressed.connect(func():
		_show_notification("Toutes les applications", "6 applications sont disponibles dans ce prototype.")
	)
	pinned_header.add_child(all_apps)

	var pinned := GridContainer.new()
	pinned.columns = 3
	pinned.add_theme_constant_override("h_separation", 6)
	pinned.add_theme_constant_override("v_separation", 6)
	layout.add_child(pinned)
	_add_pinned_app(pinned, "◎", "Browser", _open_browser)
	_add_pinned_app(pinned, "▤", "Fichiers", _open_files)
	_add_pinned_app(pinned, "⚙", "Paramètres", _open_settings)
	_add_pinned_app(pinned, "✧", "Microslop AI", _open_ai)
	_add_pinned_app(pinned, "↻", "Mise à jour", _trigger_update)
	_add_pinned_app(pinned, "▧", "Corbeille", _open_recycle_bin)

	var recommended := Label.new()
	recommended.text = "Recommandé"
	recommended.add_theme_font_size_override("font_size", 17)
	recommended.add_theme_color_override("font_color", Color("1d2a40"))
	layout.add_child(recommended)

	var recommended_card := PanelContainer.new()
	var recommended_style := _flat_style(Color("e7edf7"), 10)
	recommended_style.set_border_width_all(1)
	recommended_style.border_color = Color("dce4f0")
	recommended_card.add_theme_stylebox_override("panel", recommended_style)
	layout.add_child(recommended_card)
	var recommended_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		recommended_margin.add_theme_constant_override(side, 9)
	recommended_card.add_child(recommended_margin)
	var recommended_layout := VBoxContainer.new()
	recommended_layout.add_theme_constant_override("separation", 3)
	recommended_margin.add_child(recommended_layout)
	var sponsored := Label.new()
	sponsored.text = "Microslop Premium  ·  SPONSORISÉ"
	sponsored.add_theme_font_size_override("font_size", 12)
	sponsored.add_theme_color_override("font_color", Color("34425b"))
	recommended_layout.add_child(sponsored)
	var sponsored_description := Label.new()
	sponsored_description.text = "Votre productivité pourrait augmenter de 3 %. Cliquez ici pour voir une offre que vous n'avez pas demandée."
	sponsored_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sponsored_description.add_theme_font_size_override("font_size", 11)
	sponsored_description.add_theme_color_override("font_color", Color("68758c"))
	recommended_layout.add_child(sponsored_description)

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
	account.pressed.connect(func(): _show_notification("Compte Microslop", "Synchronisation activée. Vos préférences publicitaires ont été synchronisées."))
	profile_row.add_child(account)
	var power := Button.new()
	power.text = "⏻"
	power.tooltip_text = "Options d’alimentation simulées"
	power.custom_minimum_size = Vector2(42, 40)
	power.add_theme_font_size_override("font_size", 19)
	power.add_theme_color_override("font_color", Color("263247"))
	power.add_theme_stylebox_override("normal", _flat_style(Color(0, 0, 0, 0), 8))
	power.add_theme_stylebox_override("hover", _flat_style(Color("e1e9f5"), 8))
	power.pressed.connect(func():
		_show_notification("Options d’alimentation", "Veille, redémarrage et arrêt sont simulés dans Microslop Experience.")
	)
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
	button.text = "%s\n%s" % [glyph, caption]
	button.custom_minimum_size = Vector2(168, 62)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("263247"))
	button.add_theme_stylebox_override("normal", _flat_style(Color(1, 1, 1, 0.46), 10))
	button.add_theme_stylebox_override("hover", _flat_style(Color(0.78, 0.86, 0.97, 0.92), 10))
	button.pressed.connect(callback)
	button.focus_mode = Control.FOCUS_NONE
	parent.add_child(button)

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
		if _mission_step == 0:
			_advance_mission("Vous avez ouvert le menu Démarrer.")

func _animate_flyout(panel: Control, opening: bool, from_bottom: bool) -> void:
	if not is_instance_valid(panel):
		return
	var active_tween: Tween = _start_menu_tween if panel == _start_menu else _quick_settings_tween
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
		else:
			_quick_settings_tween = tween
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
		else:
			_quick_settings_tween = tween

func _open_window(title: String, message: String, window_size := Vector2(520, 300)) -> Control:
	_start_menu.visible = false
	_start_open = false
	# Keep the simulated desktop bounded: opening apps repeatedly must not
	# accumulate an unlimited number of live Control trees.
	const MAX_OPEN_WINDOWS := 8
	while _window_layer.get_child_count() >= MAX_OPEN_WINDOWS:
		var oldest_window := _window_layer.get_child(0)
		_window_layer.remove_child(oldest_window)
		oldest_window.queue_free()
	var app: Control = AppWindow.new()
	_window_layer.add_child(app)
	app.call("configure", title, message, window_size)
	app.position = (get_viewport_rect().size - window_size) / 2.0
	app.pivot_offset = window_size / 2.0
	app.modulate.a = 0.0
	app.scale = Vector2(0.985, 0.985)
	app.z_index = 20 + _window_layer.get_child_count()
	var appear := create_tween().set_parallel(true)
	appear.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	appear.tween_property(app, "modulate:a", 1.0, 0.16)
	appear.tween_property(app, "scale", Vector2.ONE, 0.18)
	return app

func _open_files() -> void:
	if _mission_step == 1:
		_advance_mission("Explorateur ouvert. Vos fichiers restent fictifs.")
	_open_window("Explorateur de fichiers", "Accueil\n\nDocuments\nTéléchargements\nImages\n\nVos fichiers sont parfaitement simulés. Aucun fichier personnel n'est consulté.", Vector2(600, 360))

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

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and _start_menu.visible:
			_start_menu.visible = false
			_start_open = false
			if is_instance_valid(_quick_settings_panel):
				_quick_settings_panel.visible = false
		elif event.keycode == KEY_F1:
			_open_settings()
		elif event.keycode == KEY_F2:
			_advance_mission("Progression de la campagne avancée manuellement pour le prototype.")

func _process(delta: float) -> void:
	_clock_refresh_elapsed += delta
	if _clock_refresh_elapsed >= 1.0:
		_clock_refresh_elapsed = 0.0
		if is_instance_valid(_tray_button):
			_tray_button.text = "⌃  ◖  ◉  🔊  🔋\n%s  ·  %s" % [Time.get_time_string_from_system().substr(0, 5), Time.get_date_string_from_system().replace("-", "/")]
	_event_elapsed += delta
	if _event_elapsed >= 75.0:
		_event_elapsed = 0.0
		_trigger_system_event()

func _trigger_system_event() -> void:
	var events := [
		["Offre exclusive", "Microslop Premium est en promotion. L'offre se termine dans 47 secondes."],
		["Microslop AI", "Votre assistant a une suggestion que vous n'avez pas demandée."],
		["Optimisation terminée", "Nous avons optimisé votre PC. Les performances sont identiques."],
		["Rappel système", "Vous n'avez pas encore évalué votre expérience. Note : obligatoire (mais facultative)."]
	]
	var event: Array = events[_event_index % events.size()]
	_event_index += 1
	_show_notification(str(event[0]), str(event[1]))

func _flat_style(color: Color, radius := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
