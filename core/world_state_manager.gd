extends Node

var world_seed: int = 0
var gathered_resources: Array = []

func _ready():
	randomize()
	world_seed = randi()
	print("[WorldStateManager] New world seed generated: ", world_seed)
