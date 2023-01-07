extends Node2D

# WARNING!! porting to godot4, on _process(), viewport size and resolution
# is coded under assumption of Vector2, with floats.
# TODO
var width := 2.0
var color := Color.white

func _ready():
	update()


var last_resolution:Vector2
func _process(delta):
	if OS.window_size != last_resolution:
		last_resolution = OS.window_size
		var calculated_width = max(get_viewport().size.x/last_resolution.x,get_viewport().size.y/last_resolution.y)
		width = ceil(calculated_width)
		print("Grid width changed to ",calculated_width,"/",width)
		update()
	#printt(OS.window_size,get_viewport().size)


func _draw():
	var resolution:Vector2 = get_viewport().size
	var pcs := resolution/3.0
	
	draw_line(Vector2(0,pcs.y),Vector2(resolution.x,pcs.y),color,width)
	draw_line(Vector2(0,2*pcs.y),Vector2(resolution.x,2*pcs.y),color,width)
	draw_line(Vector2(pcs.x,0),Vector2(pcs.x,resolution.y),color,width)
	draw_line(Vector2(2*pcs.x,0),Vector2(2*pcs.x,resolution.y),color,width)


func _on_Grid_toggled(button_pressed):
	visible = button_pressed
