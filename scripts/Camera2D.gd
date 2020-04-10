extends Camera2D

# ON READY SCENES
onready var target = get_node("/root/Main/HexGrid/mapPlayer")

# CONSTANTS
const RETURN_RATE = 0.03
const MIN_ZOOM = 1
const MAX_ZOOM = 3
const ZOOM_SPEED = 0.05
const ZOOM_SENSITIVITY = 10

# VARIABLES
var targetReturn = false

var currentZoom = 1.5 #1.25
var events = {}
var lastDragDistance = 0

var baseLimitBottom
var minX
var maxX
var minY
var maxY

func _process(_delta):
	if target and targetReturn:
		position = lerp(position,Vector2(0,0), RETURN_RATE)

func returnToTarget(value):
	targetReturn = value
	pass

func _unhandled_input(event):
	
	if event is InputEventScreenTouch:
		if event.is_pressed():
			events[event.index] = event
		else:
			events.erase(event.index)
			
	if event is InputEventScreenDrag:
		events[event.index] = event
		if events.size() == 1:
			var nextPos = position + event.relative * zoom.x * -1
			if nextPos.x > minX and nextPos.x < maxX and nextPos.y > minY and nextPos.y < maxY:
				position = nextPos
		elif events.size() == 2:
			var dragDistance = events[0].position.distance_to(events[1].position)
			if abs(dragDistance - lastDragDistance) > ZOOM_SENSITIVITY:
				var newZoom = (1 + ZOOM_SPEED) if dragDistance < lastDragDistance else (1 - ZOOM_SPEED)
				newZoom = clamp(zoom.x * newZoom, MIN_ZOOM, MAX_ZOOM)
				zoom = Vector2.ONE * newZoom
				currentZoom = newZoom
				lastDragDistance = dragDistance

func setLimits(playerTile,mapSize):
	maxX = (mapSize.x - 1 - playerTile.hex.id.x) * (GlobalVar.HEX_WIDTH * 0.75)
	maxY = (mapSize.y -1 - playerTile.hex.id.y) * GlobalVar.HEX_HEIGHT + (GlobalVar.HEX_HEIGHT / 2)
	minX = (playerTile.hex.id.x * (GlobalVar.HEX_WIDTH * 0.75)) * -1
	minY = (playerTile.hex.id.y * GlobalVar.HEX_HEIGHT - (GlobalVar.HEX_HEIGHT / 2)) * -1
