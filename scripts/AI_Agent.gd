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
var world_state: Dictionary = {}
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
	"stamina": 8,
	"max_stamina": 8,
	"antsy": 1,
}
var control_run_planner: bool = false

@onready var goals_textbox = $"../Control/Goals"
@onready var state_textbox = $"../Control/State/StateDebug"
@onready var sim_char_textbox = $"../Control/CharacterAttributes/SimCharDebug"




func _ready():
	world_state = {
		"chracter_can_see_target" = false,
		"character_in_attack_range" = false,
		"chracter_able_to_attack" = false,
	}
	
	primary_goals.append(Goal.new().new_goal_with_callable("conserve_health", calculate_conserve_health_priority))
	primary_goals.append(Goal.new().new_goal_with_callable("conserve_stamina", calculate_conserve_stamina_priority))
	primary_goals.append(Goal.new().new_goal_with_static_priority("defeat_enemy", 4.5))
	primary_goals.append(Goal.new().new_goal_with_timer("keep_moving", calculate_keep_moving_priority, .5, keep_moving_interval_increase, get_parent()))
	# Keep in optimal range will need to be written after some actions are in place. 
	# Initial thought: Based on the actions, determine what the optimal range is
	#primary_goals.append(Goal.new().new_goal_with_callable("keep_in_optimal_range", calculate_conserve_stamina_priority))

func _process(_delta: float) -> void:
	primary_goals=determine_priority_goal(primary_goals)
	
	# debugging
	debug_state()
	debug_simulated_character()
	debug_goals()


func debug_goals() -> void:
	var goals_text: String
	for goal in primary_goals:
		goals_text = "{goal_text}\nGoal: [{goal}], Priority: [{priority}]".format({"goal_text": goals_text, "goal": goal.goal_name, "priority": goal.goal_priority})
	goals_textbox.text = goals_text

func debug_state() -> void:
	var character_text: String
	var character_keys = simulated_character.keys()
	for attribute in character_keys:
		character_text = "{character_text}\nAttribute: [{attribute}], Value: [{value}]".format({"character_text": character_text, "attribute": attribute, "value": simulated_character[attribute]})
	sim_char_textbox.text = character_text

func debug_simulated_character() -> void:
	var state_text: String
	var state_keys = world_state.keys()
	for state in state_keys:
		state_text = "{state_text}\nState: [{state}], Value: [{value}]".format({"state_text": state_text, "state": state, "value": world_state[state]})
	state_textbox.text = state_text

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




func calculate_conserve_health_priority(parameters: Dictionary) -> float:
	var calculated_priority: float = ((float(parameters.max_health) - float(parameters.health)) / float(parameters.max_health)) * (float(parameters.max_health) - 1) + 1
	return calculated_priority

func calculate_conserve_stamina_priority(parameters: Dictionary) -> float:
	var calculated_priority: float = ((float(parameters.max_stamina) - float(parameters.stamina)) / float(parameters.max_stamina)) * (float(parameters.max_stamina) - 1) + 1
	return calculated_priority

func calculate_keep_moving_priority(parameters: Dictionary) -> float:
	return parameters.antsy

func keep_moving_interval_increase() -> void:
	simulated_character.antsy = clamp((simulated_character.antsy*1.3), 0, MAX_PRIORITY)


# Takes an Array of primary goals, runs the Planner "plan_secondary_goals" function.
# The "plan_secondary_goals" function runs through all primary goals and available actions and builds a new goal list that will be used to achieve the desired state.
func plan_secondary_goals(goals: Array) -> Array:
	var planner = Planner.new()
	goals = planner.plan_secondary_goals(available_actions, primary_goals, world_state)
	if len(goals) != len(debug_secondary_goal_priorities):
		debug_secondary_goal_priorities=goals
		debug_print_secondary_goals = true
		debug_print = true
	return goals

func run_planner() -> void:
	var planner = Planner.new()
	var plan: Array = planner.build_plan(available_actions, primary_goals, secondary_goals, world_state)
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
	simulated_character.health = clamp(simulated_character.health-1, 0, simulated_character.max_health)

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
	print(world_state)


func _on_increase_stamina_pressed():
	simulated_character.stamina = clamp(simulated_character.stamina+1, 0, simulated_character.max_stamina)


func _on_decrease_stamina_pressed():
	simulated_character.stamina = clamp(simulated_character.stamina-1, 0, simulated_character.max_stamina)
