extends Node

class_name Goal

var goal_name: String
var priority: int

func _init(new_goal_name: String, new_priority: int):
	self.goal_name = new_goal_name
	self.priority = new_priority
