extends CenterContainer



func _on_DetectResolution_resized():
	$Label.text = str(rect_size)
