extends Control

# ON READY VARIABLES
onready var createWorld = $MarginContainer/HBoxContainer/FrameContainer/CreateWorld

# EXPORT VARIABLES
export(String, FILE) var toScene

func _ready():
	createWorld.connect("back",self,"onBackPressed")
	createWorld.connect("createWorld",self,"onCreateWorld")

func onNewGamePressed():
	createWorld.visible = true

func onExitGamePressed():
	get_tree().quit()
	
func onBackPressed(node):
	node.visible = false

func onCreateWorld():
	get_tree().change_scene(toScene)
