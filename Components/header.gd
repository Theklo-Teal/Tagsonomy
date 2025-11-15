extends HBoxContainer

func _on_selected_doc():
	var filepath = G.selected_doc
	if filepath.is_empty():
		%Select_Folder.text = "No Folder/"
		%Select_Filename.text = "No Document Selected"
	else:
		%Select_Folder.text = filepath.get_base_dir() + "/"
		%Select_Filename.text = filepath.get_file()


func _on_select_filename_text_submitted(new_text: String) -> void:
	if G.selected_doc.is_empty():
		%Select_Filename.text = "No Doc Selected"
		return
	var filename : String = new_text.get_basename() + "." + G.selected_doc.get_extension()
	var filepath : String = %Select_Folder.text + filename
	if %Select_Filename.text.is_empty() or not filename.is_valid_filename():
		%Select_Filename.text = G.selected_doc.get_file()
	else:
		DirAccess.rename_absolute(G.selected_doc, filepath)
		DB.rename_doc(G.selected_doc, filepath)
		DB.save_database()
		G.reload_filter()
		G.select_doc_path(filepath)


func _on_external_pressed() -> void:
	if not G.selected_doc.is_empty():
		OS.shell_open(G.path_to(G.selected_doc))

func _on_logo_button_pressed() -> void:
	var rect = Rect2(size.x * 0.5, 20, 600, 500)
	$About.popup(rect)

func _on_close_about_pressed() -> void:
	$About.hide()

#region Tag Input Mode
func toggle_filter_mode():
	%Input_Mode.button_pressed = not %Input_Mode.button_pressed

func _on_input_mode_toggled(toggled_on: bool) -> void:
	%Input_Mode.icon.region.position.y = [96, 64][int(toggled_on)]
	%Input_Mode.tooltip_text = ["Filtering Docs", "Tagging Selected Doc"][int(toggled_on)]
	if toggled_on:
		filter_prompt = %Tag_Input.sanitize_prompt(%Tag_Input.text)
		%Tag_Input.modulate = Color(0.693, 0.363, 0.0, 1.0)
		%Tag_Input.text = doc_tags
		%Tag_Input.placeholder_text = "Add or Remove Tags to active Doc"
	else:
		doc_tags = %Tag_Input.text
		%Tag_Input.modulate = Color(0.0, 0.461, 0.869, 1.0)
		%Tag_Input.text = filter_prompt
		%Tag_Input.placeholder_text = "Find Docs matching Tags"
#endregion

#region Tag Input Prompt Editing
var filter_prompt : String
var doc_tags : String
func _on_tag_input_text_submitted() -> void:
	if %Input_Mode.button_pressed:
		doc_tags = %Tag_Input.text
		apply_tag()
	else:
		filter_prompt = %Tag_Input.sanitize_prompt(%Tag_Input.text)
		apply_filter()

func apply_tag():
	if not G.selected_doc.is_empty():
		for token in doc_tags.split(" ", false):
			var prefix = %Tag_Input.get_token_prefix(token)
			var tag = %Tag_Input.get_token_tag(token)
			if "-" in prefix:
				DB.remove_tag_from(G.selected_doc, tag)
			else:
				if "+" in prefix: # Create tag
					if not DB.tags.has_section(tag):
						DB.add_tag(tag)
				DB.add_tag_to(G.selected_doc, tag)
		DB.save_database()
		get_tree().call_group("respond_select_doc", "_on_selected_doc")
		G.reload_filter()

func apply_filter():
	filter_prompt = %Tag_Input.sanitize_prompt(filter_prompt)
	
	var neu_filt : Array[String]  # A doc that matches has these tags.
	var neg_filt : Array[String]  # A doc is rejected if it matches any of these tags.
	var pos_filt : Array[String]  # A doc with these tags will match, even if rejected before.
	
	for token in filter_prompt.split(" ", false):
		var prefix = %Tag_Input.get_token_prefix(token)
		var tag = %Tag_Input.get_token_tag(token)
		if "-" in prefix:
			neg_filt.append(tag)
		elif "+" in prefix:
			pos_filt.append(tag)
		else:
			neu_filt.append(tag)

	G.update_filter(neu_filt, neg_filt, pos_filt)


func _on_tag_prompt_set(new_prompt:PackedStringArray):
	%Tag_Input.text = " ".join(new_prompt)
func _on_tag_prompt_add(new_prompt:PackedStringArray):
	%Tag_Input.text = %Tag_Input.text.strip_edges() + " "
	%Tag_Input.text += " ".join(new_prompt)
#endregion
