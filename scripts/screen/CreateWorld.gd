extends Control

# ON READY VARIABLES
onready var sizeMenu = $VContainer/SizeContainer/SizeOption
onready var typeMenu = $VContainer/TypeContainer/TypeOption

# ENUMS
enum size {SMALL, MEDIUM, CONTINENTAL}
enum type {ARCHIPELAGO, ARTIC, BALANCED, DESERTIC, TROPICAL}

# VARIABLES
var sizeSelected
var typeSelected

# SIGNALS
signal back(node)
signal createWorld()

func _ready():
	sizeMenu.add_item("Small region",0)
	sizeMenu.add_item("Medium region",1)
	sizeMenu.add_item("Continental region",2)
	sizeMenu.selected = 2
	sizeSelected = size.CONTINENTAL
	
	typeMenu.add_item("Archipelago",0)
	typeMenu.add_item("Artic",1)
	typeMenu.add_item("Balanced",2)
	typeMenu.add_item("Desertic",3)
	typeMenu.add_item("Tropical",4)
	typeMenu.selected = 2
	typeSelected = type.BALANCED

func onBackButtonPressed():
	emit_signal("back",self)

func onSizeSelected(id):
	sizeSelected = id

func onTypeSelected(id):
	typeSelected = id

func onCreateButtonPressed():
	match sizeSelected:
		size.SMALL:
			GlobalVar.mapSize = Vector2(16,8)
		size.MEDIUM:
			GlobalVar.mapSize = Vector2(32,16)
		size.CONTINENTAL:
			GlobalVar.mapSize = Vector2(48,24)
	
	match typeSelected:
		type.ARCHIPELAGO:
			GlobalVar.minLandFraction = 45.0
			GlobalVar.maxLandFraction = 55.0
		type.BALANCED:
			GlobalVar.minLandFraction = 60.0
			GlobalVar.maxLandFraction = 70.0
	
	emit_signal("createWorld")
