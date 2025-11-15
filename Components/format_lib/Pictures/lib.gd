extends DocLib

func _init() -> void:
	color = Color("9c9c9cff")

func get_viewer():
	return preload("viewer.tscn").instantiate()

func make_thumbnail(filepath:String):
	var the_hash_path = filepath.get_base_dir() + "/" + DB.docs.get_value("path_hash", filepath)
	var tgt_path = "Thumbnails/" + the_hash_path + ".jpg"
	var raw_doc = Image.load_from_file(G.path_to(filepath))
	var raw_size = raw_doc.get_size()
	var new_size = raw_size * (float(THUMB_SIZE) / min(raw_size.x, raw_size.y))
	raw_doc.resize(new_size.x, new_size.y, Image.INTERPOLATE_NEAREST)
	var offset : int = floori(abs(new_size.y - new_size.x) * 0.5)
	if raw_size.aspect() > 1:  # Wide picture
		raw_doc = raw_doc.get_region(Rect2i(Vector2i(offset, 0), Vector2i.ONE * THUMB_SIZE))
	elif raw_size.aspect() < 1:  # Tall picture
		raw_doc = raw_doc.get_region(Rect2i(Vector2i(0, offset), Vector2i.ONE * THUMB_SIZE))
	raw_doc.save_jpg(G.path_to(tgt_path), 0.7)

func get_static_thumbnail(filepath:String) -> Texture2D:
	var the_hash_path = filepath.get_base_dir() + "/" + DB.docs.get_value("path_hash", filepath)
	the_hash_path = G.path_to( "Thumbnails/" + the_hash_path + ".jpg" )
	if FileAccess.file_exists(the_hash_path):
		var base_texture = Image.load_from_file(the_hash_path)
		return ImageTexture.create_from_image(base_texture)
	else:
		return preload("res://assets/MISSING.png")

func get_fancy_thumbnail(filepath:String) -> Control:
	var obj = preload("res://Components/format_lib/thumbnail.tscn").instantiate()
	obj.get_node("%TextureRect").texture = get_static_thumbnail(filepath)
	return obj
