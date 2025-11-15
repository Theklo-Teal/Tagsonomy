extends Node

@onready var docs := ConfigFile.new()
@onready var tags := ConfigFile.new()
@onready var alias := ConfigFile.new()

func _ready() -> void:
	docs.load(G.path_to("Database/docs.cfg"))
	tags.load(G.path_to("Database/tags.cfg"))
	alias.load(G.path_to("Database/alias.cfg"))

func save_database():
	docs.save(G.path_to("Database/docs.cfg"))
	tags.save(G.path_to("Database/tags.cfg"))
	alias.save(G.path_to("Database/alias.cfg"))


#region Test Things
func make_hash(filepath:String) -> String:
	var the_hash = hash(FileAccess.get_file_as_bytes(filepath))
	return String.num_uint64(the_hash, 16, true)

## Is one of the given files acknowledged in the database?
func exists(doc:String, is_hash:=false) -> bool:
	# Make sure that both the reference and back-reference agree.
	var hash_exists := false
	var path_exists := false
	if is_hash:
		var filepath = docs.get_value("hash_path", doc, "")
		path_exists = filepath.is_empty()
		hash_exists = docs.has_section_key("path_hash", filepath)
	else:
		var the_hash = docs.get_value("path_hash", doc, "") 
		hash_exists = the_hash.is_empty()
		path_exists = docs.has_section_key("hash_path", the_hash)
	
	return hash_exists and path_exists

func doc_count(folder_path:String) -> int:
	var ans : int = 0
	if docs.has_section("path_hash"):
		for each in docs.get_section_keys("path_hash"):
			if each.get_base_dir() == folder_path:
				ans += 1
	return ans
#endregion

#region Doc Modification
func add_doc(filepath:String, data:Dictionary={}):
	var the_hash = make_hash(filepath)
	docs.set_value("path_hash", filepath, the_hash)
	docs.set_value("hash_path", the_hash, filepath)
	
	#NOTE: Don't clear existing tag associations if the happen to exist.
	#NOTE: Prioritize «data["tags"]» is available, as a way to override database.
	var tags_of_doc = data.get(data["tags"], docs.get_value("hash_tag", the_hash, []))
	docs.set_value("hash_tag", the_hash, tags_of_doc)
	for tag in tags_of_doc:
		add_tag_to(filepath, tag)

func rem_doc(doc:String, is_hash:=false) -> Dictionary:
	if exists(doc, is_hash):
		return {}
	
	var data : Dictionary
	var filepath : String
	if is_hash:
		filepath = docs.get_value("hash_path", doc, "")
	else:
		filepath = doc
		doc = docs.get_value("path_hash", doc, "")
	
	docs.erase_section_key("path_hash", filepath)
	docs.erase_section_key("hash_path", doc)
	
	var tags_of_doc = docs.get_value("hash_tag", doc, [])
	data["tags"] = tags_of_doc
	
	for tag in tags_of_doc:
		var doc_list : Array = docs.get_value("tag_hash", tag, [])
		doc_list.erase(doc)
		docs.set_value("tag_hash", tag, doc_list)
	docs.erase_section_key("hash_tag", doc)
	
	return data

func rename_doc(from:String, to:String):
	add_doc(to, rem_doc(from, false))
#endregion

#region Tag Modification

func add_tag_to(doc:String, tag:String, is_hash:=false):
	if tag in G.get_fake_tags():
		# Don't allow to mess with exceptional tags.
		return
	
	var docs_of_tag = docs.get_value("tag_hash", tag, [])
	if docs_of_tag.is_empty():
		if not DB.tags.has_section(tag):
			# Don't add tags to things if the tag hasn't been established
			return
		
	if not is_hash:
		doc = docs.get_value("path_hash", doc)
		
	var curr_tags = docs.get_value("hash_tag", doc, [])
	
	if curr_tags.is_empty():
		curr_tags = [tag, ]
	elif not tag in curr_tags:
		curr_tags.append(tag)
	if not doc in docs_of_tag:
		docs_of_tag.append(doc)
	
	docs.set_value("hash_tag", doc, curr_tags)
	docs.set_value("tag_hash", tag, docs_of_tag)


func remove_tag_from(doc:String, tag:String, is_hash:=false):
	if not is_hash:
		doc = docs.get_value("path_hash", doc)
	var curr_tags : Array = docs.get_value("hash_tag", doc, [])
	var docs_of_tag : Array = docs.get_value("tag_hash", tag, [])
	curr_tags.erase(tag)
	docs_of_tag.erase(doc)


func add_tag(tag:String, data:Dictionary={}):
	if tag in G.get_fake_tags():
		# Don't allow to mess with exceptional tags.
		return
	
	tags.set_value(tag, "description", data.get("description", ""))
	tags.set_value(tag, "family", data.get("family", "None"))
	tags.set_value(tag, "semantics", data.get("semantics", []))
	
	var a = data.get("alias", [])
	alias.set_value("PREFER", tag, a)
	if not a.is_empty():
		for synon in a:
			alias.set_value("SYNON", synon, tag)
	
	for doc in data.get("docs", []):
		add_tag_to(doc, tag, true)

func rem_tag(tag:String) -> Dictionary:
	if tag == "favorite":
		# Don't allow to remove favorite
		return {}
	var data : Dictionary
	for key in tags.get_section_keys(tag):
		data[key] = tags.get_value(tag, key)
	data["alias"] = alias.get_value("PREFER", tag)
	
	alias.erase_section_key("PREFER", tag)
	for synon in alias.get_section_keys("SYNON"):
		alias.erase_section_key("SYNON", synon)
	
	data["docs"] = docs.get_value("tag_hash", tag, [])
	for doc in data["docs"]:
		remove_tag_from(doc, tag, true)
	docs.erase_section_key("tag_hash", tag)
	tags.erase_section(tag)
	
	return data

func rename_tag(from:String, to:String):
	var data = rem_tag(from)
	add_tag(to, data)
	for doc in data["docs"]:
		remove_tag_from(doc, from, true)
		add_tag_to(doc, to, true)
#endregion
