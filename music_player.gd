extends AudioStreamPlayer

# Replace these 3 paths with your actual song file paths!
const Start_Menu_Song = preload("res://assets/Z-Beam start-screen.wav")
const Building_Song = preload("res://assets/Z-beam building.wav")
const Attack_Song = preload("res://assets/Z-beam Zombie Attack.wav")

func play_menu() -> void:
	_change_song(Start_Menu_Song)

func play_build() -> void:
	_change_song(Building_Song)

func play_go() -> void:
	_change_song(Attack_Song)

func _change_song(song: AudioStream) -> void:
	# If this exact song is already playing, don't restart it
	if stream == song and playing:
		return
	stream = song
	play()
