extends HBoxContainer

var tree_root : TreeItem
func _ready() -> void:
	%File_List.set_column_title(0, "⭐")
	%File_List.set_column_title(2, "File Path")
	%File_List.set_column_title(3, "File Size")
	%File_List.set_column_title(4, "Mod Date")
	%File_List.set_column_expand(0, false)
	%File_List.set_column_expand(1, false)
	%File_List.set_column_expand(2, true)
	%File_List.set_column_expand(3, false)
	%File_List.set_column_expand(4, false)
	%File_List.set_column_clip_content(2, true)
	%File_List.set_column_clip_content(3, false)
	%File_List.set_column_clip_content(4, false)
	%File_List.set_column_custom_minimum_width(1, 12)
	%File_List.set_column_custom_minimum_width(3, 100)
	%File_List.set_column_custom_minimum_width(4, 100)


func back_button_pressed():
	G.curr_page -= 1
func front_button_pressed():
	G.curr_page += 1


func _on_uncheck_all_docs():
	for item in tree_root.get_children():
		item.set_checked(0, false)

func get_checked_docs() -> PackedStringArray:
	var ans : PackedStringArray
	for item in tree_root.get_children():
		if item.is_checked(0):
			ans.append(item.get_meta("filepath"))
	return ans

func _on_thumbnail_resize(new_size:int):
	if visible:
		G.sett.set_value("Doc_Tree", "thumbnail_size", new_size)
		for each in tree_root.get_children():
			each.set_icon_max_width(2, new_size)

var doc_elems : Dictionary[String, TreeItem]  # {doc_path: doc_elem} A quick reference to docs.
func _on_filter_update():
	doc_elems.clear()
	%File_List.clear()
	tree_root = %File_List.create_item()
	
	var page_size = G.sett.get_value("Main", "page_size", 32)
	page_size = G.sett.get_value("Doc_Tree", "page_size", page_size)
	var page_start = page_size * G.curr_page
	
	for doc in G.matching_docs.slice(page_start, page_start + page_size):
		var item = tree_root.create_child()
		doc_elems[doc] = item
		item.set_meta("filepath", doc)
		var the_hash = DB.docs.get_value("path_hash", doc)
		item.set_meta("hash", the_hash)
		
		var type_color = G.get_doc_lib(doc).color
		item.set_custom_bg_color(1, type_color)
		
		if "favorite" in DB.docs.get_value("hash_tag", the_hash, []):
			item.set_custom_bg_color(0, Color.YELLOW)
		else:
			item.clear_custom_bg_color(0)
		
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_editable(0, true)
		
		item.set_icon(2, G.get_doc_lib(doc).get_static_thumbnail(doc) )
		item.set_icon_max_width(2, G.sett.get_value("Doc_Tree", "thumbnail_size", 
			G.sett.get_value("Doc_Tree", "thumbsize_min", 32)) )
		item.set_text(2, doc.get_base_dir() +"/\n"+ doc.get_file())
		
		var filesize = String.humanize_size(FileAccess.get_size(G.path_to(doc)))
		var filedate = Time.get_date_string_from_unix_time(FileAccess.get_modified_time(G.path_to(doc)))
		item.set_text(3, filesize)
		item.set_text(4, str(filedate))
		
		item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_LEFT)
		item.set_text_alignment(3, HORIZONTAL_ALIGNMENT_CENTER)
		item.set_text_alignment(4, HORIZONTAL_ALIGNMENT_CENTER)

func _on_update_items():
	for item : TreeItem in tree_root.get_children():
		var the_hash = item.get_meta("hash")
		if "favorite" in DB.docs.get_value("hash_tag", the_hash, []):
			item.set_custom_bg_color(0, Color.YELLOW)
		else:
			item.clear_custom_bg_color(0)


func _on_page_changed():
	_on_filter_update()


func _on_file_list_column_title_clicked(_column: int, _mouse_button_index: int) -> void:
	# Sort table contents
	pass


func _on_file_list_item_selected() -> void:
	pass
func _on_file_list_item_activated() -> void:
	G.select_doc_path(%File_List.get_selected().get_meta("filepath"))


func _on_file_list_item_mouse_selected(_mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != 2:
		return
	var filepath = %File_List.get_selected().get_meta("filepath")
	var the_hash = %File_List.get_selected().get_meta("hash")
	match G.sett.get_value("Main", "rmb_action", G.RMB.OPEN):
		G.RMB.OPEN:
			G.select_doc_path(filepath)
			G.MAIN.get_node("%Browser").current_tab = 2
		G.RMB.SET_FAV:
			if "favorite" in DB.docs.get_value("hash_tag", the_hash, []):
				DB.remove_tag_from(filepath, "favorite")
			else:
				DB.add_tag_to(filepath, "favorite")
			DB.save_database()
			get_tree().call_group("Browser", "_on_update_items")
		G.RMB.TO_TRASH:
			DB.rem_doc(filepath)
			OS.move_to_trash(G.path_to(filepath))
			DB.save_database()
			G.reload_filter()
