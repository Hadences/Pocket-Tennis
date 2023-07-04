extends CanvasLayer

func change_scene() -> void:
	$AnimationPlayer.stop()
	$AnimationPlayer.play('dissolve')
	await $AnimationPlayer.animation_finished
	$AnimationPlayer.play_backwards('dissolve')

func slide_transition() -> void:
	$AnimationPlayer.stop()
	$AnimationPlayer.play('slide_up')

func howtoplay() -> void:
	$AnimationPlayer.play('howtoplay')

func _on_texture_button_pressed():
	SoundManager.playSound(SoundManager.SOUND.UI_CLICK)
	$AnimationPlayer.play_backwards("howtoplay")
