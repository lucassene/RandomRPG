extends Node2D

# EXPORT VARIABLES
export (PackedScene) var HexTile

# ON READY SCENES
onready var playerMarker = $mapPlayer
onready var playerCamera = $mapPlayer/Camera2D
onready var tween = $Tween

# SIGNALS
signal hover(index,id)
signal mapCreated(timeSpent)

# CONSTANTS
const TERRAIN_REGULAR = 1.0
const TERRAIN_HARD = 2.0

# VARIABLES
var tilesList = []
var selectedTile = -1

var articRegion = 0
var tropicalRegion = 0
var aridRegion = 0
var southRegion = 0

var terrainFraction

var mountainTiles = []

var articTiles = []
var waterTiles = []
var emptyTiles = []
var grasslandTiles = []
var forestTiles = []
var swampTiles = []
var desertTiles = []

var playerTile
var isMoving = false
var hasBoat = false

var aStar

func _ready():
	randomize()
	var path = .get_path()
	print(path)
	aStar = AStar2D.new() 
	playerMarker.visible = false
	
	var timeBefore = OS.get_ticks_msec()
	generateMap()
	print("Começo: ",tilesList[0].hex.position)
	print("Final: ",tilesList[tilesList.size()-1].hex.position)
	playerCamera.setLimits(tilesList[playerTile], GlobalVar.mapSize)
	var totalTime = OS.get_ticks_msec() - timeBefore
	emit_signal("mapCreated",totalTime)

func generateMap():
	terrainFraction = rand_range(GlobalVar.minLandFraction,GlobalVar.maxLandFraction)
	print("Fraction: ", terrainFraction)
	
	articTiles.clear()
	waterTiles.clear()
	emptyTiles.clear()
	grasslandTiles.clear()
	forestTiles.clear()
	swampTiles.clear()
	desertTiles.clear()
	
	if tilesList.size() > 0:
		for each in tilesList:
			each.queue_free()
		tilesList.clear()	
	
	for x in range(0, GlobalVar.mapSize.x):
		for y in range(0,GlobalVar.mapSize.y):
			var tile = HexTile.instance()
			var yPos = 0
			var xPos = 0
			add_child(tile)
			tile.connect("selected",self,"onTileSelected")
			tile.connect("hover",self,"onTileHover")
			
			if x % 2 == 0:
				yPos = (y * GlobalVar.HEX_HEIGHT) + GlobalVar.HEX_HEIGHT/2
				xPos = (x+1) * GlobalVar.HEX_WIDTH/2 + (x * GlobalVar.HEX_WIDTH/4)
				tile.position = Vector2(xPos,yPos)
				tile.hex.position = tile.position
				tile.hex.id = Vector2(x,y)
				tilesList.append(tile)
				tile.hex.index = tilesList.size()-1
				tile.hex.type = GlobalVar.hexType.REGULAR
			else:
				yPos = (y * GlobalVar.HEX_HEIGHT) + GlobalVar.HEX_HEIGHT
				xPos = (x+1) * GlobalVar.HEX_WIDTH/2 + (x * GlobalVar.HEX_WIDTH/4)
				tile.position = Vector2(xPos,yPos)
				tile.hex.position = tile.position
				tile.hex.id = Vector2(x,y)
				tilesList.append(tile)
				tile.hex.index = tilesList.size()-1
				tile.hex.type = GlobalVar.hexType.OFFSET
			
			aStar.add_point(tile.hex.index,tile.hex.position,TERRAIN_REGULAR)
			aStar.set_point_disabled(tile.hex.index,true)
			tile.setNeighbors(GlobalVar.mapSize.x,GlobalVar.mapSize.y)
				
			var num = rand_range(0.0,100.0)
			if num < terrainFraction:
				tile.setTerrain(GlobalVar.tileType.EMPTY)
				emptyTiles.append(tile.hex.index)
			else:
				tile.setTerrain(GlobalVar.tileType.WATER)
				aStar.set_point_weight_scale(tile.hex.index,TERRAIN_HARD)
				waterTiles.append(tile.hex.index)
			
			var rndA = randi() % 3
			var rndB = randi() % 3 + 1
			if x <= rndA or x >= GlobalVar.mapSize.x -rndB or y <= rndA or y >= GlobalVar.mapSize.y -rndB:
				tile.setTerrain(GlobalVar.tileType.WATER)
				aStar.set_point_weight_scale(tile.hex.index,TERRAIN_HARD)
				if waterTiles.find(tile.hex.index) == -1:
					waterTiles.append(tile.hex.index)
				if emptyTiles.find(tile.hex.index) != -1:
					emptyTiles.erase(tile.hex.index)
				
	smoothMap()
	cleanMap()
	generateCoast()
	generateInland()
	generateMountains()
	generateHills()
	cleanEmpties()
	connectTiles()
	playerStart()

func smoothMap():
	for x in range(2, GlobalVar.mapSize.x -3):
		for y in range(2, GlobalVar.mapSize.y -3):
			var neighborWater = 0
			#var dir = Vector2(x,y)
			var index = y + (x * GlobalVar.mapSize.y)
			var tile = tilesList[index]
			var neighbor
			
			for index in tile.hex.neighbors:
				neighbor = tilesList[index]
				if neighbor and neighbor.hex.terrain == GlobalVar.tileType.WATER:
					neighborWater += 1
			
			var rnd = randi() % 100
			if rnd <= 33:
				tile = neighbor
			
			if tile and neighborWater > 3:
				tile.setTerrain(GlobalVar.tileType.WATER)
				aStar.set_point_weight_scale(tile.hex.index,TERRAIN_HARD)
				if waterTiles.find(tile.hex.index) == -1:
					waterTiles.append(tile.hex.index)
				if emptyTiles.find(tile.hex.index) != -1:
					emptyTiles.erase(tile.hex.index)
			elif tile and neighborWater < 3:
				if tile.hex.id.x > 0 and tile.hex.id.x < GlobalVar.mapSize.x -1  and tile.hex.id.y > 0 and tile.hex.id.y < GlobalVar.mapSize.y -1:
					tile.setTerrain(GlobalVar.tileType.EMPTY)
					if emptyTiles.find(tile.hex.index) == -1:
						emptyTiles.append(tile.hex.index)
					if waterTiles.find(tile.hex.index) != -1:
						waterTiles.erase(tile.hex.index)

func cleanMap():	
	var counter = 0
	var nTotal = 0
	for tile in tilesList:
		var x = tile.hex.id.x
		var y = tile.hex.id.y
		if x > 0 and x < GlobalVar.mapSize.x -1 and y > 0 and y < GlobalVar.mapSize.y -1:
			var neighbors = tile.hex.neighbors
			nTotal = 0
			counter = 0
			for index in neighbors:
				var neighbor = tilesList[index]
				if neighbor:
					nTotal += 1
					if neighbor.hex.terrain != tile.hex.terrain:
						counter += 1
			var offset = randi() % 2
			if counter >= nTotal - offset:
				if tile.hex.terrain == GlobalVar.tileType.WATER:
					tile.setTerrain(GlobalVar.tileType.EMPTY)
					if emptyTiles.find(tile.hex.index) == -1:
						emptyTiles.append(tile.hex.index)
					if waterTiles.find(tile.hex.index) != -1:
						waterTiles.erase(tile.hex.index)
				else:
					tile.setTerrain(GlobalVar.tileType.WATER)
					aStar.set_point_weight_scale(tile.hex.index,TERRAIN_HARD)
					if waterTiles.find(tile.hex.index) == -1:
						waterTiles.append(tile.hex.index)
					if emptyTiles.find(tile.hex.index) != -1:
						emptyTiles.erase(tile.hex.index)

func generateCoast():
	var toRemove = []
	for index in emptyTiles:
		var waterNeighbor = 0
		var tile = tilesList[index]
		if tile.hex.terrain != GlobalVar.tileType.WATER:
			for each in tile.hex.neighbors:
				var neighbor = tilesList[each]
				if neighbor.hex.terrain == GlobalVar.tileType.WATER:
					waterNeighbor += 1
			if waterNeighbor >= 1:
				var rnd = randi() % 100
				if rnd <= GlobalVar.desertChance:
					tile.setTerrain(GlobalVar.tileType.DESERT)
					desertTiles.append(tile.hex.index)
				elif rnd <= GlobalVar.swampChance:
					tile.setTerrain(GlobalVar.tileType.SWAMP)
					swampTiles.append(tile.hex.index)
				elif rnd <= GlobalVar.articChance:
					tile.setTerrain(GlobalVar.tileType.ARTIC)
					articTiles.append(tile.hex.index)
				else:
					tile.setTerrain(GlobalVar.tileType.GRASSLAND)
					grasslandTiles.append(tile.hex.index)
				toRemove.append(tile.hex.index)
	
	for each in toRemove:
		emptyTiles.erase(each)
	
	match GlobalVar.mapType:
		GlobalVar.type.ARTIC:
			reviewTerrain(desertTiles,articTiles,GlobalVar.tileType.ARTIC,grasslandTiles,GlobalVar.tileType.GRASSLAND)
			cleanIsolated(desertTiles,articTiles,GlobalVar.tileType.ARTIC,forestTiles,GlobalVar.tileType.FOREST)
			cleanIsolated(forestTiles,articTiles,GlobalVar.tileType.ARTIC,grasslandTiles,GlobalVar.tileType.GRASSLAND)
		GlobalVar.type.BALANCED:
			reviewTerrain(swampTiles,desertTiles,GlobalVar.tileType.DESERT,grasslandTiles,GlobalVar.tileType.GRASSLAND)
			reviewTerrain(desertTiles,swampTiles,GlobalVar.tileType.SWAMP,grasslandTiles,GlobalVar.tileType.GRASSLAND)
		GlobalVar.type.DESERTIC:
			reviewTerrain(forestTiles,grasslandTiles,GlobalVar.tileType.GRASSLAND,desertTiles,GlobalVar.tileType.DESERT)
			reviewTerrain(desertTiles,grasslandTiles,GlobalVar.tileType.GRASSLAND,forestTiles,GlobalVar.tileType.FOREST)
			cleanIsolated(desertTiles,grasslandTiles,GlobalVar.tileType.GRASSLAND,forestTiles,GlobalVar.tileType.FOREST)
			cleanIsolated(grasslandTiles,desertTiles,GlobalVar.tileType.DESERT,forestTiles,GlobalVar.tileType.FOREST)
		GlobalVar.type.TROPICAL:
			reviewTerrain(desertTiles,grasslandTiles,GlobalVar.tileType.GRASSLAND,swampTiles,GlobalVar.tileType.SWAMP)
			reviewTerrain(swampTiles,grasslandTiles,GlobalVar.tileType.GRASSLAND,forestTiles,GlobalVar.tileType.FOREST)

func generateInland():
	var toRemove = []
	for index in emptyTiles:
		var tile = tilesList[index]
		var empty = 0
		if not empty == tile.hex.neighbors.size() and tile.hex.terrain != GlobalVar.tileType.WATER:
			var chance = randi() % 100
			if chance <= GlobalVar.desertChance:
				tile.setTerrain(GlobalVar.tileType.DESERT)
				desertTiles.append(tile.hex.index)
				toRemove.append(tile.hex.index)
			else:
				if chance <= GlobalVar.grasslandChance:
					tile.setTerrain(GlobalVar.tileType.GRASSLAND)
					grasslandTiles.append(tile.hex.index)
					toRemove.append(tile.hex.index)
				elif chance <= GlobalVar.forestChance:
					tile.setTerrain(GlobalVar.tileType.FOREST)
					forestTiles.append(tile.hex.index)
					toRemove.append(tile.hex.index)
				else:
					tile.setTerrain(GlobalVar.tileType.ARTIC)
					articTiles.append(tile.hex.index)
					toRemove.append(tile.hex.index)
	
	for each in toRemove:
		emptyTiles.erase(each)
	
	match GlobalVar.mapType:
		GlobalVar.type.ARTIC:
			reviewTerrain(desertTiles,articTiles,GlobalVar.tileType.ARTIC,grasslandTiles,GlobalVar.tileType.GRASSLAND)
			reviewTerrain(grasslandTiles,articTiles,GlobalVar.tileType.ARTIC,forestTiles,GlobalVar.tileType.FOREST)
			reviewTerrain(forestTiles,articTiles,GlobalVar.tileType.ARTIC,grasslandTiles,GlobalVar.tileType.GRASSLAND)
			cleanIsolated(desertTiles,articTiles,GlobalVar.tileType.ARTIC,grasslandTiles,GlobalVar.tileType.GRASSLAND)
			#cleanIsolated(grasslandTiles,articTiles,GlobalVar.tileType.ARTIC,forestTiles,GlobalVar.tileType.FOREST)
			#cleanIsolated(forestTiles,articTiles,GlobalVar.tileType.ARTIC,grasslandTiles,GlobalVar.tileType.GRASSLAND)
		GlobalVar.type.BALANCED:
			reviewTerrain(desertTiles,grasslandTiles,GlobalVar.tileType.GRASSLAND,forestTiles,GlobalVar.tileType.FOREST)
			reviewTerrain(articTiles,forestTiles,GlobalVar.tileType.FOREST,grasslandTiles,GlobalVar.tileType.GRASSLAND)
			reviewTerrain(forestTiles,articTiles,GlobalVar.tileType.ARTIC,grasslandTiles,GlobalVar.tileType.GRASSLAND)
			cleanIsolated(desertTiles,grasslandTiles,GlobalVar.tileType.GRASSLAND,forestTiles,GlobalVar.tileType.FOREST)
			cleanIsolated(articTiles,forestTiles,GlobalVar.tileType.FOREST,desertTiles,GlobalVar.tileType.DESERT)
			#cleanIsolated(forestTiles,articTiles,GlobalVar.tileType.ARTIC,desertTiles,GlobalVar.tileType.DESERT)
		GlobalVar.type.DESERTIC:
			reviewTerrain(articTiles,forestTiles,GlobalVar.tileType.FOREST,grasslandTiles,GlobalVar.tileType.GRASSLAND)
			reviewTerrain(forestTiles,desertTiles,GlobalVar.tileType.DESERT,grasslandTiles,GlobalVar.tileType.GRASSLAND)
			reviewTerrain(grasslandTiles,desertTiles,GlobalVar.tileType.DESERT,forestTiles,GlobalVar.tileType.FOREST)
			cleanIsolated(articTiles,forestTiles,GlobalVar.tileType.FOREST,desertTiles,GlobalVar.tileType.DESERT)
			#cleanIsolated(forestTiles,grasslandTiles,GlobalVar.tileType.GRASSLAND,desertTiles,GlobalVar.tileType.DESERT)
		GlobalVar.type.TROPICAL:
			reviewTerrain(desertTiles,grasslandTiles,GlobalVar.tileType.GRASSLAND,forestTiles,GlobalVar.tileType.FOREST)
			reviewTerrain(articTiles,forestTiles,GlobalVar.tileType.FOREST,grasslandTiles,GlobalVar.tileType.GRASSLAND)
			reviewTerrain(forestTiles,grasslandTiles,GlobalVar.tileType.GRASSLAND,articTiles,GlobalVar.tileType.ARTIC)
			cleanIsolated(desertTiles,grasslandTiles,GlobalVar.tileType.GRASSLAND,forestTiles,GlobalVar.tileType.FOREST)
			cleanIsolated(articTiles,forestTiles,GlobalVar.tileType.FOREST,grasslandTiles,GlobalVar.tileType.GRASSLAND)

func checkList(text,tiles,terrain):
	var count = 0
	for each in tiles:
		var tile = tilesList[each]
		if tile.hex.terrain != terrain:
			count += 1
	if count > 0:
		print(text,count," ocorrências!")

func cleanIsolated(reviewTiles,terrainATiles,terrainA,terrainBTiles,terrainB):
	if reviewTiles.size() > 1:
		var toRemove = []
		var sameTerrain = tilesList[reviewTiles[0]].hex.terrain
		for index in reviewTiles:
			var tile = tilesList[index]
			var sameTerrainCount = 0
			var grassland = 0
			var terrainACount = 0
			var terrainBCount = 0
			var neighborToCheck
			for each in tile.hex.neighbors:
				var neighbor = tilesList[each]
				match (neighbor.hex.terrain):
					sameTerrain:
						sameTerrainCount += 1
						neighborToCheck = each
					GlobalVar.tileType.GRASSLAND:
						grassland += 1
					terrainA:
						terrainACount += 1
					terrainB:
						terrainBCount += 1
			if sameTerrainCount == 1:
				sameTerrainCount = 0
				for each in tilesList[neighborToCheck].hex.neighbors:
					var neighbor = tilesList[each]
					match (neighbor.hex.terrain):
						sameTerrain:
							sameTerrainCount += 1
						GlobalVar.tileType.GRASSLAND:
							grassland += 1
						terrainA:
							terrainACount += 1
						terrainB:
							terrainBCount += 1
				if sameTerrainCount == 1:
					if terrainACount > grassland and terrainACount > terrainBCount:
						tile.setTerrain(terrainA)
						tilesList[neighborToCheck].setTerrain(terrainA)
						if not terrainATiles.has(tile.hex.index): terrainATiles.append(tile.hex.index)
						if not terrainATiles.has(neighborToCheck): terrainATiles.append(neighborToCheck)
					elif terrainBCount > grassland and terrainBCount > terrainACount:
						tile.setTerrain(terrainB)
						tilesList[neighborToCheck].setTerrain(terrainB)
						if not terrainBTiles.has(tile.hex.index): terrainBTiles.append(tile.hex.index)
						if not terrainBTiles.has(neighborToCheck): terrainBTiles.append(neighborToCheck)
					else:
						tile.setTerrain(GlobalVar.tileType.GRASSLAND)
						tilesList[neighborToCheck].setTerrain(GlobalVar.tileType.GRASSLAND)
						if not grasslandTiles.has(tile.hex.index): grasslandTiles.append(tile.hex.index)
						if not grasslandTiles.has(neighborToCheck): grasslandTiles.append(neighborToCheck)
					toRemove.append(int(index))
					toRemove.append(int(neighborToCheck))
		for each in toRemove:
			reviewTiles.erase(each)

func reviewTerrain(reviewTiles,terrainATiles,terrainA,terrainBTiles,terrainB):
	if reviewTiles.size() > 0:
		var sameTerrain = tilesList[reviewTiles[0]].hex.terrain
		var toRemove = []
		var toAppend = []
		var emptyRemove = []
		for index in reviewTiles:
			var tile = tilesList[index]
			var sameTerrainList = []
			var terrainAList = []
			var terrainBList = []
			var empty = []
			for each in tile.hex.neighbors:
				var neighbor = tilesList[each]
				match (neighbor.hex.terrain):
					sameTerrain:
						sameTerrainList.append(neighbor.hex.index)
					terrainA:
						terrainAList.append(neighbor.hex.index)
					terrainB:
						terrainBList.append(neighbor.hex.index)
					GlobalVar.tileType.EMPTY:
						empty.append(neighbor.hex.index)
			if sameTerrainList.size() == 0:
				if terrainAList.size() >= 1:
						tile.setTerrain(terrainA)
						terrainATiles.append(tile.hex.index)
						toRemove.append(tile.hex.index)
				else:
					tile.setTerrain(terrainB)
					terrainBTiles.append(tile.hex.index)
					toRemove.append(tile.hex.index)
			elif empty.size() >= 1:
				for each in empty:
					tilesList[each].setTerrain(sameTerrain)
					toAppend.append(tilesList[each].hex.index)
					emptyRemove.append(each)
		for each in toRemove:
			reviewTiles.erase(each)
		for each in toAppend:
			reviewTiles.append(each)
		for each in emptyRemove:
			emptyTiles.erase(each)

func cleanEmpties():
	if emptyTiles.size() > 0:
		for index in emptyTiles:
			var tile = tilesList[index]
			var terrains = []
			for _i in range(7):
				terrains.append(0)
			for each in tile.hex.neighbors:
				var neighbor = tilesList[each]
				match (neighbor.hex.terrain):
					GlobalVar.tileType.ARTIC:
						terrains[GlobalVar.tileType.ARTIC] += 1
					GlobalVar.tileType.DESERT:
						terrains[GlobalVar.tileType.DESERT] += 1
					GlobalVar.tileType.FOREST:
						terrains[GlobalVar.tileType.FOREST] += 1
					GlobalVar.tileType.GRASSLAND:
						terrains[GlobalVar.tileType.GRASSLAND] += 1
					GlobalVar.tileType.SWAMP:
						terrains[GlobalVar.tileType.SWAMP] += 1
					GlobalVar.tileType.WATER:
						terrains[GlobalVar.tileType.WATER] += 1
			var terrain = terrains.find(terrains.max())
			tile.setTerrain(terrain)

func generateMountains():
	mountainTiles = []
	for index in articTiles:
		var tile = tilesList[index]
		for nIndex in tile.hex.neighbors:
			var neighbor = tilesList[nIndex]
			if neighbor.hex.terrain == GlobalVar.tileType.FOREST or neighbor.hex.terrain == GlobalVar.tileType.GRASSLAND:
				var rnd = randi () % 100
				if rnd <= 80:
					tile.setFeature(GlobalVar.tileFeature.MOUNTAIN)
					aStar.set_point_weight_scale(tile.hex.index,TERRAIN_HARD)
					mountainTiles.append(tile.hex.index)
				break
	
	var toCheckTiles = []

	for each in desertTiles:
		if toCheckTiles.find(each) == -1:
			toCheckTiles.append(each)
	for each in grasslandTiles:
		if toCheckTiles.find(each) == -1:
			toCheckTiles.append(each)
	var verifiedTiles = []
	var possibleChains = []

	for tileIndex in toCheckTiles:
		var toCheck = tilesList[tileIndex]
		verifiedTiles.append(tileIndex)
		var lookedTerrain = -1
		var rnd = randi () % 100
		if toCheck.hex.terrain == GlobalVar.tileType.GRASSLAND:
			if rnd <= 33:
				lookedTerrain = GlobalVar.tileType.FOREST
			elif rnd <= 66:
				lookedTerrain = GlobalVar.tileType.DESERT
			else:
				lookedTerrain = GlobalVar.tileType.WATER
		elif toCheck.hex.terrain == GlobalVar.tileType.DESERT:
			if rnd <= 33:
				lookedTerrain = GlobalVar.tileType.FOREST
			elif rnd <= 66:
				lookedTerrain = GlobalVar.tileType.GRASSLAND
			else:
				lookedTerrain = GlobalVar.tileType.WATER
		if lookedTerrain != -1:
			var neighborToCheck = []
			var validTiles = []
			for nIndex in toCheck.hex.neighbors:
				var neighbor = tilesList[nIndex]
				if neighbor.hex.terrain == lookedTerrain:
					neighborToCheck.append(nIndex)
			var counter = randi() % 18 + 6
			if neighborToCheck.size() > 0:
				validTiles.append(tileIndex)
				while counter > 0 and neighborToCheck.size() > 0:
					var checkingTile = tilesList[neighborToCheck[0]]
					for checkingIndex in checkingTile.hex.neighbors:
						var checkingNeighbor = tilesList[checkingIndex]
						if checkingNeighbor.hex.terrain == toCheck.hex.terrain and validTiles.find(checkingIndex) == -1:
							validTiles.append(checkingIndex)
						if checkingNeighbor.hex.terrain == lookedTerrain and neighborToCheck.find(checkingIndex) == -1:
							neighborToCheck.push_back(checkingIndex)
					neighborToCheck.erase(checkingTile.hex.index)
					counter -= 1
				if validTiles.size() == 1:
					validTiles.clear()

			if validTiles.size() > 0:
				for index in validTiles:
					var tile = tilesList[index]
					var sameTerrain = 0
					for nIndex in tile.hex.neighbors:
						var neighbor = tilesList[nIndex]
						if neighbor.hex.terrain == tile.hex.terrain:
							sameTerrain += 1
					if sameTerrain == 0:
						validTiles.erase(index)

			if validTiles.size() > 1:
				possibleChains.append(validTiles)

	var mountainChains = randi() % GlobalVar.maxMountains + GlobalVar.minMountains
	while mountainChains > 0 and possibleChains.size() > 0:
		var mountains = floor(rand_range(0.0,possibleChains.size()))
		for each in possibleChains[mountains]:
			var tile = tilesList[each]
			tile.setFeature(GlobalVar.tileFeature.MOUNTAIN)
			mountainTiles.append(tile.hex.index)
			aStar.set_point_weight_scale(tile.hex.index,TERRAIN_HARD)
		mountainChains -= 1

	for each in articTiles:
		var tile = tilesList[each]
		var rnd = randi() % 100
		if rnd <= 10:
			tile.setFeature(GlobalVar.tileFeature.MOUNTAIN)
			mountainTiles.append(tile.hex.index)
			aStar.set_point_weight_scale(tile.hex.index,TERRAIN_HARD)
			rnd = randi() % tile.hex.neighbors.size()
			var neighbor = tilesList[rnd]
			if neighbor.hex.terrain != GlobalVar.tileType.WATER:
				rnd = randi() % 100
				if rnd <= 50:
					neighbor.setFeature(GlobalVar.tileFeature.MOUNTAIN)
					mountainTiles.append(neighbor.hex.index)
					aStar.set_point_weight_scale(neighbor.hex.index,TERRAIN_HARD)

func generateHills():
	var toCheckTiles = []

	for each in desertTiles:
		if toCheckTiles.find(each) == -1:
			toCheckTiles.append(each)
	for each in grasslandTiles:
		if toCheckTiles.find(each) == -1:
			toCheckTiles.append(each)
	for each in articTiles:
		if not toCheckTiles.has(each):
			toCheckTiles.append(each)
	
	for each in toCheckTiles:
		var tile = tilesList[each]
		var rnd = randi() % 100
		if rnd <= GlobalVar.hillsChance and tile.hex.feature == -1:
			tile.setFeature(GlobalVar.tileFeature.HILL)

func connectTiles():
	for tile in tilesList:
		for each in tile.hex.neighbors:
			var neighbor = tilesList[each]
			var weight = TERRAIN_REGULAR
			if neighbor.hex.feature == GlobalVar.tileFeature.MOUNTAIN:
				weight = TERRAIN_HARD
			else:
				match tilesList[each].hex.terrain:
					GlobalVar.tileType.FOREST: 
						weight = TERRAIN_HARD
					GlobalVar.tileType.SWAMP: 
						weight = TERRAIN_HARD
					GlobalVar.tileType.WATER: 
						weight = TERRAIN_HARD
						if waterTiles.find(each) == -1:
							aStar.set_point_disabled(each,true)
			
			aStar.set_point_weight_scale(each,weight)
			aStar.connect_points(tile.hex.index,each,true)

func playerStart():
	var rnd = randi() % tilesList.size() -1
	while tilesList[rnd].hex.terrain == GlobalVar.tileType.WATER or tilesList[rnd].hex.terrain == GlobalVar.tileType.EMPTY or tilesList[rnd].hex.feature == GlobalVar.tileFeature.MOUNTAIN or tilesList[rnd].hex.feature == GlobalVar.tileFeature.HILL:
		rnd = randi() % tilesList.size() -1
	
	playerMarker.position = tilesList[rnd].hex.position
	tilesList[rnd].setSettlement(randi() % GlobalVar.settlement.size())
	playerMarker.visible = true
	tilesList[rnd].setFog(false)
	revealNeighbors(tilesList[rnd],false)
	playerTile = rnd

func setTerrain(tile, terrain):
	if tile.hex.terrain == -1:
		if terrain == -1:
			terrain = randi() % GlobalVar.tileType.size()
		tile.setTerrain(terrain)
	return terrain

func onTileSelected(tile):
	if selectedTile != -1:
		tilesList[selectedTile].setTerrain(GlobalVar.UNSELECTED)
	if tile.hex.terrain == -1:
		selectedTile = -1
	elif not selectedTile == tilesList.find(tile) and not isMoving and not tile.hex.hasFog:
		var canMove = false
		if tile.hex.terrain == GlobalVar.tileType.WATER and hasBoat:
			canMove = true
		if tile.hex.terrain != GlobalVar.tileType.WATER:
			canMove = true

		if canMove:
			playerCamera.returnToTarget(true)
			movePlayer(tile)
			selectedTile = tile.hex.index
			tile.setFog(false)
			tile.setTerrain(GlobalVar.SELECTED)
	else:
		selectedTile = -1

func movePlayer(target):
	if target.hex.terrain != GlobalVar.tileType.EMPTY and not isMoving:
		var path = []
		isMoving = true
		path = aStar.get_id_path(playerTile,target.hex.index)
		path.remove(0)
		for each in path:
			var tile = tilesList[each]
			tween.interpolate_property(playerMarker,"position",playerMarker.position,tile.hex.position,0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
			tween.start()
			yield(get_tree().create_timer(0.5),"timeout")
			playerTile = each
			revealNeighbors(tilesList[playerTile],false)
		isMoving = false
		playerCamera.returnToTarget(false)
		playerCamera.setLimits(tilesList[playerTile],GlobalVar.mapSize)
	
func revealNeighbors(tile, fog):
	for each in tile.hex.neighbors:
		var neighbor = tilesList[each]
		neighbor.setFog(fog)
		if neighbor.hex.terrain != GlobalVar.tileType.WATER or hasBoat:
			aStar.set_point_disabled(each,fog)

func isNeighbor(origin,target):
	var index = -1
	for neighbor in origin.hex.neighbors:
		if neighbor == target.hex.index:
			index = neighbor
	if index != -1: 
		return true
	else:
		return false
	
func onTileHover(tile):
	var index = tilesList.find(tile)
	var text = "(%s,%s)" % [tile.hex.id.x,tile.hex.id.y]
	emit_signal("hover",index, text, tile.hex.neighbors, tile.hex.position)
	
func waterTilesDisabled(disabled):
	for each in waterTiles:
		aStar.set_point_disabled(each,disabled)

func _unhandled_input(event):
	if event.is_action_pressed("1"):
		#hasBoat = true
		#waterTilesDisabled(false)
		var timeBefore = OS.get_ticks_msec()
		generateMap()
		var totalTime = OS.get_ticks_msec() - timeBefore
		emit_signal("mapCreated",totalTime)
