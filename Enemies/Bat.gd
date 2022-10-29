extends KinematicBody2D

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200

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

onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var sprite = $Sprite
onready var shadowSprite = $ShadowSprite
onready var hurtbox = $Hurtbox
onready var animationPlayer = $AnimationPlayer

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
		
		WANDER:
			pass
			
		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				var direction = (player.global_position - global_position).normalized()
				velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
				sprite.flip_h = velocity.x < 0
			else:
				state = IDLE
		FREEZE:
			animationPlayer.stop()
			velocity = Vector2.ZERO
		
	velocity = move_and_slide(velocity)

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

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

func _on_Stats_no_health():
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
