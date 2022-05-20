extends Control

onready var PlayerShip = $WorldView/Viewport/World/PlayerShip

var pressure = 100
var oxygen = 100
var powerSupply = 100
var powerConsumption = 0

var oxygenatorActive = false

var rcsConsumption = 3
var pivotingConsumption = 1
var ionFwdConsumption = 40
var ionBwdConsumption = 20
var respirationRate = 1
var oxygenatorProduction = 10
var oxygenatorConsumption = 20


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event):
   if event is InputEventMouseMotion:
	   $Cursor.position = event.position

func _process(delta):
	handleAnimations()
	updateResources(delta)
	updateMeters()

func updateResources(delta: float):
	var P = PlayerShip
	
	pressure -= delta * (
		rcsConsumption * (
			int(P.rcs_fwd) + int(P.rcs_bwd) +
			int(P.rcs_right) + int(P.rcs_left)
		) +
		pivotingConsumption * int(P.pivoting)
	)
	
	oxygen += delta * (
		-respirationRate +
		oxygenatorProduction * int(oxygenatorActive)
	)
	
	powerConsumption = (
		ionFwdConsumption * int(P.ion_fwd) +
		ionBwdConsumption * int(P.ion_bwd) +
		oxygenatorConsumption * int(oxygenatorActive)
	)
	
	pressure = clamp(pressure, 0, 100)
	oxygen = clamp(oxygen, 0, pressure)
	powerSupply = clamp(powerSupply, 0, 100)

func updateMeters():
	$Meters/Oxygen/Base.value = pressure
	$Meters/Oxygen/Active.value = oxygen
	$Meters/Power/Base.value = powerSupply
	$Meters/Power/Active.value = powerConsumption

func handleAnimations():
	if PlayerShip.a == 0:
		$Cursor.animation = 'stabilized'
	elif PlayerShip.pivoting:
		$Cursor.animation = 'stabilizing'
	else:
		$Cursor.animation = 'default'
	
