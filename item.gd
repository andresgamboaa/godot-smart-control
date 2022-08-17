extends SmartControl
signal signal_sended

var text = "text"

func emit():
	emit_signal("signal_sended")
