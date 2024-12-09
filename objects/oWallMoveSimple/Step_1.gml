/// @description
xspd = dir*spd

if place_meeting(x + xspd, y, oWall) {
	dir *= -1
	xspd = 0	
}

x += xspd