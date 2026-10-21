extends Control
## First playable shell for Microslop Experience.
## All windows and system behaviour are simulated inside the game.

const AppWindow = preload("res://scripts/app_window.gd")
const TASKBAR_HEIGHT := 54

var _window_layer: Control
var _start_menu: PanelContainer
var _notification_layer: VBoxContainer
var _clock_label: Label
var _start_open := false
var _mission_label: Label
var _mission_step := 0

func _ready() -> void:
	_build_desktop()
	SettingsStore.apply_display_settings()
	_show_notification("Bienvenue", "Votre expérience Microslop est prête. Vous n'avez rien demandé, mais nous avons tout activé.")
	_update_mission()

func _build_desktop() -> void:
	var wallpaper := ColorRect.new()
	wallpaper.color = Color("172d55")
	wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(wallpaper)

	var glow := ColorRect.new()
	glow.color = Color(0.15, 0.35, 0.66, 0.42)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wallpaper.add_child(glow)

	var wallpaper_title := Label.new()
	wallpaper_title.text = "microslop"
	wallpaper_title.position = Vector2(36, 28)
	wallpaper_title.add_theme_font_size_override("font_size", 20)
	wallpaper_title.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0, 0.9))
	add_child(wallpaper_title)

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
	_build_mission_hint()

func _add_desktop_icon(parent: VBoxContainer, glyph: String, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(112, 70)
	button.text = "%s\n%s" % [glyph, caption]
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _flat_style(Color(0.1, 0.2, 0.38, 0.15)))
	button.add_theme_stylebox_override("hover", _flat_style(Color(0.55, 0.7, 0.95, 0.25)))
	button.pressed.connect(callback)
	parent.add_child(button)

func _build_taskbar() -> void:
	var taskbar := PanelContainer.new()
	taskbar.anchor_left = 0.0
	taskbar.anchor_top = 1.0
	taskbar.anchor_right = 1.0
	taskbar.anchor_bottom = 1.0
	taskbar.offset_top = -TASKBAR_HEIGHT
	taskbar.offset_bottom = 0
	taskbar.add_theme_stylebox_override("panel", _flat_style(Color(0.055, 0.075, 0.12, 0.94)))
	add_child(taskbar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	taskbar.add_child(row)

	var start_button := Button.new()
	start_button.text = "⊞"
	start_button.tooltip_text = "Démarrer"
	start_button.custom_minimum_size = Vector2(48, 42)
	start_button.add_theme_font_size_override("font_size", 24)
	start_button.pressed.connect(_toggle_start_menu)
	row.add_child(start_button)

	var search_button := Button.new()
	search_button.text = "Rechercher (et afficher des résultats sponsorisés)"
	search_button.custom_minimum_size.x = 300
	search_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_button.pressed.connect(_open_search)
	row.add_child(search_button)

	var settings_button := Button.new()
	settings_button.text = "⚙ Paramètres"
	settings_button.pressed.connect(_open_settings)
	row.add_child(settings_button)

	var update_button := Button.new()
	update_button.text = "↻ Mise à jour"
	update_button.pressed.connect(_trigger_update)
	row.add_child(update_button)

	_clock_label = Label.new()
	_clock_label.text = Time.get_time_string_from_system().substr(0, 5)
	_clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_clock_label.add_theme_color_override("font_color", Color.WHITE)
	_clock_label.custom_minimum_size.x = 70
	row.add_child(_clock_label)

func _build_start_menu() -> void:
	_start_menu = PanelContainer.new()
	_start_menu.position = Vector2(18, 180)
	_start_menu.size = Vector2(340, 420)
	_start_menu.visible = false
	_start_menu.add_theme_stylebox_override("panel", _flat_style(Color("f4f6fb")))
	add_child(_start_menu)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	_start_menu.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var heading := Label.new()
	heading.text = "Démarrer"
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", Color("1d2a40"))
	layout.add_child(heading)

	var sponsored := Label.new()
	sponsored.text = "RECOMMANDÉ POUR VOUS · SPONSORISÉ"
	sponsored.add_theme_font_size_override("font_size", 11)
	sponsored.add_theme_color_override("font_color", Color("68758c"))
	layout.add_child(sponsored)

	_add_menu_button(layout, "✨ Microslop AI — recommandé", _open_ai)
	_add_menu_button(layout, "🌐 Microslop Browser", _open_browser)
	_add_menu_button(layout, "📁 Explorateur de fichiers", _open_files)
	_add_menu_button(layout, "⚙ Paramètres", _open_settings)
	_add_menu_button(layout, "🔄 Rechercher des mises à jour", _trigger_update)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)

	var account := Label.new()
	account.text = "Connectez-vous pour profiter de votre expérience."
	account.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	account.add_theme_color_override("font_color", Color("44516a"))
	layout.add_child(account)

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
	card.add_theme_stylebox_override("panel", _flat_style(Color(0.04, 0.07, 0.12, 0.82)))
	add_child(card)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	card.add_child(margin)

	_mission_label = Label.new()
	_mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_label.add_theme_color_override("font_color", Color.WHITE)
	margin.add_child(_mission_label)

func _add_menu_button(parent: VBoxContainer, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 40
	button.add_theme_color_override("font_color", Color("263247"))
	button.pressed.connect(callback)
	parent.add_child(button)

func _toggle_start_menu() -> void:
	_start_open = not _start_open
	_start_menu.visible = _start_open

func _open_window(title: String, message: String, window_size := Vector2(520, 300)) -> Control:
	_start_menu.visible = false
	_start_open = false
	var app: Control = AppWindow.new()
	_window_layer.add_child(app)
	app.call("configure", title, message, window_size)
	app.position = (get_viewport_rect().size - window_size) / 2.0
	app.z_index = 20 + _window_layer.get_child_count()
	return app

func _open_files() -> void:
	_open_window("Explorateur de fichiers", "Accueil\n\nDocuments\nTéléchargements\nImages\n\nVos fichiers sont parfaitement simulés. Aucun fichier personnel n'est consulté.", Vector2(600, 360))

func _open_browser() -> void:
	_open_window("Microslop Browser", "Votre navigateur nouvelle génération.\n\nRecherche : comment travailler sans être interrompu\n\nRésultat sponsorisé : Achetez Microslop Premium pour réduire les interruptions de 3 %.", Vector2(680, 400))

func _open_recycle_bin() -> void:
	_open_window("Corbeille", "La corbeille est vide.\n\nElle a tout de même besoin d'une mise à jour de 4,7 Go.", Vector2(440, 240))

func _open_ai() -> void:
	_open_window("Microslop AI", "Bonjour ! J'ai analysé votre demande et préparé 46 suggestions.\n\nVous vouliez ouvrir le Bloc-notes ? Je peux plutôt vous proposer un abonnement.", Vector2(500, 300))

func _open_search() -> void:
	_open_window("Recherche Microslop", "Résultats pour : « ouvrir une application »\n\n1. Microslop Premium — SPONSORISÉ\n2. Microslop AI — recommandé\n3. L'application que vous recherchiez (peut-être).", Vector2(560, 300))

func _trigger_update() -> void:
	_open_window("Microslop Update", "Une mise à jour importante est disponible.\n\nMicroslop Experience Update 1.0.99 (préversion)\nProgression : 99 %\n\nNe fermez pas votre ordinateur. Cette opération peut prendre quelques instants…", Vector2(520, 280))
	_show_notification("Mise à jour en attente", "Redémarrage recommandé. Nous choisirons le moment.")

func _open_settings() -> void:
	_start_menu.visible = false
	_start_open = false
	var panel := _open_window("Paramètres", "Configurez l'affichage, le son et la langue.", Vector2(560, 500))
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

func _show_notification(title: String, message: String) -> void:
	if not is_instance_valid(_notification_layer):
		return
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _flat_style(Color("f5f7fb")))
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
	while _notification_layer.get_child_count() > 3:
		_notification_layer.get_child(0).queue_free()

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
		elif event.keycode == KEY_F1:
			_open_settings()
		elif event.keycode == KEY_F2:
			_mission_step = mini(_mission_step + 1, 3)
			_update_mission()
			_show_notification("Mission mise à jour", "Progression de la campagne modifiée pour le prototype.")

func _process(_delta: float) -> void:
	if is_instance_valid(_clock_label):
		_clock_label.text = Time.get_time_string_from_system().substr(0, 5)

func _flat_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
