extends VBoxContainer

const info_labels = [
	"Doc Hash: ",
	"File Size: ", 
	"Modification Date: ",
	"Tag Count: "
]

func _on_selected_doc():
	var true_path = G.path_to(G.selected_doc)
	var the_hash = DB.docs.get_value("path_hash", G.selected_doc, "N/A")
	var info : Array[String] = [the_hash, ]
	info.append(String.humanize_size(FileAccess.get_size(true_path)))
	info.append(Time.get_date_string_from_unix_time(FileAccess.get_modified_time(true_path)))
	
	for each in %Tag_List.get_children():
		each.queue_free()
	for each in %Sugg_List.get_children():
		each.queue_free()
	
	var all_tags = DB.docs.get_value("hash_tag", the_hash, [])
	info.append(str(all_tags.size()))
	all_tags = G.sort_tags(all_tags as PackedStringArray)
	var sugg_tags : Array[String]
	for tag in all_tags:
		var elem = preload("res://Components/tag_element.tscn").instantiate()
		elem.set_tag(tag)
		elem.add_to_group("doc_info_curr_tag")
		elem.toggle_mode = true
		%Tag_List.add_child(elem)
		for sugg in DB.tags.get_value(tag, "semantics", []):
			if sugg in all_tags:
				continue
			if not sugg in sugg_tags:
				sugg_tags.append(sugg)
				elem = preload("res://Components/tag_element.tscn").instantiate()
				elem.set_tag(sugg)
				elem.toggle_mode = true
				elem.add_to_group("doc_info_sugg_tag")
				%Sugg_List.add_child(elem)
	
	%Sugg_Container.folded = sugg_tags.is_empty()
	
	
	%Label.text = ""
	for n in range(info.size()):
		%Label.text += info_labels[n] + info[n] + "\n"


func _on_rem_pressed() -> void:
	for elem in get_tree().get_nodes_in_group("doc_info_curr_tag"):
		if elem.button_pressed:
			var tag = elem.text
			DB.remove_tag_from(G.selected_doc, tag)
	DB.save_database()
	get_tree().call_group("respond_select_doc", "_on_selected_doc")

func _on_add_pressed() -> void:
	for elem in get_tree().get_nodes_in_group("doc_info_sugg_tag"):
		if elem.button_pressed:
			var tag = elem.text
			DB.add_tag_to(G.selected_doc, tag)
	DB.save_database()
	get_tree().call_group("respond_select_doc", "_on_selected_doc")


func _on_set_tag_input_pressed() -> void:
	var prompt : PackedStringArray
	for tag_elem in get_tree().get_nodes_in_group("doc_info_curr_tag"):
		if tag_elem.button_pressed:
			prompt.append(tag_elem.text)
	get_tree().call_group("change_tag_prompt", "_on_tag_prompt_set", prompt)

func _on_add_tag_input_pressed() -> void:
	var prompt : PackedStringArray
	for tag_elem in get_tree().get_nodes_in_group("doc_info_curr_tag"):
		if tag_elem.button_pressed:
			prompt.append(tag_elem.text)
	get_tree().call_group("change_tag_prompt", "_on_tag_prompt_add", prompt)
