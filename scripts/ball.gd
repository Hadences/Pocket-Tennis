extends Area2D
class_name ball

signal on_ball_hit # when the ball is hit by an entity
signal on_ball_land # when the ball lands on ground
signal same_entity_hit # when the same entity hit the ball
signal ball_double_tapped # when the ball taps the ball more than once

@export var maxScale : float = 10
@export var minScale : float = 1
@export var maxHeight : float = 100
@export var startingHeight : float = 10
@export var damping_factor : float = 0.794
@export var friction_coefficient : float = 0.2
@export var physics_scale : float = 2

var _onGround : bool = false
var _position : Vector3 = Vector3.ZERO
var _velocity : Vector3 = Vector3.ZERO
var _acceleration : Vector3 = Vector3.ZERO
var _scale : float = 0.0
var _gravity : float = -20
var _floor : float = 0

var _force : Vector3 = Vector3.ZERO # force to apply to the ball
var _friction_force : Vector3 = Vector3.ZERO

#Game Data
var Hitter : entity #the one who hit the ball
var PreviousHitter : entity #the previous hitter of the ball
var GroundTaps : int = 0 #number of times the ball touched the ground
var OutOfBounds : bool = false

func _ready():
	_position.z = startingHeight

func _process(delta):
	#apply gravity constantly until it reaches the height of 0
	_heightUpdate()
	if _onGround:
		_friction_force = -1*friction_coefficient * _velocity
	else:
		_friction_force = Vector3.ZERO

	position.x = _position.x
	position.y = _position.y

	var screen = get_tree().root.get_node('game').screen_size
	if position.x > screen.x || position.x < 0 || position.y > screen.y || position.y < 0:
		OutOfBounds = true
	else:
		OutOfBounds = false
	
func _physics_process(delta):
	ball_physics(delta)
	pass

func _heightUpdate():
	var increment = maxScale/maxHeight * _position.z
	increment += minScale

	if increment < minScale:
		increment = minScale
	elif increment > maxScale:
		increment = maxScale
	scale = Vector2(increment,increment)

func ball_physics(delta):
	
	_position.z += _velocity.z * delta	
	_velocity.x += _acceleration.x*delta + _force.x + _friction_force.x
	_position.x += _velocity.x * delta
	_velocity.y += _acceleration.y*delta + _force.y + _friction_force.y
	_position.y += _velocity.y * delta
	
	if _position.z > _floor:
		_onGround = false
		_velocity.z += _gravity*delta + _force.z
	else:
		_onGround = true
		_velocity.z = -_velocity.z*damping_factor
		_position.z = 0
		GroundTaps += 1
		if GroundTaps >= 2: # if the ball taps the gorund more than once then emit signal
			ball_double_tapped.emit()
		on_ball_land.emit()
	
	_force = Vector3.ZERO

func addForce(force : float = 100, dir : Vector3 = Vector3.ZERO, upward_force : float = 10, hitter : entity = null):
	SoundManager.playSound(SoundManager.SOUND.BALL_HIT,1,1)
	_velocity = Vector3.ZERO
	
	_force.x += force * dir.x
	_force.y += force * dir.y
	
	_force.z += upward_force * dir.z
	#GroundTaps = 0
	if hitter == null:
		return
	if Hitter == PreviousHitter:
		same_entity_hit.emit()
	PreviousHitter = Hitter
	Hitter = hitter
	on_ball_hit.emit(hitter)

func setPosition(vec : Vector2):
	_position.x = vec.x
	_position.y = vec.y

	
