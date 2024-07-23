extends Node

class_name AI_Agent

const Goal = preload("res://scripts/Goal.gd")
const Action = preload("res://scripts/Action.gd")
const Planner = preload("res://scripts/Planner.gd")

const MIN_PRIORITY = 1
const MAX_PRIORITY = 10

var primary_goals: Array = []
var secondary_goals: Array = []
var actions: Array = []
var state: Dictionary = {}
var current_plan: Array = []
var static_actions: Array = [
	Action.new("KeepLightOnYourToes", {}, {}, {}),
]
var available_actions: Array = []


var debug_print_goals: bool = false
var debug_current_goal_priorities: Array = []
var debug_print_available_actions: bool = false
var simulated_character: Dictionary = {
	"health": 10,
	"max_health": 10,
}

func _ready():
	state = {}
	primary_goals.append(Goal.new().new_goal_with_callable("stay_alive", calculate_stay_alive_goal_priority))
	primary_goals.append(Goal.new().new_goal_with_static_priority("defeat_enemy", 6.0))

func _process(_delta: float) -> void:
	if debug_print_goals or debug_print_available_actions:
		print("-----")
	if debug_print_goals:
		print(len(primary_goals))
		for goal in primary_goals:
			print("Goal: [{goal}], Priority: [{priority}]".format({"goal": goal.goal_name, "priority": goal.goal_priority}))
		debug_print_goals = false
	if debug_print_available_actions:
		for action in available_actions:
			print("Action: [{action}]".format({"action": action.action_name}))
		debug_print_available_actions = false
	
	
	determine_priority_goal()
	


func calculate_stay_alive_goal_priority(parameters: Dictionary) -> float:
	var calculated_priority: float = ((float(parameters.max_health) - float(parameters.health)) / float(parameters.max_health)) * (float(MAX_PRIORITY) - 1) + 1
	return calculated_priority


func determine_priority_goal() -> void:
	var current_goal_priorities: Array
	for i in range(primary_goals.size()):
		primary_goals[i].calculate_goal_priority(simulated_character)
		current_goal_priorities.append(primary_goals[i].goal_priority)
	
	primary_goals.sort_custom(func (a,b): return a.goal_priority > b.goal_priority)
	
	if current_goal_priorities != debug_current_goal_priorities:
		debug_print_goals = true
		debug_current_goal_priorities = current_goal_priorities


#func _ready():
	## Define initial state, goals, and actions
	#state = {
		#"has_warehouse": false,
		#"has_house": false,
		#"has_wood": false,
		#"has_axe": false
	#}
#
	#goals.append(Goal.new("has_house", 10))
	#goals.append(Goal.new("has_warehouse", 5))
	#
	#actions.append(Action.new("Get Axe", {}, {"has_axe": true}, {}))
	#actions.append(Action.new("Collect Wood", {"has_axe": true}, {"has_wood": true}, {}))
	#actions.append(Action.new("Build House", {"has_wood": true}, {"has_house": true}, {"has_wood": false}))
	#actions.append(Action.new("Build Warehouse", {"has_wood": true}, {"has_warehouse": true}, {"has_wood": false}))
#
	## Plan and execute
	#var planner = Planner.new()
	#var current_action = planner.plan(actions, goals, state)
	#while true:
		#print("Applying Action: [{action}]".format({"action": current_action.action_name}))
		#state = current_action.apply(state)
		#if state["has_house"] && state["has_warehouse"]:
			#break
		#current_action = planner.plan(actions, goals, state)
	#print("Final state: " + str(state))


func _on_decrease_health_button_pressed():
	simulated_character.health -=1

func _on_increase_health_button_pressed():
	simulated_character.health = clamp(simulated_character.health+1, 0, simulated_character.max_health)

func _on_attack_action_button_pressed():
	available_actions.append(Action.new("AttackTarget", {"character_in_attack_range": true, "chracter_able_to_attack": true}, {"defeat_enemy": true}, {}))
	debug_print_available_actions = true

func _on_defend_action_button_pressed():
	available_actions.append(Action.new("DefendAgainstAttack", {"chracter_can_defend": true, "character_is_being_attacked": true}, {"save_health": true}, {}))
	debug_print_available_actions = true
