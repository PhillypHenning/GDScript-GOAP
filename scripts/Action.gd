extends Node

class_name Action

var action_name: String
var preconditions: Dictionary = {}
var effects: Dictionary = {}
var cost: float = 0.0
var is_static_action: bool


func _init(init_action_name: String, init_preconditions: Dictionary, init_effects: Dictionary, init_cost: float = 0.0, init_is_static_action: bool = true):
	self.action_name = init_action_name
	self.preconditions = init_preconditions
	self.effects = init_effects
	self.cost = init_cost
	self.is_static_action = init_is_static_action

# is_valid takes the world state and a key
# It first checks if the action (self) has a precondition that matches the key
# It then checks the type of they key based on the world state.
func is_valid(agent_state: Dictionary, key) -> bool:
	if preconditions.has(key):
		match typeof(preconditions[key]):
			TYPE_BOOL:
				return agent_state.get(key) == preconditions[key]
			TYPE_CALLABLE:
				return preconditions[key].call(agent_state.get(key))
	return false


func apply(agent_state: Dictionary) -> Dictionary:
	var new_state = agent_state.duplicate()
	for key in effects.keys():
		if agent_state.has(key):
			match typeof(agent_state[key]):
				TYPE_FLOAT:
					new_state[key] = clamp(new_state[key]+effects[key], 0, new_state.get("max_{value}".format({"value": key}), 100)) 
				TYPE_INT:
					new_state[key] = clamp(new_state[key]+effects[key], 0, new_state.get("max_{value}".format({"value": key}), 100)) 
				TYPE_BOOL:
					new_state[key] = effects[key]
	return new_state
