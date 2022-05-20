extends Control

onready var PlayerShip = $WorldView/Viewport/World/PlayerShip
onready var Interior = $ShipView/Viewport/Interior

var pressure = 100
var oxygen = 100
var powerSupply = 50
var powerSupplyTarget = 60
var powerConsumption = 0
var matter = 100
var health = 100

var oxygenatorActive = false
var gassifierActive = false

var explosionAlarm = false
var shipExploded = false

var rcsConsumption = 3
var pivotingConsumption = 1
var ionFwdConsumption = 40
var ionBwdConsumption = 20
var respirationRate = 1
var oxygenatorProduction = 10
var oxygenatorConsumption = 20
var gassifierMatterConsumption = 10
var gassifierPowerConsumption = 60
var gassifierProduction = 1

var massToEnergy = 0.01
var massToPower = 0.3
var maxMassDiff = 0.05
var theoreticalMaxPower = 120

func BH_massAtPower(power):
	return (theoreticalMaxPower - power) * massToPower

var BH_mass = BH_massAtPower(powerSupply)
var reserveMass = BH_massAtPower(10) - BH_mass


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
	powerSupplyTarget = clamp(powerSupplyTarget, 10, 100)
	
	if shipExploded:
		oxygenatorActive = false
		powerSupply = 0
		BH_mass = 1e99
		powerSupplyTarget = 0
	
	
	pressure += delta * (
		rcsConsumption * (
			-int(P.rcs_fwd) + int(P.rcs_bwd) +
			-int(P.rcs_right) + int(P.rcs_left)
		) +
		pivotingConsumption * -int(P.pivoting) +
		gassifierProduction * int(gassifierActive)
	)
	
	oxygen += delta * (
		-respirationRate +
		oxygenatorProduction * int(oxygenatorActive)
	)
	
	powerConsumption = (
		ionFwdConsumption * int(P.ion_fwd) +
		ionBwdConsumption * int(P.ion_bwd) +
		oxygenatorConsumption * int(oxygenatorActive) +
		gassifierPowerConsumption * int(gassifierActive)
	)
	
	if gassifierActive:
		if matter > gassifierMatterConsumption * delta:
			matter -= gassifierMatterConsumption * delta
		else:
			gassifierActive = false
	
	powerSupply = theoreticalMaxPower - BH_mass / massToPower
	var BH_usedMass = powerSupply * massToEnergy * delta
	var BH_target = BH_massAtPower(powerSupplyTarget)
	
	if BH_mass > BH_target or BH_usedMass > matter:
		BH_mass -= BH_usedMass
	else:
		matter -= BH_usedMass
	
	if BH_mass < BH_target:
		var toBeAdded = min(min(BH_target - BH_mass, matter), maxMassDiff)
		BH_mass += toBeAdded
		matter -= toBeAdded
	
	if BH_mass <= 0:
		health = 0
		shipExploded = true
	
	reserveMass = BH_massAtPower(10) - BH_mass
	if shipExploded: reserveMass = 1e99
	
	powerSupply = theoreticalMaxPower - BH_mass / massToPower
	explosionAlarm = powerSupply > 100
	
	pressure = clamp(pressure, 0, 100)
	oxygen = clamp(oxygen, 0, pressure)
	powerSupply = clamp(powerSupply, 0, 100)

func updateMeters():
	$Meters/Oxygen/Base.value = pressure
	$Meters/Oxygen/Active.value = oxygen
	$Meters/Power/Base.value = powerSupply
	$Meters/Power/Active.value = powerConsumption
	$Meters/Matter/Base.value = matter
	$Meters/Matter/Active.value = matter - reserveMass
	$Meters/Hull/Base.value = health
	$Meters/Hull/Active.value = health - 10

func handleAnimations():
	if Interior.cursorOn: $Cursor.animation = 'on'
	elif Interior.cursorOff: $Cursor.animation = 'off'
	elif PlayerShip.a == 0: $Cursor.animation = 'stabilized'
	elif PlayerShip.pivoting: $Cursor.animation = 'stabilizing'
	else: $Cursor.animation = 'default'
