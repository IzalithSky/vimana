class_name SAM extends MissileLauncher


@onready var health: Health = $Health

func _ready() -> void:
	add_to_group("targets")
	health.died.connect(die)


func die() -> void:
	queue_free()


func _process(delta: float) -> void:
	super._process(delta)
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node3D
	if target != null and ready_to_fire():
		launch_missile()
