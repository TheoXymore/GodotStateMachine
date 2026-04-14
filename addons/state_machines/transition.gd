extends Resource
class_name Transition

@export var from:String
@export var to:String

func _init(from_state:String,to_state:String)->void:
	from = from_state
	to = to_state

	
