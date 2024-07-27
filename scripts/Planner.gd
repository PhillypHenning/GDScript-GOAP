extends Node
class_name Planner

# build_plan
# 	1. Combines available_actions and static_actions
#	2. Sorts the primary_goals according to their goal_priority
#	3. Creates an empty plan array
#	4. Cycles through each goal in primary_goals
#		a. Attempts to build a plan (an array of actions to take to meet a goal)
#		b. If the plan is returned empty, then it moves on to the next goal
#		c. If the plan isn't empty it returns the plan (Array of actions)
#	5. Return the empty plan
func build_plan(available_actions: Array, static_actions: Array, primary_goals: Array, world_state: Dictionary) -> Array:
	# Combine static and available actions
	var all_actions = available_actions + static_actions
	
	# Get the highest priority goal
	primary_goals.sort_custom(func (a, b): return a.goal_priority > b.goal_priority)

	# Initialize the plan as an empty array
	var plan = []

	# Use A* algorithm or any other suitable planning algorithm to build the plan
	for goal in primary_goals:
		if build_node_plan("a*", plan, all_actions, goal, world_state):
			if plan.is_empty():
				continue
			else:
				return plan
	return plan
	
# Recursively build a plan (One of A*, DFS, or BFS)(A* is the only implemented one at this time)
func build_node_plan(algorithm: String, plan: Array, actions: Array, goal: Goal, current_state: Dictionary) -> bool:
	match algorithm:
		"a*":
			# Base Case: Check if the current state already satisfies the goal
			if satisfies_goal(current_state, goal):
				return true

			# Find potential actions that are valid in the current state
			var valid_actions = []
			for action in actions:
				# TODO: 1. is_valid is looping on the keys but returns on the first success.
				# This is causing a misinteruption of what is required.
				# It's likely the case that we will need to make a recursive loop, that finds all actions that can satisfy both the intial criteria, as well as criteria gained as a result OF the plan
				# For example:
				#	If the goal is "defeat enemy"
				#	Then the AttackEnemy action is selected
				# 	But then the AttackEnemy has preconditions itself, that will also need to be accounted for
				# 	(Attack Enemy: Satisfies Defeat Enemy) -> (Move Towards Enemy: Satisfies is character in range)
				if action.is_valid(current_state, goal.goal_criteria):
					valid_actions.append(action)

			# Iterate over valid actions and attempt to build a plan
			for action in valid_actions:

				# Create a hypothetical new state by applying the action
				var new_state = action.apply(current_state)

				# Add the action to the current plan
				plan.append(action)

				# Recursively attempt to build the rest of the plan with the new state
				if build_node_plan("a*", plan, actions, goal, new_state):
					return true

				# Backtrack if the current action did not lead to a valid plan
				plan.pop_back()
	return false

# Check if the current state satisfies the given goal
func satisfies_goal(state: Dictionary, goal: Goal) -> bool:
	return goal.is_satisfied(state)
