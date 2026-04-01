@tool
extends VBoxContainer

@onready var no_selection_label = $NoSelectionLabel
@onready var no_state_machine_panel = $NoStateMachinePanel
@onready var state_machine_graph = $StateMachineGraph

signal FSMCreation

func _ready() -> void:
	no_state_machine_panel.pressed.connect(FSM_creation)

func show_no_selection():
	no_selection_label.show()
	no_state_machine_panel.hide()
	state_machine_graph.hide()

func show_no_state_machine():
	no_selection_label.hide()
	no_state_machine_panel.show()
	state_machine_graph.hide()

func show_graph():
	no_selection_label.hide()
	no_state_machine_panel.hide()
	state_machine_graph.show()
	
func FSM_creation():
	FSMCreation.emit()
	
