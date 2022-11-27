extends VBoxContainer


onready var config:ConfigFile = ConfigFile.new()
onready var dir = Directory.new()
onready var item_list_node = $ItemList
onready var categories_node = $Categories
onready var image_viewer = get_node("..")
export var proxy_thumbnail:Texture
var item_list := {}
var item_list_search_index := {}
var item_list_viewer_index := {}


func _ready():
	randomize()
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
	
	
	# only continue if target directory is set
	if CurrentDirectory.target == "":
		print("target directory is empty. do nothing.")
		return
	
	# make the directory if it's not already exist yet
	if not dir.dir_exists(CurrentDirectory.target):
		dir.make_dir_recursive(CurrentDirectory.target)
	
	
	# Get list of files in Source directory
	item_list.clear()
	item_list_search_index.clear()
	var thumbnail_list := []
	for item_name in get_file_list(CurrentDirectory.source):
		item_list[item_name] = {}
		thumbnail_list.append(item_name)
		# generate search index
		var current_search_keyword := ""
		for letter in item_name:
			current_search_keyword += letter.to_lower()
			if not item_list_search_index.has(current_search_keyword):
				item_list_search_index[current_search_keyword] = []
			item_list_search_index[current_search_keyword].append(item_name)
	
	print_image_list()
	prepare_thumbnail(thumbnail_list)


var print_keyword_filter:String = ""
var category:int = 0
enum Category {ALL,IGNORED,UNTOUCHED,ASSIGNED}
func print_image_list():
	item_list_node.clear()
	item_list_viewer_index.clear()
	
	var item_id := 0
	if print_keyword_filter != "" and item_list_search_index.has(print_keyword_filter):
		var list:Array = _strip_list_with_category(item_list_search_index[print_keyword_filter])
		for key in list:
			_add_item_to_item_list_node(item_id,key)
			item_id += 1
	else:
		var list:Array = []
		for key in item_list:
			list.append(key)
		list = _strip_list_with_category(list)
		for key in list:
			_add_item_to_item_list_node(item_id,key)
			item_id += 1
	
	if current_image != "" and item_list_viewer_index.has(current_image):
		pause_selection = true
		item_list_node.select(item_list_viewer_index[current_image])
		item_list_node.ensure_current_is_visible()
		pause_selection = false


func _strip_list_with_category(list:Array) -> Array:
	if category == Category.ALL:
		return list.duplicate()
	var new_list := []
	for key in list:
		if _get_category(key) == category:
			new_list.append(key)
	return new_list


func _add_item_to_item_list_node(id:int,new_item_name:String):
	item_list_viewer_index[new_item_name] = id
	item_list_node.add_item(new_item_name)
	if item_list[new_item_name].has("thumb"):
		item_list_node.set_item_icon(id,item_list[new_item_name]["thumb"])
	else:
		item_list_node.set_item_icon(id,proxy_thumbnail)
	item_list_node.set_item_custom_fg_color(id,_get_fg_color(new_item_name))
	item_list_node.set_item_icon_modulate(id,_get_icon_modulate(new_item_name))


func _get_fg_color(item_name:String) -> Color:
	match _get_category(item_name):
		Category.UNTOUCHED:
			return Color.white
		Category.IGNORED:
			return Color(0.3,0.3,0.3)
		Category.ASSIGNED:
			return Color.green
	return Color.white


func _get_icon_modulate(item_name:String) -> Color:
	match _get_category(item_name):
		Category.UNTOUCHED:
			return Color.white
		Category.IGNORED:
			return Color(1,1,1,0.3)
		Category.ASSIGNED:
			return Color.white
	return Color.white


func _get_category(item_name:String) -> int:
	if not config.has_section_key(item_name,"metadata"):
		return Category.UNTOUCHED
	else:
		if config.get_value(item_name,"metadata")[9]:
			return Category.IGNORED
		else:
			return Category.ASSIGNED


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
		#set_item_icon(item_index[current_path],new_icon)
		#item_list[current_path]["thumb"] = new_icon
		_new_thumbnail_generated(current_path,new_icon)
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
	#set_item_icon(item_index[input_data[1]],new_icon)
	#item_list[input_data[1]]["thumb"] = new_icon
	_new_thumbnail_generated(input_data[1],new_icon)
	emit_signal("thumbnail_assigner_finished")


func _new_thumbnail_generated(key:String,thumbnail:ImageTexture):
	item_list[key]["thumb"] = thumbnail
	#if the already printed items thumbnail already generated
	if item_list_viewer_index.has(key):
		item_list_node.set_item_icon(item_list_viewer_index[key],thumbnail)

# ------------------------------------------------------------------------------


func _on_LineEdit_text_entered(new_text:String):
	print_keyword_filter = new_text.to_lower()
	print_image_list()


var current_image := ""
var pause_selection := false
func _on_ItemList_item_selected(index:int):
	if pause_selection: # used by print_image_list()
		return
	var item_name = item_list_node.get_item_text(index)
	if image_viewer.load_image(CurrentDirectory.source+"/"+item_name) != OK:
		print("image not found:",item_name)
		return
	current_image = item_name
	if config.has_section_key(item_name,"metadata"):
		image_viewer.set_metadata(config.get_value(item_name,"metadata"))


func _on_categories_selected(extra_arg_0:int):
	for child in categories_node.get_children():
		child.disabled = false
	category = extra_arg_0
	categories_node.get_children()[extra_arg_0].disabled = true
	print_image_list()


func _on_Save_pressed():
	if current_image == "":
		return
	config.set_value(current_image,"metadata",image_viewer.get_metadata())
	if config.has_section_key(current_image,"converted"):
		config.erase_section_key(current_image,"converted")
	var err = config.save(CurrentDirectory.config_path)
	
	item_list_node.set_item_custom_fg_color(item_list_viewer_index[current_image],_get_fg_color(current_image))
	item_list_node.set_item_icon_modulate(item_list_viewer_index[current_image],_get_icon_modulate(current_image))


#-=========================
# visibility

var shift_visibility := true setget set_shift_visibility
var hover_visibility := true


func _input(event):
	if image_viewer.dragging:
		pass
	elif (event is InputEventMouseMotion):
		hover_visibility = _is_mouse_inside() and (not is_in_cooldown or visible)
		_refresh_visibility()
	
	if event is InputEventMouseButton and not event.pressed and _is_mouse_inside():
		start_cooldown()


const COOLDOWN := 0.8
var cooldown := 0.0
var is_in_cooldown := false
func _process(delta):
	cooldown -= delta
	if cooldown < 0.0:
		cooldown = 0.0
		is_in_cooldown = false
		set_process(false)


func start_cooldown():
	is_in_cooldown = true
	cooldown = COOLDOWN
	set_process(true)


func _is_mouse_inside() -> bool:
	var mouse_pos := get_local_mouse_position()
	return (mouse_pos.x > 0.0) and (mouse_pos.y < rect_size.y)


func set_shift_visibility(new_visiblity:bool):
	shift_visibility = new_visiblity
	_refresh_visibility()


func _refresh_visibility():
	visible = shift_visibility and hover_visibility
