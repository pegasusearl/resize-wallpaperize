extends PanelContainer


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

var source_image_list := []


func _ready():
	if CurrentDirectory.target == "":
		print("target directory is empty. do nothing.")
		return
	
	var dir := Directory.new()
	
	if not dir.dir_exists(CurrentDirectory.target):
		dir.make_dir_recursive(CurrentDirectory.target)
	
	config = ConfigFile.new()
	config.load(CurrentDirectory.config_path)

	print(get_file_list(CurrentDirectory.source))


func get_file_list(path:String,filter_type:Array=["jpg","png"]) -> Array:
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


