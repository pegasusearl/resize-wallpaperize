extends Node


var working_directory := ""
var waifu2x_path := ""
var imagemagick_convert_command := ""

func get_waifu2x_path() -> String:
	if waifu2x_path == "":
		return "waifu2x-ncnn-vulkan"
	else:
		return waifu2x_path


func get_working_directory() -> String:
	if working_directory == "":
		return "/tmp"
	else:
		return working_directory


func get_imagemagick_convert_command() -> String:
	if imagemagick_convert_command == "":
		return "magick"
	else:
		return imagemagick_convert_command
