extends AutoLineEdit

signal family_selected(family:String)

const SIMI_THRES = 0.45  # How strong the seamblance between two tags must be accepted

## Return list of pairs of words, which are text to display as suggestion and the actual token that's added in the prompt if suggestion is selected.
func get_suggestions(token:String) -> Array[PackedStringArray]:
	var sugg : Dictionary[PackedStringArray, float]  # tag: similarity
	if not token.is_empty():
		for fam in DB.tags.get_section_keys("FAMILY"):
			var color = DB.tags.get_value("FAMILY", fam, Color.WHITE)
			var simi = fuzzy_match(fam, token)
			if simi > SIMI_THRES:
				sugg[PackedStringArray([fam, fam, color])] = simi
	
	# Sort by similarity
	var ans = sugg.keys()
	ans.sort_custom(func(a, b):
		return sugg[a] > sugg[b]
		)
	
	return ans

## Add a token to the prompt, allowing for performing any necessary modifications or corrections.
func update_prompt(_prompt:String, token:String) -> String:
	family_selected.emit(token)
	return token
