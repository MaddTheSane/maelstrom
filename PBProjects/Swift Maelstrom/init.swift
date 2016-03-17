//
//  init.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/11/15.
//
//

import Foundation
import SDL2

var gLastHigh: Int32 = -1

var gScrnRect = Rect()
var gClipRect = SDL_Rect()
var gStatusLine: Int32 = 0
var gTop: Int32 = 0
var gLeft: Int32 = 0
var gBottom: Int32 = 0
var gRight: Int32 = 0

private(set) var gVelocityTable = [MPoint]()
private(set) var gShotOrigins = [MPoint]()
private(set) var gThrustOrigins = [MPoint]()

//StarPtr	gTheStars[MAX_STARS];
//Uint32	gStarColors[20];


/* -- The prize CICN's */

var gAutoFireIcon: UnsafeMutablePointer<SDL_Surface> = nil
var gAirBrakesIcon: UnsafeMutablePointer<SDL_Surface> = nil
var gMult2Icon: UnsafeMutablePointer<SDL_Surface> = nil
var gMult3Icon: UnsafeMutablePointer<SDL_Surface> = nil
var gMult4Icon: UnsafeMutablePointer<SDL_Surface> = nil
var gMult5Icon: UnsafeMutablePointer<SDL_Surface> = nil
var gLuckOfTheIrishIcon: UnsafeMutablePointer<SDL_Surface> = nil
var gLongFireIcon: UnsafeMutablePointer<SDL_Surface> = nil
var gTripleFireIcon: UnsafeMutablePointer<SDL_Surface> = nil
var gKeyIcon: UnsafeMutablePointer<SDL_Surface> = nil
var gShieldIcon: UnsafeMutablePointer<SDL_Surface> = nil

var gRock1R: Blit!
var gRock2R: Blit!
var gRock3R: Blit!
var gDamagedShip: Blit!
var gRock1L: Blit!
var gRock2L: Blit!
var gRock3L: Blit!
var gShipExplosion: Blit!
var gPlayerShip: Blit!
var gExplosion: Blit!
var gNova: Blit!
var gEnemyShip: Blit!
var gEnemyShip2: Blit!
var gSteelRoidL: Blit!
var gSteelRoidR: Blit!
var gPrize: Blit!
var gBonusBlit: Blit!
var gPointBlit: Blit!
var gVortexBlit: Blit!
var gMineBlitL: Blit!
var gMineBlitR: Blit!
var gShieldBlit: Blit!
var gThrust1: Blit!
var gThrust2: Blit!
var gShrapnel1: Blit!
var gShrapnel2: Blit!
var gMult = [Blit]()


/// Put up an Ambrosia Software splash screen
private func doSplash() {
	
}

///Put up our intro splash screen
private func doIntroScreen() {
	
}

func drawLoadBar(aVar: Int) {
	
}

///Load in the blits
private func loadBlits(spriteres: MacResource) throws {
	
	drawLoadBar(1);
	
		/* -- Load in the thrusters */
		
		gThrust1 = try Blit(smallSprite: (), resource: spriteres, baseID: 400, frames: SHIP_FRAMES)
		drawLoadBar(0);
		
		gThrust2 = try Blit(smallSprite: (), resource: spriteres, baseID: 500, frames: SHIP_FRAMES)
		drawLoadBar(0);
		
		/* -- Load in the player's ship */
		
		gPlayerShip = try Blit(largeSprite: (), resource: spriteres, baseID: 500, frames: SHIP_FRAMES)
		drawLoadBar(0);
		
		/* -- Load in the large rock */
		
		gRock1R = try Blit(largeSprite: (), resource: spriteres, baseID: 500, frames: 60)
		gRock1L = gRock1R.backwardsSprite()
		drawLoadBar(0);
		
		/* -- Load in the medium rock */
		
		gRock2R = try Blit(largeSprite: (), resource: spriteres, baseID: 500, frames: 60)
		gRock2L = gRock2R.backwardsSprite()
		drawLoadBar(0);
		
		/* -- Load in the small rock */
		
		gRock3R = try Blit(smallSprite: (), resource: spriteres, baseID: 300, frames: 20)
		gRock3L = gRock3R.backwardsSprite()
		drawLoadBar(0);
		
		/* -- Load in the explosion */
		
		gExplosion = try Blit(largeSprite: (), resource: spriteres, baseID: 600, frames: 12)
		drawLoadBar(0);
		
		/* -- Load in the 2x multiplier */
		
		gMult.append(try Blit(largeSprite: (), resource: spriteres, baseID: 2000, frames: 1))
		drawLoadBar(0);
		
		/* -- Load in the 3x multiplier */
		
		gMult.append(try Blit(largeSprite: (), resource: spriteres, baseID: 2003, frames: 1))
		drawLoadBar(0);
		
		/* -- Load in the 4x multiplier */
		
		gMult.append(try Blit(largeSprite: (), resource: spriteres, baseID: 2004, frames: 1))
		drawLoadBar(0);
		
		/* -- Load in the 5x multiplier */
		
		gMult.append(try Blit(largeSprite: (), resource: spriteres, baseID: 2006, frames: 1))
		drawLoadBar(0);
		
		/* -- Load in the steel asteroid */
		
		gSteelRoidL = try Blit(largeSprite: (), resource: spriteres, baseID: 700, frames: 40)
		gSteelRoidR = gSteelRoidL.backwardsSprite()
		drawLoadBar(0);
		
		/* -- Load in the prize */
		gPrize = try Blit(largeSprite: (), resource: spriteres, baseID: 800, frames: 30)
		drawLoadBar(0);
		
		/* -- Load in the bonus */
		
		gBonusBlit = try Blit(largeSprite: (), resource: spriteres, baseID: 900, frames: 10)
		drawLoadBar(0);
		
		/* -- Load in the bonus */
		
		gPointBlit = try Blit(largeSprite: (), resource: spriteres, baseID: 1000, frames: 6)
		drawLoadBar(0);
		
		/* -- Load in the vortex */
		
		gVortexBlit = try Blit(largeSprite: (), resource: spriteres, baseID: 1100, frames: 10)
		drawLoadBar(0);
		
		/* -- Load in the homing mine */
		
		gMineBlitR = try Blit(largeSprite: (), resource: spriteres, baseID: 1200, frames: 40)
		gMineBlitL = gMineBlitR.backwardsSprite()
		drawLoadBar(0);
		
		/* -- Load in the shield */
		
		gShieldBlit = try Blit(largeSprite: (), resource: spriteres, baseID: 1300, frames: 2)
		drawLoadBar(0);
		
		/* -- Load in the nova */
		
		gNova = try Blit(largeSprite: (), resource: spriteres, baseID: 1400, frames: 18)
		drawLoadBar(0);
		
		/* -- Load in the ship explosion */
		
		gShipExplosion = try Blit(largeSprite: (), resource: spriteres, baseID: 1500, frames: 21)
		drawLoadBar(0);
		
		/* -- Load in the shrapnel */
		gShrapnel1 = try Blit(largeSprite: (), resource: spriteres, baseID: 1800, frames: 50)
		
		drawLoadBar(0);
		
		gShrapnel2 = try Blit(largeSprite: (), resource: spriteres, baseID: 1900, frames: 42)
		drawLoadBar(0);
		
		/* -- Load in the damaged ship */
		
		gDamagedShip = try Blit(largeSprite: (), resource: spriteres, baseID: 1600, frames: 10)
		drawLoadBar(0);
		
		/* -- Load in the enemy ship */
		
		gEnemyShip2 = try Blit(largeSprite: (), resource: spriteres, baseID: 1700, frames: 40)
		drawLoadBar(0);
		
		/* -- Load in the enemy ship */
		
		gEnemyShip2 = try Blit(largeSprite: (), resource: spriteres, baseID: 2100, frames: 40)
		drawLoadBar(0);
}

private func loadCICNS() -> Bool {
	gAutoFireIcon = getCIcon(screen, cicn_id: 128)
	if gAutoFireIcon == nil {
		return false;
	}
	gAirBrakesIcon = getCIcon(screen, cicn_id: 129)
	if gAirBrakesIcon == nil {
		return false
	}
	gMult2Icon = getCIcon(screen, cicn_id: 130)
	if gMult2Icon == nil {
		return false
	}
	gMult3Icon = getCIcon(screen, cicn_id: 131)
	if gMult3Icon == nil {
		return false
	}
	gMult4Icon = getCIcon(screen, cicn_id: 132)
	if gMult4Icon == nil {
		return false
	}
	gMult5Icon = getCIcon(screen, cicn_id: 134)
	if gMult5Icon == nil {
		return false
	}
	gLuckOfTheIrishIcon = getCIcon(screen, cicn_id: 133)
	if gLuckOfTheIrishIcon == nil {
		return false
	}
	gTripleFireIcon = getCIcon(screen, cicn_id: 135)
	if gTripleFireIcon == nil {
		return false
	}
	gLongFireIcon = getCIcon(screen, cicn_id: 136)
	if gLongFireIcon == nil {
		return false
	}
	gShieldIcon = getCIcon(screen, cicn_id: 137)
	if gShieldIcon == nil {
		return false
	}
	gKeyIcon = getCIcon(screen, cicn_id: 100)
	if gKeyIcon == nil {
		return false
	}
	
	return true;
}

///Initialize the stars
private func initStars() {
	
}

private func initSprites() -> Bool {
	/* Initialize sprite variables */
	//gNumSprites = 0;
	//gLastDrawn = 0L;
	
	/* Initialize player sprites */
	return(initPlayerSprites());
}

///Build the ship's velocity table
private func initShots() {
	gShotOrigins = [MPoint](count: Int(SHIP_FRAMES), repeatedValue: MPoint())
	gThrustOrigins = [MPoint](count: Int(SHIP_FRAMES), repeatedValue: MPoint())
	let xx: Int32 = 30;
	
	/* Load the shot images */
	var playerColors = Player.playerShotColors
	gPlayerShot = screen.loadImage(w: UInt16(SHOT_SIZE),h: UInt16(SHOT_SIZE), pixels: &playerColors);
	playerColors = Player.enemyShotColors
	gEnemyShot = screen.loadImage(w: UInt16(SHOT_SIZE), h: UInt16(SHOT_SIZE), pixels: &playerColors);
	
	/* Now setup the shot origin table */
	
	gShotOrigins[0].h = 15 * SCALE_FACTOR;
	gShotOrigins[0].v = 12 * SCALE_FACTOR;
	
	gShotOrigins[1].h = 16 * SCALE_FACTOR;
	gShotOrigins[1].v = 12 * SCALE_FACTOR;
	
	gShotOrigins[2].h = 18 * SCALE_FACTOR;
	gShotOrigins[2].v = 12 * SCALE_FACTOR;
	
	gShotOrigins[3].h = 21 * SCALE_FACTOR;
	gShotOrigins[3].v = 12 * SCALE_FACTOR;
	
	gShotOrigins[4].h = xx * SCALE_FACTOR;
	gShotOrigins[4].v = xx * SCALE_FACTOR;
	
	gShotOrigins[5].h = xx * SCALE_FACTOR;
	gShotOrigins[5].v = xx * SCALE_FACTOR;
	
	gShotOrigins[6].h = xx * SCALE_FACTOR;
	gShotOrigins[6].v = xx * SCALE_FACTOR;
	
	gShotOrigins[7].h = xx * SCALE_FACTOR;
	gShotOrigins[7].v = xx * SCALE_FACTOR;
	
	gShotOrigins[8].h = xx * SCALE_FACTOR;
	gShotOrigins[8].v = xx * SCALE_FACTOR;
	
	gShotOrigins[9].h = xx * SCALE_FACTOR;
	gShotOrigins[9].v = xx * SCALE_FACTOR;
	
	gShotOrigins[10].h = xx * SCALE_FACTOR;
	gShotOrigins[10].v = xx * SCALE_FACTOR;
	
	gShotOrigins[11].h = xx * SCALE_FACTOR;
	gShotOrigins[11].v = xx * SCALE_FACTOR;
	
	gShotOrigins[12].h = xx * SCALE_FACTOR;
	gShotOrigins[12].v = xx * SCALE_FACTOR;
	
	gShotOrigins[13].h = xx * SCALE_FACTOR;
	gShotOrigins[13].v = xx * SCALE_FACTOR;
	
	gShotOrigins[14].h = xx * SCALE_FACTOR;
	gShotOrigins[14].v = xx * SCALE_FACTOR;
	
	gShotOrigins[15].h = xx * SCALE_FACTOR;
	gShotOrigins[15].v = xx * SCALE_FACTOR;
	
	gShotOrigins[16].h = xx * SCALE_FACTOR;
	gShotOrigins[16].v = xx * SCALE_FACTOR;
	
	gShotOrigins[17].h = xx * SCALE_FACTOR;
	gShotOrigins[17].v = xx * SCALE_FACTOR;
	
	gShotOrigins[18].h = xx * SCALE_FACTOR;
	gShotOrigins[18].v = xx * SCALE_FACTOR;
	
	gShotOrigins[19].h = xx * SCALE_FACTOR;
	gShotOrigins[19].v = xx * SCALE_FACTOR;
	
	gShotOrigins[20].h = xx * SCALE_FACTOR;
	gShotOrigins[20].v = xx * SCALE_FACTOR;
	
	gShotOrigins[21].h = xx * SCALE_FACTOR;
	gShotOrigins[21].v = xx * SCALE_FACTOR;
	
	gShotOrigins[22].h = xx * SCALE_FACTOR;
	gShotOrigins[22].v = xx * SCALE_FACTOR;
	
	gShotOrigins[23].h = xx * SCALE_FACTOR;
	gShotOrigins[23].v = xx * SCALE_FACTOR;
	
	gShotOrigins[24].h = xx * SCALE_FACTOR;
	gShotOrigins[24].v = xx * SCALE_FACTOR;
	
	gShotOrigins[25].h = xx * SCALE_FACTOR;
	gShotOrigins[25].v = xx * SCALE_FACTOR;
	
	gShotOrigins[26].h = xx * SCALE_FACTOR;
	gShotOrigins[26].v = xx * SCALE_FACTOR;
	
	gShotOrigins[27].h = xx * SCALE_FACTOR;
	gShotOrigins[27].v = xx * SCALE_FACTOR;
	
	gShotOrigins[28].h = xx * SCALE_FACTOR;
	gShotOrigins[28].v = xx * SCALE_FACTOR;
	
	gShotOrigins[29].h = xx * SCALE_FACTOR;
	gShotOrigins[29].v = xx * SCALE_FACTOR;
	
	gShotOrigins[30].h = xx * SCALE_FACTOR;
	gShotOrigins[30].v = xx * SCALE_FACTOR;
	
	gShotOrigins[31].h = xx * SCALE_FACTOR;
	gShotOrigins[31].v = xx * SCALE_FACTOR;
	
	gShotOrigins[32].h = xx * SCALE_FACTOR;
	gShotOrigins[32].v = xx * SCALE_FACTOR;
	
	gShotOrigins[33].h = xx * SCALE_FACTOR;
	gShotOrigins[33].v = xx * SCALE_FACTOR;
	
	gShotOrigins[34].h = xx * SCALE_FACTOR;
	gShotOrigins[34].v = xx * SCALE_FACTOR;
	
	gShotOrigins[35].h = xx * SCALE_FACTOR;
	gShotOrigins[35].v = xx * SCALE_FACTOR;
	
	gShotOrigins[36].h = xx * SCALE_FACTOR;
	gShotOrigins[36].v = xx * SCALE_FACTOR;
	
	gShotOrigins[37].h = xx * SCALE_FACTOR;
	gShotOrigins[37].v = xx * SCALE_FACTOR;
	
	gShotOrigins[38].h = xx * SCALE_FACTOR;
	gShotOrigins[38].v = xx * SCALE_FACTOR;
	
	gShotOrigins[39].h = xx * SCALE_FACTOR;
	gShotOrigins[39].v = xx * SCALE_FACTOR;
	
	gShotOrigins[40].h = xx * SCALE_FACTOR;
	gShotOrigins[40].v = xx * SCALE_FACTOR;
	
	gShotOrigins[41].h = xx * SCALE_FACTOR;
	gShotOrigins[41].v = xx * SCALE_FACTOR;
	
	gShotOrigins[42].h = xx * SCALE_FACTOR;
	gShotOrigins[42].v = xx * SCALE_FACTOR;
	
	gShotOrigins[43].h = xx * SCALE_FACTOR;
	gShotOrigins[43].v = xx * SCALE_FACTOR;
	
	gShotOrigins[44].h = xx * SCALE_FACTOR;
	gShotOrigins[44].v = xx * SCALE_FACTOR;
	
	gShotOrigins[45].h = xx * SCALE_FACTOR;
	gShotOrigins[45].v = xx * SCALE_FACTOR;
	
	gShotOrigins[46].h = xx * SCALE_FACTOR;
	gShotOrigins[46].v = xx * SCALE_FACTOR;
	
	gShotOrigins[47].h = xx * SCALE_FACTOR;
	gShotOrigins[47].v = xx * SCALE_FACTOR;
	
	/* -- Now setup the thruster origin table */
	
	gThrustOrigins[0].h = 8 * SCALE_FACTOR;
	gThrustOrigins[0].v = 22 * SCALE_FACTOR;
	
	gThrustOrigins[1].h = 6 * SCALE_FACTOR;
	gThrustOrigins[1].v = 22 * SCALE_FACTOR;
	
	gThrustOrigins[2].h = 4 * SCALE_FACTOR;
	gThrustOrigins[2].v = 21 * SCALE_FACTOR;
	
	gThrustOrigins[3].h = 1 * SCALE_FACTOR;
	gThrustOrigins[3].v = 20 * SCALE_FACTOR;
	
	gThrustOrigins[4].h = 0 * SCALE_FACTOR;
	gThrustOrigins[4].v = 19 * SCALE_FACTOR;
	
	gThrustOrigins[5].h = -1 * SCALE_FACTOR;
	gThrustOrigins[5].v = 19 * SCALE_FACTOR;
	
	gThrustOrigins[6].h = -3 * SCALE_FACTOR;
	gThrustOrigins[6].v = 16 * SCALE_FACTOR;
	
	gThrustOrigins[7].h = -5 * SCALE_FACTOR;
	gThrustOrigins[7].v = 15 * SCALE_FACTOR;
	
	gThrustOrigins[8].h = -6 * SCALE_FACTOR;
	gThrustOrigins[8].v = 13 * SCALE_FACTOR;
	
	gThrustOrigins[9].h = -9 * SCALE_FACTOR;
	gThrustOrigins[9].v = 11 * SCALE_FACTOR;
	
	gThrustOrigins[10].h = -10 * SCALE_FACTOR;
	gThrustOrigins[10].v = 10 * SCALE_FACTOR;
	
	gThrustOrigins[11].h = -11 * SCALE_FACTOR;
	gThrustOrigins[11].v = 7 * SCALE_FACTOR;
	
	gThrustOrigins[12].h = -9 * SCALE_FACTOR;
	gThrustOrigins[12].v = 7 * SCALE_FACTOR;
	
	gThrustOrigins[13].h = -9 * SCALE_FACTOR;
	gThrustOrigins[13].v = 4 * SCALE_FACTOR;
	
	gThrustOrigins[14].h = -7 * SCALE_FACTOR;
	gThrustOrigins[14].v = 2 * SCALE_FACTOR;
	
	gThrustOrigins[15].h = -6 * SCALE_FACTOR;
	gThrustOrigins[15].v = 0 * SCALE_FACTOR;
	
	gThrustOrigins[16].h = -9 * SCALE_FACTOR;
	gThrustOrigins[16].v = 1 * SCALE_FACTOR;
	
	gThrustOrigins[17].h = -3 * SCALE_FACTOR;
	gThrustOrigins[17].v = -3 * SCALE_FACTOR;
	
	gThrustOrigins[18].h = -1 * SCALE_FACTOR;
	gThrustOrigins[18].v = -2 * SCALE_FACTOR;
	
	gThrustOrigins[19].h = 0 * SCALE_FACTOR;
	gThrustOrigins[19].v = -4 * SCALE_FACTOR;
	
	gThrustOrigins[20].h = 4 * SCALE_FACTOR;
	gThrustOrigins[20].v = -6 * SCALE_FACTOR;
	
	gThrustOrigins[21].h = 5 * SCALE_FACTOR;
	gThrustOrigins[21].v = -8 * SCALE_FACTOR;
	
	gThrustOrigins[22].h = 5 * SCALE_FACTOR;
	gThrustOrigins[22].v = -6 * SCALE_FACTOR;
	
	gThrustOrigins[23].h = 8 * SCALE_FACTOR;
	gThrustOrigins[23].v = -7 * SCALE_FACTOR;
	
	gThrustOrigins[24].h = 9 * SCALE_FACTOR;
	gThrustOrigins[24].v = -7 * SCALE_FACTOR;
	
	gThrustOrigins[25].h = 12 * SCALE_FACTOR;
	gThrustOrigins[25].v = -6 * SCALE_FACTOR;
	
	gThrustOrigins[26].h = 13 * SCALE_FACTOR;
	gThrustOrigins[26].v = -6 * SCALE_FACTOR;
	
	gThrustOrigins[27].h = 15 * SCALE_FACTOR;
	gThrustOrigins[27].v = -7 * SCALE_FACTOR;
	
	gThrustOrigins[28].h = 17 * SCALE_FACTOR;
	gThrustOrigins[28].v = -6 * SCALE_FACTOR;
	
	gThrustOrigins[29].h = 18 * SCALE_FACTOR;
	gThrustOrigins[29].v = -4 * SCALE_FACTOR;
	
	gThrustOrigins[30].h = 20 * SCALE_FACTOR;
	gThrustOrigins[30].v = -2 * SCALE_FACTOR;
	
	gThrustOrigins[31].h = 19 * SCALE_FACTOR;
	gThrustOrigins[31].v = -1 * SCALE_FACTOR;
	
	gThrustOrigins[32].h = 21 * SCALE_FACTOR;
	gThrustOrigins[32].v = 0 * SCALE_FACTOR;
	
	gThrustOrigins[33].h = 22 * SCALE_FACTOR;
	gThrustOrigins[33].v = 2 * SCALE_FACTOR;
	
	gThrustOrigins[34].h = 24 * SCALE_FACTOR;
	gThrustOrigins[34].v = 3 * SCALE_FACTOR;
	
	gThrustOrigins[35].h = 25 * SCALE_FACTOR;
	gThrustOrigins[35].v = 5 * SCALE_FACTOR;
	
	gThrustOrigins[36].h = 26 * SCALE_FACTOR;
	gThrustOrigins[36].v = 7 * SCALE_FACTOR;
	
	gThrustOrigins[37].h = 25 * SCALE_FACTOR;
	gThrustOrigins[37].v = 7 * SCALE_FACTOR;
	
	gThrustOrigins[38].h = 24 * SCALE_FACTOR;
	gThrustOrigins[38].v = 10 * SCALE_FACTOR;
	
	gThrustOrigins[39].h = 23 * SCALE_FACTOR;
	gThrustOrigins[39].v = 11 * SCALE_FACTOR;
	
	gThrustOrigins[40].h = 23 * SCALE_FACTOR;
	gThrustOrigins[40].v = 12 * SCALE_FACTOR;
	
	gThrustOrigins[41].h = 20 * SCALE_FACTOR;
	gThrustOrigins[41].v = 14 * SCALE_FACTOR;
	
	gThrustOrigins[42].h = 20 * SCALE_FACTOR;
	gThrustOrigins[42].v = 16 * SCALE_FACTOR;
	
	gThrustOrigins[43].h = 18 * SCALE_FACTOR;
	gThrustOrigins[43].v = 18 * SCALE_FACTOR;
	
	gThrustOrigins[44].h = 15 * SCALE_FACTOR;
	gThrustOrigins[44].v = 18 * SCALE_FACTOR;
	
	gThrustOrigins[45].h = 15 * SCALE_FACTOR;
	gThrustOrigins[45].v = 20 * SCALE_FACTOR;
	
	gThrustOrigins[46].h = 12 * SCALE_FACTOR;
	gThrustOrigins[46].v = 21 * SCALE_FACTOR;
	
	gThrustOrigins[47].h = 9 * SCALE_FACTOR;
	gThrustOrigins[47].v = 22 * SCALE_FACTOR;
	
}

private func buildVelocityTable() {
	gVelocityTable = [MPoint](count: Int(SHIP_FRAMES), repeatedValue: MPoint())
	#if COMPUTE_VELTABLE || !MULTIPLAYER_SUPPORT
		/* Calculate the appropriate values */
		
		var ss = Double(SHIP_FRAMES)
		let factor = (360.0 / ss);
		
		for index in 0..<Int(SHIP_FRAMES) {
			ss = Double(index)
			ss = -(((ss * factor) * M_PI) / 180.0)
			gVelocityTable[index].h = Int32(sin(ss) * -8.0)
			gVelocityTable[index].v = Int32(cos(ss) * -8.0)
			//let a = MPoint(h: Int32(sin(ss) * -8.0), v: Int32(cos(ss) * -8.0))
			#if PRINT_TABLE
				printf("\tgVelocityTable[%d].h = %d;\n", index,
					gVelocityTable[index].h);
				printf("\tgVelocityTable[%d].v = %d;\n", index,
					gVelocityTable[index].v);
			#endif
		}
	#else
		/* Because PI, sin() and cos() return _slightly_ different
		values across architectures, we need to precompute our
		velocity table -- make it standard across compilations. :)
		*/
		gVelocityTable[0].h = 0;
		gVelocityTable[0].v = -8;
		gVelocityTable[1].h = 1;
		gVelocityTable[1].v = -7;
		gVelocityTable[2].h = 2;
		gVelocityTable[2].v = -7;
		gVelocityTable[3].h = 3;
		gVelocityTable[3].v = -7;
		gVelocityTable[4].h = 4;
		gVelocityTable[4].v = -6;
		gVelocityTable[5].h = 4;
		gVelocityTable[5].v = -6;
		gVelocityTable[6].h = 5;
		gVelocityTable[6].v = -5;
		gVelocityTable[7].h = 6;
		gVelocityTable[7].v = -4;
		gVelocityTable[8].h = 6;
		gVelocityTable[8].v = -4;
		gVelocityTable[9].h = 7;
		gVelocityTable[9].v = -3;
		gVelocityTable[10].h = 7;
		gVelocityTable[10].v = -2;
		gVelocityTable[11].h = 7;
		gVelocityTable[11].v = -1;
		gVelocityTable[12].h = 8;
		gVelocityTable[12].v = 0;
		gVelocityTable[13].h = 7;
		gVelocityTable[13].v = 1;
		gVelocityTable[14].h = 7;
		gVelocityTable[14].v = 2;
		gVelocityTable[15].h = 7;
		gVelocityTable[15].v = 3;
		gVelocityTable[16].h = 6;
		gVelocityTable[16].v = 3;
		gVelocityTable[17].h = 6;
		gVelocityTable[17].v = 4;
		gVelocityTable[18].h = 5;
		gVelocityTable[18].v = 5;
		gVelocityTable[19].h = 4;
		gVelocityTable[19].v = 6;
		gVelocityTable[20].h = 3;
		gVelocityTable[20].v = 6;
		gVelocityTable[21].h = 3;
		gVelocityTable[21].v = 7;
		gVelocityTable[22].h = 2;
		gVelocityTable[22].v = 7;
		gVelocityTable[23].h = 1;
		gVelocityTable[23].v = 7;
		gVelocityTable[24].h = 0;
		gVelocityTable[24].v = 8;
		gVelocityTable[25].h = -1;
		gVelocityTable[25].v = 7;
		gVelocityTable[26].h = -2;
		gVelocityTable[26].v = 7;
		gVelocityTable[27].h = -3;
		gVelocityTable[27].v = 7;
		gVelocityTable[28].h = -4;
		gVelocityTable[28].v = 6;
		gVelocityTable[29].h = -4;
		gVelocityTable[29].v = 6;
		gVelocityTable[30].h = -5;
		gVelocityTable[30].v = 5;
		gVelocityTable[31].h = -6;
		gVelocityTable[31].v = 4;
		gVelocityTable[32].h = -6;
		gVelocityTable[32].v = 4;
		gVelocityTable[33].h = -7;
		gVelocityTable[33].v = 3;
		gVelocityTable[34].h = -7;
		gVelocityTable[34].v = 2;
		gVelocityTable[35].h = -7;
		gVelocityTable[35].v = 1;
		gVelocityTable[36].h = -8;
		gVelocityTable[36].v = 0;
		gVelocityTable[37].h = -7;
		gVelocityTable[37].v = -1;
		gVelocityTable[38].h = -7;
		gVelocityTable[38].v = -2;
		gVelocityTable[39].h = -7;
		gVelocityTable[39].v = -3;
		gVelocityTable[40].h = -6;
		gVelocityTable[40].v = -4;
		gVelocityTable[41].h = -6;
		gVelocityTable[41].v = -4;
		gVelocityTable[42].h = -5;
		gVelocityTable[42].v = -5;
		gVelocityTable[43].h = -4;
		gVelocityTable[43].v = -6;
		gVelocityTable[44].h = -4;
		gVelocityTable[44].v = -6;
		gVelocityTable[45].h = -3;
		gVelocityTable[45].v = -7;
		gVelocityTable[46].h = -2;
		gVelocityTable[46].v = -7;
		gVelocityTable[47].h = -1;
		gVelocityTable[47].v = -7;
	#endif
}

///Perform some initializations and report failure if we choke
func doInitializations(video_flags: SDL_WindowFlags) -> Bool {
	let library = LibPath()
	//int i;
	var icon: UnsafeMutablePointer<SDL_Surface>
	
	/* Make sure we clean up properly at exit */
	var init_flags = (SDL_INIT_VIDEO|SDL_INIT_AUDIO);
	//#ifdef SDL_INIT_JOYSTICK
	init_flags |= SDL_INIT_JOYSTICK;
	//#endif
	if SDL_Init(UInt32(init_flags)) < 0 {
		init_flags &= ~SDL_INIT_JOYSTICK;
		if SDL_Init(UInt32(init_flags)) < 0 {
			error("Couldn't initialize SDL: \(String.fromCString(SDL_GetError())!)");
			return false;
		}
	}
	atexit { () -> Void in
		haltLogic();
		saveControls();
		SDL_Quit();
	}
	signal(SIGSEGV, exit);
	
	// -- Initialize some variables
	gLastHigh = -1;
	
	// -- Create our scores file
	hScores.loadScores();
	
	//#ifdef SDL_INIT_JOYSTICK
	/* Initialize the first joystick */
	if ( SDL_NumJoysticks() > 0 ) {
		if ( SDL_JoystickOpen(0) == nil ) {
			print("Warning: Couldn't open joystick '\(String.fromCString(SDL_JoystickName(nil))!)' : \(String.fromCString(SDL_GetError())!)")
		}
	}
	//#endif
	
	/* Load the Font Server */
	do {
		fontserv = try FontServer(fontAtURL: library.path("Maelstrom Fonts")!)
	} catch {
		fatalError("Fatal: \(error)")
		//return false
	}
	
	/* Load the Sound Server and initialize sound */
	do {
		sound = try Sound(soundFileURL: library.path("Maelstrom Sounds")!, volume: gSoundLevel);
	} catch {
		fatalError("Fatal: \(error)")
		//return false
	}
	
	/* Load the Maelstrom icon */
	icon = SDL_LoadBMP(library.path("icon.bmp")!.fileSystemRepresentation);
	if icon == nil {
		print("Fatal: Couldn't load icon: \(String.fromCString(SDL_GetError())!)");
		return false;
	}
	
	/* Initialize the screen */
	do {
		screen = try FrameBuf(width: Int32(SCREEN_WIDTH), height: Int32(SCREEN_HEIGHT), videoFlags: video_flags.rawValue, colors: colorsAtGamma(Int32(gGammaCorrect)), icon: icon)
	} catch {
		fatalError("\(error)")
	}
	screen.caption = "Maelstrom"
	//atexit(CleanUp);		// Need to reset this under X11 DGA
	SDL_FreeSurface(icon);
	
	/* -- We want to access the FULL screen! */
	setRect(&gScrnRect, 0, 0, Int32(SCREEN_WIDTH), Int32(SCREEN_HEIGHT));
	gStatusLine = Int32(Int(gScrnRect.bottom - gScrnRect.top) - STATUS_HEIGHT);
	gScrnRect.bottom -= STATUS_HEIGHT;
	gTop = 0;
	gLeft = 0;
	gBottom = Int32(gScrnRect.bottom - gScrnRect.top)
	gRight = Int32(gScrnRect.right - gScrnRect.left)
	
	gClipRect.x = gLeft+SPRITES_WIDTH;
	gClipRect.y = gTop+SPRITES_WIDTH;
	gClipRect.w = gRight-gLeft-2*SPRITES_WIDTH;
	gClipRect.h = gBottom-gTop-2*SPRITES_WIDTH+STATUS_HEIGHT;
	screen.clipBlit(gClipRect);
	
	/* Do the Ambrosia Splash screen */
	screen.clear();
	screen.update();
	screen.fade();
	doSplash();
	screen.fade();
	for _ in 0..<5 {
		if ( dropEvents() != 0 ) {
			break;
		}
		Delay(60);
	}
	
	/* -- Throw up our intro screen */
	screen.fade();
	doIntroScreen();
	sound.playSound(.PrizeAppears, priority: 1);
	screen.fade();
	
	/* -- Load in our sprites and other needed resources */
	do {
		do {
			let spriteres = try MacResource(fileURL: library.path("Maelstrom Sprites")!)
			try loadBlits(spriteres)
		} catch {
			print(error)
			return false
		}
		
	}
	
	/* -- Create the shots array */
	initShots();
	
	/* -- Initialize the sprite manager - after we load blits and shots! */
	if !initSprites() {
		return false
	}
	
	/* -- Load in the prize CICN's */
	if !loadCICNS() {
		return false
	}
	
	/* -- Create the stars array */
	initStars();
	
	/* -- Set up the velocity tables */
	buildVelocityTable();
	
	return true;
}
