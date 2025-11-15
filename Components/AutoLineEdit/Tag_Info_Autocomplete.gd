extends AutoLineEdit

const SIMI_THRES = 0.45  # How strong the seamblance between two tags must be accepted

func get_suggestions(token:String) -> Array[PackedStringArray]:
	var sugg : Dictionary[PackedStringArray, float]  # tag: similarity
	if not token.is_empty():
		token = get_token_tag(token.to_lower())
		for tag in DB.alias.get_section_keys("PREFER") + DB.alias.get_section_keys("SYNON"):
			var simi = fuzzy_match(token, tag)
			if simi > SIMI_THRES:
				var prefer = DB.alias.get_value("SYNON", tag, tag)
				var new_sugg : PackedStringArray = [prefer, prefer, ""]
				if prefer != tag:
					new_sugg = [tag + " -> " + prefer, prefer, ""]
				sugg[new_sugg] = simi
	# The answer is the pair of "similar tag" and "preferred tag".
	var ans : Array[PackedStringArray] = sugg.keys()
	# Sort according to similarity
	ans.sort_custom(func(a, b): return sugg[a] > sugg[b])
	return ans

func update_prompt(prompt:String, added:String):
	var tokens = prompt.split(" ", false)
	tokens[-1] = tokens[-1].strip_edges()
	var prefix = get_token_prefix(tokens[-1])
	tokens[-1] = prefix + added
	return " ".join(tokens)


func sanitize_prompt(prompt:String) -> String:
	var tokens = prompt.split(" ", false)
	var prefixes : Array[String]
	var tags : Array[String]
	for token in tokens:
		var tag = get_token_tag(token)
		tag = DB.alias.get_value("SYNON", tag, tag).to_lower()
		if tag in tags:
			continue
		else:
			tags.append(tag)
		var prefix = get_token_prefix(token)
		if "-" in prefix:
			prefix = "-"
		if "+" in prefix:
			prefix = "+"
		prefixes.append(prefix)
	
	var ans : String = ""
	for n in range(tags.size()):
		ans += prefixes[n] + tags[n] + " "
	return ans


## RexEx expression will ignore any character from the start of the string until an alphanumeric appears, then accept «-» and «_» in the middle of alphanumerics.
func get_token_tag(token:String):
	var expr = RegEx.create_from_string("^[^a-z0-9]*([\\w\\'\\(\\)\\[\\]-]+)")
	var capture = expr.search(token)
	if capture == null:
		return ""
	else:
		return capture.get_string(1)

func get_token_prefix(token:String) -> String:
	var expr = RegEx.create_from_string("^\\W*?(?=[a-z0-9])")
	var capture = expr.search(token)
	if capture == null:
		return ""
	else:
		return capture.get_string(0)
