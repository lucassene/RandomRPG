extends Camera2D

# ON READY SCENES
onready var target = get_node("/root/Main/HexGrid/mapPlayer")

# CONSTANTS
const RETURN_RATE = 0.03
const MAX_ZOOM = 1.5
const MIN_ZOOM = 4.5
const ZOOM_SPEED = 0.1

# VARIABLES
var targetReturn = false

var currentZoom = 2
var isDragging = false

var baseLimitBottom
var minX
var maxX
var minY
var maxY

func _process(_delta):
	if target and targetReturn and not isDragging:
		position = lerp(position,Vector2(0,0), RETURN_RATE)

func returnToTarget(value):
	targetReturn = value
	pass

func _unhandled_input(event):
	if event.is_action_pressed("cam_drag"):
		isDragging = true;
	if event.is_action_released("cam_drag"):
		isDragging = false;	
	
	if event is InputEventMouseMotion and isDragging:
		var nextPos = position + event.relative * zoom.x * -1
		if nextPos.x > minX and nextPos.x < maxX and nextPos.y > minY and nextPos.y < maxY:
			position = nextPos
	
	if event.is_action("cam_zoom_in"):
		updateZoom(-ZOOM_SPEED,get_local_mouse_position())
	elif event.is_action("cam_zoom_out"):
		updateZoom(ZOOM_SPEED,get_local_mouse_position())

func updateZoom(speed, anchor):
	var oldZoom = currentZoom
	currentZoom += speed
	
	if currentZoom < MAX_ZOOM:
		currentZoom = MAX_ZOOM
	elif currentZoom > MIN_ZOOM:
		currentZoom = MIN_ZOOM
		
	if oldZoom == currentZoom: return
	
	var zoomCenter = anchor - get_offset()
	var ratio = 1 - (currentZoom / oldZoom)
	set_offset(get_offset() + zoomCenter * ratio)
	
	set_zoom(Vector2(currentZoom,currentZoom))

func setLimits(playerTile,mapSize):
	maxX = (mapSize.x - 1 - playerTile.hex.id.x) * (GlobalVar.HEX_WIDTH * 0.75)
	maxY = (mapSize.y -1 - playerTile.hex.id.y) * GlobalVar.HEX_HEIGHT + (GlobalVar.HEX_HEIGHT / 2)
	minX = (playerTile.hex.id.x * (GlobalVar.HEX_WIDTH * 0.75)) * -1
	minY = (playerTile.hex.id.y * GlobalVar.HEX_HEIGHT - (GlobalVar.HEX_HEIGHT / 2)) * -1
