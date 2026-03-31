@tool
extends EditorPlugin

var dock
var dock_content

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
	
	get_editor_interface().get_selection().selection_changed.connect(on_selection_changed)
	# Initialization of the plugin goes here.


func _exit_tree() -> void:
	remove_dock(dock)
	dock.queue_free()
	dock = null
	
func on_selection_changed():
	var selected_nodes:Array[Node] = get_editor_interface().get_selection().get_selected_nodes()
	print(selected_nodes)
	if selected_nodes.size() != 1 :
		dock_content.show_no_selection()
	else :
		var children = selected_nodes[0].get_children()
		if children.any(has_state_machine):
			dock_content.show_graph()
		else :
			dock_content.show_no_state_machine()

func has_state_machine(node):
	return node is FiniteStateMachine
