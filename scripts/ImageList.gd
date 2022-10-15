extends ItemList


onready var image_viewer = get_node("..")
var request_visibility := true setget set_request_visibility
var hover_visibility := true setget set_hover_visibility


func set_hover_visibility(new_visibility:bool):
	hover_visibility = new_visibility
	refresh_visibility()


func set_request_visibility(new_visibility:bool):
	request_visibility = new_visibility
	refresh_visibility()


func refresh_visibility():
	if request_visibility and hover_visibility:
		show()
	else:
		hide()


func _input(event):
	if event is InputEventMouseMotion:
		var mouse_position = get_local_mouse_position()
		set_hover_visibility(mouse_position.x > 0)


var item_list = []

var item_index = {}

var config:ConfigFile
"""
sections:
	image1.png:
		original_hash="" original file hash
		target_hash="" file inside target dir's hash
		settings="" conversion settings
	image2.png:
		original_hash="" original file hash
		target_hash="" file inside target dir's hash
		settings="" conversion settings
"""


func _ready():
	if CurrentDirectory.target == "":
		print("target directory is empty. do nothing.")
		return
	
	var dir := Directory.new()
	
	if not dir.dir_exists(CurrentDirectory.target):
		dir.make_dir_recursive(CurrentDirectory.target)
	
	config = ConfigFile.new()
	config.load(CurrentDirectory.config_path)

	item_list = get_file_list(CurrentDirectory.source)
	item_list.sort()
	re_generate_image_list()


func re_generate_image_list():
	item_index.clear()
	var id := 0
	clear()
	for item in item_list:
		item_index[item] = id
		add_item(get_prefix(item)+item,null)
		set_item_custom_fg_color(id,get_fg_color(item))
		id += 1


func get_prefix(item_name:String):
	if not config.has_section(item_name):
		return "_:"
	var ignored = config.get_value(item_name,"metadata")[9]
	if ignored:
		return "x:"
	else:
		return "1:"


func get_fg_color(item_name:String):
	if not config.has_section(item_name):
		return Color.white
	var ignored = config.get_value(item_name,"metadata")[9]
	if ignored:
		return Color.red
	else:
		return Color.green


func get_file_list(path:String,filter_type:Array=["jpg","png","jpeg"]) -> Array:
	var file_list = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.begins_with("."):
				pass
			elif dir.current_is_dir():
				#print("Found directory: " + file_name)
				pass
			else:
				#print("Found file: " + file_name)
				pass
				if filter_type.has(file_name.get_extension()):
					file_list.append(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return file_list


var current_image := ""
func _on_ImageList_item_selected(index):
	var item_text := get_item_text(index)
	var item_name := item_text.trim_prefix(item_text.split(":")[0]+":" )
	if image_viewer.load_image(CurrentDirectory.source+"/"+item_name) != OK:
		print("image not found:",item_name)
		return
	current_image = item_name
	if config.has_section_key(item_name,"metadata"):
		image_viewer.set_metadata(config.get_value(item_name,"metadata"))


func _on_Save_pressed():
	if current_image == "":
		return
	config.set_value(current_image,"metadata",image_viewer.get_metadata())
	if config.has_section_key(current_image,"converted"):
		config.erase_section_key(current_image,"converted")
	var err = config.save(CurrentDirectory.config_path)
	
	set_item_text(item_index[current_image],get_prefix(current_image)+current_image)
	set_item_custom_fg_color(item_index[current_image],get_fg_color(current_image))

