extends Control

# ON READY VARIABLES
onready var sizeMenu = $VContainer/SizeContainer/SizeOption
onready var typeMenu = $VContainer/TypeContainer/TypeOption
onready var landMenu = $VContainer/LandContainer/LandOption

# ENUM
enum size {SMALL, LARGE, CONTINENTAL}
enum land {ARCHIPELAGO, CONTINENT}

# VARIABLES
var sizeSelected
var landSelected
var typeSelected

# SIGNALS
signal back(node)
signal createWorld()

func _ready():
	sizeMenu.add_item("Small region",0)
	sizeMenu.add_item("Large region",1)
	sizeMenu.add_item("Continental region",2)
	sizeMenu.selected = 1
	sizeSelected = size.LARGE
	
	landMenu.add_item("Archipelago",0)
	landMenu.add_item("Continent",1)
	landMenu.selected = 1
	landSelected = land.CONTINENT
	
	typeMenu.add_item("Artic",0)
	typeMenu.add_item("Balanced",1)
	typeMenu.add_item("Desertic",2)
	typeMenu.add_item("Tropical",3)
	typeMenu.selected = 1
	typeSelected = GlobalVar.type.BALANCED

func onBackButtonPressed():
	emit_signal("back",self)

func onSizeSelected(id):
	sizeSelected = id

func onLandSelected(id):
	landSelected = id

func onTypeSelected(id):
	typeSelected = id

func onCreateButtonPressed():
	match sizeSelected:
		size.SMALL:
			GlobalVar.mapSize = Vector2(32,16)
		size.LARGE:
			GlobalVar.mapSize = Vector2(48,24)
		size.CONTINENTAL:
			GlobalVar.mapSize = Vector2(64,32)
	
	match landSelected:
		land.ARCHIPELAGO:
			setLandFraction(45.0,50.0)
			GlobalVar.minMountains = 6
			GlobalVar.maxMountains = 12
		land.CONTINENT:
			setLandFraction(60.0,70.0)
			GlobalVar.minMountains = 3
			GlobalVar.maxMountains = 8
	
	match typeSelected:
		GlobalVar.type.ARTIC:
			var forestChance = 50.0 if landSelected == land.ARCHIPELAGO else 35.0
			print(forestChance)
			setTerrainChances(5.0,0.0,75.0,15.0,forestChance,GlobalVar.type.ARTIC)
			GlobalVar.minMountains = 6
			GlobalVar.hillsChance = 10
		GlobalVar.type.BALANCED:
			setTerrainChances(15.0,25.0,40.0,40.0,75.0,GlobalVar.type.BALANCED)
			GlobalVar.hillsChance = 10
		GlobalVar.type.DESERTIC:
			setTerrainChances(60.0,0.0,15.0,70.0,75.0,GlobalVar.type.DESERTIC)
			GlobalVar.hillsChance = 20
		GlobalVar.type.TROPICAL:
			setTerrainChances(5.0,25.0,40.0,30.0,80.0,GlobalVar.type.TROPICAL)
			GlobalVar.minMountains = 2
			GlobalVar.hillsChance = 15
			
	emit_signal("createWorld")

func setLandFraction(minFraction,maxFraction):
	GlobalVar.minLandFraction = minFraction
	GlobalVar.maxLandFraction = maxFraction

func setTerrainChances(desert,swamp,artic,grassland,forest,type):
	GlobalVar.desertChance = desert
	GlobalVar.swampChance = swamp
	GlobalVar.articChance = artic
	GlobalVar.grasslandChance = grassland
	GlobalVar.forestChance = forest
	GlobalVar.mapType = type
