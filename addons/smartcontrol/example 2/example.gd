extends SmartControl

var count = 0

func increment():
	count += 1

func decrement():
	count -= 1

func _connections():
	connect_func("increment", $"%Button", "pressed")
	connect_var("count", $"%Label", "text")
	connect_func("decrement", $"%Button2", "pressed")
