extends Node3D


@onready var heat_seeker: HeatSeeker = $HeatSeeker
@onready var heat_source: HeatSource = $HeatSource


func _physics_process(delta: float) -> void:
	var t: HeatSource = heat_seeker.get_best_target()
	if t != null:
		print(t.get_magnitude_at(heat_seeker))
	else:
		print("none")
	
