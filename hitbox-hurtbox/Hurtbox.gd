extends Area2D

const HitEffect = preload("res://Effects/HitEffect.tscn")
const FreezeEffect = preload("res://Effects/FreezeEffect.tscn")
const UniceEffect = preload("res://Effects/UnfreezeEffect.tscn")

onready var statusDurationTimer = $StatusDurationTimer

var invincible = false setget set_invicible
var status_active = false

enum {
	FREEZE,
}

signal invincibility_started
signal invincibility_ended
signal status_started
signal status_stopped

onready var timer = $Timer
onready var collisionShape = $CollisionShape2D

func set_invicible(value):
	invincible = value
	if invincible == true:
		emit_signal("invincibility_started")
	else:
		emit_signal("invincibility_ended")

func start_invincibility(duration):
	timer.start(duration)
	self.invincible = true

func create_status_effect(status, area, affected):
	if status == "FREEZE" and status_active == false:
		emit_signal("status_started", Color(0.5, 0.5, 1))
		var effect = FreezeEffect.instance()
		var main = get_tree().current_scene
		main.add_child(effect)
		effect.global_position = global_position - Vector2(0, 8)
		status_active = true
		statusDurationTimer.start(area.freeze_strength)

func create_hit_effect(area):
	var effect = HitEffect.instance()
	var main = get_tree().current_scene
	main.add_child(effect)
	effect.global_position = global_position - Vector2(0,8)

func _on_Timer_timeout():
	self.invincible = false


func _on_Hurtbox_invincibility_started():
	collisionShape.set_deferred("disabled", true)


func _on_Hurtbox_invincibility_ended():
	collisionShape.disabled = false


func _on_StatusDurationTimer_timeout():
	var effect = UniceEffect.instance()
	var main = get_tree().current_scene
	main.add_child(effect)
	effect.global_position = global_position - Vector2(0,8)
	status_active = false
	emit_signal("status_stopped")
	
