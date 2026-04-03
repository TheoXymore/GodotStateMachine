@tool
extends GraphEdit

signal change_initial_state
var popup:PopupMenu

var graph_position: Vector2
var state_node_scene = preload("res://addons/state_machines/StateNode.tscn")

var hovered_state : GraphState = null

enum POPUP_OPTION {
	ADD_NODE = 0,
	RENAME = 1,
	EDIT_NODE = 2,
	ADD_TRANSITION = 3,
	SET_INITIAL = 4,
	REMOVE_NODE = 5
}

func _ready() -> void:
	popup = PopupMenu.new()
	add_child(popup)
	popup.id_pressed.connect(on_popup_pressed)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var click_position = event.position
		var click_global_position = event.global_position
		if event.button_index == MOUSE_BUTTON_RIGHT:
			popup.clear()
			on_right_click(click_position, click_global_position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			popup.clear()
			on_left_click(click_position, click_global_position)
			
func on_right_click(position:Vector2, global_position:Vector2):
	graph_position = (position + scroll_offset) / zoom
	hovered_state = get_state_at_graph_position()
	if hovered_state:
		popup.add_item("Rename", POPUP_OPTION.RENAME)
		popup.add_item("Edit Node",POPUP_OPTION.EDIT_NODE)
		popup.add_item("New Transition",POPUP_OPTION.ADD_TRANSITION)
		popup.add_item("Set as Initial",POPUP_OPTION.SET_INITIAL)	
		popup.add_item("Remove Node",POPUP_OPTION.REMOVE_NODE)
	else :
		popup.add_item("Add Node",POPUP_OPTION.ADD_NODE)
	
	popup.popup(Rect2i(global_position, Vector2i.ZERO))
	
func on_left_click(position:Vector2, global_position : Vector2):
	graph_position = (position + scroll_offset) / zoom
	pass
	
func on_popup_pressed(id:POPUP_OPTION):
	match id :
		POPUP_OPTION.ADD_NODE:
			add_state("State",graph_position)
		POPUP_OPTION.RENAME:
			hovered_state.start_rename()
		POPUP_OPTION.EDIT_NODE:
			pass
		POPUP_OPTION.ADD_TRANSITION:
			pass
		POPUP_OPTION.SET_INITIAL:
			change_initial_state.emit(hovered_state)
		POPUP_OPTION.REMOVE_NODE:
			remove_state(hovered_state)
		
func get_state_at_graph_position() -> GraphState:
	for child in get_children():
		if child is GraphState:
			var rect = Rect2(child.position_offset, child.size)
			if rect.has_point(graph_position):
				return child
	return null
	
func add_state(state_name : String, graph_position : Vector2) -> void:
	var node = GraphState.new()
	node.state_name = state_name
	node.position_offset = graph_position
	node.position_offset_changed.connect(queue_redraw)
	add_child(node)
	node.start_rename()

func remove_state(state:GraphState)->void:
	remove_child(state)
	state.queue_free()
	
func load_from_state_machine(fsm: FiniteStateMachine) -> void:
	# Clear the current graph
	for child in get_children():
		if child is GraphState:
			child.queue_free()
			
	# Draw the new graph
	for state_name in fsm._editor_state_positions:
		var node = GraphState.new()
		node.state_name = state_name
		node.position_offset = fsm._editor_state_positions[state_name]
		node.position_offset_changed.connect(queue_redraw)
		add_child(node)
		
	queue_redraw()
