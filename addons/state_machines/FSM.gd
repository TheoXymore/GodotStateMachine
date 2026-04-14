extends Node
class_name FiniteStateMachine

# --- Editor data ---
@export var scripts_location:String = "res://states"
@export var _editor_state_positions: Dictionary[String,Vector2] = {}  # state_name -> Vector2
@export var _editor_transitions: Array[Transition] = []           # Array de [String, String]
@export var _editor_initial_state: String = ""

var initial_state:State:
	set(value):
		initial_state = value

var current_state:State
var states : Dictionary = {}

func ready()->void:
	_editor_state_positions = _editor_state_positions.duplicate()
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.Transition.connect(on_state_changed) 
	current_state = initial_state
	
	
func _process(delta:float) -> void:
	#current_state.update(delta)
	pass
	
func _physics_process(delta: float) -> void:
	#current_state.physics_update(delta)
	pass
	
func on_state_changed(state:State,new_state:String):
	current_state.exit_state()
	current_state = states[new_state]
	current_state.enter_state()
	
