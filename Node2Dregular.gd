extends Node2D

var life = 100 setget set_life

func set_life(value):
	life = value
	$CanvasLayer/ui/Label.text = str(life)

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		self.life -= 1
