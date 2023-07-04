extends Node2D

enum SOUND{
	BALL_HIT,
	POINT_WIN,
	START_ROUND,
	SWING,
	UI_CLICK
}

@onready var soundEffects = {
	SOUND.BALL_HIT : $BallHit,
	SOUND.POINT_WIN : $PointWin,
	SOUND.START_ROUND : $StartRound,
	SOUND.SWING : $Swing,
	SOUND.UI_CLICK : $UIClick
}

func playSound(sound : SOUND, volume : float = 1, pitch : float = 1):
	if soundEffects.has(sound):
		var s : AudioStreamPlayer = soundEffects[sound]
		s.volume_db = volume
		s.pitch_scale = pitch
		s.play()
		
