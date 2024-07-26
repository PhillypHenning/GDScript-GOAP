extends Node
#
class_name Planner
#
const Goal = preload("res://scripts/Goal.gd")
const Action = preload("res://scripts/Action.gd")

func build_plan(available_actions: Array, static_actions: Array, goals: Array, state: Dictionary) -> Array:
	var new_build_plan: Array = []
	var state_keys = state.keys()	
	var states_needed: Array
		
	# Merge the Static and Available Actions
	var actions: Array = static_actions + available_actions
	
	# 1. Run through the goals and find the highest to lowest priority states required
	# 2. Find all the actions that satisfy those goal states
	# 3. Build plans based on those actions that cost the least to perform
	# 4. Return the most ideal plan
	
	for goal in goals:
		pass
		
	
	# Collect all states that are needed
	#for action in available_actions:
		#for precondition in action.preconditions:
			#if state_keys.has(precondition):
				#var have_state = state.get(precondition)
				#var precondition_needed = action.preconditions.get(precondition)
				#if have_state != precondition_needed:
					#states_needed.append({precondition: precondition_needed})


	#var actions_that_satisfy_world_state: Array
	# For all needed states find actions that could satisfy them
	
	return new_build_plan

func debug_actions(actions: Array) -> void:
	var text_string: String
	for action in actions:
		text_string = "{text_string}\nAction: [{name}]\n\tPreconditions:".format({"text_string": text_string, "name": action.action_name})
		for key in action.preconditions.keys():
			text_string = "{text_string}\n\t\tKey: [{name}], Value: [{value}]".format({"text_string": text_string, "name": key, "value": action.preconditions[key]})
		text_string = "{text_string}\n\tEffects:".format({"text_string": text_string})
		for key in action.effects.keys():
			text_string = "{text_string}\n\t\tKey: [{name}], Value: [{value}]".format({"text_string": text_string, "name": key, "value": action.effects[key]})
		text_string = "{text_string}\n\tCosts:".format({"text_string": text_string})
		for key in action.cost.keys():
			text_string = "{text_string}\n\t\tKey: [{name}], Value: [{value}]".format({"text_string": text_string, "name": key, "value": action.cost[key]})
	print(text_string)
