extends KinematicBody2D
const GameClass = preload("res://Game.gd")

onready var World = $"..";
onready var Game = get_tree().root.get_child(0) as GameClass

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
var rcs_ccw = false
var rcs_cw = false

var activeAsteroid: RigidBody2D = null
var drillable = false
var drilling = false

func _process(delta):
	readInputs()
	useDrill(delta)
	disableInactiveInputs()
	applyLinearForces(delta)
	applyAngularForces(delta)
	fireThrusters(delta)


func readInputs():
	rcs_ccw = false
	rcs_cw = false
	ion_fwd = Input.is_action_pressed("thrust_forward")
	ion_bwd = Input.is_action_pressed("thrust_backward")
	rcs_fwd = Input.is_action_pressed("dash_forward")
	rcs_bwd = Input.is_action_pressed("dash_backward")
	rcs_right = Input.is_action_pressed("dash_right")
	rcs_left = Input.is_action_pressed("dash_left")
	pivoting = Input.is_action_pressed("pivot")
	
	if Game.shipExploded:
		ion_fwd = false
		ion_bwd = false
		rcs_fwd = false
		rcs_bwd = false
		rcs_right = false
		rcs_left = false
		pivoting = false

func disableInactiveInputs():
	if Game.pressure == 0:
		pivoting = false
		rcs_ccw = false
		rcs_cw = false
		rcs_fwd = false
		rcs_bwd = false
		rcs_right = false
		rcs_left = false
	
	if drilling and not drillable:
		drilling = false
	
	if Game.oxygenatorGlitching or Game.gassifierGlitching or Game.drillGlitching:
		ion_fwd = false
		ion_bwd = false

func applyLinearForces(delta):
	dir = Vector2.UP.rotated(rotation)
	var right = Vector2.RIGHT.rotated(rotation)
	
	var impulse = dir * (
		int(ion_fwd) * forward_force  +
		-int(ion_bwd) * backward_force +
		int(rcs_fwd) * dash_force +
		-int(rcs_bwd) * dash_force
	) + (
		right * int(rcs_right) * dash_force +
		-right * int(rcs_left) * dash_force
	)
	
	v += impulse * delta
	move_and_slide(v)


func applyAngularForces(delta):
	var targetAngle: float = standardAngle(
		position \
		.direction_to(mousePos()) \
		.angle()
	)
	
	var angleToTarget: float = angleDiff(dir.angle(), targetAngle)
	
	if pivoting:
		if abs(a) <= 0.05 and abs(angleToTarget) <= 0.05:
			a = 0
			pivoting = false
		else:
			var impulse = 0
			
			if sign(angleToTarget) != sign(a):
				impulse = pivoting_torque * delta * sign(angleToTarget)
			elif distanceToStop(a, pivoting_torque) <= abs(angleToTarget):
				impulse = pivoting_torque * delta * sign(a)
			else:
				impulse = -pivoting_torque * delta * sign(a)
			
			a += impulse
			if impulse > 0: rcs_ccw = true
			if impulse < 0: rcs_cw = true
	
	elif rcs_ccw:
		a -= pivoting_torque * delta
	elif rcs_cw:
		a += pivoting_torque * delta
	
	rotation += a * delta


func fireThrusters(delta: float):
	$Thrusters/rcs_fwd.emitting = rcs_fwd
	$Thrusters/rcs_bwd.emitting = rcs_bwd
	$Thrusters/rcs_right.emitting = rcs_right
	$Thrusters/rcs_left.emitting = rcs_left
	
	$Thrusters/rcs_ccw1.emitting = rcs_ccw
	$Thrusters/rcs_ccw2.emitting = rcs_ccw
	$Thrusters/rcs_cw1.emitting = rcs_cw
	$Thrusters/rcs_cw2.emitting = rcs_cw
	
	$Thrusters/ion_fwd.visible = ion_fwd
	$Thrusters/ion_bwd.visible = ion_bwd
	
	$Drill/Particles.emitting = drilling

func useDrill(delta: float):
	drillable = false
	if activeAsteroid == null: return
	
	var relVel = (activeAsteroid.linear_velocity - v).rotated(-rotation)
	if relVel.length() > 50: return
	
	if abs(a) < 0.1 and not pivoting:
		a = 0
	else:
		if a > +0.1: rcs_ccw = true
		if a < -0.1: rcs_cw = true
	
	if not ion_fwd and not rcs_fwd and not ion_bwd and not rcs_bwd:
		if relVel.length() < 1:
			v = activeAsteroid.linear_velocity
		else:
			rcs_left = relVel.x < -1
			rcs_right = relVel.x > +1
			rcs_bwd = relVel.y > +1
			rcs_fwd = relVel.y < -1
			
	if relVel.length() < 1 and abs(a) < 0.1:
		drillable = true

func mousePos() -> Vector2:
	return World.get_local_mouse_position()

func standardAngle(a: float) -> float:
	return fposmod(a + PI, 2 * PI) - PI

func angleDiff(a: float, b: float) -> float:
	return standardAngle(b - a)
	
func distanceToStop(vel: float, acc: float) -> float:
	return 3 * vel*vel / (2 * acc)

func angleToBody(body: Node2D):
	return position.direction_to(body.position).angle()


func _drill_contact(body: Node2D):
	if body.is_in_group("asteroid"):
		activeAsteroid = body


func _drill_exit(body):
	if body == activeAsteroid:
		activeAsteroid = null
