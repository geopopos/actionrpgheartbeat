extends KinematicBody2D

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200
export var WANDER_TARGET_RANGE = 4

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

enum {
	IDLE,
	WANDER,
	CHASE,
	FREEZE
}

var state = CHASE
var spawner

onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var sprite = $Sprite
onready var shadowSprite = $ShadowSprite
onready var hurtbox = $Hurtbox
onready var animationPlayer = $AnimationPlayer
onready var wanderController = $WanderController
onready var blinkAnimationPlayer = $BlinkAnimationPlayer

func _ready():
	print(stats.max_health)
	print(stats.health)

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
		
			if wanderController.get_time_left() == 0:
				update_wander()
		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander()
			accelerate_towards_point(wanderController.target_position, delta)
			wanderController.update_target_position()
			
				
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				update_wander()
		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				accelerate_towards_point(player.global_position, delta)
			else:
				state = IDLE
		FREEZE:
			animationPlayer.stop()
			velocity = Vector2.ZERO
		
	velocity = move_and_slide(velocity)

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func accelerate_towards_point(position, delta):
	var direction = global_position.direction_to(position)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0

func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1,3))

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	if area.type == "FREEZE":
		hurtbox.create_status_effect(area.type, area, self)
		state = FREEZE
	else:
		hurtbox.create_hit_effect(area)
		knockback.x = global_position.x - area.global_position.x
		knockback.y = global_position.y - area.global_position.y
		var m = sqrt(knockback.x*knockback.x + knockback.y*knockback.y)
		knockback.x /= m
		knockback.y /= m
		
		knockback = knockback * 125
	hurtbox.start_invincibility(0.3)

func _on_Stats_no_health():
	spawner.set_state(1)
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position



func _on_Hurtbox_status_started(color):
	sprite.modulate = color


func _on_Hurtbox_status_stopped():
	sprite.modulate = Color(1, 1, 1)
	animationPlayer.play()
	state = CHASE


func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")


func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")
