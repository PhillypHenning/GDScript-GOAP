extends Node

class_name Action

var action_name: String
var preconditions: Dictionary = {}
var effects: Dictionary = {}
var cost: Dictionary = {}

func _init(init_action_name: String, init_preconditions: Dictionary, init_effects: Dictionary, init_cost: Dictionary):
	self.action_name = init_action_name
	self.preconditions = init_preconditions
	self.effects = init_effects
	self.cost = init_cost

func is_valid(agent_state: Dictionary) -> bool:
	for key in preconditions.keys():
		if agent_state.get(key) != preconditions[key]:
			return false
	return true

func apply(agent_state: Dictionary) -> Dictionary:
	var new_state = agent_state.duplicate()
	for key in effects.keys():
		new_state[key] = effects[key]
	for key in cost.keys():
		new_state[key] = cost[key]
	return new_state

func print():
	return "Name: [{name}]\n\tPreconditions: [{preconditions}]\n\tEffects: [{effects}]\n\tCost: [{cost}]".format({"name": self.action_name, "preconditions": self.preconditions, "effects": self.effects, "cost": self.cost})
