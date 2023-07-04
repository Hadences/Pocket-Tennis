extends CanvasLayer

class_name gamehud

func playTextAnimation(str : String):
	$AnimationPlayer.stop()
	$Message.text = str
	$AnimationPlayer.play("EndMessage")


func resetAnimation():
	$AnimationPlayer.stop()
