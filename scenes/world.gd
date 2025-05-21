class_name GameScene extends Node3D


@onready var spawn: Node3D = $objects/Spawn
@onready var objects: Node3D = $objects

var vehicle_scene: PackedScene


func _ready() -> void:
	if vehicle_scene:
		var vehicle = vehicle_scene.instantiate()
		vehicle.global_transform = spawn.global_transform
		vehicle.add_to_group("player")
		objects.add_child(vehicle)
