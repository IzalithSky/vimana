class_name MainMenu extends Node2D


@export var world: PackedScene

@export var jet: PackedScene
@export var heli: PackedScene
@export var lvd: PackedScene
@export var rigScene: PackedScene

@onready var button_jet: Button = $CanvasLayer/HBoxContainer/VBoxContainer/ButtonJet
@onready var button_heli: Button = $CanvasLayer/HBoxContainer/VBoxContainer/ButtonHeli
@onready var button_lv_d: Button = $CanvasLayer/HBoxContainer/VBoxContainer/ButtonLvD
@onready var exit_button: Button = $CanvasLayer/HBoxContainer/VBoxContainer/ExitButton


func _ready() -> void:
	button_jet.pressed.connect(func(): _start_game(jet))
	button_heli.pressed.connect(func(): _start_game(heli))
	button_lv_d.pressed.connect(func(): _start_game(lvd))
	exit_button.pressed.connect(func(): _exit_game())
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _start_game(vehicle_scene: PackedScene) -> void:
	var vehicle_root: Vimana = vehicle_scene.instantiate()
	
	var rig: PlayerControls = rigScene.instantiate()
	vehicle_root.add_child(rig)
	vehicle_root.rig_path = vehicle_root.get_path_to(rig)
	
	var player: Player = Player.new()
	vehicle_root.add_child(player)
	
	var world_instance: Node = world.instantiate()
	world_instance.add_child(vehicle_root)
	
	var old_scene: Node = get_tree().current_scene
	get_tree().root.add_child(world_instance)
	get_tree().current_scene = world_instance
	old_scene.queue_free()


func _exit_game() -> void:
	get_tree().quit()
