extends SmartControl
signal delete_button_pressed(item)

var text = "text"

func _on_delete_button_pressed():
	emit_signal("delete_button_pressed",self)
