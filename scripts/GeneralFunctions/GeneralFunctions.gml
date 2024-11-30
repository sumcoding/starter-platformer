function controlsSetup() {
	bufferTime = 5
	
	jumpKeyBuffered = 0
	jumpKeyBufferedTimer = 0
}

// always in a step event
function getControls() {
	// Direction inputs
	rightKey = clamp(keyboard_check(vk_right) + gamepad_button_check(0, gp_padr) + gamepad_button_check(0, gp_stickl), 0, 1)
	leftKey = clamp(keyboard_check(vk_left) + gamepad_button_check(0, gp_padl), 0, 1)
	
	// Action inputs
	jumpKeyPressed = clamp( keyboard_check_pressed(ord("X")) + gamepad_button_check_pressed(0, gp_face1), 0, 1)
	jumpKey = clamp(keyboard_check(ord("X")) + gamepad_button_check(0, gp_face1), 0, 1)
	runKey = clamp(keyboard_check(ord("H")) + gamepad_button_check(0, gp_face3), 0, 1)
	
	// Jump key buffering
	if jumpKeyPressed {
		jumpKeyBufferedTimer = bufferTime
	}
	if jumpKeyBufferedTimer > 0 {
		jumpKeyBuffered = 1
		jumpKeyBufferedTimer--
	} else {
		jumpKeyBuffered = 0
	}
}
