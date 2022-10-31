extends KinematicBody2D

const PlayerHurtSound = preload("res://Player/PlayerHurtSound.tscn")

export var ACCELERATION = 500
export var MAX_SPEED = 100
export var ROLL_SPEED = 150
export var FRICTION = 500

enum {
	MOVE,
	ROLL,
	ATTACK,
	FREEZE
}

var state = MOVE setget set_state
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var stats = PlayerStats

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var hurtbox = $Hurtbox
onready var hurtbox_collision = $Hurtbox/CollisionShape2D
onready var sprite = $Sprite
onready var blinkAnimationPlayer = $BlinkAnimationPlayer

func _ready():
	global_position = Global.player_initial_map_position
	stats.connect("no_health", self, "queue_free")
	animationTree.active = true
	$HitboxPivot/SwordHitbox/CollisionShape2D.disabled = true

func set_state(value):
	state = value

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
			
		ROLL:
			roll_state(delta)
			
		ATTACK:
			attack_state(delta)
			
		FREEZE:
			animationPlayer.stop()
			velocity = Vector2.ZERO
	
	
func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	move()
	
	if Input.is_action_just_pressed("attack"):
		set_state(ATTACK)
		
	if Input.is_action_just_pressed("roll"):
		hurtbox_collision.set_deferred("disabled", true)
		set_state(ROLL)
	
	
func attack_state(delta):
	# stops weird slide after attack
	velocity = Vector2.ZERO
	animationState.travel("Attack")

# called via a method call inside the attack animations in the AnimationPlayer
func attack_animation_finished():
	if state != FREEZE:
		set_state(MOVE)
	
func move():
	velocity = move_and_slide(velocity)
	
func roll_state(delta):
	velocity = roll_vector * ROLL_SPEED
	animationState.travel("Roll")
	move()
	
# called via a method call inside the roll animations in the AnimationPlayer
func roll_animation_finished():
	velocity = Vector2.ZERO
	hurtbox_collision.set_deferred("disabled", false)
	set_state(MOVE)


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(0.7)
	if area.type == "FREEZE":
		hurtbox.create_status_effect(area.type, area, self)
		set_state(FREEZE)
	else:
		hurtbox.create_hit_effect(area)
		var playerHurtSound = PlayerHurtSound.instance()
		get_tree().current_scene.add_child(playerHurtSound)


func _on_Hurtbox_status_started(color):
		sprite.modulate = color


func _on_Hurtbox_status_stopped():
	sprite.modulate = Color(1, 1, 1)
	animationPlayer.play()
	set_state(MOVE)



func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")


func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")
