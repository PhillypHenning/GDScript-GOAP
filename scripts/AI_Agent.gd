extends Node

## Create a world timer that begins upon game start and access that instead of creating a unique timer for actions. 

class_name AI_Agent

const GoalPack = preload("res://scripts/Goal.gd")
const ActionPack = preload("res://scripts/Action.gd")
const PlannerPack = preload("res://scripts/Planner.gd")

const MIN_PRIORITY = 1
const MAX_PRIORITY = 10

enum SEVERITY_LEVEL {
	NONE = 0,
	MINOR = 30,
	MIDDLING = 50,
	SEVERE = 70,
	DESPERATE = 90,
	MAX = 100,
}

var primary_goals: Array = []
var world_state: Dictionary = {}
var current_plan: Array = []
var static_actions: Array = [
	ActionPack.new("antsy_move", 
		{	# @onready var plan_len = $"../Control/PlannerDebug/PlanLen"
			"antsy": 0,
		},
		{	# Effects
			"antsy": -1,
		}, 
		{	# Cost
		},
	),
]
var available_actions: Array = []

var simulated_character: Dictionary = {
	"health": 9,
	"max_health": 10.0,
	"health_severity": SEVERITY_LEVEL.NONE,
	
	"stamina": 8.0,
	"max_stamina": 8.0,
	"stamina_severity": SEVERITY_LEVEL.NONE,
	
	"antsy": 1.0,
	"max_antsy": 10.0,
	"antsy_severity": SEVERITY_LEVEL.NONE,
}
var debug_run_planner: bool = false

@onready var goals_textbox = $"../Control/Goals/Goals"
@onready var state_textbox = $"../Control/State/StateDebug"
@onready var sim_char_textbox = $"../Control/CharacterAttributes/SimCharDebug"
@onready var static_actions_textbox = $"../Control/StaticActions/StaticActions"
@onready var available_actions_textbox = $"../Control/AvailableActions/AvailableActionsTextbox"
@onready var planner_text_box = $"../Control/PlannerDebug/PlannerTextBox"
@onready var plan_len = $"../Control/PlannerDebug/PlanLen"


func _ready():
	#primary_goals.append(GoalPack.new().new_goal_with_callable("conserve_health", calculate_conserve_health_priority, {"conserve_health": true}))
	# primary_goals.append(GoalPack.new().new_goal_with_callable("conserve_stamina", calculate_conserve_stamina_priority))
	#primary_goals.append(GoalPack.new().new_goal_with_static_priority("defeat_enemy", 4.5, {"target_in_range": true, "character_can_attack": true}))
	primary_goals.append(GoalPack.new().new_goal_with_timer("keep_moving", calculate_keep_moving_priority, .5, keep_moving_interval_increase, get_parent(), {"antsy": 0}))
	
	# Keep in optimal range will need to be written after some actions are in place.
	# Initial thought: Based on the actions, determine what the optimal range is
	# primary_goals.append(Goal.new().new_goal_with_callable("keep_in_optimal_range", calculate_conserve_stamina_priority))


func _process(_delta: float) -> void:
	calculate_severity_level(simulated_character, "health", false)
	calculate_severity_level(simulated_character, "stamina", false)
	calculate_severity_level(simulated_character, "antsy", true)


	world_state.merge(simulated_character, true)
	determine_priority_goal()

	if debug_run_planner:
		debug_run_planner = false
	run_planner()

	# debugging
	debug_state()
	debug_simulated_character()
	debug_goals()
	debug_static_actions()
	debug_available_actions()
	debug_available_plan()


func debug_goals() -> void:
	var goals_text: String
	for goal in primary_goals:
		goals_text = "{goal_text}\nGoal: [{goal}]\n\tPriority: [{priority}]\n\tCriteria:".format({"goal_text": goals_text, "goal": goal.goal_name, "priority": goal.goal_priority})
		for criteria in goal.goal_criteria:
			goals_text = "{goal_text}\n\t\t[{criteria}] : [{value}]".format({"goal_text": goals_text, "criteria": criteria, "value": goal.goal_criteria[criteria]})
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


func debug_static_actions() -> void:
	var text_string: String
	for action in static_actions:
		text_string = "{text_string}\nAction: [{name}]\n\tPreconditions:".format({"text_string": text_string, "name": action.action_name})
		for key in action.preconditions.keys():
			text_string = "{text_string}\n\t\tKey: [{name}], Value: [{value}]".format({"text_string": text_string, "name": key, "value": action.preconditions[key]})
		text_string = "{text_string}\n\tEffects:".format({"text_string": text_string})
		for key in action.effects.keys():
			text_string = "{text_string}\n\t\tKey: [{name}], Value: [{value}]".format({"text_string": text_string, "name": key, "value": action.effects[key]})
		text_string = "{text_string}\n\tCosts:".format({"text_string": text_string})
		for key in action.cost.keys():
			text_string = "{text_string}\n\t\tKey: [{name}], Value: [{value}]".format({"text_string": text_string, "name": key, "value": action.cost[key]})
	static_actions_textbox.text = text_string


func debug_available_actions() -> void:
	var text_string: String
	for action in available_actions:
		text_string = "{text_string}\nAction: [{name}]\n\tPreconditions:".format({"text_string": text_string, "name": action.action_name})
		for key in action.preconditions.keys():
			text_string = "{text_string}\n\t\tKey: [{name}], Value: [{value}]".format({"text_string": text_string, "name": key, "value": action.preconditions[key]})
		text_string = "{text_string}\n\tEffects:".format({"text_string": text_string})
		for key in action.effects.keys():
			text_string = "{text_string}\n\t\tKey: [{name}], Value: [{value}]".format({"text_string": text_string, "name": key, "value": action.effects[key]})
		text_string = "{text_string}\n\tCosts:".format({"text_string": text_string})
		for key in action.cost.keys():
			text_string = "{text_string}\n\t\tKey: [{name}], Value: [{value}]".format({"text_string": text_string, "name": key, "value": action.cost[key]})
	available_actions_textbox.text = text_string
	plan_len.text = "Plan Length: {len}".format({"len": len(current_plan)})

func debug_available_plan() -> void:
	var text_string: String
	text_string = "Current Plan:"
	for action in current_plan:
		text_string = "{text_string}\n\tAction: [{name}]".format({"text_string": text_string, "name": action.action_name})
	planner_text_box.text = text_string


# Takes an array of goals, runs the "calculate_goal_priority" function which either calls the goal callable or returns the static priority. Sorts the goals from highest priority to lowest.
func determine_priority_goal():
	var current_goal_priorities: Array = []
	for i in range(primary_goals.size()):
		primary_goals[i].calculate_goal_priority(simulated_character)
		current_goal_priorities.append(primary_goals[i].goal_priority)
	primary_goals.sort_custom(func (a,b): return a.goal_priority > b.goal_priority)


func run_planner() -> void:
	var planner = PlannerPack.new()
	current_plan = planner.build_plan(available_actions, static_actions, primary_goals, world_state)

##-- GOAL CALCULATIONS --##
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
	

func calculate_severity_level(state: Dictionary, key: String, reversed: bool) -> bool:
	var current =  simulated_character.get(key, false)
	var max = simulated_character.get("max_{key}".format({"key": key}), false)
	var severity = simulated_character.get("{key}_severity".format({"key": key}), false)

	if current == max:
		if reversed:
			severity = SEVERITY_LEVEL.MAX
		else:
			severity = SEVERITY_LEVEL.NONE
	else:
		var formula: float
		if reversed:
			formula = ((current / max) * 100)
		else:
			formula = 100 - ((current / max) * 100)
		if formula == SEVERITY_LEVEL.MAX:
			severity = SEVERITY_LEVEL.MAX
		elif formula >= SEVERITY_LEVEL.DESPERATE:
			severity = SEVERITY_LEVEL.DESPERATE
		elif formula >= SEVERITY_LEVEL.SEVERE:
			severity = SEVERITY_LEVEL.SEVERE
		elif formula >= SEVERITY_LEVEL.MIDDLING:
			severity = SEVERITY_LEVEL.MIDDLING
		elif formula > SEVERITY_LEVEL.NONE:
			severity = SEVERITY_LEVEL.MINOR
		else:
			severity = SEVERITY_LEVEL.NONE
	state["{key}_severity".format({"key": key})] = severity
	return true
##-- -------------- --##

##----- BUTTONS -----##
func _on_decrease_health_button_pressed():
	simulated_character.health = clamp(simulated_character.health-1, 0, simulated_character.max_health)


func _on_increase_health_button_pressed():
	simulated_character.health = clamp(simulated_character.health+1, 0, simulated_character.max_health)


func _on_attack_action_button_pressed():
	available_actions.append(ActionPack.new(
		"AttackTarget", 
		{
			"chracter_can_see_target": true,
			"character_in_attack_range": true, 
			"chracter_able_to_attack": true,
		}, 
		{
			"defeat_enemy": true
		}, 
		{}
	))


func _on_defend_action_button_pressed():
	available_actions.append(ActionPack.new(
		"DefendAgainstAttack", 
		{
			"chracter_can_defend": true, 
			"character_is_being_attacked": true
		}, 
		{
			"save_health": true
		}, 
		{}
	))


func _on_run_planner_pressed():
	debug_run_planner = true


func _on_increase_stamina_pressed():
	simulated_character.stamina = clamp(simulated_character.stamina+1, 0, simulated_character.max_stamina)


func _on_decrease_stamina_pressed():
	simulated_character.stamina = clamp(simulated_character.stamina-1, 0, simulated_character.max_stamina)


func _on_button_pressed():
	simulated_character.antsy = 1
##----- ------ -----##
