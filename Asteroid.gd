extends RigidBody2D

onready var PlayerShip: KinematicBody2D = \
	get_tree().root.get_child(0).get_node("WorldView/Viewport/World/PlayerShip")

func _process(delta):
	var dist = global_position.distance_to(PlayerShip.global_position)
	if dist > 2000:
		print('sudoku')
		queue_free()
