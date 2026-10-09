extends Label
@onready var timer: Timer = $Timer

<<<<<<< HEAD
var countdown: int = 10000000000000000
=======
var countdown: int = 10
>>>>>>> de16230786e73f4f2e505dd396c854cb310e6694
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
