extends SmartControl

var count = 0 setget set_count
var info = "Zero"

func set_count(value):
	count = value
	
	if count > 0:  
		info = "Positive"
	elif count < 0:
		info = "Negative"
	else:
		info = "Zero"


func increment():
	self.count += 1

func decrement():
	self.count -= 1

