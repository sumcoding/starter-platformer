/// @description

// move in a circle
dir += rotSpd

// get the target position
var _targetX = xstart + lengthdir_x(radius, dir)
var _targetY = ystart + lengthdir_y(radius, dir)

// get our xspd and yspd
xspd = _targetX - x
yspd = _targetY - y

// move
x += xspd
y += yspd
