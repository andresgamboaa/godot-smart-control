extends SmartControl

var item_scene = preload("res://tests/items_list/item.tscn")
var items = []
var input = ""



#LOGIC__________________________________________________________________________
func add_new():
	var item = item_scene.instance()
	item.text = input
	connect_func("delete_item", item, "delete_button_pressed") # Connect the function delete_item with the signal delete_button_pressed  of item
	connect_var("input", item, "text") # The text property of item will be updated every time the variable input changes
	items.append(item)  # The item will be automatically added to its parent because of line 37
	input = ""

func delete_item(item):
	items.erase(item)
	item.queue_free()

#HANDLE_SIGNALS_________________________________________________________________
func on_add_button_pressed():
	add_new()

func on_input_entered(_text):
	add_new()

func on_input_changed(text):
	input = text

#________________________________________________________________________________
func _connections():
	connect_var("items", $VBoxContainer/ScrollContainer/VBoxContainer, "children")
	connect_var("input", $VBoxContainer/LineEdit, "text")
	connect_func("on_add_button_pressed", $VBoxContainer/Button, "pressed")
	connect_func("on_input_entered", $VBoxContainer/LineEdit, "text_entered")
	connect_func("on_input_changed", $VBoxContainer/LineEdit, "text_changed")
