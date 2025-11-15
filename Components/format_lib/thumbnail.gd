extends PanelContainer

signal activated
signal right_mouse_press

var mouse_over_panel = preload("res://Components/format_lib/thumbnail_static_mouse_over.tres")
var mouse_off_panel = preload("res://Components/format_lib/thumbnail_static_mouse_off.tres")
var selected_panel = preload("res://Components/format_lib/thumbnail_static_selected.tres")


var this_doc : String : 
	set(val):
		this_hash = DB.docs.get_value("path_hash", val)
		this_doc = val
var this_hash : String

func set_content_size(width:int):
	%TextureRect.custom_minimum_size.x = width

func set_indicator(format:Color, favorite:Color):
	%Format.color = format
	%Favorite.color = favorite

var mouse_hover : bool 
var period = 0.3
var frame_count : int = 4
var curr_frame : int :
	set(val):
		val = wrapi(val, 0, frame_count)
		curr_frame = val
		var wide = sqrt(frame_count)
		%TextureRect.texture.region.position.x = val % roundi(wide) * %TextureRect.texture.region.size.x
		%TextureRect.texture.region.position.y = floor(val as float / wide) * %TextureRect.texture.region.size.y

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_on_mouse_exited()
func _on_mouse_entered():
	mouse_hover = true
	if not G.selected_doc.is_empty() and this_doc == G.selected_doc:
		set("theme_override_styles/panel/", selected_panel)
	else:
		set("theme_override_styles/panel/", mouse_over_panel)
func _on_mouse_exited():
	mouse_hover = false
	if G.selected_doc.is_empty() or not this_doc == G.selected_doc:
		set("theme_override_styles/panel/", mouse_off_panel)

func _on_selected_doc():
	if not G.selected_doc.is_empty() and this_doc == G.selected_doc:
		set("theme_override_styles/panel/", selected_panel)
	else:
		[_on_mouse_exited, _on_mouse_entered][int(mouse_hover)].call()


var elapsed : float
func _process(delta: float) -> void:
	if mouse_hover and %TextureRect.texture is AtlasTexture:
		elapsed += delta
		if elapsed > period:
			elapsed = 0
			curr_frame += 1

func _gui_input(event: InputEvent) -> void:
	if mouse_hover and event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.double_click:
					activated.emit()
			MOUSE_BUTTON_RIGHT:
				if event.is_released():
					right_mouse_press.emit()

func set_check(val:bool):
	%CheckBox.button_pressed = val
func is_checked() -> bool:
	return %CheckBox.button_pressed
