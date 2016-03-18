//
//  Game.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/10/15.
//
//

import Foundation
import SDL2

// Global variables set in this file...
var	gGameOn = false
var	gPaused = false
var	gWave: Int32 = 0
var	gBoomDelay: Int32 = 0
var	gNextBoom: Int32 = 0
var	gBoomPhase: Int32 = 0
var	gNumRocks: Int32 = 0
var	gLastStar: Int32 = 0
var	gWhenDone: Int32 = 0
var	gDisplayed: Int32 = 0

var	gMultiplierShown = false
var	gPrizeShown = false
var	gBonusShown = false
var	gWhenHoming: Int32 = 0
var	gWhenGrav: Int32 = 0
var	gWhenDamaged: Int32 = 0
var	gWhenNova: Int32 = 0
var	gShakeTime: Int32 = 0
var	gFreezeTime: Int32 = 0
//Object *gEnemySprite;
var	gWhenEnemy: Int32 = 0


func newGame() {
	
}

private func doHouseKeeping() {
	/* Don't do anything if we're paused */
	if ( gPaused ) {
		/* Give up the CPU for a frame duration */
		Delay(UInt32(FRAME_DELAY))
		return;
	}

}

/*
static void DoHouseKeeping(void)
{

#ifdef MOVIE_SUPPORT
if ( gMovie )
win->ScreenDump("MovieFrame", &gMovieRect);
#endif
/* -- Maybe throw a multiplier up on the screen */
if (gMultiplierShown && (--gMultiplierShown == 0) )
MakeMultiplier();

/* -- Maybe throw a prize(!) up on the screen */
if (gPrizeShown && (--gPrizeShown == 0) )
MakePrize();

/* -- Maybe throw a bonus up on the screen */
if (gBonusShown && (--gBonusShown == 0) )
MakeBonus();

/* -- Maybe make a nasty enemy fighter? */
if (gWhenEnemy && (--gWhenEnemy == 0) )
MakeEnemy();

/* -- Maybe create a transcenfugal vortex */
if (gWhenGrav && (--gWhenGrav == 0) )
MakeGravity();

/* -- Maybe create a recified space vehicle */
if (gWhenDamaged && (--gWhenDamaged == 0) )
MakeDamagedShip();

/* -- Maybe create a autonominous tracking device */
if (gWhenHoming && (--gWhenHoming == 0) )
MakeHoming();

/* -- Maybe make a supercranial destruction thang */
if (gWhenNova && (--gWhenNova == 0) )
MakeNova();

/* -- Maybe create a new star ? */
if ( --gLastStar == 0 ) {
gLastStar = STAR_DELAY;
TwinkleStars();
}

/* -- Time for the next wave? */
if (gNumRocks == 0) {
if ( gWhenDone == 0 )
gWhenDone = DEAD_DELAY;
else if ( --gWhenDone == 0 )
NextWave();
}

/* -- Housekeping */
DrawStatus(false, false);
}
*/

/// Flash the stars on the screen
private func TwinkleStars() {
	let theStar = Int(FastRandom(UInt16(MAX_STARS)))
	
	/* -- Draw the star */
	screen.focusBG()
	screen.drawPoint(x: gTheStars[theStar].xCoord, y: gTheStars[theStar].yCoord, color: gTheStars[theStar].color)
	setStar(theStar)
	screen.drawPoint(x: gTheStars[theStar].xCoord, y: gTheStars[theStar].yCoord, color: gTheStars[theStar].color)
	screen.update(true);
	screen.focusFG();
}	/* -- TwinkleStars */


