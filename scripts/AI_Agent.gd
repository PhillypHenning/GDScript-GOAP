extends Node

class_name AI_Agent

const GoalPack = preload("res://scripts/Goal.gd")
const ActionPack = preload("res://scripts/Action.gd")
const PlannerPack = preload("res://scripts/Planner.gd")
const UtilsPack = preload("res://scripts/Utils.gd")
var Utils = UtilsPack.new()

enum SEVERITY_LEVEL {
	NONE = 0,
	MINOR = 30,
	MIDDLING = 50,
	SEVERE = 70,
	DESPERATE = 90,
	MAX = 100,
}

var primary_goals: Array = []
var current_plan: Array = []
var static_actions: Array = [
	ActionPack.new("DoTheAntsyShuffle", 
		{
			"antsy": func(a): return a > 0, # Precondition: Antsy should be lower than "0"
		},
		{	# Effects
			"antsy": -1,
		}, 
	),
	ActionPack.new("MoveTowardsTarget", 
		{
			"target_in_attack_range": false
		},
		{	# Effects
			"target_in_attack_range": true
		},
	),
	ActionPack.new("BreakLineOfSight", 
		{	
			"has_los": true
		},
		{	# Effects
			"has_los": false,
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
	
	"character_is_being_attacked": false,
	"character_is_defending": false,
	
	"speed": 300,
	"character_position": Vector2(0,0),
	"target_position": Vector2(300,300),
}

var game_start_time: float

var goal_keep_moving: Goal = GoalPack.new()
var goal_conserve_health: Goal = GoalPack.new()
var goal_attack_enemy: Goal = GoalPack.new()
var goal_defend_against_attack: Goal = GoalPack.new()


@onready var goals_textbox = $"../Control/Goals/Goals"
@onready var sim_char_textbox = $"../Control/CharacterAttributes/SimCharDebug"
@onready var static_actions_textbox = $"../Control/StaticActions/StaticActions"
@onready var available_actions_textbox = $"../Control/AvailableActions/AvailableActionsTextbox"
@onready var planner_text_box = $"../Control/PlannerDebug/PlannerTextBox"
@onready var plan_len = $"../Control/PlannerDebug/PlanLen"
@onready var elapsed_time_text = $"../Control/ElapsedTimeText"

func _ready():
	# Improvements that could be made:
	##	1. conserve_health
	##		- Conserve health goes beyond breaking los though this is a good start. Another option for "Conserving health" would be to focus on defensive actions. In this scenario, when a creature takes damage it would temporarily boost the priority of the "defense_action" goal. 
	primary_goals.append(goal_keep_moving.new_goal_with_timer("keep_moving", calculate_keep_moving_priority, 1, keep_moving_interval_increase, get_parent(), {"antsy": 0}))
	primary_goals.append(goal_conserve_health.new_goal_with_timer("conserve_health", calculate_conserve_health_priority, 2.5, conserve_health_interval_decrease, get_parent(), {"has_los": false}))
	primary_goals.append(goal_attack_enemy.new_goal_with_static_priority("defeat_enemy", 4.5, {"defeat_enemy": true}))
	primary_goals.append(goal_defend_against_attack.new_goal_with_static_priority("defense_action", 7, {"character_is_defending": true}))

func _init():
	game_start_time = Time.get_unix_time_from_system()

func _process(_delta: float) -> void:
	calculate_severity_level(simulated_character, "health")
	calculate_severity_level(simulated_character, "stamina")
	calculate_severity_level(simulated_character, "antsy", true)

	determine_goal_priority()
	run_planner()
	
	check_if_enemy_is_defeated()

	# debugging
	debug_simulated_character()
	debug_goals()
	debug_static_actions()
	debug_available_actions()
	debug_available_plan()
	debug_game_elapsed_time()
	Utils.calculate_time_to_reach_destination(simulated_character.speed, simulated_character.character_position, simulated_character.target_position)











# Takes an array of goals, runs the "calculate_goal_priority" function which either calls the goal callable or returns the static priority. Sorts the goals from highest priority to lowest.
func determine_goal_priority():
	var current_goal_priorities: Array = []
	for i in range(primary_goals.size()):
		primary_goals[i].calculate_goal_priority(simulated_character)
		current_goal_priorities.append(primary_goals[i].goal_priority)


func run_planner() -> void:
	var planner = PlannerPack.new()
	current_plan = planner.build_plan(available_actions, static_actions, primary_goals, simulated_character)


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


func calculate_severity_level(state: Dictionary, key: String, reversed: bool = false) -> bool:
	var severity_current =  simulated_character.get(key, false)
	var severity_max = simulated_character.get("max_{key}".format({"key": key}), false)
	var severity = simulated_character.get("{key}_severity".format({"key": key}), false)

	if severity_current == severity_max:
		if reversed:
			severity = SEVERITY_LEVEL.MAX
		else:
			severity = SEVERITY_LEVEL.NONE
	else:
		var formula: float
		if reversed:
			formula = ((severity_current / severity_max) * 100)
		else:
			formula = 100 - ((severity_current / severity_max) * 100)
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

func debug_simulated_character() -> void:
	var state_text: String
	var state_keys = simulated_character.keys()
	for state in state_keys:
		state_text = "{state_text}\nState: [{state}], Value: [{value}]".format({"state_text": state_text, "state": state, "value": simulated_character[state]})
	sim_char_textbox.text = state_text


func debug_static_actions() -> void:
	var text_string: String
	for action in static_actions:
		text_string = "{text_string}\nAction: [{name}]\n\tPreconditions:".format({"text_string": text_string, "name": action.action_name})
		for key in action.preconditions.keys():
			text_string = "{text_string}\n\t\tKey: [{name}], Value: [{value}]".format({"text_string": text_string, "name": key, "value": action.preconditions[key]})
		text_string = "{text_string}\n\tEffects:".format({"text_string": text_string})
		for key in action.effects.keys():
			text_string = "{text_string}\n\t\tKey: [{name}], Value: [{value}]".format({"text_string": text_string, "name": key, "value": action.effects[key]})
		text_string = "{text_string}\n\tCosts: [{cost}]".format({"text_string": text_string, "cost": action.cost})
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
		0.0,
		false
	))


func _on_defend_action_button_pressed():
	available_actions.append(ActionPack.new(
		"DefendAgainstAttack", 
		{
			"character_is_being_attacked": true,
			"character_is_defending": false,
		},
		{
			"character_is_defending": true,
		},
		0.0,
		false
	))


func _on_increase_stamina_pressed():
	simulated_character.stamina = clamp(simulated_character.stamina+1, 0, simulated_character.max_stamina)


func _on_decrease_stamina_pressed():
	simulated_character.stamina = clamp(simulated_character.stamina-1, 0, simulated_character.max_stamina)


func _on_reset_button_pressed():
	available_actions.clear()


func _on_antsy_button_pressed():
	simulated_character.antsy = 0

func _on_apply_button_pressed():
	for index in current_plan.size():
		simulated_character = current_plan[index].apply(simulated_character)
		if !current_plan[index].is_static_action:
			for aaindex in available_actions.size():
				if available_actions[aaindex].action_name == current_plan[index].action_name:
					available_actions.remove_at(aaindex)
					break
	current_plan.clear()

func _on_being_attacked_button_pressed():
	simulated_character.character_is_being_attacked = !simulated_character.character_is_being_attacked
##----- ------ -----##
