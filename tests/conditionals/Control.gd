extends SmartControl

onready var scenes = [
	preload("res://tests/conditionals/scene_one.tscn"),
	preload("res://tests/conditionals/scene_two.tscn")
]

onready var c_index = create_binary_toggle(0)
onready var current_scene = scenes[c_index.value].instance()

var dollars = 0

# Modifier
func to_dollars(value):
	return "$"+str(value)

func change_scene():
	current_scene = scenes[c_index.value].instance()
	dollars += 1

func change():
	print("current_scene changed") # See line 27

func _connections():
	connect_func("change_scene",$VBoxContainer/Button, "pressed")
	connect_var("current_scene", $VBoxContainer/CurrentScene, "child")
	connect_var("dollars", $VBoxContainer/Label, "text", "to_dollars")
	connect_func("change", self, "current_scene")
