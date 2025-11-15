extends DocLib

const THUMB_COUNT = 16

func _init() -> void:
	color = Color("4a88bfff")

func get_viewer():
	return preload("viewer.tscn").instantiate()

func make_thumbnail(filepath:String):
	var stdout : Array
	var the_hash_path = filepath.get_base_dir() + "/" + DB.docs.get_value("path_hash", filepath)
	var in_path = OS.get_executable_path().get_base_dir() + "/" + filepath
	var out_path = OS.get_executable_path().get_base_dir() + "/Thumbnails/" + the_hash_path + ".jpg"
	if OS.has_feature("editor"):
		in_path = "/home/vex/Documents/Scripts/GODOT/Tagsonomy/" + filepath
		out_path = "/home/vex/Documents/Scripts/GODOT/Tagsonomy/Thumbnails/" + the_hash_path + ".jpg"
	var exit_code = OS.execute("Database/video_mosaic.sh", [in_path, out_path, THUMB_SIZE, THUMB_COUNT], stdout, true)
	if exit_code > 1:
		var err_file = FileAccess.open(G.path_to("video_thumbnail_stdout.txt"), FileAccess.WRITE)
		stdout.push_front("Thumbnail Mosaic Path: " + out_path)
		stdout.push_front("Original Video Path: " + in_path)
		stdout.push_front("Doc Path: " + filepath)
		stdout.push_front("Linux Exit Code: " + str(exit_code))
		err_file.store_string("\n".join(stdout))


func get_static_thumbnail(filepath:String) -> Texture2D:
	var the_hash_path = filepath.get_base_dir() + "/" + DB.docs.get_value("path_hash", filepath)
	the_hash_path = G.path_to( "Thumbnails/" + the_hash_path + ".jpg" )
	
	if FileAccess.file_exists(the_hash_path):
		var base_texture = Image.load_from_file(the_hash_path)
		base_texture = ImageTexture.create_from_image(base_texture)
	
		var atlas = AtlasTexture.new()
		atlas.atlas = base_texture
		atlas.region.size = Vector2.ONE * THUMB_SIZE
		atlas.region.position = Vector2.ONE * THUMB_SIZE * floor(sqrt(THUMB_COUNT) * 0.5)
		return atlas
	else:
		return preload("res://assets/MISSING.png")

func get_fancy_thumbnail(filepath:String) -> Control:
	var obj = preload("res://Components/format_lib/thumbnail.tscn").instantiate()
	obj.get_node("%TextureRect").texture = get_static_thumbnail(filepath)
	obj.frame_count = THUMB_COUNT
	obj.curr_frame = 0
	return obj
