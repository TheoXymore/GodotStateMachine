@tool
extends GraphEdit

var popup:PopupMenu

var graph_position: Vector2
var state_node_scene = preload("res://addons/state_machines/StateNode.tscn")

var hovered_state : GraphNode = null

enum POPUP_OPTION {
	ADD_NODE = 0,
	EDIT_NODE = 1,
	ADD_TRANSITION = 2,
	REMOVE_NODE = 3
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
		popup.add_item("Edit Node",POPUP_OPTION.EDIT_NODE)
		popup.add_item("New Transition",POPUP_OPTION.ADD_TRANSITION)	
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
			var state_node = state_node_scene.instantiate()
			state_node.position_offset = graph_position
			add_child(state_node)
		POPUP_OPTION.EDIT_NODE:
			pass
		POPUP_OPTION.ADD_TRANSITION:
			pass
		POPUP_OPTION.REMOVE_NODE:
			remove_child(hovered_state)
			hovered_state.queue_free()
		
	
func get_state_at_graph_position() -> GraphNode:
	for child in get_children():
		if child is GraphNode:
			var rect = Rect2(child.position_offset, child.size)
			if rect.has_point(graph_position):
				return child
	return null
