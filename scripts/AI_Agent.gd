extends Node

class_name AI_Agent

const Goal = preload("res://scripts/Goal.gd")
const Action = preload("res://scripts/Action.gd")
const Planner = preload("res://scripts/Planner.gd")

var goals: Array = []
var actions: Array = []
var state: Dictionary = {}
var current_plan: Array = []

func _ready():
	# Define initial state, goals, and actions
	state = {
		"has_warehouse": false,
		"has_house": false,
		"has_wood": false,
		"has_axe": false
	}

	goals.append(Goal.new("has_house", 10))
	goals.append(Goal.new("has_warehouse", 5))
	
	actions.append(Action.new("Get Axe", {}, {"has_axe": true}, {}))
	actions.append(Action.new("Collect Wood", {"has_axe": true}, {"has_wood": true}, {}))
	actions.append(Action.new("Build House", {"has_wood": true}, {"has_house": true}, {"has_wood": false}))
	actions.append(Action.new("Build Warehouse", {"has_wood": true}, {"has_warehouse": true}, {"has_wood": false}))

	# Plan and execute
	var planner = Planner.new()
	var current_action = planner.plan(actions, goals, state)
	while true:
		print("Applying Action: [{action}]".format({"action": current_action.action_name}))
		state = current_action.apply(state)
		if state["has_house"] && state["has_warehouse"]:
			break
		current_action = planner.plan(actions, goals, state)
	print("Final state: " + str(state))
