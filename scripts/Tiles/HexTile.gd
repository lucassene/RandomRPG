extends Area2D

# ON READY SCENES
onready var sprite = $mainTexture
onready var hover = $hoverTexture
onready var selected = $selectedTexture
onready var feature = $featureTexture
onready var fogOfWar = $fogOfWar

# SIGNALS
signal selected(node)
signal hover(node)

# CONSTANTS
const TOUCH_SENSITIVITY = 0.5

# VARIABLES
var emptyTxt = preload("res://assets/tiles/hex-frame.png")
var forestTxt = preload("res://assets/tiles/hex-forest.png")
var desertTxt = preload("res://assets/tiles/hex-desert.png")
var waterTxt = preload("res://assets/tiles/hex-water.png")
var articTxt = preload("res://assets/tiles/hex-artic.png")
var grasslandTxt = preload("res://assets/tiles/hex-grassland.png")
var swampTxt = preload("res://assets/tiles/hex-swamp.png")
var fogOfWarTxt = preload("res://assets/tiles/hex-fog.png")

var mountainTxt = preload("res://assets/tiles/hex-mountain-overlay.png")
var hillTxt = preload("res://assets/tiles/hex-hill-overlay.png")

var status
var touchPos

var hex = {
	"index": -1,
	"type": -1,
	"id": Vector2(0,0),
	"position": Vector2(0,0),
	"neighbors": [],
	"terrain": -1,
	"feature": -1,
	"hasConnection": false,
	"hasFog": false
	}
	
func _ready():
	hover.visible = false
	selected.visible = false
	feature.visible = false
	fogOfWar.visible = false

func _on_HexTile_mouse_entered():
#	if not status == SELECTED:
#		hover.visible = true
#	emit_signal("hover",self)
	pass

func _on_HexTile_mouse_exited():
#	hover.visible = false
	pass

func setTerrain(type):
	match type:
		GlobalVar.SELECTED:
			status = GlobalVar.SELECTED
			selected.visible = true
		GlobalVar.UNSELECTED:
			status = GlobalVar.UNSELECTED
			selected.visible = false
		GlobalVar.tileType.EMPTY:
			sprite.texture = emptyTxt
			hex.terrain = GlobalVar.tileType.EMPTY
		GlobalVar.tileType.FOREST:
			sprite.texture = forestTxt
			hex.terrain = GlobalVar.tileType.FOREST
		GlobalVar.tileType.DESERT:
			sprite.texture = desertTxt
			hex.terrain = GlobalVar.tileType.DESERT
		GlobalVar.tileType.ARTIC:
			sprite.texture = articTxt
			hex.terrain = GlobalVar.tileType.ARTIC
		GlobalVar.tileType.GRASSLAND:
			sprite.texture = grasslandTxt
			hex.terrain = GlobalVar.tileType.GRASSLAND
		GlobalVar.tileType.SWAMP:
			sprite.texture = swampTxt
			hex.terrain = GlobalVar.tileType.SWAMP
		GlobalVar.tileType.WATER:
			sprite.texture = waterTxt
			hex.terrain = GlobalVar.tileType.WATER

func setFeature(value):
	match value:
		-1:
			feature.texture = null
			feature.visible = false
			hex.feature = null
		GlobalVar.tileFeature.MOUNTAIN:
			feature.texture = mountainTxt
			feature.visible = true
			hex.feature = GlobalVar.tileFeature.MOUNTAIN
		GlobalVar.tileFeature.HILL:
			feature.texture = hillTxt
			feature.visible = true
			hex.feature = GlobalVar.tileFeature.HILL

func _on_HexTile_input_event(_viewport, event, _shape_idx):
	if event is InputEventScreenTouch and event.is_pressed():
		touchPos = event.position
	if touchPos and event is InputEventScreenTouch and not event.is_pressed():
		if event.position.is_equal_approx(touchPos):
			emit_signal("selected",self)

func setNeighbors(mapWidth,mapHeight):
	hex.neighbors = []
	var n = 0
	var ne = 0
	var se = 0
	var s = 0
	var sw = 0
	var nw = 0
	
	var listSize = (mapWidth) * (mapHeight)
	var isFirstRow = true
	var isLastRow = true
	var isFirstColumn = true
	var isLastColumn = true
	
	if hex.id.y > 0: isFirstRow = false
	if hex.id.x > 0: isFirstColumn = false
	if hex.id.y < (mapHeight-1): isLastRow = false
	if hex.id.x < (mapWidth-1): isLastColumn = false
	if hex.type == GlobalVar.hexType.REGULAR:
		n = hex.index - 1
		ne = hex.index + mapHeight - 1
		se = hex.index + mapHeight
		s = hex.index + 1
		sw = hex.index - mapHeight
		nw = hex.index - mapHeight - 1
		
		if isInList(n,listSize) and not isFirstRow: hex.neighbors.append(n)
		if isInList(ne,listSize) and not isFirstRow and not isLastColumn: hex.neighbors.append(ne) 
		if isInList(se,listSize) and not isLastColumn: hex.neighbors.append(se) 
		if isInList(s,listSize) and not isLastRow: hex.neighbors.append(s)
		if isInList(sw,listSize) and not isFirstColumn: hex.neighbors.append(sw)
		if isInList(nw,listSize) and not isFirstRow and not isFirstColumn: hex.neighbors.append(nw)
	
	elif hex.type == GlobalVar.hexType.OFFSET:
		n = hex.index -1
		ne = hex.index + mapHeight
		se = hex.index + mapHeight + 1
		s = hex.index + 1
		sw = hex.index - mapHeight + 1
		nw = hex.index - mapHeight
	
		if isInList(n,listSize) and not isFirstRow: hex.neighbors.append(n)
		if isInList(ne,listSize) and not isLastColumn: hex.neighbors.append(ne) 
		if isInList(se,listSize) and not isLastRow and not isLastColumn: hex.neighbors.append(se) 
		if isInList(s,listSize) and not isLastRow: hex.neighbors.append(s)
		if isInList(sw,listSize) and not isLastRow and not isFirstColumn: hex.neighbors.append(sw)
		if isInList(nw,listSize) and not isFirstColumn: hex.neighbors.append(nw)

func setFog(visibility):
	if visibility:
		fogOfWar.visible = false
		hex.hasFog = false
	else:
		fogOfWar.visible = false
		hex.hasFog = false

func isInList(index,size):
	if index >= 0 and index < size:
		return true
	return false
