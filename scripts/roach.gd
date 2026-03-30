extends CharacterBody2D

enum ReachState { walk, dead }
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var wal_detector: RayCast2D = $WalDetector
@onready var ground_detector: RayCast2D = $GroundDetector

var direction = 1

const SPEED = 30
const JUMP_VELOCITY = -400

var status: ReachState

func _ready() -> void:
	go_to_walk_state()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match status:
		ReachState.walk: walk_state(delta)
		ReachState.dead: dead_state(delta)

	move_and_slide()
	
func go_to_walk_state():
	status = ReachState.walk
	anim.play("running")

#func go_to_dead_state():
	#status = BearState.dead
	#anim.play("hurt")
	#hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	
func walk_state(_delta):
	velocity.x = SPEED * direction
	
	if wal_detector.is_colliding():
		scale.x *= -1
		direction *= -1
	
	if not ground_detector.is_colliding():
		scale.x *= -1
		direction *= -1
		
func take_damage():
	if status == ReachState.dead: return
	go_to_dead_state()

func go_to_dead_state():
	if status == ReachState.dead: return
	status = ReachState.dead
	anim.play("hurt")
	velocity = Vector2.ZERO 
	$Hitbox.set_deferred("monitoring", false)
	$Hitbox.set_deferred("monitorable", false)
	set_collision_layer_value(4, false)
	await get_tree().create_timer(1.5).timeout
	queue_free()

	
func dead_state(_delta):
	pass
	
