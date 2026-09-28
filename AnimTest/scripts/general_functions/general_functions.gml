function controlsSetup()
{
	bufferTime = 8;
	jumpKeyBuffered = 0;
	jumpKeyBufferTimer = 0;
}

function getControls(){
	//use clamp for multi inputs ie if right key takes more than one key here
	rightKey = keyboard_check(vk_right);
	leftKey = keyboard_check(vk_left);
	
	jumpKeyPressed = keyboard_check_pressed(vk_space);
	 
	jumpKey = keyboard_check(vk_space);
	
	//jump key buffering
	if jumpKeyPressed
	{
		jumpKeyBufferTimer = bufferTime;
	}
	if jumpKeyBufferTimer > 0
	{
		jumpKeyBuffered = 1;
		jumpKeyBufferTimer--;
	}
	else 
	{
		jumpKeyBuffered = 0;
	}
}