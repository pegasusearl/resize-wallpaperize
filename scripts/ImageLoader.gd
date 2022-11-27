extends Control


onready var node = $Viewport/TextureRect
onready var bg_node = $Viewport/BG
onready var info_node = $Label
onready var action_info_node = $Actions
onready var image_list = $ImageList

onready var ignore_button = $Panel/Ignore
onready var clear_button = $Panel/Clear
onready var controller_panel = $Panel
onready var grid_node = $DrawGrid
onready var background_picker = $Panel/BackgroundPicker

#filetype
var full_path := ""
var filetype := ""
var jpg_quality:int
var resolution := Vector2.ZERO
var aspect_ratio := 1.777777778

#viewer
var image_scale := 1.0

func _ready():
	var main_viewport_size = get_viewport().size
	$Viewport.size = main_viewport_size
	bg_node.rect_size = main_viewport_size
	bg_node.rect_position = Vector2.ZERO
	pass
	#load_image("/mnt/warehouse/Pictures/Pixiv/100639347_p0.jpg")
	#load_image("/mnt/warehouse/Pictures/Pixiv/64568561_p0.jpg")


func load_image(image_full_path:String):
	var dir = Directory.new()
	if not dir.file_exists(image_full_path):
		return ERR_DOES_NOT_EXIST
	full_path = image_full_path
	
	image_scale = 1.0
	node.rect_size = Vector2.ZERO
	node.rect_position = Vector2.ZERO
	ignore_button.pressed = false
	clear_button.disabled = true
	
	var image = ImageTexture.new()
	image.load(full_path)
	node.texture = image
	
	var info := ""
	filetype = full_path.get_extension()
	info += "Filetype: \t"+ filetype +"\n"
	
	var is_png := false
	if ["jpg","jpeg"].has(filetype):
		jpg_quality = int( run_command("identify",["-format",'%Q',full_path]) )
		info += "JPG saved quality: \t"+ str(jpg_quality) +"\n"
	else:
		is_png = true
		jpg_quality = 100
	
	if is_png:
		denoise = 0
	elif jpg_quality > 92:
		denoise = 0
	elif jpg_quality > 82:
		denoise = 1
	elif jpg_quality > 72:
		denoise = 2
	else:
		denoise = 3
	
	resolution = image.get_size()
	info += "Resolution \t"+ str(resolution) +"\n"
	
	aspect_ratio = resolution.x/resolution.y
	info += "Aspect Ration Value \t"+ str(aspect_ratio) +"\n"
	
	node.rect_size = resolution
	
	info_node.text = info
	_on_DefaultFit_pressed()
	return OK


var dragging := false setget set_dragging
var last_image_viewed_position:Vector2

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == 4 or event.button_index == 5:
			var scaled_position = node.get_local_mouse_position()/node.rect_size.x
			match event.button_index:
				4:
					image_scale += 0.05*image_scale
					node.rect_size = resolution*image_scale
				5:
					image_scale -= 0.05*image_scale
					node.rect_size = resolution*image_scale
			var delta_position = (node.get_local_mouse_position()/node.rect_size.x)-scaled_position
			node.rect_position += (delta_position*node.rect_size.x)
		
		#dragging
		elif event.button_index == 1:
			last_image_viewed_position = node.rect_position
			set_dragging(true)
		
		update_info()
	
	elif dragging == true and event is InputEventMouseMotion:
		node.rect_position += event.relative
		if Input.is_action_pressed("shift"):
			if abs(node.rect_position.x-last_image_viewed_position.x) > abs(node.rect_position.y-last_image_viewed_position.y):
				node.rect_position.y = last_image_viewed_position.y
			else:
				node.rect_position.x = last_image_viewed_position.x
		
		update_info()


func _input(event):
	if dragging and event is InputEventMouseButton and event.button_index == 1 and !event.pressed:
		set_dragging(false) 
		
		update_info()


func set_dragging(new_dragging:bool):
	dragging = new_dragging
	if dragging:
		image_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		image_list.mouse_filter = Control.MOUSE_FILTER_STOP


var target_size:Vector2
var origin:Vector2
var crop_size:Vector2
var upscale:int
var denoise:int
var mini_target_size:Vector2
var extend_top:float
var extend_left:float
var background:Color setget set_background
var ignored := false

func get_metadata():
	update_info()
	return [
		target_size, #0
		origin, #1
		crop_size, #2
		upscale, #3
		denoise, #4
		mini_target_size, #5
		extend_top, #6
		extend_left, #7
		background, #8
		ignored, #9
		
		node.rect_size, #10
		node.rect_position, #11
		image_scale, #12
	]


func set_metadata(new_metadata:Array):
	target_size = new_metadata[0]
	origin = new_metadata[1]
	crop_size = new_metadata[2]
	upscale = new_metadata[3]
	denoise = new_metadata[4]
	mini_target_size = new_metadata[5]
	extend_top = new_metadata[6]
	extend_left = new_metadata[7]
	
	#background = new_metadata[8]
	set_background(new_metadata[8])
	background_picker.color = background
	
	ignored = new_metadata[9]
	ignore_button.pressed = ignored
	
	node.rect_size = new_metadata[10]
	node.rect_position = new_metadata[11]
	image_scale = new_metadata[12]
	
	update_info()


func _process(delta):
	if Input.is_action_just_pressed("shift"):
		show_hud(false)
	elif Input.is_action_just_released("shift"):
		show_hud(true)


func update_info():
	target_size = get_viewport().size
	var info_text := ""
	
	info_text += "== Crop ==\n"
	
	var unscaled_position:Vector2 = node.rect_position/image_scale
	mini_target_size = target_size/image_scale
	origin.x = abs( clamp(round(-unscaled_position.x),0,resolution.x) )
	origin.y = abs( clamp(round(-unscaled_position.y),0,resolution.y) )
	info_text += "Origin: "+str(origin)+"\n"
	
	crop_size = target_size/image_scale
	crop_size.x = abs( round(crop_size.x) )
	crop_size.y = abs( round(crop_size.y) )
	info_text += "Size: "+str(crop_size)+"\n"
	
	info_text += "\n== Upscale w2x ==\n"
	
	upscale = 1
	var upscaled_size = crop_size*upscale
	while upscaled_size.x < target_size.x or upscaled_size.y < target_size.y:
		upscale = upscale*2
		upscaled_size = crop_size*upscale
	info_text += "Upscale: "+str("x",upscale)+"\n"
	
	info_text += "Denoise: "+str(denoise,"/3")+"\n"
	
	## resize
	
	## extend image here
	# >>>>>>>>.
	extend_top = max(unscaled_position.y,0)
	extend_left = max(unscaled_position.x,0)
	
	info_text += "\n== Extend ==\n"
	info_text += "extend_top: "+str(extend_top)+"\n"
	info_text += "extend_left: "+str(extend_left)+"\n"
	info_text += "extend_right: "+str(max(mini_target_size.x-resolution.x-unscaled_position.x,0))+"\n"
	info_text += "extend_bottom: "+str(max(mini_target_size.y-resolution.y-unscaled_position.y,0))+"\n"
	
	action_info_node.text = info_text


func run_command(command:String,arguments:Array=[]) -> String:
	#OS.execute("identify",["-format",'%Q',full_path],true,output)
	var output = []
	var err = OS.execute(command,arguments,true,output)
	return output.front()


func show_hud(show_them:bool):
	info_node.visible = show_them
	action_info_node.visible = show_them
	image_list.request_visibility = show_them
	controller_panel.visible = show_them


func take_snapshot(path:String) -> void:
	if path.ends_with(".png"):
		path = path.trim_suffix(".png")
	var img = get_viewport().get_texture().get_data()
	img.flip_y()
	img.save_png(path)


func set_background(color):
	background = color
	bg_node.modulate = color


func convert_operation_meta(source_path:String,target_path:String,metadata:Array):
	convert_operation(source_path,target_path,
			metadata[2],metadata[1],
			metadata[3],metadata[4],
			metadata[5],metadata[8],metadata[7],metadata[6],
			metadata[0]
			)


func convert_operation(source_path:String,target_path:String,
		crop_size:Vector2,origin:Vector2,
		upscale:int,denoise:int,
		mini_target_size:Vector2,background:Color,extend_left:float,extend_top:float,
		target_size:Vector2):
	var working_path := "/tmp"
	var file_name := source_path.get_file()
	var working_filepath := working_path+"/"+file_name+".png"
	#crop
	run_command("convert",[source_path,"-crop",
			str(crop_size.x,"x",crop_size.y,"+",origin.x,"+",origin.y),
			working_filepath])
	#upscale
	run_command("waifu2x-ncnn-vulkan",
			["-i",working_filepath,"-o",
			working_filepath,"-s",str(upscale),"-n=",str(denoise)])
	#extent
	var upscaled_size = mini_target_size*upscale
	run_command("convert",[working_filepath,
			"-background","#"+background.to_html(false),"-extent",
			str(round(upscaled_size.x),"x",round(upscaled_size.y),"-",round(extend_left*upscale),"-",round(extend_top*upscale)),
			working_filepath])
	#resize
	run_command("magick",[working_filepath,"-resize",str(target_size.x,"x",target_size.y),
	target_path])
	#delete working file
	var dir = Directory.new()
	dir.remove(working_filepath)


### Control # ==================================================================

func _on_TestMagick_pressed():
	#crop
	run_command("convert",[full_path,"-crop",
			str(crop_size.x,"x",crop_size.y,"+",origin.x,"+",origin.y),
			"/tmp/wauw-0.png"])
	
	#extent mode 1, disable earlier extent. check filename
#	run_command("convert",["/tmp/wauw-0.png","-background","white","-extent",
#			str(int(mini_target_size.x),"x",int(mini_target_size.y),"-",extend_left,"+",extend_top),
#			"/tmp/wauw-a.png"])
	
	#upscale
	run_command("waifu2x-ncnn-vulkan",
			["-i","/tmp/wauw-0.png","-o",
			"/tmp/wauw-b.png","-s",str(upscale),"-n=",str(denoise)])
	
	#extent mode 2. disable earlier extent, check filename
	var upscaled_size = mini_target_size*upscale
	run_command("convert",["/tmp/wauw-b.png",
			"-background","#"+background.to_html(false),"-extent",
			str(round(upscaled_size.x),"x",round(upscaled_size.y),"-",round(extend_left*upscale),"-",round(extend_top*upscale)),
			"/tmp/wauw-b1.png"])
	
	run_command("magick",["/tmp/wauw-b1.png","-resize",str(target_size.x,"x",target_size.y),"/tmp/wauw-c.png"])


func _on_StickUp_pressed():
	node.rect_position.y = 0.0
	
	update_info()


func _on_StickLeft_pressed():
	node.rect_position.x = 0.0
	
	update_info()


func _on_StickRight_pressed():
	node.rect_position.x = target_size.x-node.rect_size.x
	
	update_info()


func _on_StickDown_pressed():
	node.rect_position.y = target_size.y-node.rect_size.y
	
	update_info()


func _on_CenterFit_pressed():
	target_size = get_viewport().size
	node.rect_size.y = target_size.y
	node.rect_size.x = target_size.y*aspect_ratio
	image_scale = node.rect_size.x/resolution.x
	
	#repositioning
	var delta_size2:float = node.rect_size.x-target_size.x
	node.rect_position.y = 0.0
	node.rect_position.x = -delta_size2/2
	
	if node.rect_size.x > target_size.x:
		target_size = get_viewport().size
		node.rect_size.x = target_size.x
		node.rect_size.y = target_size.x/aspect_ratio
		image_scale = node.rect_size.x/resolution.x
		
		#repositioning
		var delta_size:float = node.rect_size.y-target_size.y
		node.rect_position.x = 0.0
		node.rect_position.y = -delta_size/2
	
	update_info()


func _on_DefaultFit_pressed():
	target_size = get_viewport().size
	node.rect_size.x = target_size.x
	node.rect_size.y = target_size.x/aspect_ratio
	image_scale = node.rect_size.x/resolution.x
	
	#repositioning
	var delta_size:float = node.rect_size.y-target_size.y
	node.rect_position.x = 0.0
	node.rect_position.y = -delta_size/2
	
	if node.rect_size.y < target_size.y:
		node.rect_size.y = target_size.y
		node.rect_size.x = target_size.y*aspect_ratio
		image_scale = node.rect_size.x/resolution.x
		
		#repositioning
		var delta_size2:float = node.rect_size.x-target_size.x
		node.rect_position.y = 0.0
		node.rect_position.x = -delta_size2/2
	
	update_info()


func _on_Ignore_toggled(button_pressed):
	ignored = button_pressed

### ----------------------------------------------------------------------------

