@tool
extends GraphEdit

signal change_initial_state
signal update_state
signal update_state_position(state_name:String,new_position:Vector2)
signal can_i_create_transition(from:GraphState,to:GraphState)
signal remove(name:String)
signal remove_transition(id:int)

var popup:PopupMenu
var popup_transitions:PopupMenu

var adding_transition:bool = false
var from_state:GraphState

var graph_position: Vector2
var state_node_scene = preload("res://addons/state_machines/StateNode.tscn")

var hovered_state : GraphState = null

var current_transitions:Array[Transition]
var current_states:Dictionary[String,Vector2]

enum POPUP_OPTION {
	ADD_NODE = 0,
	RENAME = 1,
	EDIT_NODE = 2,
	ADD_TRANSITION = 3,
	SET_INITIAL = 4,
	REMOVE_NODE = 5,
	REMOVE_TRANSITION = 6
}

func _ready() -> void:
	set_process(false)
	popup = PopupMenu.new()
	popup_transitions = PopupMenu.new()
	add_child(popup)
	add_child(popup_transitions)
	popup.id_pressed.connect(on_popup_pressed)
	popup_transitions.id_pressed.connect(on_popup_transition_pressed)
	

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
		popup.add_item("Remove Transition",POPUP_OPTION.REMOVE_TRANSITION)
	else :
		popup.add_item("Add Node",POPUP_OPTION.ADD_NODE)
	
	popup.popup(Rect2i(global_position, Vector2i.ZERO))
	
func on_left_click(position:Vector2, global_position : Vector2):
	graph_position = (position + scroll_offset) / zoom
	hovered_state = get_state_at_graph_position()
	if adding_transition:
		if hovered_state == null:
			adding_transition = false
			set_process(false)
		else :
			can_i_create_transition.emit(from_state,hovered_state)
	queue_redraw()

	
func on_popup_pressed(id:POPUP_OPTION):
	match id :
		POPUP_OPTION.ADD_NODE:
			add_state("State",graph_position)
		POPUP_OPTION.RENAME:
			hovered_state.start_rename()
		POPUP_OPTION.EDIT_NODE:
			pass
		POPUP_OPTION.ADD_TRANSITION:
			adding_transition = true
			from_state = hovered_state
			set_process(true)
		POPUP_OPTION.SET_INITIAL:
			change_initial_state.emit(hovered_state)
		POPUP_OPTION.REMOVE_NODE:
			remove_state(hovered_state)
		POPUP_OPTION.REMOVE_TRANSITION:
			init_popup_transitions()

func init_popup_transitions()->void:
	popup_transitions.clear()
	for transition_index in current_transitions.size() :
		if current_transitions[transition_index].from == hovered_state.state_name:
			popup_transitions.add_item("To %s" % current_transitions[transition_index].to, transition_index)
	popup_transitions.popup(Rect2i(get_viewport().get_mouse_position(),Vector2.ZERO))
	
func on_popup_transition_pressed(id:POPUP_OPTION):
	remove_transition.emit(id)
	current_transitions.remove_at(id)
	queue_redraw()
	
func get_state_at_graph_position() -> GraphState:
	for child in get_children():
		if child is GraphState:
			var rect = Rect2(child.position_offset, child.size)
			if rect.has_point(graph_position):
				return child
	return null
	
func add_state(state_name : String, graph_position : Vector2) -> void:
	var node = GraphState.new()
	node.position_offset = graph_position
	node.position_offset_changed.connect(state_position_changed.bind(node))
	node.state_renamed.connect(on_state_renamed)
	add_child(node)
	node.start_rename()

func remove_state(state:GraphState)->void:
	remove.emit(state.state_name)
	for i in range(current_transitions.size()-1,-1,-1):
		var transition = current_transitions[i]
		if transition.from == state.state_name or transition.to == state.state_name:
			current_transitions.remove_at(i)
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
		node.position_offset_changed.connect(state_position_changed.bind(node))
		add_child(node)
	
	current_transitions = fsm._editor_transitions.duplicate()
		
	queue_redraw()
	
func on_state_renamed(old_name, node):
	update_state.emit(old_name,node.state_name,node.position_offset)
	
func state_position_changed(node:GraphState):	
	update_state_position.emit(node.state_name,node.position_offset)
	queue_redraw()
	
func _process(delta:float)->void:
	if adding_transition:
		queue_redraw()
		
func _draw()->void:
	if adding_transition:
		var from_center = graph_to_local(from_state.position_offset + from_state.size/2)
		var mouse_pos = get_local_mouse_position()
		draw_arrow_from_points(from_center, mouse_pos)
	for transition in current_transitions:
		var from:GraphState = find_state(transition.from)
		var to:GraphState = find_state(transition.to)
		if from.state_name == to.state_name:
			draw_arrow_loop(from)
		else :
			draw_arrow(from,to)
	
func find_state(name:String)->GraphState:
	for child in get_children():
		if child is GraphState:
			if child.state_name == name :
				return child as GraphState
	return null	
	
func draw_arrow(from_state:GraphState,to_state:GraphState)->void:
	var from = graph_to_local(from_state.position_offset+from_state.size/2)
	var to = graph_to_local(to_state.position_offset+to_state.size/2)
	var direction = from.direction_to(to)
	var radius = from_state.size/2*zoom
	var start = from + direction * radius
	var end = to - direction * radius
	draw_line(start, end, Color.WHITE, 2.0)
	# Draw the tip of the arrow
	draw_arrowhead(end,direction)
	
func draw_arrow_from_points(from:Vector2,to:Vector2)->void:
	#Draw the line
	var direction = from.direction_to(to)
	var radius = from_state.size/2*zoom
	var start = from + direction * radius
	var end = to - direction * radius
	draw_line(start,end, Color.WHITE, 2.0)
	# Draw the tip of the arrow
	draw_arrowhead(end,direction)
	
func draw_arrow_loop(node: GraphState) -> void:
	# Centre de l'arc : coin haut-droit du node
	var node_top_right = node.position_offset + Vector2(node.size.x, 0)
	var center = graph_to_local(node_top_right)
	var radius = 20.0 * zoom
	
	# Arc de PI à -PI/2 (= 3PI/2) dans le sens antihoraire = 3/4 de cercle
	draw_arc(center, radius, PI/2, -PI, 32, Color.WHITE, 2.0)
	
	# La pointe de la flèche est à -PI/2 (en haut du cercle), direction vers la gauche
	var tip = center + Vector2(0, radius)
	draw_arrowhead(tip, Vector2.LEFT)
	
func draw_arrowhead(tip: Vector2, direction: Vector2) -> void:
	var angle = direction.angle()
	var arrow_size = min(12.0 * zoom, 20.0)
	var p1 = tip - Vector2(cos(angle - 0.4), sin(angle - 0.4)) * arrow_size
	var p2 = tip - Vector2(cos(angle + 0.4), sin(angle + 0.4)) * arrow_size
	draw_colored_polygon([tip, p1, p2], Color.WHITE)


func on_created_transition(transition:Transition)->void:
	var to_state = hovered_state
	var from_name = from_state.state_name
	var to_name = to_state.state_name
	if transition != null :
		current_transitions.append(transition)
	else :
		show_temp_info("Transition from %s to %s already exists" %[from_name,to_name])
	adding_transition = false
	set_process(false)
	queue_redraw()
		
func graph_to_local(graph_pos:Vector2)->Vector2:
	return graph_pos * zoom - scroll_offset
	
func show_temp_info(text: String) -> void:
	var label = Label.new()
	label.text = text
	add_child(label)
	label.position = get_local_mouse_position()
	await get_tree().create_timer(2.0).timeout
	label.queue_free()
	
