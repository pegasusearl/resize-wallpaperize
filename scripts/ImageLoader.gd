extends Control


onready var node = $TextureRect
onready var info_node = $Label
onready var action_info_node = $Actions

#filetype
var full_path := ""
var filetype := ""
var jpg_quality:int
var resolution := Vector2.ZERO
var aspect_ratio := 1.777777778

#viewer
var image_scale := 1.0

func _ready():
	load_image("/mnt/warehouse/Pictures/Pixiv/100639347_p0.jpg")
	#load_image("/mnt/warehouse/Pictures/Pixiv/64568561_p0.jpg")


func load_image(image_full_path:String):
	full_path = image_full_path
	
	image_scale = 1.0
	node.rect_size = Vector2.ZERO
	node.rect_position = Vector2.ZERO
	
	var image = ImageTexture.new()
	image.load(full_path)
	node.texture = image
	
	var info := ""
	filetype = full_path.get_extension()
	info += "Filetype: \t"+ filetype +"\n"
	
	if filetype == "jpg":
		jpg_quality = int( run_command("identify",["-format",'%Q',full_path]) )
		info += "JPG saved quality: \t"+ str(jpg_quality) +"\n"
	
	resolution = image.get_size()
	info += "Resolution \t"+ str(resolution) +"\n"
	
	aspect_ratio = resolution.x/resolution.y
	info += "Aspect Ration Value \t"+ str(aspect_ratio) +"\n"
	
	node.rect_size = resolution
	
	info_node.text = info


var dragging := false
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
			dragging = true
	
	elif dragging == true and event is InputEventMouseMotion:
		node.rect_position += event.relative
		if Input.is_action_pressed("shift"):
			if abs(node.rect_position.x-last_image_viewed_position.x) > abs(node.rect_position.y-last_image_viewed_position.y):
				node.rect_position.y = last_image_viewed_position.y
			else:
				node.rect_position.x = last_image_viewed_position.x


func _input(event):
	if dragging and event is InputEventMouseButton and event.button_index == 1 and !event.pressed:
		dragging = false


var target_size:Vector2
var origin:Vector2
var crop_size:Vector2
var upscale:int
var denoise:int
var mini_target_size:Vector2
var extend_top:float
var extend_left:float
var background:Color setget set_background

func _process(delta):
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
	
	upscale = 2
	var upscaled_size = crop_size*upscale
	while upscaled_size.x < target_size.x or upscaled_size.y < target_size.y:
		upscale = upscale*2
		upscaled_size = crop_size*upscale
	info_text += "Upscale: "+str("x",upscale)+"\n"
	
	denoise = 0
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


func take_snapshot(path:String) -> void:
	if path.ends_with(".png"):
		path = path.trim_suffix(".png")
	var img = get_viewport().get_texture().get_data()
	img.flip_y()
	img.save_png(path)


func _on_DefaultFit_pressed():
	var target_size = get_viewport().size
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
		
		var delta_size2:float = node.rect_size.x-target_size.x
		node.rect_position.y = 0.0
		node.rect_position.x = -delta_size2/2


func set_background(color):
	background = color
	$BG.modulate = color


func convert_operation(source_path:String,target_path:String,
		crop_size:Vector2,origin:Vector2,
		upscale:int,denoise:int,
		mini_target_size:Vector2,background:Color,extend_left:float,extend_top:float,
		target_size:Vector2):
	var working_path := "/tmp"
	var file_name := source_path.get_file()
	var working_filepath := working_path+"/"+file_name
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


func _on_StickLeft_pressed():
	node.rect_position.x = 0.0


func _on_StickRight_pressed():
	node.rect_position.x = target_size.x-node.rect_size.x


func _on_StickDown_pressed():
	node.rect_position.y = target_size.y-node.rect_size.y
