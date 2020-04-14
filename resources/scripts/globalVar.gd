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
enum type {ARTIC, BALANCED, DESERTIC, TROPICAL}
enum settlement {CAMP, VILLAGE, TOWN, CITY}

# VARIABLES
var mapSize = Vector2(32,16)
var mapType = -1
var minLandFraction = 50.0
var maxLandFraction = 70.0
var desertChance = 10.0
var swampChance = 10.0
var grasslandChance = 30.0
var forestChance = 30.0
var articChance = 30.0
var maxMountains = 8
var minMountains = 3
var hillsChance = 10

func _ready():
	pass
