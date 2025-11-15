extends VBoxContainer

#region Handle the Pages
@onready var last_page_size : int = G.sett.get_value("Main", "page_size", 32) as int

func _on_page_changed():
	%curr_page.text = str(G.curr_page)

func _on_home_pressed() -> void:
	G.curr_page = 0
func _on_end_pressed() -> void:
	G.curr_page = G.max_page
func _on_last_pressed() -> void:
	G.curr_page -= 1
func _on_next_pressed() -> void:
	G.curr_page += 1
	
var last_accepted_text : String
## Check if it's just numbers
func _on_curr_page_text_changed(text: String) -> void:
	if text.is_empty():
		_on_curr_page_text_changed("0")
	elif text.is_valid_int():
		last_accepted_text = text
	else:
		%curr_page.text = last_accepted_text
		%curr_page.caret_column = last_accepted_text.length()
## Actually apply the page
func _on_curr_page_text_submitted(text: String) -> void:
	G.curr_page = int(text)
#endregion


func _on_browser_tab_changed(last_tab:int = 2):
	var tab = G.sett.get_value("Main", "browser_tab")
	var page_size : int = G.sett.get_value("Main", "page_size", 32) as int
	match tab:
		0:  # Doc_Tree
			page_size = G.sett.get_value("Doc_Tree", "page_size", page_size)
		1: # Doc_Thumb
			page_size = G.sett.get_value("Doc_Thumb", "page_size", page_size)
		_:  # Don't change page_size
			return
	G.max_page = round(G.matching_docs.size() as float / page_size as float)
	
	#TODO: This could work better by finding the first page with a certain doc visible on the other browser.
	# Find which page of the new tab shows the same results of the page of the old tab.
	match last_tab:
		0:  # Doc_Tree
			last_page_size = G.sett.get_value("Doc_Tree", "page_size", last_page_size)
		1:  # Doc_Thumb
			last_page_size = G.sett.get_value("Doc_Thumb", "page_size", last_page_size)
		_:
			return
	G.curr_page = remap(G.curr_page, 0, last_page_size, 0, page_size) as int
	%max_page.text = "Pages: " + str(G.max_page)


func _ready() -> void:
	_on_browser_tab_changed.call_deferred()

 
func _on_filter_update():
	_on_browser_tab_changed()
	%counter.text = "Docs: " + str(G.matching_docs.size()) + "\nTags: " + str(G.matching_tags.size())
	
	
	for each in %Tag_List.get_children():
		each.queue_free()
	
	for tag in G.matching_tags:
		var elem = preload("res://Components/tag_element.tscn").instantiate()
		elem.set_tag(tag)
		elem.toggle_mode = true
		elem.add_to_group("matches_tag_group")
		elem.pressed.connect(_on_tag_pressed)
		%Tag_List.add_child(elem)

func _on_tag_pressed():
	get_tree().call_group("respond_select_tag", "_on_selected_tag")
