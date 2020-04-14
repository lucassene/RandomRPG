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

# TERRAIN TEXTURES
const EMPTY_TEXTURE = preload("res://assets/tiles/hex-frame.png")
const FOREST_TEXTURE = preload("res://assets/tiles/hex-forest.png")
const DESERT_TEXTURE = preload("res://assets/tiles/hex-desert.png")
const WATER_TEXTURE = preload("res://assets/tiles/hex-water.png")
const ARTIC_TEXTURE = preload("res://assets/tiles/hex-artic.png")
const GRASSLAND_TEXTURE = preload("res://assets/tiles/hex-grassland.png")
const SWAMP_TEXTURE = preload("res://assets/tiles/hex-swamp.png")
const FOGOFWAR_TEXTURE = preload("res://assets/tiles/hex-fog.png")

# FEATURE TEXTURES
const MOUNTAIN_TEXTURE = preload("res://assets/tiles/hex-mountain-overlay.png")
const HILL_TEXTURE = preload("res://assets/tiles/hex-hill-overlay.png")
const CAMP_TEXTURE = preload("res://assets/tiles/hex-camp.png")
const VILLAGE_TEXTURE = preload("res://assets/tiles/hex-village.png")
const TOWN_TEXTURE = preload("res://assets/tiles/hex-town.png")
const CITY_TEXTURE = preload("res://assets/tiles/hex-city.png")

# VARIABLES
var status

var hex = {
	"index": -1,
	"type": -1,
	"id": Vector2(0,0),
	"position": Vector2(0,0),
	"neighbors": [],
	"terrain": -1,
	"feature": -1,
	"settlement": -1,
	"hasConnection": false,
	"hasFog": true
	}
	
func _ready():
	hover.visible = false
	selected.visible = false
	feature.visible = false
	fogOfWar.visible = true

func _on_HexTile_mouse_entered():
	if not status == GlobalVar.SELECTED:
		hover.visible = true
	emit_signal("hover",self)

func _on_HexTile_mouse_exited():
	hover.visible = false

func setTerrain(type):
	match type:
		GlobalVar.SELECTED:
			status = GlobalVar.SELECTED
			selected.visible = true
		GlobalVar.UNSELECTED:
			status = GlobalVar.UNSELECTED
			selected.visible = false
		GlobalVar.tileType.EMPTY:
			sprite.texture = EMPTY_TEXTURE
			hex.terrain = GlobalVar.tileType.EMPTY
		GlobalVar.tileType.FOREST:
			sprite.texture = FOREST_TEXTURE
			hex.terrain = GlobalVar.tileType.FOREST
		GlobalVar.tileType.DESERT:
			sprite.texture = DESERT_TEXTURE
			hex.terrain = GlobalVar.tileType.DESERT
		GlobalVar.tileType.ARTIC:
			sprite.texture = ARTIC_TEXTURE
			hex.terrain = GlobalVar.tileType.ARTIC
		GlobalVar.tileType.GRASSLAND:
			sprite.texture = GRASSLAND_TEXTURE
			hex.terrain = GlobalVar.tileType.GRASSLAND
		GlobalVar.tileType.SWAMP:
			sprite.texture = SWAMP_TEXTURE
			hex.terrain = GlobalVar.tileType.SWAMP
		GlobalVar.tileType.WATER:
			sprite.texture = WATER_TEXTURE
			hex.terrain = GlobalVar.tileType.WATER

func setFeature(value):
	match value:
		-1:
			feature.texture = null
			feature.visible = false
			hex.feature = null
		GlobalVar.tileFeature.MOUNTAIN:
			feature.texture = MOUNTAIN_TEXTURE
			feature.visible = true
			hex.feature = GlobalVar.tileFeature.MOUNTAIN
		GlobalVar.tileFeature.HILL:
			feature.texture = HILL_TEXTURE
			feature.visible = true
			hex.feature = GlobalVar.tileFeature.HILL
	
func setSettlement(value):
	match value:
		-1:
			feature.texture = null
			feature.visible = false
			hex.feature = null
		GlobalVar.settlement.CAMP:
			feature.texture = CAMP_TEXTURE
			feature.visible = true
			hex.settlement = GlobalVar.settlement.CAMP
		GlobalVar.settlement.CITY:
			feature.texture = CITY_TEXTURE
			feature.visible = true
			hex.settlement = GlobalVar.settlement.CITY
		GlobalVar.settlement.TOWN:
			feature.texture = TOWN_TEXTURE
			feature.visible = true
			hex.settlement = GlobalVar.settlement.TOWN
		GlobalVar.settlement.VILLAGE:
			feature.texture = VILLAGE_TEXTURE
			feature.visible = true
			hex.settlement = GlobalVar.settlement.VILLAGE

func _on_HexTile_input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("ui_select"):
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
