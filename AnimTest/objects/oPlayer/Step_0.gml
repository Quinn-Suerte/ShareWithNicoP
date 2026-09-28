getControls();


dir_horizontal = rightKey - leftKey;

xspd = dir_horizontal * move_speed;

// x collision
var _subPixel = .5;
if (place_meeting( x + xspd, y, oWall))
{
	var _pixelCheck = _subPixel * sign(xspd);
	while !place_meeting( x + _pixelCheck, y, oWall )
	{
		x += _pixelCheck;
	}
	xspd = 0;
}

if xspd >= 0 image_xscale = -1;
else image_xscale = 1;
x += xspd;


yspd += grav;

if onGround 
{
	jumpCount = 0;
}else {
	if jumpCount == 0 { jumpCount = 1; };
}

//init jump
if jumpKeyBuffered && jumpCount < jumpMax
{
	jumpKeyBuffered = false;
	jumpKeyBufferTimer = 0;
	
	jumpCount ++;
	
	//set jump hold timer
	jumpHoldTimer = jumpHoldFrames;
	
}
//cut of jump hold by releasing the jumpbutton
if !jumpKey
{
 jumpHoldTimer = 0;
}
if jumpHoldTimer > 0
{
//constanlty set yspd to jumping speed
yspd = jspd;

jumpHoldTimer--;

}

if  yspd > termVel { yspd = termVel; };

//y collision
var _subPixel = .5;
if (place_meeting( x, y + yspd, oWall))
{
	var _pixelCheck = _subPixel * sign(yspd);
	while !place_meeting( x, y + _pixelCheck, oWall )
	{
		y += _pixelCheck;
	}
	yspd = 0;
}
//set if im on the ground
if yspd >= 0 && place_meeting(x, y+1, oWall )
{
	onGround = true;
}
else {
	onGround = false;
}

y += yspd;
