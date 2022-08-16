extends SmartControl
onready var item_scene = preload("res://item.tscn")

var text = ""
var items = [
	{scene=item_scene}
]

func add_new():
	items.append({scene=item_scene})
