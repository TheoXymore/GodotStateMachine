@tool
#Plugin script for the State Machines
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
	dock_content.state_machine_graph.update_state.connect(update_state)
	dock_content.state_machine_graph.can_i_create_transition.connect(new_transition)
	dock_content.state_machine_graph.update_state_position.connect(update_state_position)
	dock_content.state_machine_graph.remove.connect(remove_state)
	dock_content.state_machine_graph.remove_transition.connect(remove_transition)


func _exit_tree() -> void:
	remove_dock(dock)
	dock.queue_free()
	dock = null
	
#Function called when the selection in the SceneTree is changed
func on_selection_changed():
	var selected_nodes:Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	#If there is 0 or more than 1 Node selected, we tell the user to change its selection
	if selected_nodes.size() != 1 :
		dock_content.show_no_selection()
	else :
		selected_node = selected_nodes[0]
		var children = selected_node.get_children()
		#If the selected node is or has a child that is a State Machine, great ! 
		if children.any(has_state_machine) or selected_node is FiniteStateMachine:
			if selected_node is FiniteStateMachine :
				selected_state_machine = selected_node
			else :
				selected_state_machine = get_first_state_machine(children)
			dock_content.state_machine_graph.load_from_state_machine(selected_state_machine)
			dock_content.show_graph()
		#Else, we allow the user to create a new State Machine
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
	dock_content.state_machine_graph.load_from_state_machine(selected_state_machine)

func change_initial_state(state:GraphState):
	selected_state_machine._editor_initial_state = state.state_name
	selected_state_machine.initial_state = selected_state_machine.find_child(state.state_name)
	
func update_state(old_state_name : String,state_name: String, position: Vector2) -> void:
	var state_to_update = selected_state_machine.find_child(old_state_name)
	if (state_to_update == null) :
		#Script creation
		var script = GDScript.new()
		script.source_code = """extends State

func enter_state() -> void:
	pass

func exit_state() -> void:
	pass

func update(delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	pass
	"""
		var path = selected_state_machine.scripts_location
		ensure_dir_exists(path)
		var dir = DirAccess.open(path)
		var script_path = "%s/%s.gd" % [dir.get_current_dir(), ("state_" + state_name.to_lower())]
		ResourceSaver.save(script, script_path)
		
		# Node creation
		var state_node = State.new()
		state_node.name = state_name
		state_node.set_script(load(script_path))
		
		# 3. Adding node as a child of the FSM
		var undo_redo = get_undo_redo()
		undo_redo.create_action("Add State: %s" % state_name)
		undo_redo.add_do_method(selected_state_machine, "add_child", state_node)
		undo_redo.add_do_method(state_node, "set_owner", EditorInterface.get_edited_scene_root())
		undo_redo.add_undo_method(selected_state_machine, "remove_child", state_node)
		undo_redo.commit_action()
		
		# Update FSM editor data
		selected_state_machine._editor_state_positions.set(state_name,position)
		
	else :
		#Update sceneTree
		state_to_update.name = state_name
		
		#Update script path and class_name
		var old_path = "%s/state_%s.gd" % [selected_state_machine.scripts_location,old_state_name.to_lower()]
		var new_path = "%s/state_%s.gd" % [selected_state_machine.scripts_location,state_name.to_lower()]

		var script = load(old_path) as GDScript
		ResourceSaver.save(script, new_path)
		state_to_update.set_script(load(new_path))
		# Delete old file
		OS.move_to_trash(ProjectSettings.globalize_path("%s/state_%s.gd" % [selected_state_machine.scripts_location,old_state_name.to_lower()]))			
		
		# Update the editor data
		# States and positions
		selected_state_machine._editor_state_positions.set(state_name,position)
		selected_state_machine._editor_state_positions.erase(old_state_name)
		
		# Transitions
		for transition in selected_state_machine._editor_transitions:
			if transition.from == old_state_name:
				transition.from = state_name
			if transition.to == old_state_name:
				transition.to = state_name
		
		# Initial State
		if selected_state_machine._editor_initial_state == old_state_name:
			selected_state_machine._editor_initial_state = state_name
		
		#Reload the editor to see the change
		EditorInterface.get_resource_filesystem().scan()
	print(selected_state_machine._editor_state_positions)
	
func update_state_position(name:String,new_pos:Vector2):
	selected_state_machine._editor_state_positions.set(name,new_pos)


func get_first_state_machine(nodes:Array[Node]):
	for node in nodes:
		if node is FiniteStateMachine:
			return node
	return null
	
	
func new_transition(from:GraphState,to:GraphState):
	if transition_exists(from.state_name,to.state_name):
		dock_content.state_machine_graph.on_created_transition(null)
	else :
		var transition = Transition.new(from.state_name,to.state_name)
		selected_state_machine._editor_transitions.append(transition)
		dock_content.state_machine_graph.on_created_transition(transition)
		# Ajout de la méthode dans le script du state FROM
		var path = "%s/state_%s.gd" % [selected_state_machine.scripts_location,from.state_name.to_lower()]
		var script = load(path) as GDScript
		
		var func_name = "transition_to_%s" % to.state_name.to_lower()
		if func_name not in script.source_code:
			script.source_code += """
func %s() -> void:
	Transition.emit(self, \"%s\")
""" % [func_name, to.state_name]
			ResourceSaver.save(script, path)
			EditorInterface.get_resource_filesystem().scan()
	
func transition_exists(from_name:String,to_name:String)->bool:
	for transition in selected_state_machine._editor_transitions:
		if transition.from == from_name && transition.to == to_name:
			return true
	return false
	
func remove_state(name:String)->void:
	var state_to_remove = selected_state_machine.find_child(name)
	#Remove all transitions implying the state
	for i in range(selected_state_machine._editor_transitions.size()-1,-1,-1):
		var transition = selected_state_machine._editor_transitions[i]
		if transition.from == name or transition.to == name:
			selected_state_machine._editor_transitions.remove_at(i)
	selected_state_machine._editor_state_positions.erase(name)
	selected_state_machine.remove_child(state_to_remove)
	state_to_remove.queue_free()
	#No script deletion, maybe want to use it somewhere else
	
func remove_transition(id:int)->void:
	selected_state_machine._editor_transitions.remove_at(id)

func ensure_dir_exists(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
