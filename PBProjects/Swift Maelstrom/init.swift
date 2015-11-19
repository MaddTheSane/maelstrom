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

/// Put up an Ambrosia Software splash screen
private func doSplash() {
	
}

///Put up our intro splash screen
private func doIntroScreen() {
	
}

///Load in the blits
private func loadBlits(spriteres: Mac_Resource) -> Bool {
	
	
	return false
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
	if ( SDL_Init(UInt32(init_flags)) < 0 ) {
		init_flags &= ~SDL_INIT_JOYSTICK;
		if ( SDL_Init(UInt32(init_flags)) < 0 ) {
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
	screen = FrameBuf()
	/*
	if (screen->Init(SCREEN_WIDTH, SCREEN_HEIGHT, video_flags,
	colors[gGammaCorrect], icon) < 0){
	error("Fatal: %s\n", screen->Error());
	return(-1);
	}
	screen->SetCaption("Maelstrom");
	*/
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
		let spriteres = try Mac_Resource(fileURL: library.path("Maelstrom Sprites")!)

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
