extends Node2D

var life = 100

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		life -= 1
