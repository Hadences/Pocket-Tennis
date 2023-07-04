extends CanvasLayer

signal start_button_pressed
signal manual_button_pressed

func _on_button_start_pressed():
	start_button_pressed.emit()


func _on_button_manual_pressed():
	manual_button_pressed.emit()
	
