#Class to represent a State Node in a graph
extends GraphElement
class_name GraphState

signal state_renamed

const CIRCLE_COLOR = Color(0.15, 0.15, 0.15, 0.7)
const BORDER_COLOR = Color(1.0, 1.0, 1.0)
const TEXT_COLOR = Color(1.0, 1.0, 1.0)
const BORDER_WIDTH = 2.0

var state_name:String = "State":
	set(value) :
		state_name = value
		queue_redraw()
		
	get():
		return state_name
		
var line_edit:LineEdit		

func _ready()->void:
	custom_minimum_size = Vector2(80,80)
	size = custom_minimum_size
	
	line_edit = LineEdit.new()
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_edit.add_theme_color_override("font color", Color.WHITE)
	line_edit.add_theme_color_override("background", Color.TRANSPARENT)
	add_child(line_edit)
	line_edit.hide()
	
	line_edit.text_submitted.connect(on_name_submitted)
	line_edit.focus_exited.connect(on_name_submitted.bind(line_edit.text))
	

func _draw()->void:
	var center = size/2
	var radius = min(size.x,size.y)/2 - BORDER_WIDTH
	
	# Draw the inside of the node
	draw_circle(center, radius,CIRCLE_COLOR)
	
	# Draw the border of the state
	draw_arc(center, radius, 0, TAU, 64, BORDER_COLOR, BORDER_WIDTH)
	
	# Draw the name of the state
	var font = ThemeDB.fallback_font
	var font_size = ThemeDB.fallback_font_size
	var text_width = font.get_string_size(state_name,HORIZONTAL_ALIGNMENT_CENTER,-1,font_size).x
	var ascent = font.get_ascent(font_size)
	var descent = font.get_descent(font_size)
	var text_pos = Vector2(center.x - text_width / 2, center.y + (ascent - descent) / 2 )
	
	draw_string(font, text_pos,state_name,HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, TEXT_COLOR)      
	
func start_rename() -> void:
	line_edit.text = state_name
	line_edit.size = Vector2(size.x - 10,24)
	line_edit.position = Vector2(5,size.y / 2 - 12)
	line_edit.show()
	line_edit.grab_focus()
	line_edit.select_all()

func on_name_submitted(new_name:String)->void:
	var old_name:String
	if new_name != "":
		old_name = state_name
		state_name = new_name
		state_renamed.emit(old_name,self)
	line_edit.hide()
