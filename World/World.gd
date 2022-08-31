extends Node2D

onready var player = $Player
var score = DEFAULT_SCORE
var fuel = DEFAULT_FUEL
var lives = DEFAULT_LIVES

enum PropType {Jerrycan, Banana, PoliceCar}

const PROPS_TEXTURES = {
	PropType.Jerrycan: preload("res://Props/Jerrycan.png"),
	PropType.PoliceCar: preload("res://Props/PoliceCar.png"),
	PropType.Banana: preload("res://Props/Banana.png"),
	}

const BONUS_PROPS = [PropType.Jerrycan]
const MALUS_PROPS = [PropType.Banana, PropType.PoliceCar]

const DEFAULT_VELOCITY = 80
var velocity = DEFAULT_VELOCITY
const X_MIN = 125
const X_MAX = 195

const DEFAULT_SCORE = 0
const DEFAULT_LIVES = 2
const DEFAULT_FUEL = 100

const LOW_FUEL_LIMIT = 25
const FUEL_STEP = 25

const VELOCITY_STEP = 10

const DEFAULT_SPAWN_PERIOD = 1.0
const DEFAULT_FUEL_PERIOD = 5.0
const DEFAULT_SCORE_PERIOD = .5

enum FuelFrame { AlertEmpty, Empty, Quarter, Half, ThreeQuarter, Full }

const MAX_PROPS_ONSCREEN = 3
var props = []
var props_to_spawn = 0

var rng = RandomNumberGenerator.new()
var spawn_timer = Timer.new()
var fuel_timer = Timer.new()
var score_timer = Timer.new()

var playing = false

func _start_pressed():
	playing = true
	_reset_state()

	$TitleScreen.visible = false
	$GameOverScreen.visible = false
	spawn_timer.start()
	fuel_timer.start()
	score_timer.start()

func _reset_state():
	props_to_spawn = 0
	_set_score(DEFAULT_SCORE)
	_set_fuel(DEFAULT_FUEL)
	_set_lives(DEFAULT_LIVES)
	velocity = DEFAULT_VELOCITY

func _ready():
	$TitleScreen.visible = true
	rng.randomize()

	var err = $TitleScreen/Menu/Button.connect("pressed", self, "_start_pressed")
	if err != OK:
		print ("Failed to connect start button")
	err = $GameOverScreen/Button.connect("pressed", self, "_start_pressed")
	if err != OK:
		print ("Failed to connect restart button")

	spawn_timer.set_wait_time(DEFAULT_SPAWN_PERIOD)
	spawn_timer.set_one_shot(false)
	spawn_timer.connect("timeout", self, "_add_prop_to_spawn")
	add_child(spawn_timer)

	fuel_timer.set_wait_time(DEFAULT_FUEL_PERIOD)
	fuel_timer.set_one_shot(false)
	fuel_timer.connect("timeout", self, "_decrease_fuel")
	add_child(fuel_timer)

	score_timer.set_wait_time(DEFAULT_SCORE_PERIOD)
	score_timer.set_one_shot(false)
	score_timer.connect("timeout", self, "_increase_score")
	score_timer.connect("timeout", self, "_empty_fuel_flicker")
	add_child(score_timer)

func _add_prop_to_spawn():
	props_to_spawn += 1

func _decrease_fuel():
	_set_fuel(fuel - FUEL_STEP)

func _increase_score():
	_set_score(score + 1)

func _empty_fuel_flicker():
	if fuel < LOW_FUEL_LIMIT:
		match $FuelGauge.frame:
			FuelFrame.Empty:
				$FuelGauge.frame = FuelFrame.AlertEmpty
			FuelFrame.AlertEmpty:
				$FuelGauge.frame = FuelFrame.Empty

func _spawn_prop():
	var prop = Prop.new()
	var prop_sprite = Sprite.new()
	var prop_collision_shape = CollisionShape2D.new()
	prop_collision_shape.shape = CircleShape2D.new()

	var prop_type = PropType.values()[rng.randi() % PropType.size()]
	prop_sprite.texture = PROPS_TEXTURES[prop_type]

	prop.type = prop_type
	prop.add_child(prop_sprite)
	prop.add_child(prop_collision_shape)

	var x = rng.randi_range(X_MIN, X_MAX)
	prop.position = Vector2(x, 0)

	add_child(prop)
	move_child(prop, player.get_index() - 1)
	prop.add_to_group("props")
	props.push_back(prop)
	props_to_spawn -= 1

func _remove_out_of_screen_props(delta):
	var removed_props = []
	for i in range(0, props.size()):
		props[i].global_position.y += velocity * delta
		if props[i].global_position.y > get_viewport_rect().size.y:
			remove_child(props[i])
			removed_props.push_back(i)
	for prop in removed_props:
		props.remove(prop)

func _handle_collision(collider):
	if collider.is_in_group("props"):
		if collider.type == PropType.Jerrycan:
			_set_fuel(fuel + FUEL_STEP)
		else:
			_set_lives(lives - 1)
			player.spin()
		remove_child(collider)

func _set_score(value):
	score = value
	$Score.text = "SCORE %s" % score
	if score > 0 && (score % 10 == 0):
		velocity += VELOCITY_STEP
		print(velocity)

func _set_lives(value):
	if value < 0:
		_game_over()
	else:
		lives = value
		$Lives.frame = lives

func _set_fuel(value):
	if value < 0:
		_game_over()
	else:
		fuel_timer.start()
		# if fuel is already full, do not update value
		if value <= DEFAULT_FUEL:
			fuel = value
			match fuel:
				100:
					$FuelGauge.frame = FuelFrame.Full
				75:
					$FuelGauge.frame = FuelFrame.ThreeQuarter
				50:
					$FuelGauge.frame = FuelFrame.Half
				25:
					$FuelGauge.frame = FuelFrame.Quarter
				_:
					$FuelGauge.frame = FuelFrame.Empty

func _game_over():
	playing = false
	$GameOverScreen.visible = true
	$GameOverScreen/Score.text = "SCORE %s" % score

func _process(delta):
	if playing:
		$ParallaxBackground.scroll_offset.y += velocity * delta

		if props_to_spawn > 0 && props_to_spawn < MAX_PROPS_ONSCREEN:
			_spawn_prop()

		_remove_out_of_screen_props(delta)

		var collision = player.move_and_collide(player.velocity * delta)
		if collision:
			_handle_collision(collision.collider)

		player.set_max_speed(velocity)

class Prop extends StaticBody2D:
	var type = PropType.Jerrycan
