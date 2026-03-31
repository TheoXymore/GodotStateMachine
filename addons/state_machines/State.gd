@abstract
extends Node
class_name State

signal Transition

@abstract
func enter_state() -> void
	
@abstract
func exit_state() -> void

@abstract
func update(delta : float) -> void

@abstract
func physics_update(delta : float) -> void
