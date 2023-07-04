extends entity
class_name playerControls

enum Direction{
	LEFT,
	RIGHT
}

var playerDir : Direction = Direction.RIGHT

@export var maxSpeed : float = 500
@export var initial_velocity = 1.2
@export var acceleration : float = 300
@export var linearDrag : float = 10
@export var ballHitThreshold : float = 10 # the threshold for the player to be allowed to swing the ball

var changingDir = true if ((linear_velocity.x > 0.0 && _movementInput.x < 0.0) || (linear_velocity.x < 0.0 && _movementInput.x > 0.0)
|| (linear_velocity.y > 0.0 && _movementInput.y < 0.0) || (linear_velocity.y < 0.0 && _movementInput.y > 0.0)) else false

var _movementInput := Vector2.ZERO

var _nearbyBalls : Array[ball]
var _nearbyBall : bool = false
var _ballTarget : ball = null
var _canHit : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	_nearbyBalls = []
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_updateMovement() #update the inputs
	applyLinearDrag()
	_inputChecker()

func _physics_process(delta):
	_moveCharacter()
	_ballCheck()
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
		#print(_ballTarget)
	else:
		_nearbyBall = false
		_ballTarget = null

func _inputChecker():
	if(Input.is_action_just_pressed("swing")):
		_swing()

func _swing():
	$AnimationPlayer.stop()
	$AnimationPlayer.play("swing_racket_RL")
	SoundManager.playSound(SoundManager.SOUND.SWING,2,1.5)
	if _nearbyBall && _ballTarget._position.z <= ballHitThreshold && _canHit:
		#if ball is near and you swing then apply force torwards where the mouse is facing
		var pushVector = get_viewport().get_mouse_position()
		pushVector = (pushVector - position).normalized()
		pushVector = Vector3(pushVector.x, pushVector.y, 1)
		_ballTarget.addForce(400,pushVector,randf_range(10,12), self)
		
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
	
func _updateMovement():
	_movementInput = Vector2.ZERO
	if(Input.is_action_pressed("move_down")):
		_movementInput.y += 1
	if(Input.is_action_pressed("move_up")):
		_movementInput.y -= 1
	if(Input.is_action_pressed("move_left")):
		playerDir = Direction.LEFT
		_movementInput.x -= 1
	if(Input.is_action_pressed("move_right")):
		playerDir = Direction.RIGHT
		_movementInput.x += 1
	_movementInput = _movementInput.normalized()

func _on_hit_cooldown_timeout():
	_canHit = true

func _on_swing_zone_area_entered(area):
	if area is ball && !_nearbyBalls.has(area):
		_nearbyBalls.append(area)

func _on_swing_zone_area_exited(area):
	if area is ball && _nearbyBalls.has(area):
		_nearbyBalls.erase(area)
