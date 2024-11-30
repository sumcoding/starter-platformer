// make sure player exists
if !instance_exists(oPlayer) { exit }

var _cam = cameraSetup()
// set cam coor vars
finalCamX = _cam[0]
finalCamY = _cam[1]
