extends SmartControl

var items = [
	{text="task 1"},
	{text="task 2"},
	{text="task 3"},
	{text="task 4"},
	{text="task 5"},
]

func _connections():
	repeat($"%Label", "items")
