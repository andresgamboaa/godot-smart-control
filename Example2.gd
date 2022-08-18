extends SmartControl

var item_scene = preload("res://item.tscn")
var items = []
var input = ""

func _ready():
	connect_var("items", $VBoxContainer/ScrollContainer/VBoxContainer, "children")
	connect_var("input", $VBoxContainer/LineEdit, "text")
	connect_func("on_add_button_pressed", $VBoxContainer/Button, "pressed")
	connect_func("on_input_entered", $VBoxContainer/LineEdit, "text_entered")
	connect_func("on_input_changed", $VBoxContainer/LineEdit, "text_changed")
	._ready()

#LOGIC__________________________________________________________________________
func add_new():
	var item = item_scene.instance()
	item.text = input
	connect_func("delete_item", item, "delete_button_pressed")
	connect_var("input", item, "text")
	items.append(item)
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
