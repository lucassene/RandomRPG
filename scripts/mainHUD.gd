extends MarginContainer

# ON READY SCENES
onready var labelIndex = $VBoxContainer/index
onready var labelID = $VBoxContainer/id
onready var labelNeighbors = $VBoxContainer/neighbors
onready var labelTimer = $VBoxContainer/time
onready var labelPosition = $VBoxContainer/position
onready var grid = get_node("/root/Main/HexGrid")

func _ready():
	grid.connect("hover",self,"onTileHovered")
	grid.connect("mapCreated",self,"onMapCreated")

func onTileHovered(index,id,neighbors,position):
	labelIndex.text = "Index: " + str(index)
	labelID.text = "Tile: " + id
	var tiles = "Neighbors: ("
	for i in neighbors:
		tiles += str(i) + ","
	tiles += ")"
	labelNeighbors.text = tiles
	labelPosition.text = "Position: " + str(position)

func onMapCreated(timeSpent):
	labelTimer.text = "Time: " + str(timeSpent) + " ms"
