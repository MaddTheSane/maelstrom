//
//  Object.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/4/15.
//
//

import Foundation
import SDL2

class MaelObject {
	var points: Int32 = 0
	var onscreen: Bool = false
	var position: (x: Int32, y: Int32) = (0,0)
	var vec: (x: Int32, y: Int32) = (0,0)
	var size: (x: Int32, y: Int32) = (0,0)
	var exploding: Bool = false
	var solid = true
	var shootable = true
	private(set) var timeToLive: Int32 = -1
	var hitPoints: Int32 = DEFAULT_HITS
	
	var hitRect = Rect()
	var playground = Rect()
	
	private var phase: Int32 = 0
	private var phaseTime: Int32 = 0
	private var nextPhase: Int32 = 0

	var myBlit: Blit {
		didSet {
			if myBlit.isSmall {
				size = (16, 16)
			} else {
				size = (32, 32)
			}
		}
	}
	
	/* Flags */
	var isPlayer: Bool {
		return false
	}
	
	var alive: Bool {
		return true
	}
	
	init(X: Int32, Y: Int32, Xvec: Int32, Yvec: Int32, blit: Blit, phaseTime: Int32) {
		myBlit = blit
		points = DEFAULT_POINTS;

		vec = (Xvec, Yvec)
		self.phaseTime = phaseTime
		if phaseTime != NO_PHASE_CHANGE {
			phase = Int32(FastRandom(UInt16(myBlit.sprites.count)))
		} else {
			phase = 0
		}
		
		playground.left = gScrnRect.left<<Int16(SPRITE_PRECISION)
		playground.right = (gScrnRect.right<<Int16(SPRITE_PRECISION))
		playground.top = (gScrnRect.top<<Int16(SPRITE_PRECISION))
		playground.bottom = (gScrnRect.bottom<<Int16(SPRITE_PRECISION))

		setPos(x: X, y: Y)
		
		setTTL(-1)
	}

	/// We expired (returns -1 if we are dead)
	func beenTimedOut() -> Int32 {
		return -1
	}
	
	func shake(shakiness: Int32) {
		let Xvec = ((vec.x < 0) ? shakiness : -shakiness);
		let Yvec = ((vec.y < 0) ? shakiness : -shakiness);
		accelerate(xVec: Xvec, yVec: Yvec);
	}
	
	func accelerate(xVec xVec: Int32, yVec: Int32) {
		guard !exploding else {
			return
		}
		vec.x += xVec
		if abs(vec.x) > VEL_MAX {
			vec.x = ((vec.x > 0) ? VEL_MAX : -VEL_MAX);
		}
		
		vec.y += yVec
		if abs(vec.y) > VEL_MAX {
			vec.y = ((vec.y > 0) ? VEL_MAX : -VEL_MAX);
		}
	}
	
	/* Sound functions */
	func hitSound() {
		sound.playSound(.SteelHit, priority: 3)
	}
	
	func explodeSound() {
		sound.playSound(.Explosion, priority: 3)
	}
	
	/*
virtual int Collide(Object *object) {
/* Set up the location rectangles */
Rect *R1=&HitRect, *R2=&object->HitRect;

/* No collision if no overlap */
if ( ! Overlap(R1, R2) )
return(0);

/* Check the bitmasks to see if the sprites really intersect */
int  xoff1, xoff2;
int  roff;
unsigned char *mask1, *mask2;
int checkwidth, checkheight, w;

/* -- Load the ptrs to the sprite masks */
mask1 = myblit->mask[phase];
mask2 = (object->myblit)->mask[object->phase];

/* See where the sprites are relative to eachother, x-Axis */
if ( R2->left < R1->left ) {
/* The second sprite is left of the first one */
checkwidth = (R2->right-R1->left);
xoff2 = R1->left-R2->left;
xoff1 = 0;
} else {
/* The first sprite is left of the second one */
checkwidth = (R1->right-R2->left);
xoff1 = R2->left-R1->left;
xoff2 = 0;
}

/* See where the sprites are relative to eachother, y-Axis */
if ( R2->top < R1->top ) {
/* The second sprite is above of the first one */
checkheight = (R2->bottom-R1->top);
mask2 += (R1->top-R2->top)*object->xsize;
} else {
/* The first sprite is on top of the second one */
checkheight = (R1->bottom-R2->top);
mask1 += (R2->top-R1->top)*xsize;
}

/* Do the actual mask hit detection */
while ( checkheight-- ) {
for ( roff=0, w=checkwidth; w; --w, ++roff ) {
if ( mask1[xoff1+roff] && mask2[xoff2+roff] )
return(1);
}
mask1 += xsize;
mask2 += object->xsize;
}
return(0);
}
/* Should be called in main loop -- return (-1) if dead */
virtual int HitBy(Object *ship) {
Shot *shot;
while ( shootable && (shot=ship->ShotHit(&HitRect)) ) {
if ( BeenShot(ship, shot) > 0 )
return(-1);
}
if ( (solid && ship->solid) &&
Collide(ship) && (BeenRunOver(ship) > 0) )
return(-1);
return(0);
}

/* We've been shot!  (returns 1 if we are dead) */
virtual int BeenShot(Object *ship, Shot *shot) {
if ( (HitPoints -= shot->damage) <= 0 ) {
ship->IncrScore(Points);
if ( IsPlayer() )
ship->IncrFrags();
return(Explode());
} else {
HitSound();
Accelerate(shot->xvel/2, shot->yvel/2);
}
return(0);
}

/* We've been run over!  (returns 1 if we are dead) */
virtual int BeenRunOver(Object *ship) {
if ( ship->IsPlayer() )
ship->BeenDamaged(PLAYER_HITS);
if ( (HitPoints -= 1) <= 0 ) {
ship->IncrScore(Points);
return(Explode());
} else {
HitSound();
ship->Accelerate(xvec/2, yvec/2);
}
return(0);
}
*/
	
	/** We've been globally damaged!  (returns 1 if we are dead) */
	func beenDamaged(damage: Int32) -> Int32 {
		hitPoints -= damage
		if hitPoints <= 0 {
			return explode()
		}
		hitSound()
		return 0
	}

	

	/** What happens when we have been shot up or crashed into. */
	/** Returns 1 if we die here, instead of go into explosion */
	func explode() -> Int32 {
		if exploding {
			return(0);
		}
		exploding = true
		solid = false;
		shootable = false;
		phase = 0;
		nextPhase = 0;
		phaseTime = 2;
		vec = (0,0)
		myBlit = gExplosion
		setTTL(Int32(myBlit.sprites.count) * phaseTime)
		explodeSound();
		return 0;
	}
	
	func setTTL(ttl: Int32) {
		timeToLive = ttl + 1
	}
	
	func setPos(x X: Int32, y Y: Int32) {
		/* Set new X position */
		position.x = X
		if position.x > Int32(playground.right){
			position.x = Int32(playground.left) + (position.x-Int32(playground.right));
		} else if position.x < Int32(playground.left ) {
			position.x = Int32(playground.right) - (Int32(playground.left)-position.x);
		}
		
		/* Set new Y position */
		position.y = Y;
		if position.y > Int32(playground.bottom) {
			position.y = Int32(playground.top) + (position.y-Int32(playground.bottom));
		} else if position.y < Int32(playground.top) {
			position.y = Int32(playground.bottom) - (Int32(playground.top)-position.y);
		}
		
		/* Set the new HitRect */
		hitRect.left = myBlit.hitRect.left+Int16(position.x>>Int32(SPRITE_PRECISION));
		hitRect.right = myBlit.hitRect.right+Int16(position.x>>Int32(SPRITE_PRECISION))
		hitRect.top = myBlit.hitRect.top+Int16(position.y>>Int32(SPRITE_PRECISION))
		hitRect.bottom = myBlit.hitRect.bottom+Int16(position.y>>Int32(SPRITE_PRECISION))
	}
	/*
virtual void Phase(void) {
if ( phasetime != NO_PHASE_CHANGE ) {
if ( nextphase++ >= phasetime ) {
nextphase = 0;
if ( ++phase >= myblit->numFrames )
phase = 0;
}
}
}
*/
}

final class Nova :  MaelObject {

	init(x: Int32, y: Int32) {
		super.init(X: x, Y: y, Xvec: 0, Yvec: 0, blit: gNova, phaseTime: 4)
		timeToLive = Int32(gNova.sprites.count) * phaseTime
		points = NOVA_PTS
		phase = 0;
		sound.playSound(.NovaAppears, priority: 4)
		#if SERIOUS_DEBUG
			//error("Created a nova!\n");
		#endif
	}
	
	override func beenTimedOut() -> Int32 {
		if !exploding {
			sound.playSound(.NovaBoom, priority: 5)
		}
		
		return -1
	}
	/*
	int BeenTimedOut(void) {
	if ( ! Exploding ) {
	int i;
	sound->PlaySound(gNovaBoom, 5);
	OBJ_LOOP(i, gNumSprites) {
	if ( gSprites[i] == this )
	continue;
	if (gSprites[i]->BeenDamaged(1) < 0) {
	delete gSprites[i];
	gSprites[i] = gSprites[gNumSprites];
	}
	}
	OBJ_LOOP(i, gNumPlayers)
	gPlayers[i]->CutThrust(SHAKE_DURATION);
	gShakeTime = SHAKE_DURATION;
	}
	return(-1);
	}
	*/
	override func shake(shakiness: Int32) {
		//Do nothing
	}
}

final class Prize: MaelObject {
	
	override func explodeSound() {
		sound.playSound(.Idiot, priority: 4)
	}
}

final class Bonus: MaelObject {
	private var bonus = 0
	
	override func beenTimedOut() -> Int32 {
		if bonus != 0 {
			sound.playSound(.MultiplierGone, priority: 4)
		}
		return -1
	}
	
	override func shake(shakiness: Int32) {
		//Do nothing
	}
}

final class DamagedShip : MaelObject {
	
	//DamagedShip(int X, int Y, int xVel, int yVel);
	//~DamagedShip() { }
	
	/*
	int BeenRunOver(Object *ship) {
		ship->IncrLives(1);
		sound->PlaySound(gSavedShipSound, 4);
		return(1);
	}
	*/
	
	override func beenTimedOut() -> Int32 {
		if !exploding {
			return explode()
		} else {
			return -1
		}
	}
	
	/*
	
	int Explode(void) {
		/* Create some shrapnel */
		int newsprite, xVel, yVel, rx;
		
		/* Don't do anything if we're already exploding */
		if ( Exploding ) {
			return(0);
		}
		
		/* Type 1 shrapnel */
		rx = (SCALE_FACTOR);
		xVel = yVel = 0;
		
		while (xVel == 0)
		xVel = FastRandom(rx / 2) + SCALE_FACTOR;
		while (yVel == 0)
		yVel = FastRandom(rx) - (rx / 2);
		if (yVel > 0)
		yVel += SCALE_FACTOR;
		else
		yVel -= SCALE_FACTOR;
		
		newsprite = gNumSprites;
		gSprites[newsprite]=new Shrapnel(x, y, xVel, yVel, gShrapnel1);
		
		/* Type 2 shrapnel */
		rx = (SCALE_FACTOR);
		xVel = yVel = 0;
		
		while (xVel == 0)
		xVel = FastRandom(rx / 2) + SCALE_FACTOR;
		xVel *= -1;
		while (yVel == 0)
		yVel = FastRandom(rx) - (rx / 2);
		if (yVel > 0)
		yVel += SCALE_FACTOR;
		else
		yVel -= SCALE_FACTOR;
		
		newsprite = gNumSprites;
		gSprites[newsprite]=new Shrapnel(x, y, xVel, yVel, gShrapnel2);
		
		/* Finish our explosion */
		Exploding = 1;
		solid = 0;
		shootable = 0;
		phase = 0;
		nextphase = 0;
		phasetime = 2;
		xvec = yvec = 0;
		myblit = gShipExplosion;
		TTL = (myblit->numFrames*phasetime);
		ExplodeSound();
		return(0);
	}
	*/
	override func explodeSound() {
		sound.playSound(.ShipHit, priority: 5)
	}
}

var gSprites = [MaelObject]()
