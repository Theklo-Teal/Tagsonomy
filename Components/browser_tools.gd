extends VBoxContainer

func _ready() -> void:
	var curr_mode : G.RMB = G.sett.get_value("Main", "rmb_action", G.RMB.OPEN)
	%mouse_mode.text = RMB_TEXT[curr_mode]


const RMB_TEXT = {
	G.RMB.OPEN:"Open In Viewer",
	G.RMB.SET_FAV:"Set as Favorite",
	G.RMB.TO_TRASH:"Send to Trash",
}

func _shortcut_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_released():
		match event.keycode:
			KEY_F6:
				_on_mouse_mode_pressed()

func _on_mouse_mode_pressed() -> void:
	var curr : G.RMB = G.sett.get_value("Main", "rmb_action", G.RMB.OPEN)
	var next : G.RMB = wrapi(curr + 1, 0, RMB_TEXT.size()) as G.RMB
	G.sett.set_value("Main", "rmb_action", next)
	%mouse_mode.text = RMB_TEXT[next]

func _on_uncheck_pressed() -> void:
	get_tree().call_group("Browser", "_on_uncheck_all_docs")

func _on_zoom_drag_ended(value_changed: bool) -> void:
	if value_changed:
		var val = %zoom.value as int
		%zoom_label.text = "Icon Size: " + str(val) + "px"
		get_tree().call_group("Browser", "_on_thumbnail_resize", val)

func browser_changed(browser:String):
	var default_size = G.sett.get_value("Doc_"+browser, "thumb_size_min", 32)
	var thumb_size = G.sett.get_value("Doc_"+browser, "thumbnail_size", default_size)
	%zoom_label.text = "Icon Size: " + str(thumb_size) + "px"
	%zoom.min_value = G.sett.get_value("Doc_"+browser, "thumb_size_min", 0)
	%zoom.max_value = G.sett.get_value("Doc_"+browser, "thumb_size_max", 100)
	%zoom.step = G.sett.get_value("Doc_"+browser, "thumb_size_step", 12)
	%zoom.value = thumb_size


func _on_trash_pressed() -> void:
	for each in get_tree().get_nodes_in_group("Browser"):
		if each.visible and each.has_method("get_checked_docs"):
			for doc in each.get_checked_docs():
				DB.rem_doc(doc)
				OS.move_to_trash(G.path_to(doc))
			break
	DB.save_database()
	G.reload_filter()

var fav_state := false
func _on_fav_pressed() -> void:
	fav_state = not fav_state
	for each in get_tree().get_nodes_in_group("Browser"):
		if each.visible and each.has_method("get_checked_docs"):
			for doc in each.get_checked_docs():
				if fav_state:
					DB.add_tag_to(doc, "favorite")
				else:
					DB.remove_tag_from(doc, "favorite")
			break
	DB.save_database()
	get_tree().call_group("Browser", "_on_update_items")
