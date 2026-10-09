extends Label
@onready var timer: Timer = $Timer

var countdown: int = 10000000000000000
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = str(countdown)
	timer.start()
	timer.wait_time = 1
	timer.autostart = true 

func _on_timer_timeout() -> void:
	if countdown > 0:
		countdown -= 1
		text = str(countdown)
	else:
		Controller.reset_coin()
		get_tree().reload_current_scene()
