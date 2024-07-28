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
		if build_node_plan("a*", plan, all_actions, goal, world_state, goal.goal_criteria):
			if plan.is_empty():
				continue
			else:
				return plan
	return plan
	
# Recursively build a plan (One of A*, DFS, or BFS)(A* is the only implemented one at this time)
func build_node_plan(algorithm: String, plan: Array, actions: Array, goal: Goal, current_state: Dictionary, goal_criteria: Dictionary) -> bool:
	match algorithm:
		"a*":
			# Base Case: Check if the current state already satisfies the goal
			if satisfies_goal(current_state, goal_criteria):
				return true

			# Find actions that will satisfy the goals desired world state
			# For example:
			#	For the goal "Keep moving" the desired world state is to have "antsy" at 0
			var valid_actions = []
			for criteria_key in goal_criteria:
				for action in actions:
					if action.is_valid(current_state, criteria_key):
						valid_actions.append(action)
						# Add any preconditions to the goal_criteria list
						# Example:
						##	AttackTarget is used to "defeatenemy"
						## 	But AttackTarget requires that the character is in range
						##	The precondition of "GetInRange" is now required to build a plan
						goal_criteria.merge(action.preconditions)

			# Iterate over valid actions and attempt to build a plan
			for action in valid_actions:

				# Create a hypothetical new state by applying the action
				var new_state = action.apply(current_state)

				# Add the action to the current plan
				plan.append(action)

				# Recursively attempt to build the rest of the plan with the new state
				if build_node_plan("a*", plan, actions, goal, new_state, goal_criteria):
					return true

				# Backtrack if the current action did not lead to a valid plan
				plan.pop_back()
	return false


func satisfies_goal(agent_state: Dictionary, goal_criteria: Dictionary) -> bool:
	var tracker: bool = false
	for key in goal_criteria.keys():
		tracker = agent_state.get(key) == goal_criteria[key]
		if !tracker:
			return false
	return tracker
