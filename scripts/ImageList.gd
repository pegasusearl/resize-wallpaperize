extends ItemList


onready var image_viewer = get_node("..")
onready var dir = Directory.new()
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
	randomize()
	if CurrentDirectory.target == "":
		print("target directory is empty. do nothing.")
		return
	
	#var dir := Directory.new()
	
	#THUMBNAIL
	dir.make_dir_recursive(thumbnail_directory)
	
	if not dir.dir_exists(CurrentDirectory.target):
		dir.make_dir_recursive(CurrentDirectory.target)
	
	config = ConfigFile.new()
	config.load(CurrentDirectory.config_path)

	item_list = get_file_list(CurrentDirectory.source)
	item_list.sort()
	thumbnail_queue = item_list.duplicate(true)
	re_generate_image_list()
	refresh_thumbnail()
	fixed_icon_size.y = 200.0/get_viewport().size.x*get_viewport().size.y


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


### Thumbnail Generator --------------------------------------------------------

# generate thumbnail filename and target path in user://, check if there is any 
# image that has not assigned thumbnail path and add it.
# save them in Config.section
# put all image in the queue
# then generate thumbnail based on this queue in separate thread.
# check if thumbnail already exist before actually generating it, incase it's
# generated when saving config. Or it's already generated in previous run.

var thumbnail_queue := []
onready var thumbnail_directory := OS.get_user_data_dir()+"/thumbnail"

# magick source.png -quality 92 -define webp:lossless=false -resize 200x200 -strip target.webp

signal bot_thumbnail_finished


var thumbnail_bot
var thumbnail_assign

var processing_thumbnail := false
func refresh_thumbnail():
	if processing_thumbnail or thumbnail_queue.size() == 0:
		print("thumbnail operation stopped")
		return
	processing_thumbnail = true
	var working_thumbnail:String = thumbnail_queue.pop_front()
	var source_fullpath := CurrentDirectory.source+"/"+working_thumbnail
	var thumbnail_name := str("/",randi(),"_",working_thumbnail,".webp")
	
	if config.has_section_key(working_thumbnail,"tb"):
		thumbnail_name = config.get_value(working_thumbnail,"tb")
	else:
		config.set_value(working_thumbnail,"tb",thumbnail_name)
		config.save(CurrentDirectory.config_path)
	
	var thumbnail_fullpath := thumbnail_directory+thumbnail_name
	
	if not dir.file_exists(thumbnail_fullpath):
		thumbnail_bot = Thread.new()
		thumbnail_bot.start(self,"_thumbnail_convert",[source_fullpath,thumbnail_fullpath])
		yield(self,"bot_thumbnail_finished")
		thumbnail_bot.wait_to_finish()
	
	thumbnail_assign = Thread.new()
	thumbnail_assign.start(self,"_thumbnail_assign",[thumbnail_fullpath,working_thumbnail])
	yield(self,"bot_thumbnail_finished")
	thumbnail_assign.wait_to_finish()
	
	processing_thumbnail = false
	refresh_thumbnail()


func _thumbnail_convert(input_data:Array):
	image_viewer.run_command("magick",[input_data[0],"-quality","92","-define","webp:lossless=false","-resize","200x200","-strip",input_data[1]])
	emit_signal("bot_thumbnail_finished")


func _thumbnail_assign(input_data:Array):
	var new_icon := ImageTexture.new()
	new_icon.load(input_data[0])
	set_item_icon(item_index[input_data[1]],new_icon)
	emit_signal("bot_thumbnail_finished")

# ------------------------------------------------------------------------------
