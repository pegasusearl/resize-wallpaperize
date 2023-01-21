extends MarginContainer


onready var new_width = $Pages/Projects/HBoxContainer3/PanelContainer/VBoxContainer/GridContainer/Width
onready var new_height = $Pages/Projects/HBoxContainer3/PanelContainer/VBoxContainer/GridContainer/Height
onready var new_path = $Pages/Projects/HBoxContainer3/PanelContainer/VBoxContainer/HBoxContainer/NewPath
onready var new_source_path = $Pages/Projects/HBoxContainer3/PanelContainer/VBoxContainer/HBoxContainer2/SourcePath

onready var error_node = $Popup/Error
onready var recent_project_node = $Pages/Projects/HBoxContainer3/PanelContainer2/VBoxContainer/RecentProjectList
onready var settings = ConfigFile.new()

#file manager
onready var new_project_fm = $Popup/NewProject
onready var open_project_fm = $Popup/OpenProject
onready var source_dir_fm = $Popup/SourceDir

func _ready():
	settings.load("user://settings.cfg")
	
	var pictures_dir:String = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	
	initialize_folder_dialog(new_project_fm,"new_project_dir",pictures_dir)
	initialize_folder_dialog(open_project_fm,"open_project_dir",pictures_dir)
	initialize_folder_dialog(source_dir_fm,"source_dir",pictures_dir)
	
	if settings.has_section_key("history","list"):
		for entry in settings.get_value("history","list"):
			recent_project_node.add_item(entry)


func initialize_folder_dialog(folder_dialog:FileDialog,save_name:String,fallback_dir:String):
	if settings.has_section_key("history",save_name):
		folder_dialog.current_dir = settings.get_value("history",save_name)
	else:
		folder_dialog.current_dir = fallback_dir


func _exit_tree():
	settings.set_value("history","new_project_dir",new_project_fm.current_dir)
	settings.set_value("history","open_project_dir",open_project_fm.current_dir)
	settings.set_value("history","source_dir",source_dir_fm.current_dir)
	settings.save("user://settings.cfg")


func _on_Go_pressed():
	CurrentDirectory.source = $Pages/Projects/HBoxContainer2/SourceDir.text
	CurrentDirectory.target = $Pages/Projects/HBoxContainer/TargetDir.text
	get_tree().change_scene("res://layout/main.tscn")


func dir_contents(path):
	var dir = Directory.new()
	var count := 0
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.begins_with("."):
				pass
			else:
				count += 1
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		return -1
	return count


func scan_images_in_dir(path):
	var dir = Directory.new()
	var count := 0
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.begins_with("."):
				pass
			elif ["png","jpg","jpeg"].has(file_name.get_extension()):
				count += 1
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		return -1
	return count


func _on_CreateNew_pressed():
	var errors := []
	var dir = Directory.new()
	
	var target_path:String = new_path.text.rstrip("/")
	var target_cfg_path:String = target_path+"/"+"wallpaperize.cfg"
	var source_images_path:String = new_source_path.text.rstrip("/")
	var item_inside_folder_count:int = dir_contents(new_path.text)
	var image_count:int = scan_images_in_dir(source_images_path)
	
	if new_path.text == "":
		errors.append("Target directory is not specified.")
	if not dir.dir_exists(new_path.text):
		errors.append("Target directory "+new_path.text+" does not exist.")
	elif dir.file_exists(target_cfg_path):
		errors.append("wallpaperize.cfg already exist in "+new_path.text)
	if item_inside_folder_count > 0:
		errors.append("Target directory is not empty. (There are "+str(item_inside_folder_count)+" files)")
	elif item_inside_folder_count < 0:
		errors.append("Error when accessing target directory.")
	
	if image_count == 0:
		errors.append("There is no image in image folder source.")
	elif image_count < 0:
		errors.append("Something wrong when trying to access image folder source.")
	
	
	var resolution := Vector2(1920,1080)
	if new_width.text != "":
		resolution.x = int(new_width.text)
	if new_height.text != "":
		resolution.y = int(new_height.text)
	
	if errors.size() > 0:
		error_node.dialog_text = ""
		for error_message in errors:
			error_node.dialog_text += error_message+"\n"
		error_node.popup_centered()
		return
	
	# start!!
	open_project(target_path,source_images_path,resolution)


func open_project(target:String,source:String,resolution:Vector2):
	CurrentDirectory.target = target
	CurrentDirectory.new_resolution = resolution
	CurrentDirectory.source = source
	var new_history = settings.get_value("history","list",[])
	new_history.push_front(target)
	settings.set_value("history","list",new_history)
	get_tree().change_scene("res://layout/main.tscn")


func _on_OpenProject_dir_selected(dir):
	dir = dir.rstrip("/")
	CurrentDirectory.target = dir
	var new_history:Array = settings.get_value("history","list",[])
	new_history.erase(dir)
	new_history.push_front(dir)
	settings.set_value("history","list",new_history)
	get_tree().change_scene("res://layout/main.tscn")


func _on_OpenProject_file_selected(path):
	_on_OpenProject_dir_selected(path.rstrip("wallpaperize.cfg"))


func _on_RecentProjectList_item_activated(index):
	_on_OpenProject_dir_selected(recent_project_node.get_item_text(index))
