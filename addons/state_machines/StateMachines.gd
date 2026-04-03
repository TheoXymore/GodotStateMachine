@tool
extends EditorPlugin

var dock
var dock_content

var selected_node:Node
var selected_state_machine:FiniteStateMachine

func _enable_plugin() -> void:
	# Add autoloads here
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	dock = EditorDock.new()
	dock.title = "State Machine"
	#dock.dock_icon = preload("./dock_icon.png")
	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	dock_content = preload("res://addons/state_machines/state_machine_dock.tscn").instantiate()
	dock.add_child(dock_content)
	add_dock(dock)
	
	EditorInterface.get_selection().selection_changed.connect(on_selection_changed)
	dock_content.FSMCreation.connect(state_machine_initialization)
	
	dock_content.state_machine_graph.change_initial_state.connect(change_initial_state)


func _exit_tree() -> void:
	remove_dock(dock)
	dock.queue_free()
	dock = null
	
func on_selection_changed():
	var selected_nodes:Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes.size() != 1 :
		dock_content.show_no_selection()
	else :
		selected_node = selected_nodes[0]
		var children = selected_node.get_children()
		if children.any(has_state_machine) or selected_node is FiniteStateMachine:
			if selected_node is FiniteStateMachine :
				selected_state_machine = selected_node
			else :
				selected_state_machine = get_first_state_machine(children)
			#dock_content.state_machine_graph.load_from_state_machine(selected_state_machine)
			dock_content.show_graph()
		else :
			dock_content.show_no_state_machine()

func has_state_machine(node):
	return node is FiniteStateMachine
	
func state_machine_initialization()->void:
	var parent:Node = EditorInterface.get_selection().get_selected_nodes()[0]
	var fsm:FiniteStateMachine = FiniteStateMachine.new()
	fsm.name = "StateMachine"
	
	var undo_redo = get_undo_redo()
	undo_redo.create_action("Create State Machine")
	undo_redo.add_do_method(parent,"add_child",fsm)
	undo_redo.add_do_method(fsm,"set_owner",EditorInterface.get_edited_scene_root())
	undo_redo.add_undo_method(parent,"remove_child",fsm)
	
	undo_redo.commit_action()

	selected_state_machine = fsm
	dock_content.show_graph()  

func change_initial_state(state:GraphState):
	selected_state_machine._editor_initial_state = state.state_name
	selected_state_machine.initial_state = selected_state_machine.find_child(state.state_name)

func get_first_state_machine(nodes:Array[Node]):
	for node in nodes:
		if node is FiniteStateMachine:
			return node
	return null
