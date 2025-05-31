class_name GameScene extends Node3D


@export var scenes_to_warm_up: Array[PackedScene]

@onready var loading_box: VBoxContainer = $ui/CanvasLayer/VBoxContainer
@onready var progress_bar: ProgressBar = $ui/CanvasLayer/VBoxContainer/ProgressBar


func _ready() -> void:
	_start_warmup()


func _start_warmup() -> void:
	get_tree().paused = true
	await get_tree().create_timer(1.0).timeout
	
	var total: int = scenes_to_warm_up.size()
	var i: int = 0
	
	for packed_scene: PackedScene in scenes_to_warm_up:
		var instance: Node3D = packed_scene.instantiate()
		add_child(instance)
		for _frame in 3:
			await get_tree().process_frame
		instance.visible = false
		i += 1
		progress_bar.value = float(i) / float(total) * 100.0
		await get_tree().process_frame
	
	loading_box.visible = false
	get_tree().paused = false
