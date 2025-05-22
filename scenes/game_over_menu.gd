class_name GameOverMenu extends Node2D


@export var main_menu_scene: PackedScene

@onready var main_menu_button: Button = $CanvasLayer/HBoxContainer/VBoxContainer/MainMenuButton
@onready var exit_button: Button = $CanvasLayer/HBoxContainer/VBoxContainer/ExitButton


func _ready() -> void:
	main_menu_button.pressed.connect(func(): _return_to_main_menu())
	exit_button.pressed.connect(func(): _exit_game())
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _return_to_main_menu() -> void:
	if main_menu_scene:
		var menu = main_menu_scene.instantiate()
		get_tree().root.add_child(menu)
		get_tree().current_scene.queue_free()
		get_tree().current_scene = menu

func _exit_game() -> void:
	get_tree().quit()
