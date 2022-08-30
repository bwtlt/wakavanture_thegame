extends Node2D

onready var title_screen = $TitleScreen
onready var start_button = $TitleScreen/Menu/Button
onready var background = $ParallaxBackground
onready var background_layer = $ParallaxBackground/ParallaxLayer
onready var player = $Player
onready var score_label = $Score
var score = 0

enum PropType {Jerrycan, Banana, PoliceCar}

const PROPS_TEXTURES = {
	PropType.Jerrycan: preload("res://Props/Jerrycan.png"),
	PropType.PoliceCar: preload("res://Props/PoliceCar.png"),
	PropType.Banana: preload("res://Props/Banana.png"),
	}
	
const BONUS_PROPS = [PropType.Jerrycan]
const MALUS_PROPS = [PropType.Banana, PropType.PoliceCar]

var VELOCITY = 100
const X_MIN = 125
const X_MAX = 195

var props = []
var props_to_spawn = 0

var fuel = 1.0

var rng = RandomNumberGenerator.new()
var spawn_timer = Timer.new()
var fuel_timer = Timer.new()

var playing = false

func _start_pressed():
	playing = true
	title_screen.visible = false
	spawn_timer.start()
	fuel_timer.start()
	
	fuel = 4

func _ready():
	rng.randomize()
	
	start_button.connect("pressed", self, "_start_pressed")
	
	spawn_timer.set_wait_time(1.0)
	spawn_timer.set_one_shot(false)
	spawn_timer.connect("timeout", self, "_add_prop_to_spawn")
	add_child(spawn_timer)
	
	fuel_timer.set_wait_time(5.0)
	fuel_timer.set_one_shot(false)
	fuel_timer.connect("timeout", self, "_decrease_fuel")
	add_child(fuel_timer)

func _add_prop_to_spawn():
	props_to_spawn += 1
	
func _decrease_fuel():
	fuel -= 1

func _spawn_prop():
	var prop = Prop.new()
	var prop_sprite = Sprite.new()
	var prop_collision_shape = CollisionShape2D.new()
	prop_collision_shape.shape = CircleShape2D.new()

	var prop_type = PropType.values()[rng.randi() % PropType.size()]
	prop_sprite.texture = PROPS_TEXTURES[prop_type]
	if BONUS_PROPS.has(prop_type):
		prop.bonus = true

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
		props[i].global_position.y += VELOCITY * delta
		if props[i].global_position.y > get_viewport_rect().size.y:
			remove_child(props[i])
			removed_props.push_back(i)
	for prop in removed_props:
		props.remove(prop)

func _handle_collision(collider):
	if collider.is_in_group("props"):
		if collider.type == PropType.Jerrycan && fuel < 4:
			fuel += 1
		if collider.bonus:
			score += 1
		else:
			score -= 1
			player.spin()
		remove_child(collider)
		score_label.text = "SCORE %s" % score

func _process(delta):
	if playing:
		if fuel >= 0:
			$FuelGauge.frame = fuel
		
		background.scroll_offset.y += VELOCITY * delta

		if props_to_spawn > 0 && props_to_spawn < 3:
			_spawn_prop()

		_remove_out_of_screen_props(delta)
			
		var collision = player.move_and_collide(player.velocity * delta)
		if collision:
			_handle_collision(collision.collider)
		
		if score >= 10:
			VELOCITY = 120

class Prop extends StaticBody2D:
	var bonus = false
	var type = PropType.Jerrycan
