extends Node

@export var tutorial_steps := [
	{"text": "Move with [W][A][S][D]", "action": "move"},
	{"text": "Hold [SPACE] to charge, release to jump", "action": "jump"},
	{"text": "Use [LMB] to aim", "action": "aim"},
	{"text": "Use [RMB] to shoot", "action": "shoot"},
	{"text": "Press [E] to interact", "action": "interact"},
	{"text": "Press [TAB] to open inventory", "action": "inventory"},
	{"text": "Press [ESC] to pause the game", "action": "pause"}
]

@onready var tutorial_label: Label = $"../HUD/TutorialLabel"
var current_step := 0
var completed_actions := {}

func _ready():
	if GameData.tutorial_done:
		tutorial_label.visible = false
	else:
		show_step(0)

func show_step(index: int):
	if index >= tutorial_steps.size():
		tutorial_label.visible = false
		GameData.tutorial_done = true
		return
	
	current_step = index
	tutorial_label.text = tutorial_steps[index]["text"]
	tutorial_label.visible = true

func mark_action_done(action_name: String):
	# Skip if already completed
	if completed_actions.has(action_name):
		return

	completed_actions[action_name] = true

	# If this action matches the current step, go to next
	if tutorial_steps[current_step]["action"] == action_name:
		await get_tree().create_timer(1.0).timeout
		advance_to_next_step()
	else:
		# In case player did a future step early, auto-skip finished ones
		advance_to_next_step()

func advance_to_next_step():
	while current_step < tutorial_steps.size() and completed_actions.has(tutorial_steps[current_step]["action"]):
		current_step += 1
	show_step(current_step)
