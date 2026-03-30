extends CharacterBody2D

enum PlayerState { idle, walk, jump, fall, duck, slide, dead}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var max_speed = 180
@export var acceleration = 200
@export var deceleration = 200
@export var slide_decelaration = 100

const JUMP_VELOCITY = -300.0

var direction = 0
var status: PlayerState
var count_jumps: int = 0 #contador para o pulo duplo
const MAX_JUMPS = 2 #limite de pulos

#CollisionShape2d
func set_small_collider():
	collision_shape_2d.shape.radius = 5
	collision_shape_2d.shape.height = 10
	collision_shape_2d.position.y = 3

func set_large_collider():
	collision_shape_2d.shape.radius = 6
	collision_shape_2d.shape.height = 16
	collision_shape_2d.position.y = 0

#var normal_height = 16
#var normal_radius = 6
#var normal_pos_y = 0
#
#var duck_height = 10
#var duck_radius = 5
#var duck_pos_y = 3

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		count_jumps = 0 #reseta o contador ao tocar o chão

	match status:
		PlayerState.idle: idle_state(delta)
		PlayerState.walk: walk_state(delta)
		PlayerState.jump: jump_state(delta)   
		PlayerState.duck: duck_state(delta)
		PlayerState.fall: fall_state(delta)
		PlayerState.slide: slide_state(delta)
		PlayerState.dead: dead_state(delta)

	move_and_slide()

#States
func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")

func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")

func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	perform_jump()

func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")
	
func go_to_duck_state():
	status = PlayerState.duck
	anim.play("duck")
	set_small_collider()
	#var shape = collision_shape_2d.shape as CapsuleShape2D
	#if shape:
		#shape.radius = duck_radius
		#shape.height = duck_height

func exit_from_duck_state():
	set_large_collider()
	#var shape = collision_shape_2d.shape as CapsuleShape2D
	#if shape:
		#shape.radius = normal_radius
		#shape.height = normal_height

func go_to_slide_state():
	status = PlayerState.slide
	anim.play("slide")
	set_small_collider()

func exit_slide_state():
	set_large_collider()

#func go_to_dead_state():
	#status = PlayerState.dead
	#anim.play("dead")
	#velocity = Vector2.ZERO

func perform_jump():
	velocity.y = JUMP_VELOCITY
	count_jumps += 1

func idle_state(delta):
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
	elif Input.is_action_just_pressed("jump"):
		go_to_jump_state()
	elif Input.is_action_pressed("duck"):
		go_to_duck_state()

func walk_state(delta):
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
	elif Input.is_action_just_pressed("jump"):
		go_to_jump_state()
	elif !is_on_floor():
		count_jumps += 1
		go_to_fall_state()
	elif Input.is_action_just_pressed("duck"):
		go_to_slide_state()

func jump_state(delta):
	move(delta)
	
	#Pulo Duplo
	if Input.is_action_just_pressed("jump") and can_jump():
		perform_jump()
	
	if velocity.y > 0:
		go_to_fall_state()
		return

func fall_state(delta):
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return

	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
	return

func can_jump() -> bool:
	return count_jumps < MAX_JUMPS

func duck_state(_delta):
	update_direction()
	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()
	return

func slide_state(delta):
	velocity.x = move_toward(velocity.x, 0, slide_decelaration * delta)
	
	if Input.is_action_just_pressed("duck"):
		exit_from_duck_state()
		go_to_walk_state()
	elif velocity.x == 0:
		exit_slide_state()
		go_to_duck_state()

func _on_hitbox_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	
	if enemy.has_method("take_damage"):
		
		var is_falling = velocity.y > 0
		var is_above = global_position.y < (enemy.global_position.y - 10)

		if is_falling or is_above:
			enemy.take_damage()

			velocity.y = JUMP_VELOCITY * 0.7 
			go_to_jump_state()
			print("Inimigo derrotado!")
			return

	if status != PlayerState.dead:
		print("Player atingido lateralmente!")
		go_to_dead_state()

	if status != PlayerState.dead:
		go_to_dead_state()

func dead_state(_delta):
	pass

func move(delta):
	update_direction()
	
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x,  0, deceleration * delta)

func update_direction():
	direction = Input.get_axis("left","right")
	# Orientação do Sprite
	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false

func go_to_dead_state():
	if status == PlayerState.dead: return
	status = PlayerState.dead
	anim.play("dead") # Use aquele sprite da barata que gerei se quiser!
	velocity = Vector2.ZERO
	
	# Bloqueia colisões para não morrer "duas vezes"
	collision_shape_2d.set_deferred("disabled", true)
	
	# Timer para reiniciar a fase
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()

func _on_killzone_body_entered(body: Node2D) -> void:
	if body.has_method("go_to_dead_state"):
		print("Player caiu no void/água!")
		body.go_to_dead_state()
