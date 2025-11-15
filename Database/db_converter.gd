extends RefCounted
class_name DBConverter

## This converts data in an old database to a new one, when we change how they work.

func _init() -> void:
	var old_cont = ConfigFile.new()
	old_cont.load("res://Database/old_docs.cfg")
	var curr_cont = ConfigFile.new()
	curr_cont.load("res://Database/docs.cfg")
	var new_cont = ConfigFile.new()
	new_cont.load("res://Database/new_docs.cfg")
	
	for old_hash in old_cont.get_section_keys("hash_path"):
		var path : String = old_cont.get_value("hash_path", old_hash, "") as String
		var new_hash : String = curr_cont.get_value("path_hash", path, "") as String
		if new_hash.is_empty():
			continue
		
		new_cont.set_value("hash_path", new_hash, path)
		new_cont.set_value("path_hash", path, new_hash)
		
		var hash_tag = old_cont.get_value("hash_tag", old_hash, [])
		new_cont.set_value("hash_tag", new_hash, hash_tag)
		for tag in hash_tag:
			var docs_of_tag = new_cont.get_value("tag_hash", tag, [])
			docs_of_tag.append(tag)
		
		
	new_cont.save("res://Database/new_docs.cfg")
