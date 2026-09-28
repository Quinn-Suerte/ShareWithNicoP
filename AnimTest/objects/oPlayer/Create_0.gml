//controls setup
controlsSetup();

//moving
dir_horizontal = 0;
move_speed = 1;
xspd = 0;
yspd = 0;

//jumping
grav = 0.275;
termVel = 4;
jspd = -3.15;
jumpMax = 15;
jumpCount = 0;
jumpHoldTimer = 0;
jumpHoldFrames = 5;
onGround = true;