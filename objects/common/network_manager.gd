extends Node

@export var world_scene_path: String = "res://scenes/world_0.tscn"
@export var player_scene: PackedScene = preload("res://objects/vehicles/vimana_j/vimana_j.tscn")

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()


func _ready() -> void:
	multiplayer.peer_connected.connect(_spawn_player)
	multiplayer.connected_to_server.connect(_on_connected)


func host(port: int = 7777) -> void:
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	_spawn_world()
	_spawn_player(multiplayer.get_unique_id())


func join(ip: String, port: int = 7777) -> void:
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	_spawn_world()      # ← spawn world immediately on the client


func _on_connected() -> void:
	_spawn_world()


func _spawn_world() -> void:
	if world_scene_path != "" and !get_tree().root.has_node("World"):
		var world_scene: PackedScene = load(world_scene_path)
		var world: Node = world_scene.instantiate()
		world.name = "World"
		get_tree().root.add_child(world)

		var menu: Node = get_tree().current_scene
		if menu != null and menu != world:
			menu.queue_free()
			get_tree().current_scene = world


func _spawn_player(id: int) -> void:
	if !multiplayer.is_server():
		return
	var container: Node = get_tree().root.get_node("World/objects")
	if container == null:
		return
	var p: Node = player_scene.instantiate()
	p.set_multiplayer_authority(id)
	container.add_child(p)
