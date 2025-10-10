# GameData.gd
extends Node

var best_time: float = -1.0
var elapsed_time: float = 0.0
var timing_active: bool = true
var loaded_save_data = null
var collected_coin_positions: Dictionary = {}
var npcs_to_save: Dictionary = {}
var at_goal: bool = false
var custom_seed = -1

func reset_timer():
	elapsed_time = 0.0
	timing_active = true

func reset_best_time():
	best_time = -1.0
	
var collected_keys = {"K": false,"U": false,"C": false,"O": false,"M": false,"S": false,"C2": false,"I": false} 

func reset_keys():
	collected_keys = {"K": false,"U": false,"C": false,"O": false,"M": false,"S": false,"C2": false,"I": false}

func has_all_keys() -> bool:
	for key in collected_keys.values():
		if not key:
			return false
	return true
