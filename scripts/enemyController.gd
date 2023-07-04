extends entity
class_name enemyControls

enum Direction{
	LEFT,
	RIGHT
}

enum Side{
	LEFT,
	RIGHT
}

var playerSide : enemyControls.Side = enemyControls.Side.LEFT

var playerDir : Direction = Direction.RIGHT

@export var maxSpeed : float = 500
@export var initial_velocity = 1.2
@export var acceleration : float = 300
@export var linearDrag : float = 10
@export var ballHitThreshold : float = 3 # the threshold for the player to be allowed to swing the ball
var hasAI : bool = false

var changingDir = true if ((linear_velocity.x > 0.0 && _movementInput.x < 0.0) || (linear_velocity.x < 0.0 && _movementInput.x > 0.0)
|| (linear_velocity.y > 0.0 && _movementInput.y < 0.0) || (linear_velocity.y < 0.0 && _movementInput.y > 0.0)) else false

var _movementInput := Vector2.ZERO

var _nearbyBalls : Array[ball]
var _nearbyBall : bool = false
var _ballTarget : ball = null
var _canHit : bool = true

var _inBallRadius : bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	_nearbyBalls = []
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if hasAI:
		_processAI(delta)
	applyLinearDrag()

func _physics_process(delta):
	_moveCharacter()
	_ballCheck()

func _processAI(delta):
	var Ball : ball = %world.getBall()
	var Screen = get_tree().root.get_node('game').screen_size
	
	_updateSide(Screen)
	if Ball._position.y < Screen.y/2:
		#function that will run constantly, where ai logic goes
		if !_inBallRadius && !%world.getBall().OutOfBounds && Ball.GroundTaps <= 1:
			_goToBallEntityBallRadius()
		else:
			_movementInput = Vector2.ZERO
			
		#hit the ball when ball has tapped once
		if Ball.GroundTaps == 1 && Ball._position.z <= ballHitThreshold && Ball._position.z > 1:
			#await get_tree().create_timer(randf_range(0.2,0.5)).timeout
			_swing()
	else:
		_movementInput = Vector2.ZERO

func _updateSide(Screen):
	if position.x > Screen.x/2:
		playerSide = enemyControls.Side.RIGHT
	else:
		playerSide = enemyControls.Side.LEFT
		

func _goToBallEntityBallRadius():
	#make the entity follow the ball until it reaches the ball zone
	#get the ball pos, and make enemy follow that direction
	var BallPos = %world.getBall().get_node('EntityBallRadius').global_position
	BallPos = Vector2(BallPos.x,BallPos.y)
	
	var followDir = (BallPos-position).normalized()
	_movementInput = followDir
	
func _ballCheck():
	if !_nearbyBalls.is_empty():
		_nearbyBall = true
		#set ball target as closest ball from player
		var closestBall : ball = _nearbyBalls[0]
		var closestDist : float = (closestBall.position - position).length()
		for b in _nearbyBalls:
			var dist : float = (b.position - position).length()
			if dist < closestDist:
				closestBall = b
				closestDist = dist
		_ballTarget = closestBall

	else:
		_nearbyBall = false
		_ballTarget = null

func _swing():
	if _nearbyBall && _ballTarget._position.z <= ballHitThreshold && _canHit:
		if(!$AnimationPlayer.is_playing()):
			$AnimationPlayer.stop()
			$AnimationPlayer.play("swing_racket_RL")
		SoundManager.playSound(SoundManager.SOUND.SWING,2,1.5)
		var BottomLeft : Vector2 = %Corner_BottomLeft.global_position
		var BottomRight : Vector2 = %Corner_BottomRight.global_position
		var pushVector = Vector2(0,1).normalized()
		var angleOfRotation = 0
		if playerSide == enemyControls.Side.LEFT:
			BottomRight = BottomRight - position
			BottomRight = BottomRight.normalized()
			angleOfRotation = -1*acos((pushVector.dot(BottomRight))/(pushVector.length()*BottomRight.length()))
		elif playerSide == enemyControls.Side.RIGHT:
			BottomLeft = BottomLeft - position
			BottomLeft = BottomLeft.normalized()
			angleOfRotation = 1*acos((pushVector.dot(BottomLeft))/(pushVector.length()*BottomLeft.length()))
		angleOfRotation = randf_range(0,angleOfRotation)
		
		pushVector = pushVector.rotated(angleOfRotation)
		pushVector = Vector3(pushVector.x, pushVector.y, 1)
		_ballTarget.addForce(randf_range(400,450),pushVector,randf_range(10,15),self)
		_canHit = false
		$HitCooldown.start()

func applyLinearDrag():
	if(_movementInput.length() < 0.4 || changingDir):
		linear_damp = linearDrag
	else:
		linear_damp = linearDrag/4

func _moveCharacter():
	#set direction of sprite
	if playerDir == Direction.LEFT:
		$AnimationSprite2D.flip_h = true
	elif playerDir == Direction.RIGHT:
		$AnimationSprite2D.flip_h = false
	#animation stuff
	if(_movementInput == Vector2.ZERO):
		#player is not moving
		$AnimationSprite2D.play("idle")
	else:
		$AnimationSprite2D.play("run")
	
	apply_force(_movementInput * initial_velocity * acceleration)
	if(abs(linear_velocity.length()) > maxSpeed):
		linear_velocity = linear_velocity.normalized() * maxSpeed

func _on_hit_cooldown_timeout():
	_canHit = true

func _on_swing_zone_area_entered(area):
	if area is ball && !_nearbyBalls.has(area):
		_nearbyBalls.append(area)

func _on_swing_zone_area_exited(area):
	if area is ball && _nearbyBalls.has(area):
		_nearbyBalls.erase(area)

func _on_ai_zone_area_entered(area):
	_inBallRadius = true

func _on_ai_zone_area_exited(area):
	_inBallRadius = false
