/// @description 

// functions
function setOnGround(_val = true) {
	if _val == true {
		onGround = _val
		hangTimer = hangFrames
	} else {
		onGround = _val
		hangTimer = 0
	}
}

// controls setup
controlsSetup()

// sprite setup
maskSpr = sPlayerIdle
idleSpr = sPlayerIdle
walkSpr = sPlayerWalk
runSpr = sPlayerRun
jumpSpr = sPlayerJump
crouchSpr = sPlayerCrouch


// Moving
face = 1
moveDir = 0
runType = 0
moveSpd = [2, 3.5]
xSpd = 0
ySpd = 0

// Jumping
gravSpd = .375
velSpd = 4 // maximum speed you can fall at

jumpMax = 2
jumpCount = 0
jumpHoldTimer = 0
jumpHoldFrames = [12, 6]
jumpSpd = [-3.15, -2.15]

onGround = true

// coyote time
// two kinds, 1. (hang time) player acts as if the ground is still there for a second
// 2. (jump time) gravity still there, but you can still jump. I think I want this one.
// Hang time
hangFrames = 2
hangTimer = 0
// Jump time
jumpFrames = 5
jumpTimer = 0

