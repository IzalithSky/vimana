class_name SAM extends MissileLauncher



@export var fire_interval: float = 2.0

@onready var health: Health = $Health

var _timer: float = 0.0


func _ready() -> void:
	add_to_group("targets")
	health.died.connect(die)


func die() -> void:
	queue_free()


func _process(delta: float) -> void:
	if not target:
		target = get_tree().get_first_node_in_group("player")
	
	if target:
		_timer += delta
		if _timer >= fire_interval:
			_timer = 0.0
			launch_missile()
