extends Camera3D
## Demo-only camera for racer_palms_demo.tscn (not needed in your game).
##
## Keys:  1-5 camera views   W wind on/off   +/- wind strength
##        P   save screenshot to user://racer_palms_screenshots/
## Command line (renders all five views as PNG and quits):
##        godot --path <project> res://racer_palms/demo/racer_palms_demo.tscn -- --racer-palms-screenshots

const VIEWS := [
	{"name": "1_coastal_palm", "eye": Vector3(29.0, 4.5, 72.0), "target": Vector3(21.0, 5.6, 60.0)},
	{"name": "2_tall_palm", "eye": Vector3(71.0, 5.0, 77.0), "target": Vector3(60.0, 7.3, 60.0)},
	{"name": "3_windblown_palm", "eye": Vector3(110.0, 4.0, 73.0), "target": Vector3(102.5, 4.6, 60.0)},
	{"name": "4_all_variants", "eye": Vector3(39.0, 5.5, 164.0), "target": Vector3(39.5, 5.5, 140.0)},
	{"name": "5_coastal_road", "eye": Vector3(1.8, 2.4, 12.0), "target": Vector3(-0.5, 3.2, -40.0)},
]

var _view := 4
var _wind_on := true
var _wind_strength := 1.0
var _label: Label


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(16, 12)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	layer.add_child(_label)
	_set_view(_view)
	RacerPalmsWind.set_wind_enabled(true)
	RacerPalmsWind.set_wind(_wind_strength)
	if "--racer-palms-screenshots" in OS.get_cmdline_user_args():
		_capture_all.call_deferred()


func _process(_delta: float) -> void:
	_label.text = "Racer Palms demo  |  %s  |  wind %s %.1f  |  %d FPS\n1-5 views   W wind   +/- strength   P screenshot" % [
			VIEWS[_view]["name"], "on" if _wind_on else "off", _wind_strength,
			Engine.get_frames_per_second()]


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			_set_view(key.keycode - KEY_1)
		KEY_W:
			_wind_on = not _wind_on
			RacerPalmsWind.set_wind_enabled(_wind_on)
		KEY_PLUS, KEY_KP_ADD, KEY_EQUAL:
			_wind_strength = minf(_wind_strength + 0.25, 3.0)
			RacerPalmsWind.set_wind(_wind_strength)
		KEY_MINUS, KEY_KP_SUBTRACT:
			_wind_strength = maxf(_wind_strength - 0.25, 0.0)
			RacerPalmsWind.set_wind(_wind_strength)
		KEY_P:
			_save_screenshot(VIEWS[_view]["name"])


func _set_view(index: int) -> void:
	_view = clampi(index, 0, VIEWS.size() - 1)
	var v: Dictionary = VIEWS[_view]
	look_at_from_position(v["eye"], v["target"], Vector3.UP)


func _save_screenshot(file_name: String) -> void:
	DirAccess.make_dir_recursive_absolute("user://racer_palms_screenshots")
	var path := "user://racer_palms_screenshots/%s.png" % file_name
	get_viewport().get_texture().get_image().save_png(path)
	print("Racer Palms screenshot: ", ProjectSettings.globalize_path(path))


func _capture_all() -> void:
	_label.visible = false
	for i in VIEWS.size():
		_set_view(i)
		for _f in 30:  # let shaders compile, shadows and wind settle
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		_save_screenshot(VIEWS[i]["name"])
	get_tree().quit()
