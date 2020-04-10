extends Node

# CONSTANTS
const TOOL_BAR_HEIGHT = 100

const HEX_WIDTH = 164.0
const HEX_HEIGHT = 142.0
const SELECTED = 99
const UNSELECTED = -1

const OFFSET_NEIGHBORS = [Vector2(0,-1),Vector2(1,0),Vector2(1,1),Vector2(0,1),Vector2(-1,1),Vector2(-1,0)]
const REGULAR_NEIGHBORS = [Vector2(0,-1),Vector2(1,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0),Vector2(-1,-1)]

# ENUMS
enum hexType {REGULAR, OFFSET}
enum tileType {EMPTY, FOREST, DESERT, ARTIC, GRASSLAND, SWAMP, WATER}
enum tileFeature {MOUNTAIN, HILL}

func _ready():
	pass
