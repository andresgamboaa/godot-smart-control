extends SmartControl

# DATA__________________________________________________________________
var input = ""

var tasks = [
	{text="task 1"},
	{text="task 2"}
]

# HANDLE SIGNALS________________________________________________________________
func on_input_changed(text): 
	input = text

func on_input_entered(_t): 
	if input:
		tasks.push_front({text=input})
		input = ""

func handle_task_deletion(control):
	remove_repeatable(control, tasks)

# CONNECTIONS___________________________________________________________________
func _connections():
	connect_var("input", $"%LineEdit", "text")
	connect_func("on_input_changed", $"%LineEdit", "text_changed")
	connect_func("on_input_entered", $"%LineEdit", "text_entered")
	connect_func("handle_task_deletion", $"%Task", "delete")
	repeat($"%Task", "tasks") # Repeat the task control node for every item in the task array, a reference to a control node will be inserted in the item as control_node
