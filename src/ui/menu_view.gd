class_name MenuView
extends Control
## The local-match setup menu. Each side toggles its army independently among
## Xiangqi, 大肥鱼的象棋, and Shogi, then starts the match. Thin presentation:
## it emits the chosen armies and keeps no match state.

signal started(side1_army: Army.Type, side2_army: Army.Type)

var _armies: Array = Army.all()

## Selected army index for each side: _indices[0] is Side 1, _indices[1] is
## Side 2.
var _indices := [0, 0]

var _side1_button: Button
var _side2_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_buttons()


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "ChessCraft"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	_side1_button = _make_army_button()
	_side1_button.pressed.connect(_toggle_side.bind(0))
	vbox.add_child(_make_side_row("Side 1", _side1_button))

	_side2_button = _make_army_button()
	_side2_button.pressed.connect(_toggle_side.bind(1))
	vbox.add_child(_make_side_row("Side 2", _side2_button))

	var start := Button.new()
	start.text = "Start"
	start.pressed.connect(_on_start_pressed)
	vbox.add_child(start)


func _make_side_row(side_label: String, button: Button) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = side_label + ":"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	row.add_child(button)
	return row


func _make_army_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(170.0, 0.0)
	return button


func _refresh_buttons() -> void:
	_side1_button.text = Army.display_name(_armies[_indices[0]])
	_side2_button.text = Army.display_name(_armies[_indices[1]])


## Cycles one side's army to the next in menu order.
func _toggle_side(side_index: int) -> void:
	_indices[side_index] = (_indices[side_index] + 1) % _armies.size()
	_refresh_buttons()


func _on_start_pressed() -> void:
	started.emit(_armies[_indices[0]], _armies[_indices[1]])
