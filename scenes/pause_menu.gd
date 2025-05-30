class_name PauseMenu extends Control

@export var main_menu_scene_path: String = "res://scenes/main_menu.tscn"

@onready var main_menu_button: Button = $HBoxContainer/VBoxContainer/MainMenuButton
@onready var exit_button: Button = $HBoxContainer/VBoxContainer/ExitButton


func _ready() -> void:
	visible = false
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()


func toggle_pause() -> void:
	if get_tree().paused:
		visible = false
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		visible = true
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene_path)


func _on_exit_pressed() -> void:
	get_tree().quit()
