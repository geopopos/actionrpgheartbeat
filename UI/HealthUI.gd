extends Control

export var max_hearts = 4 setget set_max_hearts
export(int) var hearts = 4 setget set_hearts

onready var heartUIEmpty = $HeartUIEmpty
onready var heartUIFull = $HeartUIFull

func set_hearts(value):
	hearts = clamp(value, 0, max_hearts)
	if heartUIFull != null:
		heartUIFull.rect_size = Vector2(15*hearts, 11)
	
	
func set_max_hearts(value):
	max_hearts = max(value, 1)
	self.hearts = clamp(hearts, 0, max_hearts)
	if heartUIEmpty != null:
		heartUIEmpty.rect_size = Vector2(15*max_hearts, 11)

func _ready():
	self.max_hearts = PlayerStats.max_health
	self.hearts = PlayerStats.health
	heartUIEmpty.rect_size = Vector2(15*max_hearts, 11)
	heartUIFull.rect_size = Vector2(15*hearts, 11)
	PlayerStats.connect("health_changed", self, "set_hearts")
	PlayerStats.connect("max_health_changed", self, "set_max_hearts")
