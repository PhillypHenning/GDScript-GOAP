extends Node

class_name AI_Agent

const GoalPack = preload("res://scripts/Goal.gd")
const ActionPack = preload("res://scripts/Action.gd")
const PlannerPack = preload("res://scripts/Planner.gd")

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
	ActionPack.new("DoTheAntsyShuffle", 
		{
			"antsy": func(a): return a > 0, # Precondition: Antsy should be lower than "0"
		},
		{	# Effects
			"antsy": -1,
		}, 
		{	# Cost
		},
	),
	ActionPack.new("MoveTowardsTarget", 
		{
			"target_in_attack_range": false
		},
		{	# Effects
			"target_in_attack_range": true
		}, 
		{	# Cost
			"antsy": 1
		},
	),
	ActionPack.new("BreakLineOfSight", 
		{	
			"has_los": true
		},
		{	# Effects
			"has_los": false,
		},
		{	# Cost
		},
	),
]
var available_actions: Array = []

var simulated_character: Dictionary = {
	"health": 10.0,
	"max_health": 10.0,
	"health_severity": SEVERITY_LEVEL.NONE,
	
	"stamina": 8.0,
	"max_stamina": 8.0,
	"stamina_severity": SEVERITY_LEVEL.NONE,
	
	"antsy": 0.0,
	"max_antsy": 5.0,
	"antsy_severity": SEVERITY_LEVEL.NONE,
	
	"has_los": true,
	
	"target_in_attack_range": false,
	"character_can_attack": true,
	
	"defeat_enemy": false,
}

var game_start_time: float

var debug_run_planner: bool = false

# Goal Preloads (Allows access to priority)
var goal_keep_moving: Goal = GoalPack.new()
var goal_conserve_health: Goal = GoalPack.new()
var goal_conserve_stamina: Goal = GoalPack.new()
var goal_attack_enemy: Goal = GoalPack.new()


@onready var goals_textbox = $"../Control/Goals/Goals"
@onready var state_textbox = $"../Control/State/StateDebug"
@onready var sim_char_textbox = $"../Control/CharacterAttributes/SimCharDebug"
@onready var static_actions_textbox = $"../Control/StaticActions/StaticActions"
@onready var available_actions_textbox = $"../Control/AvailableActions/AvailableActionsTextbox"
@onready var planner_text_box = $"../Control/PlannerDebug/PlannerTextBox"
@onready var plan_len = $"../Control/PlannerDebug/PlanLen"
@onready var elapsed_time_text = $"../Control/ElapsedTimeText"

func _ready():
	#primary_goals.append(GoalPack.new().new_goal_with_callable("conserve_health", calculate_conserve_health_priority, {"conserve_health": true}))
	#primary_goals.append(goal_conserve_stamina.new_goal_with_callable("conserve_stamina", calculate_conserve_stamina_priority, {"conserve_stamina": true}))
	
	
	primary_goals.append(goal_keep_moving.new_goal_with_timer("keep_moving", calculate_keep_moving_priority, 1, keep_moving_interval_increase, get_parent(), {"antsy": 0}))
	primary_goals.append(goal_conserve_health.new_goal_with_timer("conserve_health", calculate_conserve_health_priority, 2.5, conserve_health_interval_decrease, get_parent(), {"has_los": false}))
	primary_goals.append(goal_attack_enemy.new_goal_with_static_priority("defeat_enemy", 4.5, {"defeat_enemy": true}))

	# Keep in optimal range will need to be written after some actions are in place.
	# Initial thought: Based on the actions, determine what the optimal range is
	# primary_goals.append(Goal.new().new_goal_with_callable("keep_in_optimal_range", calculate_conserve_stamina_priority))

func _init():
	game_start_time = Time.get_unix_time_from_system()

func _process(_delta: float) -> void:
	calculate_severity_level(simulated_character, "health", false)
	calculate_severity_level(simulated_character, "stamina", false)
	calculate_severity_level(simulated_character, "antsy", true)


	world_state.merge(simulated_character, true)
	determine_goal_priority()
	
	run_planner()
	
	check_if_enemy_is_defeated()

	# debugging
	debug_state()
	debug_simulated_character()
	debug_goals()
	debug_static_actions()
	debug_available_actions()
	debug_available_plan()
	debug_game_elapsed_time()












# Takes an array of goals, runs the "calculate_goal_priority" function which either calls the goal callable or returns the static priority. Sorts the goals from highest priority to lowest.
func determine_goal_priority():
	var current_goal_priorities: Array = []
	for i in range(primary_goals.size()):
		primary_goals[i].calculate_goal_priority(simulated_character)
		current_goal_priorities.append(primary_goals[i].goal_priority)


func run_planner() -> void:
	var planner = PlannerPack.new()
	current_plan = planner.build_plan(available_actions, static_actions, primary_goals, world_state)


##-- GOAL CALCULATIONS --##
func calculate_conserve_health_priority(_parameters: Dictionary) -> float:
	return goal_conserve_health.goal_priority


func conserve_health_interval_decrease() -> void:
	goal_conserve_health.goal_priority -= .5


func calculate_conserve_stamina_priority(parameters: Dictionary) -> float:
	var calculated_priority: float = ((float(parameters.max_stamina) - float(parameters.stamina)) / float(parameters.max_stamina)) * (float(parameters.max_stamina) - 1) + 1
	return calculated_priority


func calculate_keep_moving_priority(parameters: Dictionary) -> float:
	return parameters.antsy


func keep_moving_interval_increase() -> void:
	simulated_character.antsy = clamp((simulated_character.antsy+.3), 0, simulated_character.max_antsy)


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

func check_if_enemy_is_defeated() -> void:
	simulated_character.defeat_enemy = false
##-- -------------- --##


















##----- DEBUG -----##
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

func debug_game_elapsed_time() -> void:
	elapsed_time_text.text = "Elapsed Time: [{elapsed}]".format({"elapsed": "%0.2f" % (Time.get_unix_time_from_system() - game_start_time)})


##----- BUTTONS -----##
func _on_decrease_health_button_pressed():
	simulated_character.health = clamp(simulated_character.health-1, 0, simulated_character.max_health)
	calculate_severity_level(simulated_character, "health", false)
	goal_conserve_health.goal_priority = (simulated_character.health_severity/10)


func _on_increase_health_button_pressed():
	simulated_character.health = clamp(simulated_character.health+1, 0, simulated_character.max_health)
	calculate_severity_level(simulated_character, "health", false)
	var new_priority = (simulated_character.health_severity/10)
	if new_priority > goal_conserve_health.goal_priority:
		goal_conserve_health.goal_priority = (simulated_character.health_severity/10)


func _on_attack_action_button_pressed():
	available_actions.append(ActionPack.new(
		"AttackTargetInRange", 
		{
			"target_in_attack_range": true,
			"defeat_enemy": false,
		},
		{
			"defeat_enemy": true,
		},
		{
			"stamina": -1
		}
	))


func _on_defend_action_button_pressed():
	available_actions.append(ActionPack.new(
		"DefendAgainstAttack", 
		{
			"chracter_can_defend": true, 
			"character_is_being_attacked": true
		}, 
		{
			"save_health": true,
			"antsy": 1,
		}, 
		{
		}
	))


func _on_run_planner_pressed():
	debug_run_planner = true


func _on_increase_stamina_pressed():
	simulated_character.stamina = clamp(simulated_character.stamina+1, 0, simulated_character.max_stamina)


func _on_decrease_stamina_pressed():
	simulated_character.stamina = clamp(simulated_character.stamina-1, 0, simulated_character.max_stamina)


func _on_button_pressed():
	simulated_character.antsy = 0
##----- ------ -----##
