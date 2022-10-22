extends Node


onready var thumbnail_db := ConfigFile.new()
onready var dir := Directory.new()
onready var thumbnail_directory := OS.get_user_data_dir()+"/thumbnail"

signal thumbnail_ready (image_fullpath,thumbnail_name)
var thumbnail_queue := []
var is_ready := false


func _ready():
	dir.make_dir_recursive(thumbnail_directory)
	thumbnail_db.load("user://thumb_db.cfg")
	randomize()
	is_ready = true
	process_thumbnail()


func request_thumbnails(list_of_image_fullpath:Array) -> void:
	thumbnail_queue.append_array(list_of_image_fullpath)
	if is_ready and not processing_thumbnail:
		process_thumbnail()


#func request_thumbnail(image_fullpath) -> void:
#	thumbnail_queue.append(image_fullpath)
#	if not processing_thumbnail:
#		process_thumbnail()


func _exit_tree():
	thumbnail_db.save("user://thumb_db.cfg")


var processing_thumbnail := false

func process_thumbnail() -> void:
	if processing_thumbnail or thumbnail_queue.size() == 0:
		thumbnail_db.save("user://thumb_db.cfg")
		return
	
	processing_thumbnail = true
	var current_file_path:String = thumbnail_queue.pop_front()
	var current_fullpath:String = CurrentDirectory.source+"/"+current_file_path
	
	var thumbnail_path:String
	var thumbnail_name:String
	var file_name := current_fullpath.get_file()
	# is thumbnail already generated?
	if thumbnail_db.has_section_key("thumb",current_fullpath):
		thumbnail_path = thumbnail_directory+thumbnail_db.get_value("thumb",current_fullpath)
		if dir.file_exists(thumbnail_path):
			emit_signal("thumbnail_ready",current_file_path,thumbnail_db.get_value("thumb",current_fullpath))
			processing_thumbnail = false
			call_deferred("process_thumbnail")
			return
	else:
		thumbnail_name = str("/",randi(),"_",file_name,".webp")
		thumbnail_path = thumbnail_directory+thumbnail_name
	
	# ok lets generate thumbnail.
	
	while dir.file_exists(thumbnail_path):
		thumbnail_name = str("/",randi(),"_",file_name,".webp")
		thumbnail_path = thumbnail_directory+thumbnail_name
	
	var thumbnail_bot = Thread.new()
	thumbnail_bot.start(self,"_thumbnail_convert",[current_fullpath,thumbnail_path])
	yield(self,"bot_thumbnail_finished")
	yield(get_tree().create_timer(0.1),"timeout") # trying to prevent crash when first time generating thumbnail. not sure if it worked
	thumbnail_bot.wait_to_finish()
	
	thumbnail_db.set_value("thumb",current_fullpath,thumbnail_name)
	processing_thumbnail = false
	emit_signal("thumbnail_ready",current_file_path,thumbnail_db.get_value("thumb",current_fullpath))
	call_deferred("process_thumbnail")


signal bot_thumbnail_finished

func _thumbnail_convert(input_data:Array):
	var output = []
	print("executing imagemagick thumbmnailing at ",OS.get_ticks_msec())
	var err = OS.execute("magick",[input_data[0],"-quality","92","-define","webp:lossless=false","-resize","200x200","-strip",input_data[1]],true,output)
	#print("magick",input_data)
	if err != OK:
		print("error while executing magick thumbnail generation. ",input_data[0],output)
	emit_signal("bot_thumbnail_finished")
