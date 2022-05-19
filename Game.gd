extends Control

var oxygen

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event):
   if event is InputEventMouseMotion:
	   $Cursor.position = event.position
