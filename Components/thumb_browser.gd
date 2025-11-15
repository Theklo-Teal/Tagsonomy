extends HBoxContainer

func _on_uncheck_all_docs():
	for each in %File_List.get_children():
		each.set_check(false)

func get_checked_docs() -> PackedStringArray:
	var ans : PackedStringArray
	for each in %File_List.get_children():
		if each.is_checked():
			ans.append(each.this_doc)
	return ans

func _on_thumbnail_resize(new_size:int):
	if visible:
		G.sett.set_value("Doc_Thumb", "thumbnail_size", new_size)
		for each in %File_List.get_children():
			each.set_content_size(new_size)

func _on_filter_update():
	var scroll_position = %ScrollContainer.scroll_vertical
	for each in %File_List.get_children():
		each.queue_free()

	var page_size = G.sett.get_value("Main", "page_size", 32)
	page_size = G.sett.get_value("Doc_Thumb", "page_size", page_size)
	var page_start = page_size * G.curr_page
	
	for doc in G.matching_docs.slice(page_start, page_start + page_size):
		var obj := G.get_doc_lib(doc).get_fancy_thumbnail(doc)
		obj.set_content_size(G.sett.get_value("Doc_Thumb", "thumbnail_size",
			G.sett.get_value("Doc_Thumb", "thumbsize_min",96)) )
		obj.this_doc = doc
		obj.activated.connect(_on_doc_activated.bind(obj))
		obj.right_mouse_press.connect(_on_doc_rmb_press.bind(obj))
		%File_List.add_child(obj)
	
	%ScrollContainer.call_deferred("set", "scroll_vertical", scroll_position)
	
	_on_update_items()

func _on_update_items():
	const fav_color = Color.YELLOW
	const none_format = Color("3f3f3f")
	for item in %File_List.get_children():
		var format = G.get_doc_lib(item.this_doc).color
		var is_fav = "favorite" in DB.docs.get_value("hash_tag", item.this_hash, [])
		is_fav = [none_format, fav_color][int(is_fav)]
		item.set_indicator(format, is_fav)

func _on_doc_activated(item:Control):
	G.select_doc_path(item.this_doc)

func _on_doc_rmb_press(item:Control):
	match G.sett.get_value("Main", "rmb_action", G.RMB.OPEN):
		G.RMB.OPEN:
			G.select_doc_path(item.this_doc)
			G.MAIN.get_node("%Browser").current_tab = 2
		G.RMB.SET_FAV:
			if "favorite" in DB.docs.get_value("hash_tag", item.this_hash, []):
				DB.remove_tag_from(item.this_doc, "favorite")
			else:
				DB.add_tag_to(item.this_doc, "favorite")
			DB.save_database()
			get_tree().call_group("Browser", "_on_update_items")
		G.RMB.TO_TRASH:
			DB.rem_doc(item.this_doc)
			OS.move_to_trash(G.path_to(item.this_doc))
			DB.save_database()
			G.reload_filter()


func _on_page_changed():
	_on_filter_update()

func back_button_pressed():
	G.curr_page -= 1
func front_button_pressed():
	G.curr_page += 1
