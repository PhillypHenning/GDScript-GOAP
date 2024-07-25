extends Node

class_name Goal

var goal_name: String
var goal_priority: float
var goal_priority_callable: Callable

func _init() -> void:
	pass

func new_goal_with_callable(inc_goal_name: String, inc_goal_priority_callable: Callable) -> Goal:
	self.goal_name = inc_goal_name
	self.goal_priority_callable = inc_goal_priority_callable
	return self
	
func new_goal_with_static_priority(inc_goal_name: String, inc_goal_priority: float) -> Goal:
	self.goal_name = inc_goal_name
	self.goal_priority = inc_goal_priority
	return self

func new_goal_with_timer(inc_goal_name: String,  inc_goal_priority_callable: Callable, increase_interval: float, timer_callable: Callable, root: Node2D) -> Goal:
	self.goal_name = inc_goal_name
	self.goal_priority_callable = inc_goal_priority_callable
	
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
		self.goal_priority = self.goal_priority_callable.call(parameters)

