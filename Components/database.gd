extends VBoxContainer

var tree_root : TreeItem
var thread : Thread
func _ready() -> void:
	thread = Thread.new()
	
	$Buttons.show()
	$Update_Header.hide()

	$Folder_List.set_column_title(0, "Folder Path")
	$Folder_List.set_column_title(1, "Scanned")
	$Folder_List.set_column_title(2, "Files")
	$Folder_List.set_column_expand(0, true)
	$Folder_List.set_column_expand(1, false)
	$Folder_List.set_column_expand(2, false)
	$Folder_List.set_column_custom_minimum_width(1, 80)
	$Folder_List.item_activated.connect(_on_folder_list_item_activated)
	$Folder_List.item_edited.connect(_on_folder_list_item_edited)
	update_folder_list()
	
	$FileDialog.root_subfolder = G.path_to("")


func _on_folder_list_item_activated():
	var item : TreeItem = $Folder_List.get_selected()
	if item.collapsed:
		item.collapsed = false
	else:
		item.set_collapsed_recursive(true)

func _on_folder_list_item_edited():
	var folders = G.sett.get_value("DB", "folders", {})
	for directory : String in folders:
		var path = directory.split("/", false)
		var end_item : TreeItem = walk_tree_path(path, tree_root)
		folders[directory] = end_item.is_checked(0)
	G.sett.set_value("DB", "folders", folders)
	$Folder_List.deselect_all()

func update_folder_list():
	$Folder_List.clear()
	tree_root = $Folder_List.create_item()
	
	var folders = G.sett.get_value("DB", "folders", {})
	for directory : String in folders:
		var path = directory.split("/", false)
		var end_item : TreeItem = walk_tree_path(path, tree_root)
		set_tree_end_item(end_item, path)
		end_item.set_checked(0, folders[directory])
		set_file_count(end_item)

## Return the end item of the tree for a given directory path, creating new tree items if necessary.
func walk_tree_path(directory:PackedStringArray, last:TreeItem):
	# Find if item in tree for given folder already exists.
	# Return its index as child of «last».
	var next_idx : int = -1
	var i : int = 0
	for each in last.get_children():
		if each.get_meta("folder", "") == directory[0]:
			next_idx = i
			break
		i += 1
	
	# The Tree Item child of «last»
	var next : TreeItem
	if next_idx == -1:
		next = last.create_child()
		next.set_meta("folder", directory[0])
		next.set_text(0, directory[0])
	else:
		next = last.get_child(next_idx)
	
	var next_dir = directory.slice(1)  # Find the next folder down the directory.
	if next_dir.is_empty(): # No more folders deep?
		return next # Return the one we made
	else:
		return walk_tree_path(next_dir, next) # Create or find the next folder in the chain.

func set_tree_end_item(item:TreeItem, directory:PackedStringArray):
	item.set_meta("directory", "/".join(directory))
	item.set_tooltip_text(0, "/".join(directory))
	item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	item.set_editable(0, true)
	item.set_text(0, directory[-1])
	item.set_text(1, "NaN")
	item.set_text(2, "NaN")
	item.set_text_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)


func set_file_count(item:TreeItem):
	var folder = item.get_meta("directory")
	var file_count : int = 0
	for file in DirAccess.get_files_at(G.path_to(folder)):
		if not file.get_extension() in ["import", "uid"]:
			file_count += 1
	
	var percent_scanned = DB.doc_count(folder) as float / file_count as float * 100
	
	item.set_text(2, str(file_count))
	item.set_text(1, str(roundi(percent_scanned)) + "%")


var all_check : bool
func _on_tog_folder_pressed() -> void:
	all_check = not all_check
	var folders = G.sett.get_value("DB", "folders", {})
	for directory : String in folders:
		var path = directory.split("/", false)
		var end_item : TreeItem = walk_tree_path(path, tree_root)
		end_item.set_checked(0, all_check)

func _on_rem_folder_pressed() -> void:
	var folders = G.sett.get_value("DB", "folders", {})
	var new_folders : Dictionary = folders.duplicate()
	for directory : String in folders:
		var path = directory.split("/", false)
		var end_item : TreeItem = walk_tree_path(path, tree_root)
		if end_item.is_checked(0):
			new_folders.erase(end_item.get_meta("directory"))
	G.sett.set_value("DB", "folders", new_folders)


var update_cancel := false
func _on_update_cancel_pressed() -> void:
	update_cancel = true

func _on_scan_pressed() -> void:
	update_cancel = false
	$Buttons.hide()
	$Update_Header.show()
	$Update_Header/Warn_Mess.text = "Scanning in Progress:\nSearching New Files"
	$Folder_List.set_column_title(2, "New Files")
	
	var folders = G.sett.get_value("DB", "folders", {})
	for directory : String in folders:
		var path = directory.split("/", false)
		var end_item : TreeItem = walk_tree_path(path, tree_root)
		end_item.set_editable(0, false)
		end_item.set_text(1, "0%")
	
	await get_tree().process_frame
	
	for directory in G.get_folders(true):
		DirAccess.make_dir_recursive_absolute(G.path_to("Thumbnails/" + directory))  # Make sure the directory exists.
		
		var path = directory.split("/", false)
		var end_item : TreeItem = walk_tree_path(path, tree_root)
		
		if not end_item.is_checked(0):
			continue
		var novel_files : PackedStringArray
		for file in DirAccess.get_files_at(G.path_to(directory)):
			if file.get_extension() in ["import", "uid"]:
				continue
			if update_cancel:
				break
			
			var filepath = directory + "/" + file
			
			if not DB.exists(filepath):
				novel_files.append(filepath)
				end_item.set_text(2, str(novel_files.size()))
				await get_tree().process_frame
		var percent_scanned = DB.doc_count(directory) as float / novel_files.size() as float * 100
		end_item.set_text(1, str(roundi(percent_scanned)) + "%")
		
		$Update_Header/Warn_Mess.text = "Scanning in Progress:\nUpdating Database"
		await get_tree().process_frame
		
		for filepath in novel_files:
			if update_cancel:
				break
			
			DB.add_doc(filepath)
			percent_scanned = DB.doc_count(directory) as float / novel_files.size() as float * 100
			end_item.set_text(1, str(roundi(percent_scanned)) + "%")
			var method = G.get_doc_lib(filepath)
			thread.start(method.make_thumbnail.bind(filepath))
			thread.wait_to_finish()
			await get_tree().process_frame
	
	DB.save_database()
	$Buttons.show()
	$Update_Header.hide()
	$Folder_List.set_column_title(2, "Files")
	
	for directory : String in folders:
		var path = directory.split("/", false)
		var end_item : TreeItem = walk_tree_path(path, tree_root)
		end_item.set_editable(0, true)
		set_file_count(end_item)
	
	G.reload_filter()


func _on_cleanup_pressed() -> void:
	# pruning bogus references to files that don't exist and sanitize references to files that don't match up.
	update_cancel = false
	$Buttons.hide()
	$Update_Header.show()
	$Update_Header/Warn_Mess.text = "Cleaning Up Database"
	await get_tree().process_frame
	$Buttons.show()
	$Update_Header.hide()


func _on_add_folder_pressed() -> void:
	$FileDialog.popup()

func _on_file_dialog_dir_selected(dir: String) -> void:
	if OS.has_feature("Editor"):
		dir = ProjectSettings.localize_path(dir).trim_prefix("res://").left(-1)
	else:
		dir = dir.trim_prefix(OS.get_executable_path().get_base_dir() + "/") 
	var curr_folders = G.sett.get_value("DB", "folders", {})
	curr_folders[dir] = true  # This doesn't need to be saved because dictionaries within ConfigFile are passed by reference.
	DirAccess.make_dir_absolute(G.path_to("Thumbnails/"+dir))
	update_folder_list()
