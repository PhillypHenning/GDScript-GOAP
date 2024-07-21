# Action.gd
extends Node

class_name Action

var action_name: String
var preconditions: Dictionary = {}
var effects: Dictionary = {}

func _init(new_action_name: String, new_preconditions: Dictionary, new_effects: Dictionary):
	self.action_name = new_action_name
	self.preconditions = new_preconditions
	self.effects = new_effects

func is_valid(agent_state: Dictionary) -> bool:
	for key in preconditions.keys():
		if agent_state.get(key) != preconditions[key]:
			return false
	return true

func apply(agent_state: Dictionary) -> Dictionary:
	var new_state = agent_state.duplicate()
	for key in effects.keys():
		new_state[key] = effects[key]
	return new_state
