extends Node3D


@onready var ray: RayCast3D = $terrain/RayCast3D
@onready var radar_beam: RadarBeam = %RadarBeam


#func _physics_process(delta: float) -> void:
	#var parts: Array[String] = []
	#for echo in radar_beam.get_echoes():
		#parts.append("[r:%d v:%d e:%.2f]" % [echo.range_bin, echo.radial_velocity_bin, echo.energy])
	#print("Echoes: " + " ".join(parts))
	
	#ray.force_raycast_update()
	#if ray.is_colliding():
		#var hit_obj = ray.get_collider()
		#if hit_obj: 
			#print("Hit terrain:", hit_obj)
	
	#print(radar_beam.get_targets())
	
	#var e: RadarEcho = RadarEcho.new()
	#e.radial_velocity_bin = 0
	#e.range_bin = 1
	#print(radar_beam.get_target_for_echo(e))
