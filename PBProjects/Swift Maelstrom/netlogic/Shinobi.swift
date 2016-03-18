//
//  Shinobi.swift
//  Maelstrom
//
//  Created by C.W. Betts on 3/17/16.
//
//

import Foundation

class Shinobi: MaelObject {
	init(x: Int32, y: Int32, blit: Blit, shotOdds: Int32) {
		super.init(X: x, Y: y, Xvec: 0, Yvec: 0, blit: blit, phaseTime: 1)
		points = ENEMY_PTS
		hitPoints = ENEMY_HITS
		
		sound.playSound(.EnemyAppears, priority: 4)
	}
	/*
Shinobi(int X, int Y, Blit *blit, int ShotOdds) :
Object(X, Y, 0, 0, blit, 1) {
Set_Points(ENEMY_PTS);
Set_HitPoints(ENEMY_HITS);

for ( int i=0; i<MAX_SHOTS; ++i ) {
shots[i] = new Shot;
shots[i]->damage = PLAYER_HITS;
}
nextshot = 0;
shotodds = ShotOdds;
target = AcquireTarget();
barrel = phase;
numshots = 0;

gEnemySprite = this;
}
*/
	/*
/* This is duplicated in the Homing class */
virtual int AcquireTarget(void) {
int i, newtarget=(-1);

for ( i=0; i<gNumPlayers; ++i ) {
if ( gPlayers[i]->Alive() )
break;
}
if ( i != gNumPlayers ) {	// Player(s) alive!
do {
newtarget = FastRandom(gNumPlayers);
} while ( ! gPlayers[newtarget]->Alive() );
}
return(newtarget);
}

virtual Shot *ShotHit(Rect *hitRect) {
int i;
/* Shots are painless if we are exploding */
if ( Exploding )
return(NULL);

/* Otherwise.. Ow! :-) */
OBJ_LOOP(i, numshots) {
if ( Overlap(&shots[i]->hitRect, hitRect) ) {
/* KillShot() rearranges the shot[] array */
Shot *shotputt = shots[i];
KillShot(i);
return(shotputt);
}
}
return(NULL);
}
virtual int Move(int Frozen) {
int DX, DY, slope;
int newphase;
int coin, i, alive;

/* Move and time out old shots */
OBJ_LOOP(i, numshots) {
int offset;

if ( --shots[i]->ttl == 0 ) {
KillShot(i);
continue;
}

/* Set new X position */
shots[i]->x += shots[i]->xvel;
if ( shots[i]->x > playground.right )
shots[i]->x = playground.left +
(shots[i]->x-playground.right);
else if ( shots[i]->x < playground.left )
shots[i]->x = playground.right -
(playground.left-shots[i]->x);

/* Set new Y position */
shots[i]->y += shots[i]->yvel;
if ( shots[i]->y > playground.bottom )
shots[i]->y = playground.top +
(shots[i]->y-playground.bottom);
else if ( shots[i]->y < playground.top )
shots[i]->y = playground.bottom -
(playground.top-shots[i]->y);

/* -- Setup the hit rectangle */
offset = (shots[i]->y>>SPRITE_PRECISION);
shots[i]->hitRect.top = offset;
shots[i]->hitRect.bottom = offset+SHOT_SIZE;
offset = (shots[i]->x>>SPRITE_PRECISION);
shots[i]->hitRect.left = offset;
shots[i]->hitRect.right = offset+SHOT_SIZE;
}

/* Do no shooting if we are exploding. */
if ( Exploding ) {
return(Object::Move(Frozen));
}

/* Find out where our target is */
if ( ((target >= 0) && gPlayers[target]->Alive()) ||
((target=AcquireTarget()) >= 0) ) {
gPlayers[target]->GetPos(&DX, &DY);
DX -= x;
DY -= y;
slope = (abs(DX)-abs(DY));

/* -- See if we should accelerate */
/* -- figure out what sector we are in */
if ( DY < 0 ) {
if ( DX < 0 ) {
/* -- We are in sector 4 */
newphase = 6;
if ( slope < 0 )
++newphase;
} else {
/* -- We are in sector 1 */
newphase = 0;
if ( slope > 0 )
++newphase;
}
} else {
if ( DX < 0 ) {
/* -- We are in sector 3 */
newphase = 4;
if ( slope > 0 )
++newphase;
} else {
/* -- We are in sector 2 */
newphase = 2;
if ( slope < 0 )
++newphase;
}
}

newphase *= 6;
newphase += FastRandom(6);

/* -- Turn to a new one */
xvec = 30;

coin = FastRandom(100);
if ( coin == 0 )
yvec = 30;
else if ( coin == 1 )
yvec = -30;
else if ( coin < 7 )
yvec = 0;

barrel = (barrel + newphase)/2;
//error("phase = %d, blit = 0x%x\n", barrel, myblit);
++nextshot;
if ( (FastRandom(shotodds) == 0) &&
(nextshot >= ENEMY_SHOT_DELAY) ) {
/* -- If we are within range and facing the ship, FIRE! */
(void) MakeShot(0);
}
}

alive = Object::Move(Frozen);

if ( ((x+26)>>SPRITE_PRECISION) >= SCREEN_WIDTH )
alive = -1;
return(alive);
}
virtual void BlitSprite(void) {
/* Draw the new shots */
int i;
OBJ_LOOP(i, numshots) {
int X = (shots[i]->x>>SPRITE_PRECISION);
int Y = (shots[i]->y>>SPRITE_PRECISION);
screen->QueueBlit(X, Y, gEnemyShot);
}
Object::BlitSprite();
}
virtual void UnBlitSprite(void) {
/* Erase all old shots */
int i;
OBJ_LOOP(i, numshots) {
int X = (shots[i]->x>>SPRITE_PRECISION);
int Y = (shots[i]->y>>SPRITE_PRECISION);
screen->Clear(X, Y, SHOT_SIZE, SHOT_SIZE, DOCLIP);
}
Object::UnBlitSprite();
}
*/
	override func hitSound() {
		sound.playSound(.Bonk, priority: 3)
	}
	
	override func explodeSound() {
		sound.playSound(.Explosion, priority: 3)
	}
/*
private:
Shot *shots[MAX_SHOTS];
int nextshot;
int shotodds;
int target;
int barrel;
int numshots;

virtual int MakeShot(int offset) {
int shotphase;

if ( numshots == MAX_SHOTS )
return(-1);

/* Handle the velocity */
if ( (shotphase = barrel+offset) < 0 )
shotphase = myblit->numFrames-1;
else if ( shotphase == myblit->numFrames )
shotphase = 0;
shots[numshots]->yvel =
(gVelocityTable[shotphase].v<<SHOT_SCALE_FACTOR);
shots[numshots]->xvel =
(gVelocityTable[shotphase].h<<SHOT_SCALE_FACTOR);

/* Handle the position */
shots[numshots]->x = x;
shots[numshots]->y = y;
offset = ((SPRITES_WIDTH/2)-2)<<SPRITE_PRECISION;
shots[numshots]->x += offset;
shots[numshots]->y += offset;

shots[numshots]->xvel += xvec;
shots[numshots]->x -= xvec;
shots[numshots]->yvel += yvec;
shots[numshots]->y -= yvec;

/* -- Setup the hit rectangle */
offset = (shots[numshots]->y>>SPRITE_PRECISION);
shots[numshots]->hitRect.top = offset;
shots[numshots]->hitRect.bottom = offset+SHOT_SIZE;
offset = (shots[numshots]->x>>SPRITE_PRECISION);
shots[numshots]->hitRect.left = offset;
shots[numshots]->hitRect.right = offset+SHOT_SIZE;

/* How LONG do they live? :) */
shots[numshots]->ttl = SHOT_DURATION;
return(++numshots);
}

virtual void KillShot(int index) {
OBJ_KILL(shots, index, numshots, Shot);
}
*/
}

final class BigShinobi : Shinobi {
	init(x: Int32, y: Int32) {
		super.init(x: x, y: y, blit: gEnemyShip2, shotOdds: 30)
	}
}

final class LittleShinobi : Shinobi {
	init(x: Int32, y: Int32) {
		super.init(x: x, y: y, blit: gEnemyShip2, shotOdds: 15)
	}
}

