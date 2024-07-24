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
var static_actions: Array = []
var available_actions: Array = []

var debug_print: bool = false
var debug_print_goals: bool = false
var debug_print_available_actions: bool = false
var debug_print_secondary_goals: bool = false
var debug_print_plan: bool = false
var debug_current_goal_priorities: Array = []
var debug_secondary_goal_priorities: Array = []
var simulated_character: Dictionary = {
	"health": 10,
	"max_health": 10,
}
var control_run_planner: bool = false

func _ready():
	state = {
		"chracter_can_see_target" = false,
		"character_in_attack_range" = false,
		"chracter_able_to_attack" = false,
	}
	primary_goals.append(Goal.new().new_goal_with_callable("stay_alive", calculate_stay_alive_goal_priority))
	primary_goals.append(Goal.new().new_goal_with_static_priority("defeat_enemy", 6.0))

func _process(_delta: float) -> void:
	handle_debug()

	primary_goals=determine_priority_goal(primary_goals)
	#secondary_goals=plan_secondary_goals(secondary_goals)
	

	#run_planner()
	if control_run_planner:
		run_planner()
		control_run_planner = false




func calculate_stay_alive_goal_priority(parameters: Dictionary) -> float:
	var calculated_priority: float = ((float(parameters.max_health) - float(parameters.health)) / float(parameters.max_health)) * (float(MAX_PRIORITY) - 1) + 1
	return calculated_priority


# Takes an array of goals, runs the "calculate_goal_priority" function which either calls the goal callable or returns the static priority. Sorts the goals from highest priority to lowest.
func determine_priority_goal(goals: Array) -> Array:
	var current_goal_priorities: Array
	for i in range(goals.size()):
		goals[i].calculate_goal_priority(simulated_character)
		current_goal_priorities.append(goals[i].goal_priority)
	
	goals.sort_custom(func (a,b): return a.goal_priority > b.goal_priority)
	
	if current_goal_priorities != debug_current_goal_priorities:
		debug_print_goals = true
		debug_print = true
		debug_current_goal_priorities = current_goal_priorities
	
	return goals

# Takes an Array of primary goals, runs the Planner "plan_secondary_goals" function.
# The "plan_secondary_goals" function runs through all primary goals and available actions and builds a new goal list that will be used to achieve the desired state.
func plan_secondary_goals(goals: Array) -> Array:
	var planner = Planner.new()
	goals = planner.plan_secondary_goals(available_actions, primary_goals, state)
	if len(goals) != len(debug_secondary_goal_priorities):
		debug_secondary_goal_priorities=goals
		debug_print_secondary_goals = true
		debug_print = true
	return goals

func run_planner() -> void:
	var planner = Planner.new()
	var plan: Array = planner.build_plan(available_actions, primary_goals, secondary_goals, state)
	if current_plan != plan:
		current_plan = plan
		debug_print_plan = true
		debug_print = true


func handle_debug() -> void:
	if debug_print:
		print("--START CHANGE--")
		if debug_print_goals:
			for goal in primary_goals:
				print("Goal: [{goal}], Priority: [{priority}]".format({"goal": goal.goal_name, "priority": goal.goal_priority}))
			debug_print_goals = false
		if debug_print_secondary_goals:
			for goal in secondary_goals:
				print("Secondary Goal: [{goal}], Priority: [{priority}]".format({"goal": goal.goal_name, "priority": goal.goal_priority}))
			debug_print_secondary_goals = false
		
		if debug_print_available_actions:
			for action in available_actions:
				print("Action: [{action}]".format({"action": action.action_name}))
			debug_print_available_actions = false
		if debug_print_plan:
			print("Plan: [{plan}]".format({"plan": current_plan}))
	if debug_print:
		print("--END CHANGE--")
		debug_print = false


func _on_decrease_health_button_pressed():
	simulated_character.health -=1

func _on_increase_health_button_pressed():
	simulated_character.health = clamp(simulated_character.health+1, 0, simulated_character.max_health)

func _on_attack_action_button_pressed():
	available_actions.append(Action.new("AttackTarget", {
		"chracter_can_see_target": true,
		"character_in_attack_range": true, 
		"chracter_able_to_attack": true,
	}, {"defeat_enemy": true}, {}))
	debug_print_available_actions = true
	debug_print = true

func _on_defend_action_button_pressed():
	available_actions.append(Action.new("DefendAgainstAttack", {"chracter_can_defend": true, "character_is_being_attacked": true}, {"save_health": true}, {}))
	debug_print_available_actions = true
	debug_print = true


func _on_run_planner_pressed():
	control_run_planner = true


func _on_print_state_pressed():
	print(state)
