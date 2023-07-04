extends Node2D

class_name world

@onready var SoundManager : soundManager = $soundManager

func getSoundManager():
	return SoundManager
	
func getPlayer():
	return $Player as playerControls

func getBall():
	return $Ball as ball

func getEnemy():
	return $Enemy as enemyControls
	
