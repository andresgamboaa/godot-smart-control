extends Object
class_name BinaryToggle

var value := 0 setget set_value, get_value

func set_value(_value):
	value = value

func get_value():
	var current = value
	value = 1 if value == 0 else 0
	return current

func _init(initial:int=0):
	if initial != 0 and initial != 1:
		push_error("Invalid initial value for binary toggle. Use 0 of 1.")
	value = initial

func current():
	return value
