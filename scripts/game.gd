extends Node2D
class_name game

@onready var screen_size = get_viewport().get_visible_rect().size

@onready var NET : CollisionShape2D = %NetBoundary

var _net_height : float = 1
var enemy_score : int = 0
var player_score : int = 0

var server : entity = null
var inGame : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	initGame()
	#$world.getBall().setPosition(Vector2(screen_size.x/2,screen_size.y/2)	)
	
func initGame(): #the init method, when the game first loads, this function is triggered
	#initially, the game should be at a pause and only hud can be interacted with.
	getWorld().getBall().hide()
	getWorld().getPlayer().hide()
	getWorld().getEnemy().hide()
	$game_hud.hide()
	$HUD.show()
	pauseGame()
	screen_size

func _process(delta):
	var Ball : ball = %Ball
	if (Ball._position.y <= %NetBoundary.global_position.y + 5 && Ball._position.y >= %NetBoundary.global_position.y - 5):
		Ball.GroundTaps = 0
	_ball_hit_net()

func pauseGame():
	get_tree().paused = true

func unPauseGame():
	get_tree().paused = false

func getWorld():
	return %world as world

func startInit():
	SceneTransition.slide_transition()
	await get_tree().create_timer(0.8).timeout
	$HUD.hide() #hide the HUD
	$game_hud.show()
	startGame()
	
func startGame():
	resetScores()
	updateScores()
	var Player : playerControls = getWorld().getPlayer()
	var Ball : ball = getWorld().getBall()
	var Enemy : enemyControls = getWorld().getEnemy()
	server = Enemy if randi_range(0,1) == 0 else Player
	
	Player.show()
	Ball.show()
	Enemy.show()
	Player.position = _getData().spawnPoint_Player.position
	Enemy.position = _getData().spawnPoint_Enemy.position
	
	await get_tree().create_timer(0.5).timeout
	if server is enemyControls:
		_placeBall(Vector3(server.position.x, server.position.y+50 ,10))
	elif server is playerControls:
		_placeBall(Vector3(server.position.x, server.position.y-20 ,10))
	Enemy.hasAI = true
	Ball.GroundTaps = 0
	Ball.Hitter = null
	Ball.PreviousHitter = null
	unPauseGame()
	inGame = true
	SoundManager.playSound(SoundManager.SOUND.START_ROUND,1,1)
	
func startRound(Server : entity):
	unPauseGame()
	SoundManager.playSound(SoundManager.SOUND.START_ROUND,1,1)
	var Player : playerControls = getWorld().getPlayer()
	var Ball : ball = getWorld().getBall()
	var Enemy : enemyControls = getWorld().getEnemy()
	server = Enemy if randi_range(0,1) == 0 else Player
	Player.show()
	Ball.show()
	Enemy.show()
	Player.position = _getData().spawnPoint_Player.position
	Enemy.position = _getData().spawnPoint_Enemy.position
	Ball._velocity = Vector3.ZERO
	
	if Server is enemyControls:
		_placeBall(Vector3(Server.position.x, Server.position.y+50 ,10))
	elif Server is playerControls:
		_placeBall(Vector3(Server.position.x, Server.position.y-20 ,10))
	else:
		if server is enemyControls:
			_placeBall(Vector3(server.position.x, server.position.y+50 ,10))
		elif server is playerControls:
			_placeBall(Vector3(server.position.x, server.position.y-20 ,10))
	Enemy.hasAI = true
	Ball.GroundTaps = 0
	Ball.Hitter = null
	Ball.PreviousHitter = null

func endRound(winner : entity = null):
	SoundManager.playSound(SoundManager.SOUND.POINT_WIN,1,1)
	if winner is playerControls:
		player_score += 1
	elif winner is enemyControls:
		enemy_score += 1
	updateScores()
	pauseGame()
	
	if player_score == 12 || enemy_score == 12:
		#end game logic
		var gameHud : gamehud = $game_hud
		var str : String = ''
		if player_score == 12:
			str = 'BEAR'
		elif enemy_score == 12:
			str = 'DUCK'	
		gameHud.playTextAnimation(str + " Wins!")
		inGame = false
		await get_tree().create_timer(3).timeout
		gameHud.resetAnimation()
		initGame()
	else:
		#await get_tree().create_timer(1).timeout
		SceneTransition.change_scene()
		await get_tree().create_timer(2).timeout
		startRound(winner)
	
func updateScores():
	$game_hud/Bear/BearScore.text = str(player_score)
	$game_hud/Duck/DuckScore.text = str(enemy_score)
	
func resetScores():
	player_score = 0;
	enemy_score = 0;

func _on_hud_manual_button_pressed():
	SoundManager.playSound(SoundManager.SOUND.UI_CLICK)
	SceneTransition.howtoplay()

func _on_hud_start_button_pressed():
	SoundManager.playSound(SoundManager.SOUND.UI_CLICK)
	startInit()

func _getData():
	return %Data as data

func _placeBall(pos : Vector3):
	#places the ball at the position 
	var Ball : ball = getWorld().getBall()
	Ball._position = Vector3(pos.x,pos.y,pos.z)

func _on_ball_on_ball_hit():
	pass # Replace with function body.

func _ball_hit_net():
	#when the ball hits the net
	var Ball : ball = %Ball
	if Ball._position.z <= _net_height && (Ball._position.y <= %NetBoundary.global_position.y + 5 && Ball._position.y >= %NetBoundary.global_position.y - 5):
		Ball._velocity = Vector3.ZERO
		if Ball.Hitter is playerControls:
			endRound(%Enemy)
		elif Ball.Hitter is enemyControls:
			endRound(%Player)

func _on_ball_ball_double_tapped() -> void:
	if inGame == false:
		return
	var Ball : ball = %Ball
	var playerSide : bool = false
	
	if Ball._position.y > %NetBoundary.global_position.y:
		playerSide = true
	else:
		playerSide = false
	
	
	Ball._velocity = Vector3.ZERO
	if Ball.Hitter is playerControls:
		if playerSide:
			endRound(%Enemy)
		else:
			endRound(%Player)
	elif Ball.Hitter is enemyControls:
		if !playerSide:
			endRound(%Player)
		else:
			endRound(%Enemy)
	else:
		endRound()

func _on_ball_on_ball_land():
	var Ball : ball = %Ball
	if Ball.GroundTaps == 1 && _BallOutOfBounds(Ball):
		if Ball.Hitter is playerControls:
			endRound(%Enemy)
		elif Ball.Hitter is enemyControls:
			endRound(%Player)

func _BallOutOfBounds(Ball : ball) -> bool:
	if %Floor_Enemy.get_overlapping_areas().has(Ball) || %Floor_Player.get_overlapping_areas().has(Ball):
		return false
	return true

func _on_ball_same_entity_hit():
	var Ball : ball = %Ball
	if Ball.Hitter is playerControls:
		endRound(%Enemy)
	elif Ball.Hitter is enemyControls:
		endRound(%Player)
			
