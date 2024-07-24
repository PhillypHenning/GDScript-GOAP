extends Node
#
class_name Planner
#
const Goal = preload("res://scripts/Goal.gd")



# Consider the actions available and the goals that need to be achieved. 
# Based on the state, come up with "interm" goals that need to be accomplished
# Interm goals are goals that are "fluid"/"dynamic".
func plan_secondary_goals(actions: Array, goals: Array, state: Dictionary) -> Array:
	var secondary_goals: Array = []
	var state_keys = state.keys()
	for action in actions:
		for key in state_keys:
			var precondition = action.preconditions.get(key)
			if precondition:
				if key == "chracter_can_see_target" and !state.get(key):
					secondary_goals.append(Goal.new().new_goal_with_static_priority("get_line_of_sight", 6.0))
				elif key == "character_in_attack_range" and !state.get(key):
					secondary_goals.append(Goal.new().new_goal_with_static_priority("get_into_attack_range", 6.0))
				elif key == "chracter_able_to_attack" and !state.get(key):
					secondary_goals.append(Goal.new().new_goal_with_static_priority("wait_until_character_can_attack", 6.0))	
	return secondary_goals

# First consider primary goals and whether they are achievable
# Next consider secondary goals and how they can be achieved
# return an Action Plan to accomplish the goals. The Action Plan will be fed into another AI (FSM) which will perform the actions in the plan.
func plan(actions: Array, primary_goals: Array, secondary_goals: Array, state: Dictionary) -> Array:
	return []

#
## Create a plan of actions that the AI can take to achieve a goal
#func plan(actions: Array, goals: Array, current_state: Dictionary) -> Action:
	## Given a goal, the state and the available actions create an action plan
	#var debug_message: String
	#for goal in goals:
		#debug_message += "Goal: [{goal}]\n".format({"goal": goal.goal_name})
	#debug_message += "Available Actions:\n"
	#for action in actions:
		#debug_message += "\tAction: [{action}]\n".format({"action": action.action_name})
	#debug_message += "Current State: [{state}]".format({"state": current_state})
	#print(debug_message)
#
	#var target_goals = determine_and_prioritize_goals(goals, current_state)
#
	## Desired state needs to be achieved, create an action plan
	### NOTE: In this step the goal should be searched for, if there is a prereq and the prereq it currently not achieved than the action plan should be returned to achieve the prereq.
	#return build_plan(actions, target_goals[0], current_state)
#
#
#func build_plan(actions: Array, goal: Goal, state: Dictionary) -> Action:
	#var sub_goals: Array = []
	#
	#for action in actions:
		#if action.effects.get(goal.goal_name):
			#if action.preconditions:
				#var precondition_keys = action.preconditions.keys()
				#for precondition_key in precondition_keys:
					#if not state.get(precondition_key):
						#print("Precondition not met: [{precondition}]".format({"precondition": precondition_key}))
						#sub_goals.append(Goal.new(precondition_key, 10))
				#if sub_goals:
					#return build_plan(actions, sub_goals[0], state)
			#print("Action selected: [{action}]".format({"action": action.action_name}))
			#return action
	#return null
#
#func determine_and_prioritize_goals(goals: Array, state: Dictionary) -> Array:
	#var unachieved_goals: Array
	#for goal in goals:
		#if !state.get(goal.goal_name):
			#unachieved_goals.append(goal)
	#unachieved_goals.sort_custom(func(a, b): return a.priority > b.priority)
	#return unachieved_goals
