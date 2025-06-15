class_name Player extends Node


@export var game_over_menu_scene_path: String = "res://scenes/main_menu.tscn"

@onready var health: Health = get_parent().get_node("Health")


func _ready() -> void:
	health.died.connect(_on_player_died)
	get_parent().add_to_group("player")
	get_parent().add_to_group("alpha")
	get_parent().add_to_group("anchors")


func _on_player_died(cause: Health.DeathCause) -> void:
	if cause == Health.DeathCause.COLLISION:
		if game_over_menu_scene_path:
			var scene: PackedScene = load(game_over_menu_scene_path)
			var game_over_instance: Node = scene.instantiate()
			get_tree().root.add_child(game_over_instance)
			get_tree().current_scene.queue_free()
			get_tree().current_scene = game_over_instance
