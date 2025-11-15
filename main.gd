extends Node

func _ready() -> void:
	G.MAIN = self
	get_window().size = G.sett.get_value("Main", "window_size", Vector2(1200, 700))
	get_window().size_changed.connect(_on_window_size_changed)
	%Sidebar_SplitContainer.split_offset = G.sett.get_value("Main", "sidebar_splitter", 0)
	%HSplitContainer.split_offset = G.sett.get_value("Main", "splitter", 0)
	%Browser.current_tab = clampi( G.sett.get_value("Main", "browser_tab", 0), 0, 1 )  #NOTE: This never allows to start the app in the Viewer tab
	%Info.current_tab = G.sett.get_value("Main", "info_tab", 0)
	%Browser.tab_changed.connect(_on_browser_tab_changed)
	%Info.tab_changed.connect(_on_info_tab_changed)
	%Browser_Tools.browser_changed(%Browser.get_tab_title(%Browser.current_tab))

func _on_window_size_changed():
	G.sett.set_value("Main", "window_size", get_window().size)

func _shortcut_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_released():
		match event.keycode:
			KEY_F1:
				%Browser.current_tab = 0
			KEY_F2:
				%Browser.current_tab = 1
			KEY_F3:
				%Browser.current_tab = 2
			KEY_F5:
				%Header.toggle_filter_mode()
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_released():
		match event.button_index:
			MOUSE_BUTTON_XBUTTON1: # Back page or document
				%Browser.get_current_tab_control().back_button_pressed()
			MOUSE_BUTTON_XBUTTON2: # Front page or document
				%Browser.get_current_tab_control().front_button_pressed()


func _on_sidebar_split_container_drag_ended(source: SplitContainer) -> void:
	G.sett.set_value("Main", "sidebar_splitter", source.split_offset)

func _on_h_split_container_drag_ended(source: SplitContainer) -> void:
	G.sett.set_value("Main", "splitter", source.split_offset)


func _on_browser_tab_changed(tab: int) -> void:
	var last_tab = G.sett.get_value("Main", "browser_tab", tab)
	G.sett.set_value("Main", "browser_tab", tab)
	if %Browser.get_tab_title(tab) == "Viewer":
		%Matches.hide()
		%Browser_Tools.hide()
	else:
		%Matches.show()
		%Browser_Tools.show()
		%Browser_Tools.browser_changed(%Browser.get_tab_title(tab))
	get_tree().call_group("Browser", "_on_browser_tab_changed", last_tab)
 
func _on_info_tab_changed(tab: int) -> void:
	G.sett.set_value("Main", "info_tab", tab)
