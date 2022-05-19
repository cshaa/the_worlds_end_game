extends Control

onready var PlayerShip = $WorldView/Viewport/World/PlayerShip

var oxygen

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event):
   if event is InputEventMouseMotion:
	   $Cursor.position = event.position

func _process(delta):
	if PlayerShip.a == 0:
		$Cursor.animation = 'stabilized'
	elif PlayerShip.pivoting:
		$Cursor.animation = 'stabilizing'
	else:
		$Cursor.animation = 'default'
