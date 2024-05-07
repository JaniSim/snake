extends Node2D

# Constants
const CELL_SIZE : int = 50
const START_POS = Vector2(5, 5)
const UP = Vector2(0, -1)
const DOWN = Vector2(0, 1)
const LEFT = Vector2(-1, 0)
const RIGHT = Vector2(1, 0)

# Constants for opposite directions and user actions
const DIRECTION_MAP = {
	"move_down": DOWN,
	"move_up": UP,
	"move_right": RIGHT,
	"move_left": LEFT
}

const OPPOSITE_DIRECTIONS = {
	UP: DOWN,
	DOWN: UP,
	LEFT: RIGHT,
	RIGHT: LEFT
}

# Exported Variables
@export var snake_scene : PackedScene

# Private Variables
var _score : int
var _gameStarted : bool = false
var _cells : int = 20
var _foodPos : Vector2
var _regenFood : bool = true
var _oldData : Array
var _snakeData : Array
var _snake : Array
var _moveDir : Vector2
var _canMove : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_startNewGame()

# Starts a new game
func _startNewGame() -> void:
	_setInitialGameSettings()
	_createNewSnake()
	_moveFood()

# Sets initial game settings
func _setInitialGameSettings() -> void:
	get_tree().paused = false
	$GameOver.hide()
	_clearParts()
	_score = 0 
	_updateScoreDisplay()
	_canMove = true

# Clears snake parts
func _clearParts() -> void:
	get_tree().call_group("parts", "queue_free")

# Updates score display
func _updateScoreDisplay() -> void:
	$CanvasLayer.get_node("Score").text = "SCORE: " + str(_score)

# Creates a new snake
func _createNewSnake() -> void:
	_clearSnakeData()
	for i in range(3):
		_addPart(START_POS + Vector2(0, i))

# Clears snake data
func _clearSnakeData() -> void:
	_oldData.clear()
	_snakeData.clear()
	_snake.clear()

# Adds a part to the snake
func _addPart(pos: Vector2) -> void:
	_snakeData.append(pos)
	var snakePart = _createSnakePart(pos)
	_snake.append(snakePart)

# Creates a snake part
func _createSnakePart(pos: Vector2) -> Panel:
	var snakePart = snake_scene.instantiate()
	snakePart.position = (pos * CELL_SIZE) + Vector2(0, CELL_SIZE)
	add_child(snakePart)
	return snakePart

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_moveSnake()

# Moves the snake
func _moveSnake() -> void:
	if _canMove:
		_handleUserInput()

# Handles user input
func _handleUserInput() -> void:
	for action in DIRECTION_MAP.keys():
		if Input.is_action_just_pressed(action) and _moveDir != OPPOSITE_DIRECTIONS[DIRECTION_MAP[action]]:
			_setMoveDirection(DIRECTION_MAP[action])
			break

# Sets move direction
func _setMoveDirection(direction: Vector2) -> void:
	_moveDir = direction
	_canMove = false
	if not _gameStarted:
		_startGame()

# Starts the game
func _startGame() -> void:
	_gameStarted = true
	$Timer.start()

func _on_timer_timeout() -> void:
	_canMove = true
	_updateSnakeData()
	_checkGameConditions()

# Updates snake data
func _updateSnakeData() -> void:
	_oldData = [] + _snakeData
	_snakeData[0] += _moveDir
	for i in range(len(_snakeData)):
		_updateSnakePartData(i)

# Updates snake part data
func _updateSnakePartData(i: int) -> void:
	if i > 0:
		_snakeData[i] = _oldData[i-1]
	_snake[i].position = (_snakeData[i] * CELL_SIZE) + Vector2(0, CELL_SIZE)

# Checks game conditions
func _checkGameConditions() -> void:
	_checkBoundaries()
	_checkSelf()
	_checkFood()

func _checkBoundaries() -> void:
	if _snakeData[0].x < 0 or _snakeData[0].x > _cells - 1 or _snakeData[0].y < 0 or _snakeData[0].y > _cells - 1:
		_endGame()

func _checkSelf() -> void:
	for i in range(1, len(_snakeData)):
		if _snakeData[0] == _snakeData[i]:
			_endGame()

func _checkFood() -> void:
	if _snakeData[0] == _foodPos:
		_score += 1
		_updateScoreDisplay()
		_addPart(_oldData[-1])
		_moveFood()

func _moveFood() -> void:
	while _regenFood:
		_regenFood = false
		_generateFoodPosition()
	$Food.position = (_foodPos * CELL_SIZE) + Vector2(0, CELL_SIZE)
	_regenFood = true

# Generates food position
func _generateFoodPosition() -> void:
	_foodPos = Vector2(randi_range(0, _cells - 1), randi_range(0, _cells - 1))
	for i in _snakeData:
		if _foodPos == i:
			_regenFood = true

# Ends the game
func _endGame() -> void:
	$GameOver.show()
	$Timer.stop()
	_gameStarted = false
	get_tree().paused = true

func _on_game_over_restart() -> void:
	_startNewGame()
