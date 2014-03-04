
#include <stdlib.h>

#include "screenlib/SDL_FrameBuf.h"
#include "maclib/Mac_FontServ.h"
#include "maclib/Mac_Compat.h"

#include "Maelstrom.h"

#include "myerror.h"
#include "fastrand.h"
#include "logic.h"
#include "scores.h"
#include "controls.h"
#include "sound.h"


// The Font Server :)
extern FontServ *fontserv;

// The Sound Server *grin*
extern Maelstrom::Sound *sound;

// The SCREEN!! :)
extern FrameBuf *screen;

/* Boolean type */
typedef Uint8 Bool;
#define true	1
#define false	0

// Functions from main.cc
extern void   PrintUsage(void);
extern int    DrawText(int x, int y, char *text, MFont *font, Uint8 style,
						Uint8 R, Uint8 G, Uint8 B);
extern void   Message(char *message);

// Functions from init.cc
extern void  SetStar(int which);

// External variables...
// in main.cc : 
extern Bool	gUpdateBuffer;
extern Bool	gRunning;
extern int	gNoDelay;

// in init.cc : 
extern Sint32	gLastHigh;
extern Rect	gScrnRect;
extern SDL_Rect	gClipRect;
extern int	gStatusLine;
extern int	gTop, gLeft, gBottom, gRight;
extern MPoint	gShotOrigins[SHIP_FRAMES];
extern MPoint	gThrustOrigins[SHIP_FRAMES];
extern MPoint	gVelocityTable[SHIP_FRAMES];
extern StarPtr	gTheStars[MAX_STARS];
extern Uint32	gStarColors[];
// in controls.cc :
extern Controls	controls;
extern Uint8	gSoundLevel;
extern Uint8	gGammaCorrect;
// int scores.cc :
extern Scores	hScores[];

// -- Variables specific to each game 
// in main.cc : 
extern int	gStartLives;
extern int	gStartLevel;
// in init.cc : 
extern Uint32	gLastDrawn;
extern int	gNumSprites;

/* -- The blit'ers we use */
extern BlitPtr	gRock1R, gRock2R, gRock3R, gDamagedShip;
extern BlitPtr	gRock1L, gRock2L, gRock3L, gShipExplosion;
extern BlitPtr	gPlayerShip, gExplosion, gNova, gEnemyShip, gEnemyShip2;
extern BlitPtr	gMult[], gSteelRoidL;
extern BlitPtr	gSteelRoidR, gPrize, gBonusBlit, gPointBlit;
extern BlitPtr	gVortexBlit, gMineBlitL, gMineBlitR, gShieldBlit;
extern BlitPtr	gThrust1, gThrust2, gShrapnel1, gShrapnel2;

/* -- The prize CICN's */

extern SDL_Surface *gAutoFireIcon, *gAirBrakesIcon, *gMult2Icon, *gMult3Icon;
extern SDL_Surface *gMult4Icon, *gMult5Icon, *gLuckOfTheIrishIcon;
extern SDL_Surface *gLongFireIcon, *gTripleFireIcon, *gKeyIcon, *gShieldIcon;
