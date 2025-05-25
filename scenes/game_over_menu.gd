class_name NetworkManager
extends Node                      # Autoload singleton

@export var world_scene_path: String = "res://scenes/world_0.tscn"
@export var player_scene: PackedScene = preload("res://objects/vehicles/vimana_j/vimana_j.tscn")

var peer := ENetMultiplayerPeer.new()

func _ready() -> void:
	# hook signals once
	multiplayer.peer_connected.connect(_spawn_player)
	multiplayer.connected_to_server.connect(_on_connected)


# -------- public API ---------------------------------------------------------

func host(port: int = 7777) -> void:
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	_spawn_world()
	_spawn_player(multiplayer.get_unique_id())   # host’s own player


func join(ip: String, port: int = 7777) -> void:
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	# world will spawn via _on_connected() when the connection completes


# -------- callbacks ----------------------------------------------------------

func _on_connected() -> void:
	_spawn_world()   # client loads world; players arrive via peer_connected


func _spawn_player(id: int) -> void:
	if !multiplayer.is_server():
		return                              # only server instantiates players
	var container := get_tree().root.get_node("World/objects")
	if container == null:
		return                              # world not ready yet
	var p := player_scene.instantiate()
	p.set_multiplayer_authority(id)
	container.add_child(p)                  # MultiplayerSpawner replicates it


func _spawn_world() -> void:
	if world_scene_path != "" and !get_tree().root.has_node("World"):
		var world_scene := load(world_scene_path) as PackedScene
		var world := world_scene.instantiate()
		world.name = "World"
		get_tree().root.add_child(world)
