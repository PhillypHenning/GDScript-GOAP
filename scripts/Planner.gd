extends Node

class_name Planner

const Goal = preload("res://scripts/Goal.gd")

# Create a plan of actions that the AI can take to achieve a goal
func plan(actions: Array, goal: Goal, current_state: Dictionary) -> Action:
	# Given a goal, the state and the available actions create an action plan
	var debug_message: String = "Goal: [{goal}]\nAvailable Actions:\n".format({"goal": goal.goal_name})
	for action in actions:
		debug_message += "\tAction: [{action}]\n".format({"action": action.action_name})
	debug_message += "Current State: [{state}]".format({"state": current_state})
	print(debug_message)

	# Is the Desired State already achieved?
	if current_state.get(goal.goal_name):
		return null
	
	# Desired state needs to be achieved, create an action plan
	## NOTE: In this step the goal should be searched for, if there is a prereq and the prereq it currently not achieved than the action plan should be returned to achieve the prereq.
	return build_plan(actions, goal, current_state)


func build_plan(actions: Array, goal: Goal, state: Dictionary) -> Action:
	# 1. Search through actions for goal target
	var sub_goals: Array = []
	
	for action in actions:
		if action.effects.get(goal.goal_name):
			if action.preconditions:
				var precondition_keys = action.preconditions.keys()
				for precondition_key in precondition_keys:
					if not state.get(precondition_key):
						print("Precondition not met: [{precondition}]".format({"precondition": precondition_key}))
						sub_goals.append(Goal.new(precondition_key, 10))
				if sub_goals:
					return build_plan(actions, sub_goals[0], state)
			print("Action selected: [{action}]".format({"action": action.action_name}))
			return action
	return null

func apply_action_effects(goal_state: Dictionary, effects: Dictionary) -> Dictionary:
	var new_goal_state = goal_state.duplicate()
	for effect_key in effects.keys():
		new_goal_state[effect_key] = effects[effect_key]
	return new_goal_state
