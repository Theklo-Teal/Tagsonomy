extends Node

var MAIN : Node
var curr_page : int = 0 : 
	set(val):
		curr_page = clamp(val, 0, max_page)
		get_tree().call_group("Browser", "_on_page_changed")
var max_page : int = 0 : 
	set(val):
		max_page = abs(val)


var matching_docs : Array[String]  # List of filepaths that fulfill set filter
var matching_tags : Array[String]  # tags of the docs that fulfill set filter

var filter : Dictionary[String, PackedStringArray] = {
	"neutral":[],  # A doc must match all of these tags to be accepted.
	"negative":[],  # A doc is rejected if it matches any of these tags.
	"positive":[]  # A doc that matches has any of these tags.
}

func reload_filter():
	update_filter(filter.neutral, filter.negative, filter.positive)

func update_filter(neu:PackedStringArray = [], neg:PackedStringArray = [], pos:PackedStringArray = []):
	filter.neutral = neu
	filter.negative = neg
	filter.positive = pos
	
	var neg_hashes : Array[String]  # List of hashes that fulfill the negative filter.
	for the_hash in DB.docs.get_section_keys("hash_path"):
		var reject : bool = false
		var tags_of_doc := get_fake_tags(the_hash, true)
		tags_of_doc.append_array( DB.docs.get_value("hash_tag", the_hash, []) )
		for tag_of_doc in tags_of_doc:
			if tag_of_doc in neg:
				reject = true
				break
		if not reject:
			neg_hashes.append(the_hash)
	
	var hashes : Array[String]  # List of hashes that fulfill the positive and neutral filter.
	for the_hash in neg_hashes:
		var reject : bool = false
		var accepted : bool = false
		var tags_of_doc := get_fake_tags(the_hash, true)
		tags_of_doc.append_array( DB.docs.get_value("hash_tag", the_hash, []) )
		for tag in filter.positive:
			if tag in tags_of_doc:
				accepted = true
				break
		if not accepted:
			for tag in filter.neutral:
				if not tag in tags_of_doc:
					reject = true
					break
		if not reject:
			hashes.append(the_hash)
	
	# Translating hashes to filepaths and placing them in the list.
	matching_docs.clear()
	matching_tags.clear()
	for doc in hashes:
		var path = DB.docs.get_value("hash_path", doc)
		matching_docs.append(path)
		
		var tags_of_doc := get_fake_tags(doc, true)
		tags_of_doc.append_array( DB.docs.get_value("hash_tag", doc, []) )
		
		for tag in tags_of_doc:
			if not tag in matching_tags:
				matching_tags.append(tag)
	
	# Sorting things out
	var foo : Array[String]
	foo.append_array(sort_tags(matching_tags))
	matching_tags = foo
	
	matching_docs.sort_custom(
		func(a,b):
			return a.naturalnocasecmp_to(b) < 1
	)
	matching_docs.sort_custom(
		func(a,b):
			return FileAccess.get_size(a) < FileAccess.get_size(b)
	)
	
	get_tree().call_group("Browser", "_on_filter_update")

func sort_tags(tags:Array[String]) -> PackedStringArray:
	# Sort alphabetically first
	tags.sort_custom(func(a, b):
		return a.filenocasecmp_to(b) < 0
		)
	# Then sort by family
	tags.sort_custom(func(a, b):
		var fam_a = DB.tags.get_value(a, "family", "None").to_lower()
		var fam_b = DB.tags.get_value(b, "family", "None").to_lower()
		var to_top = [
			fam_a == "meta",
			fam_b == "none",
		]
		var to_bottom = [
			fam_a == "none",
			fam_b == "meta",
		]
		
		if fam_a == fam_b:
			# Make sure we preserve the alphabetic order.
			return a.filenocasecmp_to(b) < 0
		else:
			if true in to_top:
				return true
			if true in to_bottom:
				return false
			
		return fam_a.filenocasecmp_to(fam_b) < 0
		)
	return PackedStringArray(tags)


## Returns exceptional tags that are automatically associated to docs, rather than the user deciding.
## You can provide a doc to only return tags that apply to that doc, otherwise return all possible fake tags.
func get_fake_tags(doc:String="", is_hash:bool=false) -> PackedStringArray:
	var tags : PackedStringArray
		
	if not doc.is_empty():
		if not is_hash:
			doc = DB.docs.get_value("path_hash", doc)
			
		if DB.docs.get_value("hash_tag", doc, []).is_empty():
			tags.append("untagged")
		tags.append(get_doc_type(doc, true).to_lower())
	else:
		tags.append("untagged")
		for method in doc_libs:
			tags.append(method.to_lower())
	return tags


var selected_index : int
var selected_doc : String 
## For when you know the filepath to the doc, but not the index in «matching_docs»
func select_doc_path(filepath:String):
	selected_index = matching_docs.find(filepath)
	selected_doc = filepath
	get_tree().call_group("respond_select_doc", "_on_selected_doc")
## When you know the index of the doc in «matching_docs», but not the filepath
func select_doc_index(idx:int):
	selected_index = wrapi(idx, 0, matching_docs.size())
	selected_doc = matching_docs[selected_index]
	get_tree().call_group("respond_select_doc", "_on_selected_doc")

@onready var sett := ConfigFile.new()
@onready var doc_libs : Dictionary = {
	"Pictures": load("res://Components/format_lib/Pictures/lib.gd").new(),
	"Videos": load("res://Components/format_lib/Videos/lib.gd").new(),
	}

func _ready() -> void:
	sett.load(G.path_to("settings.ini"))
	
	# Make sure thumbnail folders exist.
	var thumbnails_dir = path_to("Thumbnails")
	if not DirAccess.dir_exists_absolute(thumbnails_dir):
		DirAccess.make_dir_absolute(thumbnails_dir)
	for folder in sett.get_value("DB", "folders", {}):
		folder = path_to("Thumbnails/"+folder)
		if not DirAccess.dir_exists_absolute(folder):
			DirAccess.make_dir_absolute(folder)
	
	# Make sure file base directories exist.
	for each in doc_libs:
		var directory = path_to(each)
		var thumb_dir = path_to("Thumbnails/"+each)
		if not DirAccess.dir_exists_absolute(directory):
			DirAccess.make_dir_absolute(directory)
		if not DirAccess.dir_exists_absolute(thumb_dir):
			DirAccess.make_dir_absolute(thumb_dir)
		
	
	# Make sure the Database folder exists.
	var database_dir = path_to("Database")
	if not DirAccess.dir_exists_absolute(database_dir):
		DirAccess.make_dir_absolute(database_dir)
	
	update_filter.call_deferred()

func _exit_tree() -> void:
	sett.save(G.path_to("settings.ini"))

## When accessing files outside the executable on an exported project, the file paths need to be different.
## This function handles that for you.
func path_to(filepath:String):
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path(filepath)
	else:
		return OS.get_executable_path().get_base_dir().path_join(filepath)

## Get a list of folders where docs are kept. Pass «true» to get only those set for scanning.
func get_folders(checked_only:bool = false) -> PackedStringArray:
	var ans : PackedStringArray
	var all_folders = sett.get_value("DB", "folders", [])
	for each in all_folders:
		if not checked_only or all_folders[each] == true:
			ans.append(each)
	return ans


func get_doc_type(doc:String, is_hash:bool=false) -> String:
	var filepath = doc
	if is_hash:
		filepath = DB.docs.get_value("hash_path", doc)
	var pos = filepath.find("/")
	return filepath.left(pos)
	
func get_doc_lib(filepath:String) -> DocLib:
	return doc_libs[get_doc_type(filepath)]


enum RMB{
	OPEN,
	SET_FAV,
	TO_TRASH,
}
