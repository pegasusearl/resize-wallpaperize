extends PanelContainer


func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		OS.window_fullscreen = not OS.window_fullscreen


func _ready():
	yield(get_tree(),"idle_frame")
	return


#dont use anymore, delete
#TODO: delete
func reassing_denoise_level_delete_later():
	var image_list = $ImageViewer/ImageList
	var image_viewer = $ImageViewer
	for section in image_list.config.get_sections():
		var full_path:String = CurrentDirectory.source+"/"+section
		var file_type := full_path.get_extension()
		if file_type == "jpg":
			var configuration = image_list.config.get_value(section,"metadata")
			var denoise = configuration[4]
			var jpg_quality = int( image_viewer.run_command("identify",["-format",'%Q',full_path]) )
			if jpg_quality > 92:
				denoise = 0
			elif jpg_quality > 82:
				denoise = 1
			elif jpg_quality > 72:
				denoise = 2
			else:
				denoise = 3
			printt(full_path,denoise,jpg_quality)
			configuration[4] = denoise
			image_list.config.set_value(section,"metadata",configuration)
			yield(get_tree(),"idle_frame")
	var err = image_list.config.save(CurrentDirectory.config_path)
	print(err,"config saved")


var operation_in_progress := false
func start_convert_operation():
	
	if operation_in_progress:
		return
	
	var image_list = $ImageViewer/NewImageList
	var image_viewer = $ImageViewer
	var progress_bar = $Operation/VBoxContainer/ProgressBar
	var operation_node = $Operation
	var operation_label = $Operation/VBoxContainer/Label
	
	var unignored_list = []
	for section in image_list.config.get_sections():
		if image_list.config.has_section_key(section,"converted"):
			pass
		elif not image_list.config.has_section_key(section,"metadata"):
			pass
		elif not image_list.config.get_value(section,"metadata")[9]:
			unignored_list.append(section)
	
	progress_bar.max_value = unignored_list.size()
	progress_bar.value = 0
	operation_label.text = str("Converting ",progress_bar.max_value," images...")
	
	operation_in_progress = true
	operation_node.show()
	
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	
	for section in unignored_list:
		image_viewer.convert_operation_meta(CurrentDirectory.source+"/"+section,CurrentDirectory.target+"/"+section,
			image_list.config.get_value(section,"metadata"))
		progress_bar.value += 1
		image_list.config.set_value(section,"converted",true)
		image_list.config.save(CurrentDirectory.config_path)
		yield(get_tree(),"idle_frame")
	
	operation_node.hide()
	operation_in_progress = false


func _on_Convert_pressed():
	start_convert_operation()
