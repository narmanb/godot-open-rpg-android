## Phone-first touchscreen controls for the Android port.
##
## This deliberately emits keyboard events instead of changing OpenRPG's gameplay code. The
## existing game already understands arrows, Space, and Escape, so the mobile layer stays isolated
## and can later grow into a fully draggable/resizable layout editor.
extends CanvasLayer

const SETTINGS_PATH := "user://mobile_controls.cfg"
const BUTTON_SIZE := 150.0
const BUTTON_GAP := 14.0
const DEFAULT_OPACITY := 0.45
const OPACITY_LEVELS := [0.25, 0.40, 0.55, 0.70, 0.85]

var _controls_root: Node2D
var _utility_root: Node2D
var _button_groups := {}
var _opacity := DEFAULT_OPACITY
var _opacity_index := 1
var _opacity_label: Label


func _ready() -> void:
	layer = 100
	_load_settings()

	_controls_root = Node2D.new()
	_controls_root.name = "GameplayControls"
	add_child(_controls_root)

	_utility_root = Node2D.new()
	_utility_root.name = "TouchControlUtilities"
	add_child(_utility_root)

	_create_key_button("up", "↑", KEY_UP)
	_create_key_button("down", "↓", KEY_DOWN)
	_create_key_button("left", "←", KEY_LEFT)
	_create_key_button("right", "→", KEY_RIGHT)
	_create_key_button("confirm", "A", KEY_SPACE)
	_create_key_button("cancel", "B", KEY_ESCAPE)
	_create_opacity_button()

	_refresh_opacity()
	_layout_controls()
	get_viewport().size_changed.connect(_layout_controls)


func _create_key_button(id: String, text: String, keycode: Key) -> void:
	var group := Node2D.new()
	group.name = id.capitalize()
	_controls_root.add_child(group)
	_button_groups[id] = group

	_add_button_visual(group, text, Vector2(BUTTON_SIZE, BUTTON_SIZE), 44)

	var touch := TouchScreenButton.new()
	touch.name = "TouchTarget"
	touch.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	touch.passby_press = true
	touch.shape_visible = false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	touch.shape = shape
	touch.pressed.connect(_send_key.bind(keycode, true))
	touch.released.connect(_send_key.bind(keycode, false))
	group.add_child(touch)


func _create_opacity_button() -> void:
	var group := Node2D.new()
	group.name = "Opacity"
	_utility_root.add_child(group)
	_button_groups["opacity"] = group

	_opacity_label = _add_button_visual(group, "45%", Vector2(100.0, 76.0), 26)

	var touch := TouchScreenButton.new()
	touch.name = "TouchTarget"
	touch.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	touch.shape_visible = false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(100.0, 76.0)
	touch.shape = shape
	touch.pressed.connect(_cycle_opacity)
	group.add_child(touch)


func _add_button_visual(parent: Node2D, text: String, size: Vector2, font_size: int) -> Label:
	var background := ColorRect.new()
	background.name = "Background"
	background.position = -size / 2.0
	background.size = size
	background.color = Color(0.05, 0.05, 0.05, 0.82)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(background)

	var label := Label.new()
	label.name = "Label"
	label.position = -size / 2.0
	label.size = size
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _layout_controls() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var step := BUTTON_SIZE + BUTTON_GAP
	var dpad_center := Vector2(230.0, viewport_size.y - 225.0)

	_button_groups["up"].position = dpad_center + Vector2(0.0, -step)
	_button_groups["down"].position = dpad_center + Vector2(0.0, step)
	_button_groups["left"].position = dpad_center + Vector2(-step, 0.0)
	_button_groups["right"].position = dpad_center + Vector2(step, 0.0)

	_button_groups["confirm"].position = Vector2(viewport_size.x - 185.0, viewport_size.y - 250.0)
	_button_groups["cancel"].position = Vector2(viewport_size.x - 355.0, viewport_size.y - 135.0)
	_button_groups["opacity"].position = Vector2(viewport_size.x - 72.0, 62.0)


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = false
	Input.parse_input_event(event)


func _cycle_opacity() -> void:
	_opacity_index = (_opacity_index + 1) % OPACITY_LEVELS.size()
	_opacity = OPACITY_LEVELS[_opacity_index]
	_refresh_opacity()
	_save_settings()


func _refresh_opacity() -> void:
	if _controls_root:
		_controls_root.modulate.a = _opacity
	if _opacity_label:
		_opacity_label.text = "%d%%" % roundi(_opacity * 100.0)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		_opacity = clampf(float(config.get_value("touch_controls", "opacity", DEFAULT_OPACITY)), 0.1, 1.0)

	var best_distance := INF
	for index in range(OPACITY_LEVELS.size()):
		var distance := absf(OPACITY_LEVELS[index] - _opacity)
		if distance < best_distance:
			best_distance = distance
			_opacity_index = index
	_opacity = OPACITY_LEVELS[_opacity_index]


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("touch_controls", "opacity", _opacity)
	config.save(SETTINGS_PATH)
