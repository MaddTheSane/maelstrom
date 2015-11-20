//
//  init.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/11/15.
//
//

import Foundation

var gLastHigh: Int32 = 0

var gScrnRect = Rect()
var gClipRect = SDL_Rect()
var gStatusLine: Int32 = 0
var gTop: Int32 = 0
var gLeft: Int32 = 0
var gBottom: Int32 = 0
var gRight: Int32 = 0
//MPoint	gShotOrigins[SHIP_FRAMES];
//MPoint	gThrustOrigins[SHIP_FRAMES];
//MPoint	gVelocityTable[SHIP_FRAMES];
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
private func loadBlits(spriteres: MacResource) -> Bool {
	
	drawLoadBar(1);
	
	do {
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
		
		return true;
	} catch _ {
		return false
	}
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
	
	
	return false
}

private func initShots() {
	
}

private func buildVelocityTable() {
	
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

			if !loadBlits(spriteres) {
				return false;
			}
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
