class_name Explosion extends Node3D

@export_range(0.0, 1.0) var pitch_variation_percent: float = 0.2

@onready var sparks: GPUParticles3D = $Sparks
@onready var smoke: GPUParticles3D = $Smoke
@onready var fire: GPUParticles3D = $Fire
@onready var explosion_sound: AudioStreamPlayer3D = $ExplosionSound

func _ready() -> void:
	sparks.emitting = true
	smoke.emitting = true
	fire.emitting = true

	var variation: float = randf_range(-pitch_variation_percent, pitch_variation_percent)
	explosion_sound.pitch_scale = 1.0 + variation
	explosion_sound.play()

	await get_tree().create_timer(2.0).timeout
	queue_free()
