extends ItemList


onready var image_viewer = get_node("..")
onready var dir = Directory.new()
export var proxy_thumbnail:Texture
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


var last_mouse_hovered := false

func _input(event):
	if event is InputEventMouseMotion:
		var mouse_position = get_local_mouse_position()
		var now_mouse_hovered = mouse_position.x > 0 and mouse_position.y < rect_size.y
		image_viewer.dragging
		if now_mouse_hovered != last_mouse_hovered and not image_viewer.dragging:
			set_hover_visibility(now_mouse_hovered)
		last_mouse_hovered = now_mouse_hovered


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
	return #DISABLER
	randomize()
	config = ConfigFile.new()
	config.load(CurrentDirectory.config_path)
	
	# apply project config
	if config.has_section_key("@$project_data","resolution"):
		get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT,SceneTree.STRETCH_ASPECT_KEEP,config.get_value("@$project_data","resolution"))
	else:
		config.set_value("@$project_data","resolution",CurrentDirectory.new_resolution)
		get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT,SceneTree.STRETCH_ASPECT_KEEP,config.get_value("@$project_data","resolution"))
	if config.has_section_key("@$project_data","source_dir"):
		CurrentDirectory.source = config.get_value("@$project_data","source_dir")
	else:
		config.set_value("@$project_data","source_dir",CurrentDirectory.source)
	
	if CurrentDirectory.target == "":
		print("target directory is empty. do nothing.")
		return
	
	#var dir := Directory.new()
	
	if not dir.dir_exists(CurrentDirectory.target):
		dir.make_dir_recursive(CurrentDirectory.target)

	item_list = get_file_list(CurrentDirectory.source)
	item_list.sort()
	re_generate_image_list()
	prepare_thumbnail(item_list.duplicate(true))
	if get_viewport().size.x > get_viewport().size.y:
		fixed_icon_size.y = 200.0/get_viewport().size.x*get_viewport().size.y
	else:
		fixed_icon_size.x = 200.0/get_viewport().size.y*get_viewport().size.x


func _exit_tree():
	config.save(CurrentDirectory.config_path)


func re_generate_image_list():
	item_index.clear()
	var id := 0
	clear()
	for item in item_list:
		item_index[item] = id
		add_item(get_prefix(item)+item,proxy_thumbnail)
		#set_item_icon(id,proxy_thumbnail)
		set_item_custom_fg_color(id,get_fg_color(item))
		set_item_icon_modulate(id,get_icon_modulate(item))
		id += 1


func get_prefix(item_name:String):
#	if not config.has_section(item_name):
#		return "_:"
	if not config.has_section_key(item_name,"metadata"):
		return "_:"
	var ignored = config.get_value(item_name,"metadata")[9]
	if ignored:
		return "x:"
	else:
		return "1:"


func get_fg_color(item_name:String):
#	if not config.has_section(item_name):
#		return Color.white
	if not config.has_section_key(item_name,"metadata"):
		return Color.white
	var ignored = config.get_value(item_name,"metadata")[9]
	if ignored:
		return Color(0.3,0.3,0.3)
	else:
		return Color.green


func get_icon_modulate(item_name:String):
	if not config.has_section_key(item_name,"metadata"):
		return Color.white
	var ignored = config.get_value(item_name,"metadata")[9]
	if ignored:
		return Color(1,1,1,0.3)
	else:
		return Color.white


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
	return #DISABLER
	if current_image == "":
		return
	config.set_value(current_image,"metadata",image_viewer.get_metadata())
	if config.has_section_key(current_image,"converted"):
		config.erase_section_key(current_image,"converted")
	var err = config.save(CurrentDirectory.config_path)
	
	set_item_text(item_index[current_image],get_prefix(current_image)+current_image)
	set_item_custom_fg_color(item_index[current_image],get_fg_color(current_image))
	set_item_icon_modulate(item_index[current_image],get_icon_modulate(current_image))


### Thumbnail Assigner --------------------------------------------------------

## CONFIG
const USE_THREAD := true


onready var thumbnail_directory := OS.get_user_data_dir()+"/thumbnail"

# magick source.png -quality 92 -define webp:lossless=false -resize 200x200 -strip target.webp

var thumbnail_assign

func prepare_thumbnail(thumbnail_list:Array):
	Thumbnailer.connect("thumbnail_ready",self,"_on_thumbnail_ready")
	Thumbnailer.request_thumbnails(thumbnail_list)


func _on_thumbnail_ready(current_path,thumbnail_path):
	if not USE_THREAD:
		var new_icon := ImageTexture.new()
		new_icon.load(thumbnail_directory+"/"+thumbnail_path)
		set_item_icon(item_index[current_path],new_icon)
		return
	#else:
	queue_thumbnail_to_assign.append([thumbnail_directory+"/"+thumbnail_path,current_path])
	if not assigning_thumbnail:
		assign_thumbnail()


var queue_thumbnail_to_assign:Array = []

var assigning_thumbnail := false
func assign_thumbnail():
	if queue_thumbnail_to_assign.size() == 0:
		return
	assigning_thumbnail = true
	thumbnail_assign = Thread.new()
	thumbnail_assign.start(self,"_thumbnail_assign",queue_thumbnail_to_assign.pop_front())
	yield(self,"thumbnail_assigner_finished")
	yield(get_tree(),"idle_frame") # trying to prevent crash when first time generating thumbnail
	thumbnail_assign.wait_to_finish()
	assigning_thumbnail = false
	call_deferred("assign_thumbnail")


signal thumbnail_assigner_finished
func _thumbnail_assign(input_data:Array):
	var new_icon := ImageTexture.new()
	new_icon.load(input_data[0])
	set_item_icon(item_index[input_data[1]],new_icon)
	emit_signal("thumbnail_assigner_finished")

# ------------------------------------------------------------------------------
