/// @description 

// functions
function setOnGround(_val = true) {
	if _val == true {
		onGround = _val
		hangTimer = hangFrames
	} else {
		onGround = _val
		// forget the platform we were on
		curFloorPlat = noone
		hangTimer = 0
	}
}

function checkInstance(inst, obj = curFloorPlat) {
	return obj && (obj.object_index == inst 
		|| object_is_ancestor(obj.object_index, inst))
}

function checkForLowerSemiSolidWall(_x, _y) {
	var _actual_inst = noone
	// check if we are moving down and if we are colliding with a semi solid wall
	if yspd >= 0 && place_meeting(_x, _y, oSemiSolidWall)
	{
		// create a list of all the semi solid walls below us
		var _list = ds_list_create()
		var _listSize = instance_place_list(_x, _y, oSemiSolidWall, _list, false)

		// loop through instances and only return one if its colliding with the player
		for (var i = 0; i < _listSize; i++) {
			var _inst = _list[| i]
			if 
			_inst != forgetSemiSolidWall &&// [Down off semi solid wall]
			floor(bbox_bottom) <= ceil(_inst.bbox_top - _inst.yspd) {
				_actual_inst = _inst
				break
			}
		}
		ds_list_destroy(_list)
	}
	return _actual_inst;
} 

depth = -30

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
xspd = 0
yspd = 0

// State vars
crouching = false

// Jumping
gravSpd = .375
vspd = 4 // maximum speed you can fall at or terminal velocity

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


// moving platforms
curFloorPlat = noone
downSemiSolidWall = noone
// [Down off semi solid wall] use below if you want to allow the player to willfully fall through semi solid walls (look for other instances of this, to see implementation)
forgetSemiSolidWall = noone
movePlatXspd = vspd
earlyMovePlatXspd = false

