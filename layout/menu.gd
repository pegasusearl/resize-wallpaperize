extends MarginContainer


onready var new_width = $VBoxContainer/HBoxContainer3/PanelContainer/VBoxContainer/GridContainer/Width
onready var new_height = $VBoxContainer/HBoxContainer3/PanelContainer/VBoxContainer/GridContainer/Height
onready var new_path = $VBoxContainer/HBoxContainer3/PanelContainer/VBoxContainer/HBoxContainer/NewPath
onready var new_source_path = $VBoxContainer/HBoxContainer3/PanelContainer/VBoxContainer/HBoxContainer2/SourcePath
onready var cover = $Cover

onready var error_node = $Popup/Error


func _on_Go_pressed():
	CurrentDirectory.source = $VBoxContainer/HBoxContainer2/SourceDir.text
	CurrentDirectory.target = $VBoxContainer/HBoxContainer/TargetDir.text
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
		error_node.dialog_text = str(errors)
		error_node.popup_centered()
		return
	
	# start!!
	open_project(target_path,source_images_path,resolution)


func open_project(target:String,source:String,resolution:Vector2):
	CurrentDirectory.target = target
	CurrentDirectory.new_resolution = resolution
	CurrentDirectory.source = source
	#cover.show()
	get_viewport().size = resolution
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	#OS.window_size = resolution
	return
	get_tree().change_scene("res://layout/main.tscn")
