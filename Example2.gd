extends SmartControl

var item_scene = preload("res://item.tscn")

var items = []

func add_new():
	items.append({
		text="new",
		events=[
			{signal_sended=on_signal_sended}
		],
		scene=item_scene
	})

func on_signal():
	print("signal recieved")
