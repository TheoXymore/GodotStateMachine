extends Node
class_name FiniteStateMachine

var current_state:State
var states : Dictionary = {}

func ready()->void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.Transition.connect(on_state_changed) 
	
func _process(delta:float) -> void:
	current_state.update(delta)
	
func _physics_process(delta: float) -> void:
	current_state.physics_update(delta)
	
func on_state_changed(state:State,new_state:String):
	current_state.exit_state()
	current_state = states[new_state]
	current_state.enter_state()
	
