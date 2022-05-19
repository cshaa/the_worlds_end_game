extends Sprite

onready var World = $"..";

var v = Vector2()
var a = 0
var dir = Vector2.UP

var forward_force = 10
var backward_force = forward_force / 2
var dash_force = 10
var pivoting_torque = 5

var pivoting = false
var ion_fwd = false
var ion_bwd = false
var rcs_fwd = false
var rcs_bwd = false
var rcs_right = false
var rcs_left = false

func _process(delta):
	readInputs()
	applyLinearForces(delta)
	applyAngularForces(delta)
	fireThrusters(delta)


func readInputs():
	ion_fwd = Input.is_action_pressed("thrust_forward")
	ion_bwd = Input.is_action_pressed("thrust_backward")
	rcs_fwd = Input.is_action_pressed("dash_forward")
	rcs_bwd = Input.is_action_pressed("dash_backward")
	pivoting = Input.is_action_pressed("pivot")


func applyLinearForces(delta):
	dir = Vector2.UP.rotated(rotation)
	
	var impulse = dir * (
		int(ion_fwd) * forward_force  +
		-int(ion_bwd) * backward_force +
		int(rcs_fwd) * dash_force +
		-int(rcs_bwd) * dash_force
	)
	
	v += impulse * delta
	position += v * delta


func applyAngularForces(delta):
	var targetAngle: float = standardAngle(
		position \
		.direction_to(mousePos()) \
		.angle()
	)
	
	var angleToTarget: float = angleDiff(dir.angle(), targetAngle)
	
	if pivoting:
		if abs(a) <= 0.01 and abs(angleToTarget) <= 0.01:
			a = 0
			pivoting = false
		elif sign(angleToTarget) != sign(a):
			a += pivoting_torque * delta * sign(angleToTarget)
		elif distanceToStop(a, pivoting_torque) <= abs(angleToTarget):
			a += pivoting_torque * delta * sign(a)
		else:
			a -= pivoting_torque * delta * sign(a)
	
	rotation += a * delta


func fireThrusters(delta: float):
	setParticleVelocity($Thrusters/rcs_fwd, -50 * dir, delta)
	setParticleVelocity($Thrusters/rcs_bwd, 50 * dir, delta)
	
	$Thrusters/rcs_fwd.emitting = rcs_fwd
	$Thrusters/rcs_bwd.emitting = rcs_bwd

func setParticleVelocity(node: Particles2D, vec: Vector2, delta: float):
	var material = node.process_material as ParticlesMaterial
	var totalVelocity = vec + v * delta
	node.rotation = totalVelocity.angle()
	material.initial_velocity = totalVelocity.length()

func mousePos() -> Vector2:
	return World.get_local_mouse_position()

func standardAngle(a: float) -> float:
	return fposmod(a, 2 * PI) - PI

func angleDiff(a: float, b: float) -> float:
	return standardAngle(b - a)
	
func distanceToStop(vel: float, acc: float) -> float:
	return 3 * vel*vel / (2 * acc)
