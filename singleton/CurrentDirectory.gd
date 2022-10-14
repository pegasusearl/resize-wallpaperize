extends Node


var target:String setget set_target
var source:String

var config_path:String


func set_target(new_target:String) -> void:
	print("TargetDir: ",new_target)
	print("Config file: ",new_target.rstrip("/")+"/.wallpaperize.cfg")
	target = new_target
	config_path = new_target.rstrip("/")+"/wallpaperize.cfg"
