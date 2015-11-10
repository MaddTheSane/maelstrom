//
//  Object.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/4/15.
//
//

import Foundation

class MaelObject {
	var points: Int32 = 0
	var phase: Int32 = 0
	var onscreen: Bool = false
	var position: (x: Int32, y: Int32) = (0,0)
	var size: (x: Int32, y: Int32) = (0,0)
	var exploding: Bool = false
	/* Flags */
	var isPlayer: Bool {
		return false
	}
	var alive: Bool {
		return true
	}
	
	init(X: Int32, Y: Int32, Xvec: Int32, Yvec: Int32, blit: Blit, phaseTime: Int32) {
		/*
	points = DEFAULT_POINTS;
	
	Set_Blit(blit);
		if ( (phasetime=PhaseTime) != NO_PHASE_CHANGE ) {
	phase = FastRandom(myblit->numFrames);
		} else {
	phase = 0;
		}
	nextphase = 0;
	
	playground.left = (gScrnRect.left<<SPRITE_PRECISION);
	playground.right = (gScrnRect.right<<SPRITE_PRECISION);
	playground.top = (gScrnRect.top<<SPRITE_PRECISION);
	playground.bottom = (gScrnRect.bottom<<SPRITE_PRECISION);
	
	SetPos(X, Y);
	xvec = Xvec;
	yvec = Yvec;
	
	solid = 1;
	shootable = 1;
	HitPoints = DEFAULT_HITS;
	Exploding = 0;
	Set_TTL(-1);
	onscreen = 0;
	++gNumSprites;*/
	}

	func beenTimedOut() -> Int32 {
		return 0
	}
	
	func shake(shakiness: Int32) {
		
	}
	/*
int Points;
int x, y;
int xvec, yvec;
int xsize, ysize;
int solid;
int shootable;
int HitPoints;
int TTL;

int onscreen;
int phase;
int phasetime;
int nextphase;
Blit *myblit;
Rect HitRect;
Rect playground;
int Exploding;
*/
	/* Sound functions */
	final func hitSound() {
		sound.playSound(.SteelHit, priority: 3)
	}
	
	final func explodeSound() {
		sound.playSound(.Explosion, priority: 3)
	}
}

var gNova = Blit()

final class Nova :  MaelObject {
	
	init(x: Int32, y: Int32) {
		super.init(X: x, Y: y, Xvec: 0, Yvec: 0, blit: gNova, phaseTime: 4)
		//Set_TTL(gNova->numFrames*phasetime);
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

var gSprites = [MaelObject]()
