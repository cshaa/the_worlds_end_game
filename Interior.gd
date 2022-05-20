extends Node2D
const GameClass = preload("res://Game.gd")
onready var Game = get_tree().root.get_child(0) as GameClass

var cursorOn = false
var cursorOff = false

func _input(event):
	cursorOn = false
	cursorOff = false
	var c = getHoveredComponent()
	if c == null: return
	
	if Game.shipExploded:
		cursorOff = true
	elif isComponentOn(c):
		cursorOn = true
	else:
		cursorOff = true
	
	
	if event is InputEventMouseButton and event.pressed:
		onComponentClick(c)

func getHoveredComponent():
	var collisions = get_world_2d().direct_space_state.intersect_point(get_local_mouse_position())
	for c in collisions:
		if c.collider == $Oxygenator: return 'oxygenator'
		if c.collider == $Gassifier: return 'gassifier'
		if c.collider == $Drill: return 'drill'
		if c.collider == $BHEngineMinus: return 'bhminus'
		if c.collider == $BHEnginePlus: return 'bhplus'
	return null

func isComponentOn(c: String) -> bool:
	match c:
		'oxygenator': return Game.oxygenatorActive
		'gassifier': return Game.gassifierActive
		'drill': return Game.drillActive
		'bhminus': return true
		'bhplus': return true
	return false

func onComponentClick(c: String):
	match c:
		'oxygenator':
			Game.oxygenatorActive = not Game.oxygenatorActive and not Game.oxygenatorGlitching
			Game.oxygenatorGlitching = false
		'gassifier':
			Game.gassifierActive = not Game.gassifierActive and not Game.gassifierGlitching
			Game.gassifierGlitching = false
		'drill':
			Game.drillActive = not Game.drillActive and not Game.drillGlitching
			Game.drillGlitching = false
		'bhminus': Game.powerSupplyTarget -= 10
		'bhplus': Game.powerSupplyTarget += 10


func _process(delta):
	animateEquipment()

func animateEquipment():
	$Oxygenator/Sprite.animation = 'glitching' if Game.oxygenatorGlitching else 'on' if Game.oxygenatorActive else 'off'
	$Gassifier/Sprite.animation = 'glitching' if Game.gassifierGlitching else 'on' if Game.gassifierActive else 'off'
	$Drill/Sprite.animation = 'glitching' if Game.drillGlitching else 'on' if Game.drillActive else 'off'
	$BHEngine.animation = 'alarm' if Game.explosionAlarm else 'default'
	
	if Game.shipExploded:
		$Oxygenator/Sprite.animation = 'destroyed'
		$Gassifier/Sprite.animation = 'destroyed'
		$Drill/Sprite.animation = 'off' # TODO
		$BHEngine.animation = 'destroyed'
