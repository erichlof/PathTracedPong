// scene/demo-specific variables go here
let ballRad = 5; // 5
let paddleRadX = 25; // 25
let paddleRadY = 15; // 15
let halfPaddleRadX = paddleRadX * 0.5;
let halfPaddleRadY = paddleRadY * 0.5;
let oldRotY = 0;
let newRotY = 0;
let oldRotX = 0;
let newRotX = 0;
let ballPos = new THREE.Vector3();
let ballDir = new THREE.Vector3();
let ballVel = new THREE.Vector3();
let computerPos2D = new THREE.Vector2();
let ballPos2D = new THREE.Vector2();
let targetDir2D = new THREE.Vector2();
let computerSpeed = 0;
let maxComputerSpeed = 0;
let initialBallSpeed = 0;
let ballSpeed = 0;
let halfRoomDimensions = new THREE.Vector3(100, 50, 200); // (100, 50, 200)
let paddle_Z = halfRoomDimensions.z - 100; 
let playerPos = new THREE.Vector3(0, 0, paddle_Z);
let computerPos = new THREE.Vector3(0, 0, -paddle_Z);
let newGameFlag = true;
let newVolleyFlag = false;
let playerMissed = false;
let computerMissed = false;
let gravityOn = true;
let playerScore = 0;
let computerScore = 0;
let numberOfPointsToWinGame = 5;
let playerWins = false;
let computerWins = false;
let missTimer = 0;
let cutSceneTimer = 0;
let cutSceneLengthInSeconds = 5;
let difficulty = 'Novice';
let saved_Z_Position = paddle_Z + 80;
let cutSceneIsPlaying = false;

let gravity_ToggleController, gravity_ToggleObject;
let needChangeGravityToggle = false;
let difficulty_SettingController, difficulty_SettingObject;
let needChangeDifficultySetting = false;

// WebAudio variables
let audioLoader;
let listener;
let highPingSound1;
let highPingSound2;
let lowPingSound1;
let lowPingSound2;
let ballMissedSound;
let winnerSound;
let losingSound;
let ballObj = new THREE.Object3D();
let playerObj = new THREE.Object3D();
let computerObj = new THREE.Object3D();


let playerScoreElement = document.getElementById('playerScore');
playerScoreElement.style.cursor = "default";
playerScoreElement.style.userSelect = "none";
playerScoreElement.style.MozUserSelect = "none";
let computerScoreElement = document.getElementById('computerScore');
computerScoreElement.style.cursor = "default";
computerScoreElement.style.userSelect = "none";
computerScoreElement.style.MozUserSelect = "none";
let infoBannerElement = document.getElementById('infoBanner');
infoBannerElement.style.cursor = "default";
infoBannerElement.style.userSelect = "none";
infoBannerElement.style.MozUserSelect = "none";

// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'Path_Traced_Pong_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	allowOrthographicCamera = false;
	
	sceneIsDynamic = true;

	pixelEdgeSharpness = 0.5;
	
	cameraFlightSpeed = 100;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 0.75;

	EPS_intersect = 0.001;

	useGenericInput = false;

	// the usual directional buttons for mobile are not needed on this game
	mobileShowButtons = false;

	// set camera's field of view
	worldCamera.fov = 50; // 50

	audioLoader = new THREE.AudioLoader();
	listener = new THREE.AudioListener();
	worldCamera.add(listener);

	audioLoader.load('sounds/highPing.mp3', function (buffer)
	{ 
		highPingSound1 = new THREE.PositionalAudio(listener);
		highPingSound1.setBuffer(buffer);
		highPingSound1.setVolume(2);
		ballObj.add(highPingSound1);
		highPingSound2 = new THREE.PositionalAudio(listener);
		highPingSound2.setBuffer(buffer);
		highPingSound2.setVolume(2);
		ballObj.add(highPingSound2); 
	});

	audioLoader.load('sounds/lowPing.mp3', function (buffer)
	{
		lowPingSound1 = new THREE.PositionalAudio(listener);
		lowPingSound1.setBuffer(buffer);
		lowPingSound1.setVolume(3);
		playerObj.add(lowPingSound1);
		lowPingSound2 = new THREE.PositionalAudio(listener);
		lowPingSound2.setBuffer(buffer);
		lowPingSound2.setVolume(3);
		computerObj.add(lowPingSound2);
	});

	audioLoader.load('sounds/ballMiss.mp3', function (buffer)
	{
		ballMissedSound = new THREE.PositionalAudio(listener);
		ballMissedSound.setBuffer(buffer);
		ballMissedSound.setVolume(0.2);
		worldCamera.add(ballMissedSound);
	});

	audioLoader.load('sounds/winner.mp3', function (buffer)
	{
		winnerSound = new THREE.PositionalAudio(listener);
		winnerSound.setBuffer(buffer);
		winnerSound.setVolume(0.05);
		worldCamera.add(winnerSound);
	});

	audioLoader.load('sounds/synthHit.mp3', function (buffer)
	{
		losingSound = new THREE.PositionalAudio(listener);
		losingSound.setBuffer(buffer);
		losingSound.setVolume(0.04);
		worldCamera.add(losingSound);
	});


	gravity_ToggleObject = {
		Gravity: false
	};

	difficulty_SettingObject = {
		Difficulty: 'Novice'
	};

	function handleGravityToggleChange()
	{
		needChangeGravityToggle = true;
	}

	function handleDifficultySettingChange()
	{
		needChangeDifficultySetting = true;
	}

	gravity_ToggleController = gui.add(gravity_ToggleObject, 'Gravity', false).onChange(handleGravityToggleChange);
	difficulty_SettingController = gui.add(difficulty_SettingObject, 'Difficulty', ['Novice', 'Advanced', 'PONG LORD']).onChange(handleDifficultySettingChange);

	// jumpstart the game settings and GUI menu 
	handleGravityToggleChange();
	handleDifficultySettingChange();

	// scene/demo-specific uniforms go here
	pathTracingUniforms.uHalfRoomDimensions = { value: halfRoomDimensions };
	pathTracingUniforms.uBallPos = { value: ballPos };
	pathTracingUniforms.uPlayerPos = { value: playerPos };
	pathTracingUniforms.uComputerPos = { value: computerPos };
	pathTracingUniforms.uPaddleRadX = { value: paddleRadX };
	pathTracingUniforms.uPaddleRadY = { value: paddleRadY };
	pathTracingUniforms.uCutSceneIsPlaying = { value: cutSceneIsPlaying };

} // end function initSceneData()




function startNewGame() 
{
	missTimer = 0;
	cutSceneTimer = 0;
	playerScore = 0;
	computerScore = 0;
	playerScoreElement.innerHTML = "Player: " + playerScore;
	computerScoreElement.innerHTML = "Computer: " + computerScore;
	cameraInfoElement.innerHTML = "";
	infoBannerElement.innerHTML = "";
	
	// position and orient camera
	cameraControlsObject.position.set(0, 0, saved_Z_Position);
	
	cameraControlsYawObject.rotation.set(0,0,0);
	cameraControlsPitchObject.rotation.set(0,0,0);
	
	pathTracingUniforms.uCutSceneIsPlaying.value = false;

	newVolleyFlag = true;
	newGameFlag = false;
	playerWins = false;
	computerWins = false;
} // end function startNewGame()


function startNewVolley() 
{
	missTimer = 0;
	ballSpeed = initialBallSpeed;
	ballPos.set(0, 0, 0);
	ballDir.set(Math.random() * 2.0 - 1.0, Math.random() * 2.0 - 1.0, -1).normalize();

	if (playerMissed)
	{
		computerScore += 1;
		computerScoreElement.innerHTML = "Computer: " + computerScore;
	}
	if (computerMissed)
	{
		playerScore += 1;
		playerScoreElement.innerHTML = "Player: " + playerScore;
	}
	
	if (playerScore >= numberOfPointsToWinGame)
	{
		playerWins = true;
		winnerSound.play();
		infoBannerElement.style.color = "rgb(26,179,255)";
		infoBannerElement.innerHTML = "Player WINS!"
		pathTracingUniforms.uCutSceneIsPlaying.value = true;
	}
	if (computerScore >= numberOfPointsToWinGame)
	{
		computerWins = true;
		losingSound.play();
		infoBannerElement.style.color = "rgb(179,26,255)";
		infoBannerElement.innerHTML = "Computer WINS!"
		pathTracingUniforms.uCutSceneIsPlaying.value = true;
	}

	playerMissed = false;
	computerMissed = false;
	newVolleyFlag = false;
} // end function startNewVolley() 


function updateComputerAI()
{
	computerPos2D.set(computerPos.x, computerPos.y);
	ballPos2D.set(ballPos.x, ballPos.y);
	targetDir2D.subVectors(ballPos2D, computerPos2D);
	computerSpeed = Math.min(targetDir2D.length(), maxComputerSpeed);

	computerPos.x += targetDir2D.x * computerSpeed * frameTime;
	computerPos.y += targetDir2D.y * computerSpeed * frameTime;
	computerPos.z = -paddle_Z; // clamp computer's Z position

	// clamp computer's position against room walls
	if (computerPos.x + paddleRadX > halfRoomDimensions.x)
		computerPos.x = halfRoomDimensions.x - paddleRadX;
	if (computerPos.x - paddleRadX < -halfRoomDimensions.x)
		computerPos.x = -halfRoomDimensions.x + paddleRadX;
	if (computerPos.y + paddleRadY > halfRoomDimensions.y)
		computerPos.y = halfRoomDimensions.y - paddleRadY;
	if (computerPos.y - paddleRadY < -halfRoomDimensions.y)
		computerPos.y = -halfRoomDimensions.y + paddleRadY;
} // end function updateComputerAI()


function updateGameState() 
{
	// first check if there is a winner - if so, do a simple winner cutscene animation	
	if (playerWins)
	{
		cutSceneTimer += 1.0 * frameTime;
		if (cutSceneTimer >= cutSceneLengthInSeconds)
		{
			newGameFlag = true;
		}
		
		cameraIsMoving = true;

		cameraControlsObject.position.x = playerPos.x + (Math.cos(cutSceneTimer) * (cutSceneLengthInSeconds - cutSceneTimer + 1) * 50); // 80
		cameraControlsObject.position.y = playerPos.y + 20;
		cameraControlsObject.position.z = playerPos.z - (Math.sin(cutSceneTimer) * (cutSceneLengthInSeconds - cutSceneTimer + 1) * 50); // 80

		worldCamera.lookAt(playerPos);
	}
	
	if (computerWins)
	{
		cutSceneTimer += 1.0 * frameTime;
		if (cutSceneTimer >= cutSceneLengthInSeconds)
		{
			newGameFlag = true;
		}

		cameraIsMoving = true;
		
		cameraControlsObject.position.x = computerPos.x + (Math.cos(cutSceneTimer) * (cutSceneLengthInSeconds - cutSceneTimer + 1) * 50); // 80
		cameraControlsObject.position.y = computerPos.y + 20;
		cameraControlsObject.position.z = computerPos.z - (Math.sin(cutSceneTimer) * (cutSceneLengthInSeconds - cutSceneTimer + 1) * 50); // 80

		worldCamera.lookAt(computerPos);
	}

	if (newGameFlag)
		startNewGame();
	if (newVolleyFlag)
		startNewVolley();

	// move ball
	if (cutSceneTimer == 0)
	{
		if (gravityOn)
			ballDir.y -= 0.5 * frameTime; // simulate constant acceleration due to gravity
		ballVel.copy(ballDir);
		ballVel.multiplyScalar(ballSpeed * frameTime);
		ballPos.add(ballVel);
	}
	
	
	// check player-ball collision
	if (!playerMissed && ballPos.z + ballRad > playerPos.z)
	{
		if ( ballPos.x - ballRad < playerPos.x + paddleRadX && ballPos.x + ballRad > playerPos.x - paddleRadX &&
		     ballPos.y - ballRad < playerPos.y + paddleRadY && ballPos.y + ballRad > playerPos.y - paddleRadY )
		{
			if (!lowPingSound1.isPlaying)
				lowPingSound1.play();
			ballPos.z = playerPos.z - ballRad;
			ballDir.z *= -1;
			
			halfPaddleRadX = playerPos.x + (paddleRadX * 0.5);
			if (ballPos.x > playerPos.x)
			{
				ballDir.x += (ballPos.x - playerPos.x) / paddleRadX * 0.5;
				ballDir.x = Math.min(ballDir.x, 0.6);
			}
			halfPaddleRadX = playerPos.x - (paddleRadX * 0.5);     
			if (ballPos.x < playerPos.x)
			{
				ballDir.x += (ballPos.x - playerPos.x) / paddleRadX * 0.5;
				ballDir.x = Math.max(ballDir.x, -0.6);
			}
			halfPaddleRadY = playerPos.y + (paddleRadY * 0.5);    
			if (ballPos.y > playerPos.y)
			{
				ballDir.y += (ballPos.y - playerPos.y) / paddleRadY * 0.5;
				ballDir.y = Math.min(ballDir.y, 0.6);
			}
			halfPaddleRadY = playerPos.y - (paddleRadY * 0.5);      
			if (ballPos.y < playerPos.y)
			{
				ballDir.y += (ballPos.y - playerPos.y) / paddleRadY * 0.5;
				ballDir.y = Math.max(ballDir.y, -0.6);
			}
				
			ballDir.normalize();
			ballSpeed *= 1.015; // slightly increase ball speed
		}
		else
		{
			ballMissedSound.play();
			playerMissed = true;
		}
			
	}

	// check A.I.-ball collision
	if (!computerMissed && ballPos.z - ballRad < computerPos.z)
	{
		if (ballPos.x - ballRad < computerPos.x + paddleRadX && ballPos.x + ballRad > computerPos.x - paddleRadX &&
			ballPos.y - ballRad < computerPos.y + paddleRadY && ballPos.y + ballRad > computerPos.y - paddleRadY)
		{
			if (!lowPingSound2.isPlaying)
				lowPingSound2.play();
			ballPos.z = computerPos.z + ballRad;
			ballDir.z *= -1;
			ballSpeed *= 1.015; // slightly increase ball speed
		}
		else
		{
			ballMissedSound.play();
			computerMissed = true;
		}
			
	}

	// check ball-room walls collision
	if (ballPos.x + ballRad > halfRoomDimensions.x) 
	{
		ballPos.x = halfRoomDimensions.x - ballRad;
		ballDir.x *= -1;
		if (!playerMissed && !computerMissed)
		{
			if (!highPingSound1.isPlaying)
				highPingSound1.play();
			else highPingSound2.play();
		}
	}
	if (ballPos.x - ballRad < -halfRoomDimensions.x)
	{
		ballPos.x = -halfRoomDimensions.x + ballRad;
		ballDir.x *= -1;
		if (!playerMissed && !computerMissed)
		{
			if (!highPingSound1.isPlaying)
				highPingSound1.play();
			else highPingSound2.play();
		}
	}
	if (ballPos.y + ballRad > halfRoomDimensions.y)
	{
		ballPos.y = halfRoomDimensions.y - ballRad;
		ballDir.y *= -1;
		if (!playerMissed && !computerMissed)
		{
			if (!highPingSound1.isPlaying)
				highPingSound1.play();
			else highPingSound2.play();
		}
	}
	if (ballPos.y - ballRad < -halfRoomDimensions.y)
	{
		ballPos.y = -halfRoomDimensions.y + ballRad;
		ballDir.y *= -1;
		if (!playerMissed && !computerMissed)
		{
			if (!highPingSound1.isPlaying)
				highPingSound1.play();
			else highPingSound2.play();
		}
	}
	if (ballPos.z > halfRoomDimensions.z)
	{
		missTimer += 1.1 * frameTime;
		if (missTimer >= 3)
			newVolleyFlag = true;
	}
	if (ballPos.z < -halfRoomDimensions.z)
	{
		missTimer += 1.1 * frameTime;
		if (missTimer >= 3)
			newVolleyFlag = true;
	}

} // end function updateGameState()


function updateInputAndCamera()
{
	// disable horizontal pinch FOV changing on mobile
	increaseFOV = decreaseFOV = false;
	// disable vertical pinch aperture size changing on mobile
	increaseAperture = decreaseAperture = false;

	// slightly add to the player movement speed on mobile
	if (!mouseControl)
	{
		if (newDeltaX)
			cameraControlsYawObject.rotation.y += (mobileControlsMoveX) * 0.001;
		if (newDeltaY)
			cameraControlsPitchObject.rotation.x += (mobileControlsMoveY) * 0.001;
	}

	newRotY = -100 * cameraControlsYawObject.rotation.y;
	newRotX = 100 * cameraControlsPitchObject.rotation.x;

	if (cutSceneTimer == 0)
		playerPos.set(newRotY, newRotX, paddle_Z);

	if (playerPos.x + paddleRadX > halfRoomDimensions.x)
	{
		playerPos.x = halfRoomDimensions.x - paddleRadX;
		cameraControlsYawObject.rotation.y = oldRotY;
	}
	if (playerPos.x - paddleRadX < -halfRoomDimensions.x)
	{
		playerPos.x = -halfRoomDimensions.x + paddleRadX;
		cameraControlsYawObject.rotation.y = oldRotY;
	}
	if (playerPos.y + paddleRadY > halfRoomDimensions.y)
	{
		playerPos.y = halfRoomDimensions.y - paddleRadY;
		cameraControlsPitchObject.rotation.x = oldRotX;
	}
	if (playerPos.y - paddleRadY < -halfRoomDimensions.y)
	{
		playerPos.y = -halfRoomDimensions.y + paddleRadY;
		cameraControlsPitchObject.rotation.x = oldRotX;
	}
	// save oldRot for next frame
	oldRotY = cameraControlsYawObject.rotation.y;
	oldRotX = cameraControlsPitchObject.rotation.x;

	worldCamera.lookAt(playerPos);

	if (dollyCameraOut)
	{
		cameraControlsObject.position.z += 2;
		if (cameraControlsObject.position.z > paddle_Z + 120)
			cameraControlsObject.position.z = paddle_Z + 120;

		// save z position for next game
		saved_Z_Position = cameraControlsObject.position.z;

		cameraIsMoving = true;
		dollyCameraOut = false;
	}
	if (dollyCameraIn)
	{
		cameraControlsObject.position.z -= 2;
		if (cameraControlsObject.position.z < paddle_Z + 50)
			cameraControlsObject.position.z = paddle_Z + 50;

		// save z position for next game
		saved_Z_Position = cameraControlsObject.position.z;

		cameraIsMoving = true;
		dollyCameraIn = false;
	}
} // end function updateInputAndCamera()


// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{
	if (needChangeGravityToggle)
	{
		gravityOn = gravity_ToggleController.getValue();

		if (gravityOn)
		{
			if (difficulty == 'Novice')
				maxComputerSpeed = 4;
			else if (difficulty == 'Advanced')
				maxComputerSpeed = 6;
			else if (difficulty == 'PONG LORD')
				maxComputerSpeed = 7.5;
		}
		else if (!gravityOn)
		{
			if (difficulty == 'Novice')
				maxComputerSpeed = 3.5;
			else if (difficulty == 'Advanced')
				maxComputerSpeed = 5.5;
			else if (difficulty == 'PONG LORD')
				maxComputerSpeed = 7;
		}

		needChangeGravityToggle = false;
	}

	if (needChangeDifficultySetting)
	{
		difficulty = difficulty_SettingController.getValue();

		if (difficulty == 'Novice')
		{
			maxComputerSpeed = gravityOn ? 4 : 3.5;
			initialBallSpeed = 110;
			ballSpeed = initialBallSpeed;
		}
		else if (difficulty == 'Advanced')
		{
			maxComputerSpeed = gravityOn ? 6 : 5.5;
			initialBallSpeed = 150;
			ballSpeed = initialBallSpeed;
		}
		else if (difficulty == 'PONG LORD')
		{
			maxComputerSpeed = gravityOn ? 7.5 : 7;
			initialBallSpeed = 200;
			ballSpeed = initialBallSpeed;
		}

		needChangeDifficultySetting = false;
	}

	// INPUT and CAMERA
	if (cutSceneTimer == 0) // only if not during a 'winner' cutscene
		updateInputAndCamera();
	
	// GAME STATE
	updateGameState();

	if (cutSceneTimer == 0) // only if not during a 'winner' cutscene
	{
		// if ball is still in play
		// do simple A.I. and update computer's position
		if (ballPos.z < halfRoomDimensions.z && ballPos.z > -halfRoomDimensions.z)
			updateComputerAI();

		// BALL
		pathTracingUniforms.uBallPos.value.copy(ballPos);

		// PLAYER
		pathTracingUniforms.uPlayerPos.value.copy(playerPos);

		// A.I.
		pathTracingUniforms.uComputerPos.value.copy(computerPos);
	}
	
	// update Positional Sound sources
	ballObj.position.copy(ballPos);
	playerObj.position.copy(playerPos);
	computerObj.position.copy(computerPos);
	
	// DEBUG INFO
	//cameraInfoElement.innerHTML = "maxComputerSpeed: " + maxComputerSpeed.toFixed(1);

} // end function updateVariablesAndUniforms()


// begin Web Audio user-interaction requirement for MacOS & iOS
const startButton = document.getElementById('startButton');
startButton.addEventListener('click', beginInit);

function beginInit()
{
	const overlay = document.getElementById('overlay');
	overlay.remove();
	init(); // init app and start animating
}
// end Web Audio user-interaction requirement for MacOS & iOS
