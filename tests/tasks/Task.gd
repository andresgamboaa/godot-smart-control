extends SmartControl

signal delete(task)
var text


func emit_delete_signal():
	emit_signal("delete", self)


func _connections():
	connect_var("text", $PanelContainer/HBoxContainer/Label, "text")
	connect_func("emit_delete_signal", $PanelContainer/HBoxContainer/Button, "pressed")
