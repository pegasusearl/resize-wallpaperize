extends Node2D



func _ready():
	update()


func _draw():
	var resolution:Vector2 = get_viewport().size
	var pcs := resolution/3.0
	
	var color := Color.white
	var width := 2.0
	
	draw_line(Vector2(0,pcs.y),Vector2(resolution.x,pcs.y),color,width)
	draw_line(Vector2(0,2*pcs.y),Vector2(resolution.x,2*pcs.y),color,width)
	draw_line(Vector2(pcs.x,0),Vector2(pcs.x,resolution.y),color,width)
	draw_line(Vector2(2*pcs.x,0),Vector2(2*pcs.x,resolution.y),color,width)


func _on_Grid_toggled(button_pressed):
	visible = button_pressed
