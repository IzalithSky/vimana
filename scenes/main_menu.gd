class_name MainMenu extends Node2D


@export var world: PackedScene

@export var jet: PackedScene
@export var heli: PackedScene
@export var lvd: PackedScene

@onready var button_jet: Button = $CanvasLayer/HBoxContainer/VBoxContainer/ButtonJet
@onready var button_heli: Button = $CanvasLayer/HBoxContainer/VBoxContainer/ButtonHeli
@onready var button_lv_d: Button = $CanvasLayer/HBoxContainer/VBoxContainer/ButtonLvD
@onready var exit_button: Button = $CanvasLayer/HBoxContainer/VBoxContainer/ExitButton
@onready var host_button: Button = $CanvasLayer/HBoxContainer/VBoxContainer/HostButton
@onready var join_button: Button = $CanvasLayer/HBoxContainer/VBoxContainer/JoinButton
@onready var ip_input: LineEdit = $CanvasLayer/HBoxContainer/VBoxContainer/IPField


func _ready() -> void:
	button_jet.pressed.connect(func(): _start_game(jet))
	button_heli.pressed.connect(func(): _start_game(heli))
	button_lv_d.pressed.connect(func(): _start_game(lvd))
	exit_button.pressed.connect(func(): _exit_game())
	host_button.pressed.connect(func(): nm.host())
	join_button.pressed.connect(func(): nm.join(ip_input.text))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _start_game(vehicle_scene: PackedScene) -> void:
	var world_instance = world.instantiate()
	world_instance.vehicle_scene = vehicle_scene
	get_tree().root.add_child(world_instance)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = world_instance


func _exit_game() -> void:
	get_tree().quit()
