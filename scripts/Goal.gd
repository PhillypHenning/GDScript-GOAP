extends Node

class_name Goal

const MIN_PRIORITY = 0
const MAX_PRIORITY = 10

var goal_name: String
var goal_priority: float
var goal_priority_callable: Callable
var goal_criteria: Dictionary = {}

func _init() -> void:
	pass

func new_goal_with_callable(inc_goal_name: String, inc_goal_priority_callable: Callable, criteria: Dictionary) -> Goal:
	self.goal_name = inc_goal_name
	self.goal_priority_callable = inc_goal_priority_callable
	self.goal_criteria = criteria
	return self
	
func new_goal_with_static_priority(inc_goal_name: String, inc_goal_priority: float, criteria: Dictionary) -> Goal:
	self.goal_name = inc_goal_name
	self.goal_priority = inc_goal_priority
	self.goal_criteria = criteria
	return self

func new_goal_with_timer(inc_goal_name: String,  inc_goal_priority_callable: Callable, increase_interval: float, timer_callable: Callable, root: Node2D, criteria: Dictionary) -> Goal:
	self.goal_name = inc_goal_name
	self.goal_priority_callable = inc_goal_priority_callable
	self.goal_criteria = criteria

	var timer = Timer.new()
	timer.name = inc_goal_name
	timer.wait_time = increase_interval
	timer.one_shot = false
	timer.autostart = true
	timer.connect("timeout", timer_callable)
	root.call_deferred("add_child", timer)
	return self

	
func calculate_goal_priority(parameters: Dictionary) -> void:
	if goal_priority_callable:
		self.goal_priority = clamp(self.goal_priority_callable.call(parameters), MIN_PRIORITY, MAX_PRIORITY)


func is_satisfied(agent_state: Dictionary) -> bool:
	# NOTE: This will only work on the first key that matches.. 
	for key in goal_criteria.keys():
		return agent_state.get(key) == goal_criteria[key]
	return false
