class_name Player extends Node


@export var game_over_menu_scene: PackedScene

@onready var health: Health = get_parent().get_node("Health")


func _ready() -> void:
	health.died.connect(_on_player_died)


func _on_player_died() -> void:
	if game_over_menu_scene:
		var game_over_instance := game_over_menu_scene.instantiate()
		get_tree().root.add_child(game_over_instance)
		get_tree().current_scene.queue_free()
		get_tree().current_scene = game_over_instance
