extends RefCounted
class_name DocLib

const THUMB_SIZE = 192
var color : Color


func set_doc(_filepath:String):
	pass

func make_thumbnail(_filepath:String):
	pass

func get_static_thumbnail(_filepath:String) -> Texture2D:
	return load("res://assets/MISSING.png")

func get_fancy_thumbnail(filepath:String) -> Control:
	var obj = TextureRect.new()
	obj.texture = get_static_thumbnail(filepath)
	return obj

func get_viewer():
	pass
