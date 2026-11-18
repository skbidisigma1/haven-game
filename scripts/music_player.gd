extends Node

const MENU = preload("res://assets/menu.wav")
const BUILD = preload("res://assets/planning.wav")
const VICTORY = preload("res://assets/victory.wav")
const ATTACK = preload("res://assets/firing.wav")
var players: Array[AudioStreamPlayer] = []
var current: AudioStream
var fade: Tween
var active := 0

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(_on_close_requested)
	for track in [MENU, BUILD, ATTACK]:
		track.loop_begin = 0
		track.loop_end = int(track.get_length() * track.mix_rate)
		track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.volume_db = -60
		add_child(player)
		players.append(player)

func play_menu() -> void: _change_song(MENU)
func play_build() -> void: _change_song(BUILD)
func play_go() -> void: _change_song(ATTACK)

func play_victory() -> void:
	_change_song(VICTORY)

func _change_song(song: AudioStream) -> void:
	if current == song: return
	current = song
	if fade: fade.kill()
	var old := players[active]
	active = 1 - active
	var next := players[active]
	next.stream = song
	next.volume_db = -60
	next.play()
	fade = create_tween().set_parallel(true)
	fade.tween_property(old, "volume_db", -60.0, 0.65)
	fade.tween_property(next, "volume_db", -16.0, 0.8)
	fade.chain().tween_callback(old.stop)

func stop_music() -> void:
	if fade: fade.kill()
	current = null
	for player in players:
		player.stop()
		player.stream = null

func _exit_tree() -> void:
	stop_music()

func _on_close_requested() -> void:
	stop_music()
	# Give the audio thread one buffer to release its looping playback.
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
