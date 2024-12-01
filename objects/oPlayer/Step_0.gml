/// @description 
// Get inputs, must be done first
getControls()

function jump() {
	// Gravity
	if hangTimer > 0 {
		hangTimer--
	} else {
		yspd += gravSpd
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
		// constantly set the yspd to be the jumpSpd
		yspd = jumpSpd[jumpCount-1]
		
		//Count down jump timer
		jumpHoldTimer--	
	}

}
// stops character when they hit a wall up or down
function basicYCollision() {
	var _subPixel = .5
	// scoot up to wall
	var _pixelCheck = _subPixel * sign(yspd)

	while !place_meeting(x, y + _pixelCheck, oWall) {
		y += _pixelCheck
	}
	
	// bonk code
	if yspd < 0 {
		jumpHoldTimer = 0
	}

	// collide
	yspd = 0
}

// for non moving platforms
function floorYCollision() {
  // check for solid and semi solid platforms underneath
	var _clampYspd = max(0, yspd)
	// ds use memory unlike arrays, 
	// important to get rid of this when you are done with it
	// stores all the object the player runs into
	var _list = ds_list_create()
	var _array = array_create(0)

	array_push(_array, oWall, oSemiSolidWall)

	// collision check and add to list
	var _listSize = instance_place_list(x, y + 1 + _clampYspd + vspd, _array, _list, false)

	// loop through colliding instances and only return one if its top is below the player
	for (var i = 0; i < _listSize; i++) {
		// get an instance of wall or semi solid wall
		var _inst = _list[| i]
		// IMPORTANT: it is expected that all walls have an xspd and a yspd
		// avoid magnitism to floor
		if (_inst.yspd <= yspd || instance_exists(curFloorPlat)) 
		&& (_inst.yspd > 0 || place_meeting(x, y + 1 + _clampYspd, _inst)) {
			// get a solid wall or semi solid wall below player
			if checkInstance(oWall, _inst) 
			|| floor(bbox_bottom) <= ceil(_inst.bbox_top - _inst.yspd) {
				// get the "highest" wall object
				if !instance_exists(curFloorPlat)
				|| _inst.bbox_top + _inst.yspd <= curFloorPlat.bbox_top + curFloorPlat.yspd 
				|| _inst.bbox_top + _inst.yspd <= bbox_bottom {
					curFloorPlat = _inst
				}
			}
		}
	}
	// destroy list to avoid the memory leak
	ds_list_destroy(_list)

	// one last check to make sure the floor is below us, resets the current floor instance
	if instance_exists(curFloorPlat) && !place_meeting(x, y + vspd + vspd, curFloorPlat) {
		curFloorPlat = noone
	}
	// land on ground platform, stops us from clipping through the floor occasionally
	if instance_exists(curFloorPlat) {
		var _subPixel = .5
		// scoot up to floor
		while !place_meeting(x, y + _subPixel, curFloorPlat) && !place_meeting(x, y, oWall) {
			y += _subPixel
		}
		// make sure we dont end up below the top of a semi solid wall
		if checkInstance(oSemiSolidMove) {
			while place_meeting(x, y, curFloorPlat) { y -= _subPixel }
		}
		// prevents tiny clips into floor, smooths things out, good for non moving platforms
		y = floor(y)

		// collide with ground
		yspd = 0
		setOnGround()
	}
}

// NOTE: bbox means cant use odd shaped objects, only squares

function movingFloorXCollision() {
	platXspd = 0
	// get the platform x speed
	if instance_exists(curFloorPlat) { platXspd = curFloorPlat.xspd }

	// move with the plat xspd
	if place_meeting(x + platXspd, y, oWall) {
		var _subPixel = .5
		// scoot up to wall
		var _pixelCheck = _subPixel * sign(platXspd)
		while !place_meeting(x + _pixelCheck, y, oWall) {
			x += _pixelCheck
		}

		// set plat x speed to 0 to finish collision
		platXspd = 0
	}

	// move with the platform
	x += platXspd
}

function movingFloorYCollision() {		
	// y - snap player to floor platform if moving vertically
	if instance_exists(curFloorPlat) && (
		curFloorPlat.yspd != 0 
		|| checkInstance(oSemiSolidMove)
	) {
		// snap to top of floor platform ( un-floor the y var so its not choppy)
		if !place_meeting(x, curFloorPlat.bbox_top, oWall)
		&& curFloorPlat.bbox_top >= bbox_bottom - vspd {
			y = curFloorPlat.bbox_top
		}

		// THIS WILL LIKELY GO AWAY... part 8
		// going up into a solid wall while on a semisolid platform
		if curFloorPlat.yspd < 0 && place_meeting(x, y + curFloorPlat.yspd, oWall) {
			if checkInstance(oSemiSolidWall) {
				var _subPixel = .25
				// get pushed down through the semi solid wall
				while place_meeting(x, y + curFloorPlat.yspd, oWall) {
					y += _subPixel
				}
				// if we got pushed into the a solid wall while going downwards, push back out
				while place_meeting(x, y, oWall) {
					y -= _subPixel
				}
				y = round(y)
			}

			// cancel the curFloorPlat
			setOnGround(false)
		}
	}
}

function xMovement() {
	moveDir = rightKey - leftKey
	// get face
	if moveDir != 0 { face = moveDir }

	// Get X speed
	runType = runKey
	xspd = moveDir * moveSpd[runType]

	// X collision
	var _subPixel = .5
	if place_meeting(x + xspd, y, oWall) {
		// if i am moving up a slope and there is no wall above me
		if !place_meeting(x + xspd, y - abs(xspd) - 1, oWall) {
			while place_meeting(x + xspd, y, oWall) {
				y -= _subPixel
			}
		} else {
			// check if ceiling slope, do abs(xspd * 2) if you want to slide on steeper ceilings
			if !place_meeting(x + xspd, y + abs(xspd) + 1, oWall) {
				// slide down slope instead of sticking
				while place_meeting(x + xspd, y, oWall) {
					y += _subPixel
				}
			} else {
				// scoot up to wall nice and tight
				var _pixelCheck = _subPixel * sign(xspd)

				while !place_meeting(x + _pixelCheck, y, oWall) {
					x += _pixelCheck
				}

				// collide/stop
				xspd = 0
			}
		}
	}

	// go down slopes
	if yspd >= 0 && !place_meeting(x + xspd, y + 1, oWall) && place_meeting(x + xspd, y + abs(xspd) + 1, oWall) {
		while !place_meeting(x + xspd, y + _subPixel, oWall) {
			y += _subPixel
		}
	}

	// Move the character
	x += xspd

	movingFloorXCollision()
}

function yMovement() {
	// Y Collision
	// Cap fall speed
	if yspd > vspd { yspd = vspd }

	var _subPixel = .5
	// upwards y collision (with ceiling slopes) (ONLY IF YOU WANT TO HAVE CEILINGS KINDA PULL YOU UP)
	if yspd < 0 && place_meeting(x, y + yspd, oWall) {
		var _slopeSlide = false
		// Jump into sloped ceilings
		// slide up/left slope
		// moveDir is the direction the player is moving, 
		// which currently matches the speed because our character currently has no momentum, might revisit if we add that.
		if moveDir == 0 && !place_meeting(x - abs(yspd)-1, y + yspd, oWall) {
			while place_meeting(x, y + yspd, oWall) {
				// use one as it does not need to be as precise and subpixel is a bit touchy
				x -= 1
			}
			_slopeSlide = true
		}
		// slide up/right slope
		if moveDir == 0 && !place_meeting(x + abs(yspd)+1, y + yspd, oWall) {
			while place_meeting(x, y + yspd, oWall) {
				x += 1
			}
			_slopeSlide = true
		}
		// if not sliding up a slope, do as normal
		if !_slopeSlide {
			basicYCollision()
		}

	}

	// downwards y collision (before moving platforms)
	// if yspd >= 0 {
	// 	if place_meeting(x, y + yspd, oWall) {
	// 		basicYCollision()
	// 	}

	// 	// set if i am on the ground
	// 	if place_meeting(x, y + 1, oWall) {
	// 		setOnGround()
	// 	}
	// }
	floorYCollision()

	// move up
	y += yspd

	movingFloorYCollision()
}

// Call movement in correct order
xMovement()
jump()
yMovement()


/* Sprite control */ 
// walking
if abs(xspd) > 0 { sprite_index = walkSpr }
// running
if abs(xspd) >= moveSpd[1] { sprite_index = runSpr }
// idle
if xspd == 0 { sprite_index = idleSpr }
// jumping
if !onGround { sprite_index = jumpSpr }

mask_index = maskSpr
