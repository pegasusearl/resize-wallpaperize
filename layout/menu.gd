extends MarginContainer


func _on_Go_pressed():
	CurrentDirectory.source = $VBoxContainer/HBoxContainer2/SourceDir.text
	CurrentDirectory.target = $VBoxContainer/HBoxContainer/TargetDir.text
	get_tree().change_scene("res://layout/main.tscn")
	
