extends ParallaxBackground

const VELOCITY = 100

func _process(delta):
	scroll_offset.y += VELOCITY * delta
