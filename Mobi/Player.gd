extends KinematicBody2D

const ACCELERATION = 300
const MAX_SPEED = 100
const FRICTION = 200

var velocity = Vector2.ZERO

func _ready():
	$AnimatedSprite.connect("animation_finished", self, "_on_AnimatedSprite_animation_finished")
	$AnimatedSprite.play("default")

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = Vector2.ZERO

	if $AnimatedSprite.animation != "spin":
		if velocity.x > 0:
			$AnimatedSprite.play("turn_right")
		elif velocity.x < 0:
			$AnimatedSprite.play("turn_left")
		else:
			$AnimatedSprite.play("default")

func spin():
	$AnimatedSprite.play("spin")

func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "spin":
		$AnimatedSprite.play("default")
