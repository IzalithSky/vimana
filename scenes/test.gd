extends Node3D


@onready var radar_beam: RadarBeam = $radar/RadarBeam
@onready var ray: RayCast3D = $terrain/RayCast3D


func _physics_process(delta: float) -> void:
	var parts: Array[String] = []
	for echo in radar_beam.get_echoes():
		parts.append("[r:%d v:%d e:%.2f]" % [echo.range_bin, echo.radial_velocity_bin, echo.energy])
	print("Echoes: " + " ".join(parts))
	
	#ray.force_raycast_update()
	#if ray.is_colliding():
		#var hit_obj = ray.get_collider()
		#if hit_obj: 
			#print("Hit terrain:", hit_obj)
