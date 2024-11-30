/// @description 
// Get inputs, must be done first
getControls()

/*  X movement */
function xMovement() {
	moveDir = rightKey - leftKey
	// get face
	if moveDir != 0 { face = moveDir }

	// Get X speed
	runType = runKey
	xSpd = moveDir * moveSpd[runType]

	// X collision
	var _subPixel = .5
	if place_meeting(x + xSpd, y, oWall) {
		// if i am moving up a slope and there is no wall above me
		if !place_meeting(x + xSpd, y - abs(xSpd) - 1, oWall) {
			while place_meeting(x + xSpd, y, oWall) {
				y -= _subPixel
			}
		} else {
			// check if ceiling slope, do abs(xSpd * 2) if you want to slide on steeper ceilings
			if !place_meeting(x + xSpd, y + abs(xSpd) + 1, oWall) {
				// slide down slope instead of sticking
				while place_meeting(x + xSpd, y, oWall) {
					y += _subPixel
				}
			} else {
				// scoot up to wall nice and tight
				var _pixelCheck = _subPixel * sign(xSpd)

				while !place_meeting(x + _pixelCheck, y, oWall) {
					x += _pixelCheck
				}

				// collide/stop
				xSpd = 0
			}
		}
	}

	// go down slopes
	if ySpd >= 0 && !place_meeting(x + xSpd, y + 1, oWall) && place_meeting(x + xSpd, y + abs(xSpd) + 1, oWall) {
		while !place_meeting(x + xSpd, y + _subPixel, oWall) {
			y += _subPixel
		}
	}

	// Move the character
	x += xSpd
}

function jump() {
	// Gravity
	if hangTimer > 0 {
		hangTimer--
	} else {
		ySpd += gravSpd
		// no longer on ground
		setOnGround(false)
	}

		// reset jump amount
	if onGround {
		jumpCount = 0
		jumpHoldTimer = 0
		jumpTimer = jumpFrames
		
	} else {
		// if in air treat it as if its the first jump
		jumpTimer--
		if jumpCount == 0 && jumpTimer <= 0 { jumpCount = 1 }
	}

	// Initiate the Jump
	if jumpKeyBuffered && jumpCount < jumpMax {
		//reset buffer
		jumpKeyBuffered = false
		jumpKeyBufferedTimer = 0
		
		// increase jump count
		jumpCount++
		
		// Set jump hold timer
		jumpHoldTimer = jumpHoldFrames[jumpCount-1]
		
		// ensure some stuff is reset, cant hurt
		setOnGround(false)
		jumpTimer = 0
	}
	// Cut off jump by releasing jump button
	if !jumpKey {
		jumpHoldTimer = 0
	}
	// Jump based on the timer/holding the button
	if jumpHoldTimer > 0 {
		// constantly set the ySpd to be the jumpSpd
		ySpd = jumpSpd[jumpCount-1]
		
		//Count down jump timer
		jumpHoldTimer--	
	}

}
function downYCollision() {
	var _subPixel = .5
	// scoot up to wall
	var _pixelCheck = _subPixel * sign(ySpd)

	while !place_meeting(x, y + _pixelCheck, oWall) {
		y += _pixelCheck
	}
	
	// bonk code
	if ySpd < 0 {
		jumpHoldTimer = 0
	}

	// collide
	ySpd = 0
}

function yMovement() {
	// Y Collision
	// Cap fall speed
	if ySpd > velSpd { ySpd = velSpd }

	var _subPixel = .5
	// upwards y collision (with ceiling slopes) (ONLY IF YOU WANT TO HAVE CEILINGS KINDA PULL YOU UP)
	if ySpd < 0 && place_meeting(x, y + ySpd, oWall) {
		var _slopeSlide = false
		// Jump into sloped ceilings
		// slide up/left slope
		// moveDir is the direction the player is moving, 
		// which currently matches the speed because our character currently has no momentum, might revisit if we add that.
		if moveDir == 0 && !place_meeting(x - abs(ySpd)-1, y + ySpd, oWall) {
			while place_meeting(x, y + ySpd, oWall) {
				// use one as it does not need to be as precise and subpixel is a bit touchy
				x -= 1
			}
			_slopeSlide = true
		}
		// slide up/right slope
		if moveDir == 0 && !place_meeting(x + abs(ySpd)+1, y + ySpd, oWall) {
			while place_meeting(x, y + ySpd, oWall) {
				x += 1
			}
			_slopeSlide = true
		}
		// if not sliding up a slope, do as normal
		if !_slopeSlide {
			downYCollision()
		}

	}

	// downwards y collision
	if ySpd >= 0 {
		if place_meeting(x, y + ySpd, oWall) {
			downYCollision()
		}

		// set if i am on the ground
		if place_meeting(x, y + 1, oWall) {
			setOnGround()
		}
	}
	// move up
	y += ySpd
}

// Call movement in correct order
xMovement()
jump()
yMovement()

/* Sprite control */ 
// walking
if abs(xSpd) > 0 { sprite_index = walkSpr }
// running
if abs(xSpd) >= moveSpd[1] { sprite_index = runSpr }
// idle
if xSpd == 0 { sprite_index = idleSpr }
// jumping
if !onGround { sprite_index = jumpSpr }

mask_index = maskSpr
