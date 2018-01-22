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
	fileprivate(set) var timeToLive: Int32 = -1
	var hitPoints: Int32 = DEFAULT_HITS
	
	var hitRect = Rect()
	var playground = Rect()
	
	fileprivate var phase: Int32 = 0
	fileprivate var phaseTime: Int32 = 0
	fileprivate var nextPhase: Int32 = 0

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
	
	init(X: Int32, Y: Int32, xVec Xvec: Int32, yVec Yvec: Int32, blit: Blit, phaseTime: Int32) {
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
		gNumSprites += 1
	}
	
	deinit {
		gNumSprites -= 1
	}

	/// We expired (returns -1 if we are dead)
	func beenTimedOut() -> Int32 {
		return -1
	}
	
	func shake(_ shakiness: Int32) {
		let Xvec = ((vec.x < 0) ? shakiness : -shakiness);
		let Yvec = ((vec.y < 0) ? shakiness : -shakiness);
		accelerate(xVec: Xvec, yVec: Yvec);
	}
	
	func accelerate(xVec: Int32, yVec: Int32) {
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
		sound.playSound(.steelHit, priority: 3)
	}
	
	func explodeSound() {
		sound.playSound(.explosion, priority: 3)
	}
	
	/// This function returns `0`, or `-1` if the sprite died
	func move(frozen: Bool) -> Int32 {
		return 0
	}
	
	/// This function is called to see if we shot something
	func shotHit(_ hitRect: inout Rect) -> Shot? {
		return nil
	}
	
	func collide(against object: MaelObject) -> Int {
		// TODO: implement
		return 0
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
	*/
	
	///Should be called in main loop -- return `-1` if dead
	func hitBy(_ ship: MaelObject) -> Int32 {
		
		return 0
	}
	/*
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

	*/
	
	/// We've been shot!  (returns 1 if we are dead)
	func beenShot(by ship: MaelObject, shot: Shot) -> Int32 {
		hitPoints -= shot.damage
		if hitPoints <= 0 {
			ship.increaseScore(points)
			if isPlayer {
				ship.increaseFrags()
			}
			return explode()
		} else {
			hitSound()
			accelerate(xVec: shot.xvel / 2, yVec: shot.yvel / 2)
		}
		return 0
	}
	
	/// We've been run over!  (returns 1 if we are dead)
	func beenRunOver(by ship: MaelObject) -> Int32 {
		if ship.isPlayer {
			_=ship.beenDamaged(PLAYER_HITS)
		}
		hitPoints -= 1
		if hitPoints <= 0 {
			ship.increaseScore(points)
			return explode()
		} else {
			hitSound()
			ship.accelerate(xVec: vec.x / 2, yVec: vec.y / 2)
		}
		return 0
	}
	
	func increaseScore(_ pts: Int32) {
		
	}
	
	func increaseFrags() {
		
	}
	
	/** We've been globally damaged!  (returns 1 if we are dead) */
	func beenDamaged(_ damage: Int32) -> Int32 {
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
			return 0
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
	
	func setTTL(_ ttl: Int32) {
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
	
	func doPhase() {
		if phaseTime != NO_PHASE_CHANGE {
			let lastNextPhase = nextPhase
			nextPhase += 1
			if lastNextPhase >= phaseTime {
				nextPhase = 0
				phase += 1
				if Int(phase) >= myBlit.sprites.count {
					phase = 0
				}
			}
		}
	}
	
	/* Player access functions (not used here) */
	func setSpecial(_ spec: Player.Features) {
		
	}
	
	func increaseShieldLevel(_ level: Int32) {
		
	}
	
	func multiplier(_ multiplier: Int32) {
		
	}
	
	func increaseBonus(_ bonus: Int32) {
		
	}
	
	func increaseLives(_ lives: Int32) {
		
	}
}

final class Multiplier: MaelObject {
	private var multiplier: Int32 = 0
	
	override func beenShot(by ship: MaelObject, shot: Shot) -> Int32 {
		ship.multiplier(multiplier)
		sound.playSound(.multShot, priority: 4)
		return 1
	}
	
	override func beenDamaged(_ damage: Int32) -> Int32 {
		return 0
	}
	
	override func beenTimedOut() -> Int32 {
		sound.playSound(.multiplierGone, priority: 4)
		return -1
	}
	
	override func shake(_ shakiness: Int32) {
		//do nothing
	}
}

final class Nova :  MaelObject {
	init(x: Int32, y: Int32) {
		super.init(X: x, Y: y, xVec: 0, yVec: 0, blit: gNova, phaseTime: 4)
		timeToLive = Int32(gNova.sprites.count) * phaseTime
		points = NOVA_PTS
		phase = 0;
		sound.playSound(.novaAppears, priority: 4)
		#if SERIOUS_DEBUG
			//error("Created a nova!\n");
		#endif
	}
	
	override func beenTimedOut() -> Int32 {
		if !exploding {
			sound.playSound(.novaBoom, priority: 5)
			for i in (0 ..< gNumSprites).reversed() {
				if gSprites[i] === self {
					continue
				}
				if gSprites[i].beenDamaged(1) < 0 {
					gSprites[i] = gSprites[gNumSprites]
				}
			}
			for i in (0 ..< gNumPlayers).reversed() {
				Player.players[Int(i)]!.cutThrust(SHAKE_DURATION)
			}
			gShakeTime = SHAKE_DURATION
		}
		
		return -1
	}

	override func shake(_ shakiness: Int32) {
		//Do nothing
	}
}

final class Prize: MaelObject {
	
	init(X: Int32, Y: Int32, Xvec: Int32, Yvec: Int32) {
		super.init(X: X, Y: Y, xVec: Xvec, yVec: Yvec, blit: gPrize, phaseTime: 2)
		setTTL(PRIZE_DURATION)
		sound.playSound(.prizeAppears, priority: 4)
	}
	
	override func explodeSound() {
		sound.playSound(.idiot, priority: 4)
	}
	
	/* When we are run over, we give prizes! */
	override func beenRunOver(by ship: MaelObject) -> Int32 {
		
		guard ship.isPlayer, ship.alive else {
			return 0
		}
		
		let prize = FastRandom(UInt16(NUM_PRIZES))
		switch prize {
		case 0:
			/* -- They got machine guns! */
			ship.setSpecial(.machineGuns)

		case 1:
			/* -- They got Air brakes */
			ship.setSpecial(.airBrakes)
			
		case 2:
			/* -- They might get Lucky */
			ship.setSpecial(.luckyIrish)
			
		case 3:
			/* -- They triple fire */
			ship.setSpecial(.tripleFire)

		case 4:
			/* -- They got long range */
			ship.setSpecial(.longRange)

		case 5:
			/* -- They got more shields */
			ship.increaseShieldLevel(MAX_SHIELD/5 + Int32(FastRandom(Uint16(MAX_SHIELD/2))))

		case 6:
			/* -- Put 'em on ICE */
			sound.playSound(.freeze, priority: 4)
			gFreezeTime = FREEZE_DURATION;

		case 7:
			/* Blow up everything */
			sound.playSound(.novaBoom, priority: 5)
			for i in (0 ..< gNumSprites).reversed() {
				if gSprites[i] === self {
					continue
				}
				
				if gSprites[i].beenDamaged(1) < 0 {
					gSprites[i] = gSprites[gNumSprites]
				}
			}
			for i in (0 ..< gNumPlayers).reversed() {
				Player.players[Int(i)]!.cutThrust(SHAKE_DURATION)
				gShakeTime = SHAKE_DURATION
			}

		default:
			fatalError("Unknown random number \(prize) outside of prize range!")
		}
		
		sound.playSound(.gotPrize, priority: 4)
		return 1
	}
	
	override func beenTimedOut() -> Int32 {
		/* If we time out, we explode, then die. */
		if exploding {
			return -1
		} else {
			return explode()
		}
	}
}

final class Bonus: MaelObject {
	private var bonus: Int32
	init(X: Int32, Y: Int32, Xvec: Int32, Yvec: Int32, bonus: Int32) {
		self.bonus = bonus
		super.init(X: X, Y: Y, xVec: Xvec, yVec: Yvec, blit: gBonusBlit, phaseTime: 2)
		setTTL(BONUS_DURATION)
		solid = false
		sound.playSound(.bonusAppears, priority: 4)
	}
	
	override func beenTimedOut() -> Int32 {
		if bonus != 0 {
			sound.playSound(.multiplierGone, priority: 4)
		}
		return -1
	}
	
	override func beenShot(by ship: MaelObject, shot: Shot) -> Int32 {
		/* Increment the ship's bonus. :) */
		ship.increaseBonus(bonus)
		sound.playSound(.bonusShot, priority: 4)
		
		/* Display point bonus */
		shootable = false
		myBlit = gPointBlit
		phaseTime = NO_PHASE_CHANGE
		phase = bonus / 1000
		setTTL(POINT_DURATION)
		vec = (0,0)
		
		bonus = 0
		return 0
	}
	
	override func beenDamaged(_ damage: Int32) -> Int32 {
		return 0
	}
	
	override func shake(_ shakiness: Int32) {
		//Do nothing
	}
}

final class DamagedShip : MaelObject {
	init(X: Int32, Y: Int32, Xvec: Int32, Yvec: Int32) {
		super.init(X: X, Y: Y, xVec: Xvec, yVec: Yvec, blit: gDamagedShip, phaseTime: 1)
		setTTL(DAMAGED_DURATION * phaseTime)
		sound.playSound(.damagedAppears, priority: 4)
	}
	
	override func beenRunOver(by ship: MaelObject) -> Int32 {
		ship.increaseLives(1)
		sound.playSound(.savedShip, priority: 4)
		return 1
	}
	
	override func beenTimedOut() -> Int32 {
		if !exploding {
			return explode()
		} else {
			return -1
		}
	}
	
	override func explode() -> Int32 {
		/* Create some shrapnel */

		/* Don't do anything if we're already exploding */
		if exploding {
			return 0
		}
		
		/* Type 1 shrapnel */
		let rx = SCALE_FACTOR
		var xVel: Int32 = 0
		var yVel: Int32 = 0

		while xVel == 0 {
			xVel = Int32(FastRandom(UInt16(rx / 2))) + SCALE_FACTOR
		}
		while yVel == 0 {
			yVel = Int32(FastRandom(UInt16(rx/2))) - rx / 2
		}
		if yVel > 0 {
			yVel += SCALE_FACTOR
		} else {
			yVel -= SCALE_FACTOR
		}
		
		gSprites.append(Shrapnel(X: position.x, Y: position.y, xVec: xVel, yVec: yVel, blit: gShrapnel1))

		/* Type 2 shrapnel */
		xVel = 0
		yVel = 0

		while xVel == 0 {
			xVel = Int32(FastRandom(UInt16(rx / 2))) + SCALE_FACTOR
		}
		xVel *= -1
		while yVel == 0 {
			yVel = Int32(FastRandom(UInt16(rx/2))) - rx / 2
		}
		if yVel > 0 {
			yVel += SCALE_FACTOR
		} else {
			yVel -= SCALE_FACTOR
		}
		
		gSprites.append(Shrapnel(X: position.x, Y: position.y, xVec: xVel, yVec: yVel, blit: gShrapnel2))

		/* Finish our explosion */
		exploding = true;
		solid = false;
		shootable = false;
		phase = 0;
		nextPhase = 0;
		phaseTime = 2;
		vec = (0, 0)
		myBlit = gShipExplosion;
		timeToLive = Int32(myBlit.sprites.count) * phaseTime
		explodeSound()

		return 0
	}
	
	override func explodeSound() {
		sound.playSound(.shipHit, priority: 5)
	}
}

final class Shrapnel: MaelObject {
	init(X: Int32, Y: Int32, xVec Xvec: Int32, yVec Yvec: Int32, blit: Blit) {
		super.init(X: X, Y: Y, xVec: Xvec, yVec: Yvec, blit: blit, phaseTime: 2)
		solid = false
		shootable = false
		phase = 0;
		timeToLive = Int32(myBlit.sprites.count) * phaseTime
		
	}
	
	override func beenDamaged(_ damage: Int32) -> Int32 {
		return 0
	}
}

final class Gravity: MaelObject {
	
	override func move(frozen: Bool) -> Int32 {
		
		return super.move(frozen: frozen)
	}
	
	override func shake(_ shakiness: Int32) {
		// do nothing
	}
}

/*
class Gravity : public Object {

public:
Gravity(int X, int Y);
~Gravity() { }

int Move(int Frozen) {
int i;

/* Don't gravitize while exploding */
if ( Exploding )
return(Object::Move(Frozen));

/* Warp the courses of the players */
OBJ_LOOP(i, gNumPlayers) {
int X, Y, xAccel, yAccel;

if ( ! gPlayers[i]->Alive() )
continue;

/* Gravitize! */
gPlayers[i]->GetPos(&X, &Y);

if ( ((X>>SPRITE_PRECISION)+(SPRITES_WIDTH/2)) <=
((x>>SPRITE_PRECISION)+(SPRITES_WIDTH/2)) )
xAccel = GRAVITY_MOVE;
else
xAccel = -GRAVITY_MOVE;

if ( ((Y>>SPRITE_PRECISION)+(SPRITES_WIDTH/2)) <=
((y>>SPRITE_PRECISION)+(SPRITES_WIDTH/2)) )
yAccel = GRAVITY_MOVE;
else
yAccel = -GRAVITY_MOVE;

gPlayers[i]->Accelerate(xAccel, yAccel);
}

/* Phase normally */
return(Object::Move(Frozen));
}
void Shake(int shakiness) { }
};
*/

class HomingSuper: MaelObject {
	final func acquireTarget() -> Int32 {
		var newTarget: Int32 = -1
		var i: Int32 = 0
		
		for ii in 0 ..< gNumPlayers {
			if Player.players[Int(ii)]!.alive {
				i = ii
				break
			}
		}
		if i != gNumPlayers {	// Player(s) alive!
			repeat {
				newTarget = FastRandom(gNumPlayers)
			} while !Player.players[Int(newTarget)]!.alive
		}
		return newTarget
	}
}


final class Homing: HomingSuper {
	var target: Int32 = -1
	
	init(X: Int32, Y: Int32, xVec: Int32, yVec: Int32) {
		super.init(X: X, Y: Y, xVec: xVec, yVec: yVec, blit: ((xVec > 0) ? gMineBlitR : gMineBlitL), phaseTime: 2)
		hitPoints = HOMING_HITS
		points = HOMING_PTS
		target = acquireTarget()
		sound.playSound(.homingAppears, priority: 4)
		#if SERIOUS_DEBUG
			error("Created a homing mine!\n");
		#endif
	}

	override func move(frozen: Bool) -> Int32 {
		
		
		return super.move(frozen: frozen)
	}
}
/*
class Homing : public Object {

public:
Homing(int X, int Y, int xVel, int yVel);
~Homing() { }

int Move(int Frozen) {
if ( ((target >= 0) && gPlayers[target]->Alive()) ||
((target=AcquireTarget()) >= 0) ) {
int X, Y, xAccel=0, yAccel=0;

gPlayers[target]->GetPos(&X, &Y);
if ( ((X>>SPRITE_PRECISION)+(SPRITES_WIDTH/2)) <=
((x>>SPRITE_PRECISION)+(SPRITES_WIDTH/2)) )
xAccel -= HOMING_MOVE;
else
xAccel += HOMING_MOVE;
if ( ((Y>>SPRITE_PRECISION)+(SPRITES_WIDTH/2)) <=
((y>>SPRITE_PRECISION)+(SPRITES_WIDTH/2)) )
yAccel -= HOMING_MOVE;
else
yAccel += HOMING_MOVE;
Accelerate(xAccel, yAccel);
}
return(Object::Move(Frozen));
}

protected:
int target;
};
*/

final class SmallRock: MaelObject {
	init(X: Int32, Y: Int32, xVel: Int32, yVel: Int32, phaseTime: Int32) {
		super.init(X: X, Y: Y, xVec: xVel, yVec: yVel, blit: ((xVel > 0) ? gRock3R : gRock3L), phaseTime: phaseTime)
		points = SMALL_ROID_PTS
		gNumRocks += 1
	}

	deinit {
		gNumRocks -= 1
	}
	
	override func explode() -> Int32 {
		/* Don't do anything if we're already exploding */
		if exploding {
			return 0
		}
		
		/* Speed things up. :-) */
		gBoomDelay = max(BOOM_MIN, gBoomDelay - 1)
		#if SERIOUS_DEBUG
			error("-   Small rock! (\(gNumRocks))\n");
		#endif

		return super.explode()
	}
}

var gSprites = [MaelObject]()
