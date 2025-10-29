# GameData.gd
extends Node

var best_time: float = -1.0
var elapsed_time: float = 0.0
var timing_active: bool = true
var mouse_sensitivity := 0.0015
var loaded_save_data = null
var collected_coin_positions: Dictionary = {}
var npcs_to_save: Dictionary = {}
var at_goal: bool = true
var custom_seed = -1
var tutorial_done = false
func reset_timer():
	elapsed_time = 0.0
	timing_active = true

func reset_best_time():
	best_time = -1.0
	tutorial_done = false
	at_goal = true
var collected_keys = {"K": false,"U": false,"C": false,"O": false,"M": false,"S": false,"C2": false,"I": false} 

func reset_keys():
	collected_keys = {"K": false,"U": false,"C": false,"O": false,"M": false,"S": false,"C2": false,"I": false}

func has_all_keys() -> bool:
	for key in collected_keys.values():
		if not key:
			return false
	return true
