/// @description 
// Get inputs, must be done first
getControls()

// get out of the solid moving walls that have posistioned themselves into the player in begin step
function getOutOfSolidMoveWalls() {
	var _rightWall = noone
	var _leftWall = noone
	var _upWall = noone
	var _downWall = noone

	var _list = ds_list_create()
	var _listSize = instance_place_list(x, y, oWallMove, _list, false)

	for (var i = 0; i < _listSize; i++) {
		var _inst = _list[| i]
		// get the closest right wall
		if _inst.bbox_left - _inst.xspd >= bbox_right-1 {
			if !instance_exists(_rightWall) || _inst.bbox_left < _rightWall.bbox_left {
				_rightWall = _inst
			}
		}
		// get the closest left wall
		if _inst.bbox_right - _inst.xspd <= bbox_left+1 {
			if !instance_exists(_leftWall) || _inst.bbox_right > _leftWall.bbox_right {
				_leftWall = _inst
			}
		}
		// get the closest down wall
		if _inst.bbox_top - _inst.yspd >= bbox_bottom-1 {
			if !instance_exists(_downWall) || _inst.bbox_top < _downWall.bbox_top {
				_downWall = _inst
			}
		}
		// get the closest up wall
		if _inst.bbox_bottom - _inst.yspd <= bbox_top+1 {
			if !instance_exists(_upWall) || _inst.bbox_bottom > _upWall.bbox_bottom {
				_upWall = _inst
			}
		}
	}

	ds_list_destroy(_list)

	// right wall
	if instance_exists(_rightWall) {
		var _rightDist = bbox_right - x
		x = _rightWall.bbox_left - _rightDist
	}
	// left wall
	if instance_exists(_leftWall) {
		var _leftDist = x - bbox_left
		x = _leftWall.bbox_right + _leftDist
	}
	// down wall
	if instance_exists(_downWall) {
		var _downDist = bbox_bottom - y
		y = _downWall.bbox_top - _downDist
	}
	// up wall - includes collision for crouch feature, which is why its different to the above
	if instance_exists(_upWall) {
		var _upDist = y - bbox_top
		var _targetY = _upWall.bbox_bottom + _upDist
		// check if there isnt a wall in the way
		if !place_meeting(x, _targetY, oWall) {
			y = _targetY
		} 
	}

	// dont get left behind by the moving walls
	earlyMovePlatXspd = false
	if instance_exists(curFloorPlat) 
	   && curFloorPlat.xspd != 0
	   && !place_meeting(x, y + movePlatXspd + 1, curFloorPlat) {

		var _xCheck = curFloorPlat.xspd
		// go ahead and move back on to the wall if no wall is in the way
		if !place_meeting(x + _xCheck, y, oWall) {
			x += _xCheck
			earlyMovePlatXspd = true
		}
	}
}

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

	// [Down off semi solid wall]
	var _floorIsSolid = false
	if instance_exists(curFloorPlat) && checkInstance(oWall) {
		_floorIsSolid = true
	}
	// Initiate the Jump
	if jumpKeyBuffered && jumpCount < jumpMax 
	&& (!downKey || _floorIsSolid) // [Down off semi solid wall]
	{
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

	// HIGH RES FIX: same principle as the downSemiSolidWall, check for semisolid plat below me
	var _ycheck = y + 1 + _clampYspd + vspd
	if instance_exists(curFloorPlat) { _ycheck += max(_ycheck, curFloorPlat.yspd) }
	var _semiSolidInst = checkForLowerSemiSolidWall(x, _ycheck)

	// loop through colliding instances and only return one if its top is below the player
	for (var i = 0; i < _listSize; i++) {
		// get an instance of wall or semi solid wall
		var _inst = _list[| i]
		// IMPORTANT: it is expected that all walls have an xspd and a yspd
		// avoid magnitism to floor
		if (
		_inst != forgetSemiSolidWall && // [Down off semi solid wall]
		(_inst.yspd <= yspd || instance_exists(curFloorPlat)) 
		&& (_inst.yspd > 0 || place_meeting(x, y + 1 + _clampYspd, _inst))) 
	  || _inst == _semiSolidInst // HIGH RES FIX
		{
			// get a solid wall or semi solid wall below playerd
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

	// if we have a downSemisolidWall, make that the current floor
	if instance_exists(downSemiSolidWall) { curFloorPlat = downSemiSolidWall }

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
	movePlatXspd = 0
	// get the platform x speed
	if instance_exists(curFloorPlat) { movePlatXspd = curFloorPlat.xspd }

	// move with the plat xspd
	if !earlyMovePlatXspd {
		if place_meeting(x + movePlatXspd, y, oWall) {
			var _subPixel = .5
			// scoot up to wall
			var _pixelCheck = _subPixel * sign(movePlatXspd)
			while !place_meeting(x + _pixelCheck, y, oWall) {
				x += _pixelCheck
			}

			// set plat x speed to 0 to finish collision
			movePlatXspd = 0
		}

		// move with the platform
		x += movePlatXspd
	}
}

function movingFloorYCollision() {		
	// y - snap player to floor platform if moving vertically
	if instance_exists(curFloorPlat) && (
		curFloorPlat.yspd != 0 
	  || checkInstance(oWallMove)
		|| checkInstance(oSemiSolidMove)
	) {
		// snap to top of floor platform ( un-floor the y var so its not choppy)
		if !place_meeting(x, curFloorPlat.bbox_top, oWall)
		&& curFloorPlat.bbox_top >= bbox_bottom - vspd {
			y = curFloorPlat.bbox_top
		}

						// THIS WILL LIKELY GO AWAY... part 8 - made redundent by code block below
						// going up into a solid wall while on a semisolid platform
						/* if curFloorPlat.yspd < 0 && place_meeting(x, y + curFloorPlat.yspd, oWall) {
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
						} */
	}

	// get pushed down through a semisolid wall by a moving solid wall
	if instance_exists(curFloorPlat) 
		 && checkInstance(oSemiSolidWall) 
		 && place_meeting(x, y, oWall) 
	{
		// if player is already stuck in a wall, try and move me down to get below semi solid
		// if still stuck player is crushed

		// dont check too far so we dont warp below walls
		var _maxPushDist = 10 // 10 pixels, fastest a move plat should be able to move down
		var _pushedDist = 0
		var _startY = y
		while place_meeting(x, y, oWall) && _pushedDist < _maxPushDist {
			y++
			_pushedDist++
		}
		// forget curFloorPlat
		curFloorPlat = noone

		// if we are still stuck, we are crushed, take me back to my y to avoid the funk
		if _pushedDist > _maxPushDist {
			y = _startY
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
	downSemiSolidWall = noone
	if yspd >= 0 && !place_meeting(x + xspd, y + 1, oWall) && place_meeting(x + xspd, y + abs(xspd) + 1, oWall) {
		// check for semisolid wall below
		downSemiSolidWall = checkForLowerSemiSolidWall(x + xspd, y + abs(xspd) + 1)
		// if no semisolid wall below, precisely go down slope
		if !instance_exists(downSemiSolidWall) {
			while !place_meeting(x + xspd, y + _subPixel, oWall) { y += _subPixel }
		}
	}

	// Move the character
	x += xspd

	movingFloorXCollision()
}

// [Down off semi solid wall]
function pushPlayerThroughWallOnDown() {
	if downKey && jumpKeyPressed {
		// push through semi solid wall
		if instance_exists(curFloorPlat) && checkInstance(oSemiSolidWall) {
			var _ycheck = max(1, curFloorPlat.yspd + 1)
			if !place_meeting(x, y + _ycheck, oWall) {
				// move below the platform
				y += 1

				// inherit any downward speed from the platform so it doesnt catch
				yspd = _ycheck - 1
				// forget for a breaf moment so we dont get caught again
				forgetSemiSolidWall = curFloorPlat

				// no more floor for player
				setOnGround(false)
			}
		}
	}

	// This may need to be under y += yspd in yMovement
	if instance_exists(forgetSemiSolidWall) && !place_meeting(x, y, forgetSemiSolidWall) {
		forgetSemiSolidWall = noone
	}
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

	// [Down off semi solid wall]
	pushPlayerThroughWallOnDown()

	// move up
	if !place_meeting(x, y + yspd, oWall) { y += yspd }

	movingFloorYCollision()
}

// IMPORTANT: must be called before anything else
getOutOfSolidMoveWalls()

// Call movement in correct order
xMovement()
jump()
yMovement()

// temp - check if crushed
image_blend = c_white
if place_meeting(x, y, oWall) { image_blend = c_blue }

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
