extends VBoxContainer

@onready var path_family = %TEMPLATE.get_path_to(%Family, false)
@onready var path_fam_color = %TEMPLATE.get_path_to(%Family_Color, false)
@onready var path_descript = %TEMPLATE.get_path_to(%Description, false)
@onready var path_new_name = %TEMPLATE.get_path_to(%New_Name, false)
@onready var path_semantic = %TEMPLATE.get_path_to(%Semantics_List, false)
@onready var path_add_semantic = %TEMPLATE.get_path_to(%Add_Semantics, false)


func _ready() -> void:
	%TEMPLATE.hide()

func _on_selected_tag():
	for each in %Tag_List.get_children():
		if each.name != "TEMPLATE":
			each.queue_free()
	
	for tag_elem in get_tree().get_nodes_in_group("matches_tag_group"):
		if not tag_elem.button_pressed:
			continue
		var tag : String = tag_elem.text
		var fold_cont : FoldableContainer = %TEMPLATE.duplicate()
		fold_cont.title = tag
		fold_cont.show()
		%Tag_List.add_child(fold_cont)
		
		var family : String = DB.tags.get_value(tag, "family", "None")
		var fam_color : Color = DB.tags.get_value("FAMILY", family, Color.WHITE ) 
		var descript : String = DB.tags.get_value(tag, "description", "")
		var semantics : Array[String]
		semantics.append_array(DB.tags.get_value(tag, "semantics", []))
		var semantics_string : String = ""
		
		for n in range(semantics.size()):
			var color = DB.tags.get_value(semantics[n], "family", "None")
			color = DB.tags.get_value("FAMILY", color, Color.WHITE)
			semantics_string += "[color='" + color.to_html(false) + "']" + semantics[n] + "[/color] | "
		
		fold_cont.get_node(path_family).text = family
		fold_cont.get_node(path_fam_color).color = fam_color
		fold_cont.get_node(path_descript).text = descript
		fold_cont.get_node(path_semantic).text = semantics_string
		fold_cont.get_node(path_semantic).set_meta("semantics", semantics)
		fold_cont.get_node(path_add_semantic).pressed.connect(_on_add_semantics_pressed.bind(tag, semantics))
		
		if tag in G.get_fake_tags() + PackedStringArray(["favorite"]):
			# Don't allow to mess with exceptional tags
			fold_cont.get_node(path_family).editable = false
			fold_cont.get_node(path_new_name).editable = false


var semantics_target : String
var curr_semantics_list : Array[String]
func _on_add_semantics_pressed(tgt_tag:String, curr:Array[String]) -> void:
	var rect = get_rect()
	rect.position = global_position
	rect.position.x -= rect.size.x + 10
	$All_Tags.popup(rect)
	semantics_target = tgt_tag
	curr_semantics_list = curr
	
	for each in %Present_List.get_children() + %Absent_List.get_children():
		each.queue_free()
	generate_present_tags()

func generate_present_tags():
	for tag in curr_semantics_list:
		var elem = preload("res://Components/tag_element.tscn").instantiate()
		elem.set_tag(tag)
		%Present_List.add_child(elem)
		elem.pressed.connect(_on_present_tags_pressed.bind(elem))

func _on_search_tags_suggestions_updated(_suggestions: PackedStringArray, replacements: PackedStringArray) -> void:
	for each in %Absent_List.get_children():
		each.queue_free()
	
	var reject := G.get_fake_tags() + PackedStringArray( curr_semantics_list + [semantics_target])
	
	for tag in replacements:
		if tag in reject:
			continue
		
		var elem = preload("res://Components/tag_element.tscn").instantiate()
		elem.set_tag(tag)
		elem.pressed.connect(_on_absent_tags_pressed.bind(elem))
		%Absent_List.add_child(elem)


func _on_present_tags_pressed(tag_elem:Control):
	curr_semantics_list.erase(tag_elem.text)
	%Present_List.remove_child(tag_elem)

func _on_absent_tags_pressed(tag_elem:Control):
	curr_semantics_list.append(tag_elem.text)
	%Absent_List.remove_child(tag_elem)
	for each in %Present_List.get_children():
		each.queue_free()
	generate_present_tags()


func _on_all_tags_popup_hide() -> void:
	#FIXME: Why is this not being called?
	DB.tags.set_value(semantics_target, "semantics", curr_semantics_list)
	DB.save_database()
	get_tree().call_group("respond_select_tag", "_on_selected_tag")


func _on_fold_all_pressed() -> void:
	for each in %Tag_List.get_children():
		if each.name == "TEMPLATE":
			continue
		each.fold()

func _on_deselect_pressed() -> void:
	for each in get_tree().get_nodes_in_group("matches_tag_group"):
		each.button_pressed = false
	get_tree().call_group("respond_select_tag", "_on_selected_tag")

func _on_save_all_pressed() -> void:
	for fold_cont in %Tag_List.get_children():
		if fold_cont.name == "TEMPLATE":
			continue
		var tag = fold_cont.title
		var family = fold_cont.get_node(path_family).text
		var descript = fold_cont.get_node(path_descript).text
		var semantics = fold_cont.get_node(path_semantic).get_meta("semantics", [])
		var new_name = fold_cont.get_node(path_new_name).text
		var fam_color = fold_cont.get_node(path_fam_color).color
		
		family = [family, "None"][int(family.is_empty())]
		
		DB.tags.set_value("FAMILY", family, fam_color)
		DB.tags.set_value(tag, "family", family)
		DB.tags.set_value(tag, "description", descript)
		DB.tags.set_value(tag, "semantics", semantics)
		
		if not new_name.is_empty():
			DB.rename_tag(tag, new_name.to_lower())
		
		DB.save_database()
		G.reload_filter()


func _on_set_tag_input_pressed() -> void:
	var prompt : PackedStringArray
	for tag_elem in get_tree().get_nodes_in_group("matches_tag_group"):
		if tag_elem.button_pressed:
			prompt.append(tag_elem.text)
	get_tree().call_group("change_tag_prompt", "_on_tag_prompt_set", prompt)

func _on_add_tag_input_pressed() -> void:
	var prompt : PackedStringArray
	for tag_elem in get_tree().get_nodes_in_group("matches_tag_group"):
		if tag_elem.button_pressed:
			prompt.append(tag_elem.text)
	get_tree().call_group("change_tag_prompt", "_on_tag_prompt_add", prompt)
