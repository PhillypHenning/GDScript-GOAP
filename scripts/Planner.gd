extends Node
class_name Planner

func build_plan(available_actions: Array, static_actions: Array, primary_goals: Array, world_state: Dictionary) -> Array:
	# Combine static and available actions
	var all_actions = available_actions + static_actions
	
	# Get the highest priority goal
	primary_goals.sort_custom(func (a, b): return a.goal_priority > b.goal_priority)
	var highest_goal = primary_goals[0]

	# Initialize the plan as an empty array
	var plan = []

	# Use A* algorithm or any other suitable planning algorithm to build the plan
	if build_node_plan("a*", plan, all_actions, highest_goal, world_state):
		return plan

	return []
	
# Recursively build a plan (you can use A*, DFS, or BFS)
func build_node_plan(algorithm: String, plan: Array, actions: Array, goal: Goal, current_state: Dictionary) -> bool:
	match algorithm:
		"a*":
			# Base Case: Check if the current state already satisfies the goal
			if satisfies_goal(current_state, goal):
				return true
			
			# Find potential actions that are valid in the current state
			var valid_actions = []
			for action in actions:
				if action.is_valid(current_state):
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
