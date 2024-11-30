/// @description Camera
if keyboard_check_pressed(vk_f8) {
	window_set_fullscreen(!window_get_fullscreen())
}

// make sure player exists
if !instance_exists(oPlayer) { exit }

var _cam = cameraSetup()

// set cam coor vars
finalCamX += (_cam[0] - finalCamX) * camTrailSpd
finalCamY += (_cam[1] - finalCamY) * camTrailSpd

// Set camera coordinates
camera_set_view_pos(view_camera[0], finalCamX, finalCamY)
