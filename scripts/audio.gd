extends Node
# Procedural SFX manager — fire audio for every game event

var muted := false
var _players := {}
var _streams := {}

func _ready() -> void:
	var names := ["click", "cash", "buy", "heat", "drift", "achievement", "power", "meet_win"]
	for n in names:
		var path := "res://assets/audio/%s.wav" % n
		if ResourceLoader.exists(path):
			_streams[n] = load(path)
	# pool of players (avoid overlap cutoff)
	for i in range(8):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players[i] = {"player": p, "busy": false}

func play(name: String, vol := 0.0) -> void:
	if muted or not _streams.has(name):
		return
	# find free player
	for i in _players:
		var e: Dictionary = _players[i]
		var p: AudioStreamPlayer = e["player"]
		if not p.playing:
			p.stream = _streams[name]
			p.volume_db = vol
			p.play()
			return
	# all busy — steal first
	var p0: AudioStreamPlayer = _players[0]["player"]
	p0.stream = _streams[name]
	p0.volume_db = vol
	p0.play()

func toggle_mute() -> bool:
	muted = not muted
	return muted
