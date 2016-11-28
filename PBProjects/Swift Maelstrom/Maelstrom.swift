//
//  mainClass.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/3/15.
//
//

import Foundation
import SDL2

private let Version = "Maelstrom v1.4.3 (GPL version 3.0.6) -- 10/19/2002 by Sam Lantinga\n"

func error(err: String, line: Int = #line, file: StaticString = #file) {
	print("\(file):\(line), \(err)")
}

// Sound resource definitions...
enum SoundResource: UInt16 {
	case Shot = 100
	case Multiplier
	case Explosion
	case ShipHit
	case Boom1
	case Boom2
	case MultiplierGone
	case MultShot
	case SteelHit
	case Bonk
	case Riff
	case PrizeAppears
	case GotPrize
	case GameOver
	case NewLife
	case BonusAppears
	case BonusShot
	case NoBonus
	case GravAppears
	case HomingAppears
	case ShieldOn
	case NoShield
	case NovaAppears
	case NovaBoom
	case Lucky
	case DamagedAppears
	case SavedShip
	case Funk
	case EnemyAppears
	case PrettyGood = 131
	case Thruster
	case EnemyFire
	case Freeze
	case Idiot
	case Pause
}

let MAX_SPRITE_FRAMES = 60

let SCREEN_WIDTH: UInt16 = 640
let SCREEN_HEIGHT: UInt16 = 480

let SOUND_DELAY:UInt32 = 6
let FADE_STEPS = 40

/// Time in 60'th of second between frames
let FRAME_DELAY = 2

let buttons = ButtonList()

let MAX_SPRITES			= 100
let MAX_STARS			= 30
let SHIP_FRAMES:Int32	= 48
let SPRITES_WIDTH		= 32
///internal <--> screen precision
let SPRITE_PRECISION	= 4
let VEL_FACTOR			= 4
let VEL_MAX				= Int32(8 << SPRITE_PRECISION)
let SCALE_FACTOR:Int32	= 16
let SHAKE_FACTOR		= 256
let MIN_BAD_DISTANCE	= 64

/// Sprite doesn't change phase
let NO_PHASE_CHANGE: Int32 = -1

let MAX_SHOTS			= 18
let SHOT_SIZE:Int32		= 4
let SHOT_SCALE_FACTOR	= 4

let STATUS_HEIGHT	= 14
let SHIELD_WIDTH	= 55
let INITIAL_BONUS	= 2000

let ENEMY_HITS: Int32	= 3
let HOMING_HITS			= 9
let STEEL_SPECIAL		= 10
let DEFAULT_HITS:Int32	= 1

let NEW_LIFE: Int32			= 50000
let SMALL_ROID_PTS: Int32	= 300
let MEDIUM_ROID_PTS: Int32	= 100
let BIG_ROID_PTS: Int32		= 50
let GRAVITY_PTS: Int32		= 500
let HOMING_PTS: Int32		= 700
let NOVA_PTS: Int32			= 1000
let STEEL_PTS: Int32		= 100
let ENEMY_PTS: Int32		= 1000

let HOMING_MOVE		= 6
let GRAVITY_MOVE	= 3

let BLUE_MOON	= 50
let MOON_FACTOR	= 4
let NUM_PRIZES	= 8
let LUCK_ODDS	= 3


//MARK: - Structures and typedefs

struct MPoint {
	var h: Int32 = 0
	var v: Int32 = 0
}

struct Star {
	var xCoord: Int16 = 0
	var yCoord: Int16 = 0
	var color: UInt32 = 0
}

typealias StarPtr = UnsafeMutablePointer<Star>

///Sprite blitting information structure
final class Blit {
	let isSmall: Bool
	private(set) var hitRect: Rect = Rect()
	private(set) var sprites: [(mask: [UInt8], sprite: UnsafeMutablePointer<SDL_Surface>)] = []

	private init(isSmall small: Bool) {
		isSmall = small
	}
	
	enum Errors: ErrorType {
		case CouldNotCreateImage
	}
	
	#if false
	deinit {
		for aSprite in sprites {
			screen.freeImage(aSprite.sprite)
		}
	}
	#endif
	
	func backwardsSprite() -> Blit {
		let reversed = Blit(isSmall: self.isSmall)
		
		reversed.hitRect = self.hitRect
		/* -- Reverse the sprite images */
		reversed.sprites = self.sprites.reverse()
		
		return reversed
	}

	init(smallSprite: (), resource spriteres: MacResource, baseID: Int32, frames numFrames: Int32) throws {
		isSmall = true
		
		var left = 16
		var right = 0
		var top = 16
		var bottom = 0
		
		for index in 0..<numFrames {
			let m = try spriteres.resource(type: MaelOSType(stringValue: "ics#")!, id: UInt16(baseID+index))
			var mask = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(m.bytes).advancedBy(32), count: 32))
			
			let S = try spriteres.resource(type: MaelOSType(stringValue: "ics8")!, id: UInt16(baseID+index))
			
			/* -- Figure out the hit rectangle */
			/* -- Do the top/left first */
			for row in 0..<16 {
				for col in 0..<16 {
					let offset = (row*16)+col;
					if ((mask[Int(offset/8)] >> UInt8(7-(offset%8))) & 0x01) == 0x01 {
						if row < top {
							top = row;
						}
						if col < left {
							left = col;
						}
					}
				}
			}
			for row in (top..<15).reverse() {
				for col in (left..<15).reverse() {
					let offset = (row*16)+col;
					if ((mask[offset/8] >> UInt8(7-(offset%8))) & 0x01) == 0x01 {
						if row > bottom {
							bottom = row;
						}
						if col > right {
							right = col;
						}
					}
				}
			}
			hitRect = Rect(top: Int16(top), left: Int16(left), bottom: Int16(bottom), right: Int16(right))
			
			/* Load the image */
			let aSprite = screen.loadImage(w: 16, h: 16, pixels: UnsafeMutablePointer<UInt8>(S.bytes), mask: &mask)
			guard aSprite != nil else {
				throw Errors.CouldNotCreateImage
			}
			
			/* Create the bytemask */
			let maskLen = (m.length - 32) * 8
			var blitMask = [UInt8](count: maskLen, repeatedValue: 0)
			for offset in 0 ..< m.length {
				blitMask[offset] =
					((mask[offset/8]>>UInt8(7-(offset%8)))&0x01);
			}
			sprites.append((mask: blitMask, sprite: aSprite))
		}
	}
	
	init(largeSprite: (), resource spriteres: MacResource, baseID: Int32, frames numFrames: Int32) throws {
		isSmall = true
		
		var left = 32
		var right = 0
		var top = 32
		var bottom = 0
		
		for index in 0..<numFrames {
			let m = try spriteres.resource(type: MaelOSType(stringValue: "ics#")!, id: UInt16(baseID+index))
			var mask = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(m.bytes).advancedBy(128), count: 128))
			
			let S = try spriteres.resource(type: MaelOSType(stringValue: "ics8")!, id: UInt16(baseID+index))
			
			/* -- Figure out the hit rectangle */
			/* -- Do the top/left first */
			for row in 0..<32 {
				for col in 0..<32 {
					let offset = (row*32)+col;
					if ((mask[Int(offset/8)] >> UInt8(7-(offset%8))) & 0x01) == 0x01 {
						if row < top {
							top = row;
						}
						if col < left {
							left = col;
						}
					}
				}
			}
			for row in (top..<31).reverse() {
				for col in (left..<31).reverse() {
					let offset = (row*32)+col;
					if ((mask[offset/8] >> UInt8(7-(offset%8))) & 0x01) == 0x01 {
						if row > bottom {
							bottom = row;
						}
						if col > right {
							right = col;
						}
					}
				}
			}
			hitRect = Rect(top: Int16(top), left: Int16(left), bottom: Int16(bottom), right: Int16(right))
			
			/* Load the image */
			let aSprite = screen.loadImage(w: 32, h: 32, pixels: UnsafeMutablePointer<UInt8>(S.bytes), mask: &mask)
			guard aSprite != nil else {
				throw Errors.CouldNotCreateImage
			}
			
			/* Create the bytemask */
			let maskLen = (m.length - 128) * 8
			var blitMask = [UInt8](count: maskLen, repeatedValue: 0)
			for offset in 0 ..< m.length {
				blitMask[offset] =
					((mask[offset/8]>>UInt8(7-(offset%8)))&0x01);
			}
			sprites.append((mask: blitMask, sprite: aSprite))
		}
	}
}

var gUpdateBuffer = false
var gStartLives: Int32 = 0
var gStartLevel: Int32 = 0
var gNoDelay: Int32 = 0

extension Sound {
	func playSound(sndID: SoundResource, priority: UInt8, callback: ((channel: UInt8) -> ())? = nil) -> Bool {
		return self.playSound(sndID.rawValue, priority: priority, callback: callback)
	}
}

/// The Font Server :)
var fontserv: FontServer!

/// The Sound Server *grin*
var sound: Sound!

/// The SCREEN!! :)
var screen: FrameBuf!

private var gRunning = false

private var progname: UnsafeMutablePointer<CChar> = nil

/// Print a usage message and quit.
///
/// In several places we depend on this function exiting.
private func printUsage() {
	print("\nUsage: %s [-netscores] -printscores", progname);
	print("or");
	print("Usage: %s <options>\n\n", progname);
	print("Where <options> can be any of:\n")
	print("\t-fullscreen\t\t# Run Maelstrom in full-screen mode")
	print("\t-gamma [0-8]\t\t# Set the gamma correction")
	print("\t-volume [0-8]\t\t# Set the sound volume")
	print("\t-netscores\t\t# Use the world-wide network score server")
	logicUsage();
	print("\n");
	exit(1);
}

///Run a graphics speed test.
private func runSpeedTest() {
	let test_reps: UInt32 = 100;	/* How many full cycles to run */
	
	let x = Int16((640/2)-16)
	let y = Int16((480/2)-16)
	var onscreen = false
	
	
	screen.clear();
	let then = SDL_GetTicks();
	for _ in 0..<test_reps {
		for frame in 0..<SHIP_FRAMES {
			if onscreen {
				screen.clear(x: x, y: y, w: 32, h: 32);
			} else {
				onscreen = true
			}
			screen.queueBlit(x: Int32(x), y: Int32(y), src: gPlayerShip.sprites[Int(frame)].sprite);
			screen.update();
		}
	}
	let now = SDL_GetTicks();
	print("Graphics speed test took \((now-then)/test_reps) microseconds per cycle.");
}

func drawText(x x: UInt16, y: UInt16, text: String, font: FontServer.MFont, style: FontStyle,
	R: UInt8, G: UInt8, B: UInt8) -> Int32 {
	return drawText(x: Int32(x), y: Int32(y), text: text, font: font, style: style, R: R, G: G, B: B)
}

func drawText(x x: Int32, y: Int32, text: String, font: FontServer.MFont, style: FontStyle,
	R: UInt8, G: UInt8, B: UInt8) -> Int32
{
	var width: Int32 = 0
	let textimage = fontserv.newTextImage(text, font: font, style: style, foreground: (R, G, B))
	if textimage == nil {
		return 0
	} else {
		screen.queueBlit(x: x, y: y - textimage.memory.h + 2, src: textimage, do_clip: .NOCLIP)
		width = textimage.memory.w;
		fontserv.freeText(textimage)
	}
	return width
}

private func drawMainScreen() {
	var title: UnsafeMutablePointer<SDL_Surface> = nil
	var pt = MPoint()
	var width:UInt16 = 0
	var height:UInt16 = 0
	
	var xOff:UInt16 = 0
	var yOff:UInt16 = 0
	var botDiv:UInt16 = 0
	var rightDiv:UInt16 = 0
	
	var index1: UInt16 = 0
	var sRt:UInt16 = 0
	var wRt:UInt16 = 0
	var sw:UInt16 = 0
	
	
	var buffer = ""
	var offset = 0
	
	gUpdateBuffer = false;
	buttons.removeAllButtons();
	
	width = 512;
	height = 384;
	xOff = (SCREEN_WIDTH - width) / 2;
	yOff = (SCREEN_HEIGHT - height) / 2;
	
	title = loadTitle(screen, title_id: 129);
	if title == nil {
		fatalError("Can't load 'title' title! (ID=\(129))");
		//exit(255);
	}
	
	let clr = screen.mapRGB(red: UInt8(30000>>8), green: UInt8(30000>>8), blue: 0xFF);
	let ltClr = screen.mapRGB(red: UInt8(40000>>8), green: UInt8(40000>>8), blue: 0xFF);
	let ltrClr = screen.mapRGB(red: UInt8(50000>>8), green: UInt8(50000>>8), blue: 0xFF);
	
	screen.lock();
	screen.clear();
	/* -- Draw the screen frame */
	//screen.
	screen.drawRect(x: Int16(xOff)-1, y: Int16(yOff)-1, width: Int16(width+2), height: Int16(height+2), color: clr);
	screen.drawRect(x: Int16(xOff)-2, y: Int16(yOff)-2, width: Int16(width+4), height: Int16(height+4), color: clr);
	screen.drawRect(x: Int16(xOff)-3, y: Int16(yOff)-3, width: Int16(width+6), height: Int16(height+6), color: ltClr);
	screen.drawRect(x: Int16(xOff)-4, y: Int16(yOff)-4, width: Int16(width+8), height: Int16(height+8), color: ltClr);
	screen.drawRect(x: Int16(xOff)-5, y: Int16(yOff)-5, width: Int16(width+10), height: Int16(height+10), color: ltrClr);
	screen.drawRect(x: Int16(xOff)-6, y: Int16(yOff)-6, width: Int16(width+12), height: Int16(height+12), color: ltClr);
	screen.drawRect(x: Int16(xOff)-7, y: Int16(yOff)-7, width: Int16(width+14), height: Int16(height+14), color: clr);
	
	/* -- Draw the dividers */
	botDiv = UInt16(yOff + 5) + UInt16(title.memory.h) + 5;
	rightDiv = xOff + 5 + UInt16(title.memory.w) + 5;
	screen.drawLine(x1: rightDiv, y1: yOff, x2: rightDiv, y2: yOff+height, color: ltClr);
	screen.drawLine(x1: xOff, y1: botDiv, x2: rightDiv, y2: botDiv, color: ltClr);
	screen.drawLine(x1: rightDiv, y1: 263+yOff, x2: xOff+width, y2: 263+yOff, color: ltClr);
	/* -- Draw the title image */
	screen.unlock();
	screen.queueBlit(x: Int32(xOff+5), y: Int32(yOff+5), src: title, do_clip: .NOCLIP);
	screen.update();
	screen.freeImage(title);
	
	
	/* -- Draw the high scores */
	
	/* -- First the headings  -- fontserv() isn't elegant, but hey.. */
	guard let bigfont = try? fontserv.newFont("New York", pointSize: 18) else {
		fatalError("Can't use New York (18) font! -- Exiting.");
		//exit(255);
	}
	drawText(x: Int32(xOff)+5, y: Int32(botDiv+22), text: "Name", font: bigfont, style: .Underline,
		R: 0xFF, G: 0xFF, B: 0x00);
	sRt = xOff+185;
	drawText(x: Int32(sRt), y: Int32(botDiv+22), text: "Score", font: bigfont, style: .Underline,
		R: 0xFF, G: 0xFF, B: 0x00);
	sRt += fontserv.textWidth("Score", font: bigfont, style: .Underline)
	wRt = xOff+245;
	drawText(x: Int32(wRt), y: Int32(botDiv+22), text: "Wave", font: bigfont, style: .Underline,
		R: 0xFF, G: 0xFF, B: 0x00);
	wRt += fontserv.textWidth("Wave", font: bigfont, style: .Underline)-10;
	
	/* -- Now the scores */
	hScores.loadScores();
	guard var font = try? fontserv.newFont("New York", pointSize: 14) else {
		fatalError("Can't use New York (14) font! -- Exiting.");
		//exit(255);
	}
	
	for index in UInt16(0)..<10 {
		index1 = index
		var R: UInt8 = 0
		var G: UInt8 = 0
		var B: UInt8 = 0
		
		if ( gLastHigh == Int32(index) ) {
			R = 0xFF;
			G = 0xFF;
			B = 0xFF;
		} else {
			R = UInt8(30000>>8);
			G = UInt8(30000>>8);
			B = UInt8(30000>>8);
		}
		drawText(x: xOff+5, y: botDiv+42+(index*18), text: hScores[Int(index)].name,
			font: font, style: .Bold, R: R, G: G, B: B);
		buffer = String(hScores[Int(index)].score)
		sw = fontserv.textWidth(buffer, font: font, style: .Bold);
		drawText(x: sRt-sw, y: botDiv+42+(index*18), text: buffer,
			font: font, style: .Bold, R: R, G: G, B: B);
		buffer = String(hScores[Int(index)].wave)
		sw = fontserv.textWidth(buffer, font: font, style: .Bold);
		drawText(x: wRt-sw, y: botDiv+42+(index*18), text: buffer,
			font: font, style: .Bold, R: R, G: G, B: B);
	}
	//delete font;
	
	drawText(x: xOff+5, y: botDiv+46+(10*18)+3, text: "Last Score: ",
		font: bigfont, style: [], R: 0xFF, G: 0xFF, B: 0xFF);
	buffer = String(getScore())
	sw = fontserv.textWidth("Last Score: ", font: bigfont, style: [])
	drawText(x: xOff+5+sw, y: botDiv+46+(index1*18)+3, text: buffer,
		font: bigfont, style: [], R: 0xFF, G: 0xFF, B: 0xFF);
	
	/* -- Draw the Instructions */
	offset = 34;
	
	pt.h = Int32(rightDiv) + 10;
	pt.v = Int32(yOff) + 10;
	drawKey(&pt, key: "P", text: " Start playing Maelstrom", callback: runPlayGame);
	
	pt.h = Int32(rightDiv) + 10;
	pt.v += offset;
	drawKey(&pt, key: "C", text: " Configure the game controls", callback: runConfigureControls);
	
	pt.h = Int32(rightDiv) + 10;
	pt.v += offset;
	drawKey(&pt, key: "Z", text: " Zap the high scores", callback: runZapScores);
	
	pt.h = Int32(rightDiv) + 10;
	pt.v += offset;
	drawKey(&pt, key: "A", text: " About Maelstrom...", callback: runDoAbout);
	
	pt.v += offset;
	
	pt.h = Int32(rightDiv) + 10;
	pt.v += offset;
	drawKey(&pt, key: "Q", text: " Quit Maelstrom", callback: runQuitGame);
	
	pt.h = Int32(rightDiv) + 10;
	pt.v += offset;
	drawKey(&pt, key: "0", text: " ", callback: decrementSound);
	
	guard let afont = try? fontserv.newFont("Geneva", pointSize: 9) else {
		fatalError("Can't use Geneva font! -- Exiting.\n");
	}
	font = afont
	
	drawText(x: pt.h+gKeyIcon.memory.w+3, y: pt.v+19, text: "-",
		font: font, style: [], R: 0xFF, G: 0xFF, B: 0x00);
	
	pt.h = Int32(rightDiv) + 50;
	drawKey(&pt, key: "8", text: " Set Sound Volume", callback: incrementSound);
	
	/* -- Draw the credits */
	
	drawText(x: xOff+5+68, y: yOff+5+127, text: "Port to Linux by Sam Lantinga",
		font: font, style: .Bold, R: 0xFF, G: 0xFF, B: 0x00);
	drawText(x: rightDiv+10, y: yOff+259, text: "©1992-4 Ambrosia Software, Inc.",
		font: font, style: .Bold, R: 0xFF, G: 0xFF, B: 0xFF);
	
	/* -- Draw the version number */
	
	drawText(x: xOff+20, y: yOff+151, text: VERSION_STRING,
		font: font, style: [], R: 0xFF, G: 0xFF, B: 0xFF);
	
	drawSoundLevel();
	
	/* Always drawing while faded out -- fade in */
	screen.update();
	screen.fade();
}

private func runZapScores() {
	Delay(SOUND_DELAY);
	sound.playSound(.MultShot, priority: 5);
	if hScores.zapHighScores() {
		/* Fade the screen and redisplay scores */
		screen.fade();
		Delay(SOUND_DELAY);
		sound.playSound(.Explosion, priority: 5);
		gUpdateBuffer = true;
	}
}


private func setSoundLevel(volume: Int) {
	/* Make sure the device is working */
	sound.volume = UInt8(volume)
	
	/* Set the new sound level! */
	gSoundLevel = UInt8(volume)
	sound.playSound(.NewLife, priority: 5)
	
	/* -- Draw the new sound level */
	drawSoundLevel();
}


private func runDoAbout() {
	gNoDelay = 0;
	Delay(SOUND_DELAY);
	sound.playSound(.NovaAppears, priority: 5);
	doAbout();
}

private func runConfigureControls() {
	Delay(SOUND_DELAY);
	sound.playSound(.HomingAppears, priority: 5);
	configureControls();
}

private func runPlayGame()
{
	gStartLives = 3;
	gStartLevel = 1;
	gNoDelay = 0;
	sound.playSound(.NewLife, priority: 5);
	Delay(SOUND_DELAY);
	newGame();
	//Message(NULL);		/* Clear any messages */
}


let KMOD_ALT = KMOD_LALT.rawValue | KMOD_RALT.rawValue

func SDL_main(argc2: Int32, _ argv2: UnsafeMutablePointer<UnsafeMutablePointer<Int8>>) -> Int32 {
	var argc = argc2
	var argv = argv2
	var video_flags = SDL_WindowFlags(0)
	var event = SDL_Event()
	
	var doprinthigh = false
	var speedtest = false
	
	/* Seed the random number generator */
	SeedRandom(0);
	/* Initialize the controls */
	loadControls();
	
	/* Initialize game logic data structures */
	if !initLogicData() {
		exit(1);
	}
	
	progname = argv2[0]
	
	argc -= 1
	while argc != 0 {
		defer {
			argv = argv.successor()
			argc -= 1
		}
		if ( strcmp(argv[1], "-fullscreen") == 0 ) {
			video_flags = SDL_WINDOW_FULLSCREEN | video_flags
		} else if ( strcmp(argv[1], "-gamma") == 0 ) {
			var gammacorrect: Int32 = 0
			
			if argv[2] != nil {  /* Print the current gamma */
				print("Current Gamma correction level: \(gGammaCorrect)")
				exit(0);
			}
			gammacorrect = atoi(argv[2])
			if ( gammacorrect < 0 ||
				gammacorrect > 8 ) {
				fatalError(
					"Gamma correction value must be between 0 and 8. -- Exiting.");
				//exit(1);
			}
			/* We need to update the gamma */
			gGammaCorrect = UInt8(gammacorrect)
			saveControls();
			
			argv = argv.successor();
			argc -= 1;
		} else if strcmp(argv[1], "-volume") == 0 {
			var volume: Int32 = 0
			
			if argv[2] != nil {  /* Print the current volume */
				print("Current volume level: \(gSoundLevel)");
				exit(0);
			}
			volume = atoi(argv[2])
			if volume < 0 || volume > 8 {
				fatalError(
					"Volume must be a number between 0 and 8. -- Exiting.");
				//exit(1);
			}
			/* We need to update the volume */
			gSoundLevel = UInt8(volume)
			saveControls();
			
			argv = argv.successor();
			argc -= 1;
		}
			/*
			//#define CHECKSUM_DEBUG
			#if CHECKSUM_DEBUG
			else if ( strcmp(argv[1], "-checksum") == 0 ) {
			mesg("Checksum = %s\n", get_checksum(NULL, 0));
			exit(0);
			}
			#endif /* CHECKSUM_DEBUG */
			*/
		else if ( strcmp(argv[1], "-printscores") == 0 ) {
			doprinthigh = true;
		} else if ( strcmp(argv[1], "-netscores") == 0 ) {
			HighScores.netScores = true;
		} else if ( strcmp(argv[1], "-speedtest") == 0 ) {
			speedtest = true;
		} else if ( logicParseArgs(&argv, &argc) ) {
			/* LogicParseArgs() took care of everything */
		} else if ( strcmp(argv[1], "-version") == 0 ) {
			print(Version)
			exit(0);
		} else {
			printUsage();
		}
	}
	
	/* Do we just want the high scores? */
	if doprinthigh {
		hScores.printHighScores();
		exit(0);
	}
	
	/* Make sure we have a valid player list (netlogic) */
	if !initLogic() {
		exit(1);
	}
	
	/* Initialize everything. :) */
	if !doInitializations(video_flags) {
		/* An error message was already printed */
		exit(1);
	}
	
	if speedtest {
		runSpeedTest();
		exit(0);
	}
	
	gRunning = true;
	sound.playSound(.NovaBoom, priority: 5);
	screen.fade();		/* Fade-out */
	Delay(SOUND_DELAY);
	
	gUpdateBuffer = true;
	var unusedChannel: UInt8 = 0
	while sound.playing(channel: &unusedChannel) {
		Delay(SOUND_DELAY);
	}
	
	while gRunning {
		/* Update the screen if necessary */
		if gUpdateBuffer {
			drawMainScreen();
		}
		
		/* -- Get an event */
		screen.waitEvent(&event)
		
		if event.type == SDL_KEYDOWN.rawValue {
			switch Int(event.key.keysym.sym) {
				
				/* -- Toggle fullscreen */
			case SDLK_RETURN:
				if ( event.key.keysym.mod & Uint16(KMOD_ALT) == Uint16(KMOD_ALT)) {
					screen.toggleFullScreen()
				}
				break;
				
				/* -- About the game...*/
			case SDLK_a:
				runDoAbout();
				break;
				
				/* -- Configure the controls */
			case SDLK_c:
				runConfigureControls();
				break;
				
				/* -- Start the game */
			case SDLK_p:
				runPlayGame();
				break;
				
				/* -- Start the game */
			case SDLK_l:
				Delay(SOUND_DELAY);
				sound.playSound(.Lucky, priority: 5);
				gStartLevel = hScores.beginCustomLevel()
				if ( gStartLevel > 0 ) {
					Delay(SOUND_DELAY);
					sound.playSound(.NewLife, priority: 5);
					Delay(SOUND_DELAY);
					newGame();
				}
				break;
				
				/* -- Let them leave */
			case SDLK_q:
				runQuitGame();
				break;
				
				/* -- Set the volume */
				/* (SDLK_0 - SDLK_8 are contiguous) */
			case SDLK_0, SDLK_1, SDLK_2, SDLK_3, SDLK_4, SDLK_5, SDLK_6, SDLK_7, SDLK_8:
				setSoundLevel(Int(event.key.keysym.sym)
					- SDLK_0);
				break;
				
				/* -- Give 'em a little taste of the peppers */
			case SDLK_x:
				Delay(SOUND_DELAY);
				sound.playSound(.EnemyAppears, priority: 5);
				showDawn();
				break;
				
				/* -- Zap the high scores */
			case SDLK_z:
				runZapScores();
				break;
				
				/* -- Create a screen dump of high scores */
			case SDLK_F3:
				screen.screenDump("ScoreDump",
				                  x: 64, y: 48, w: 298, h: 384);
				break;
				
			// Ignore Shift, Ctrl, Alt keys
			case SDLK_LSHIFT, SDLK_RSHIFT, SDLK_LCTRL, SDLK_RCTRL, SDLK_LALT, SDLK_RALT:
				break;
				
			// Dink! :-)
			default:
				Delay(SOUND_DELAY);
				sound.playSound(.SteelHit, priority: 5)
				break;
			}
		} else
			/* -- Handle mouse clicks */
			if event.type == SDL_MOUSEBUTTONDOWN.rawValue {
				buttons.activateButton(x: UInt16(event.button.x),
				                       y: UInt16(event.button.y))
			} else
				/* -- Handle window close requests */
				if event.type == SDL_QUIT.rawValue {
					runQuitGame();
		}
		
	}
	
	screen.fade()
	Delay(60)
	return 0
}

private func runQuitGame() {
	Delay(SOUND_DELAY);
	sound.playSound(.MultiplierGone, priority: 5)
	while sound.playing {
		Delay(SOUND_DELAY);
	}
	gRunning = false;
}

/* -- Draw the key and its function */

private func drawKey(inout pt: MPoint, key: String, text: String, callback: (()-> Void)?)
{
	guard let geneva = try? fontserv.newFont("Geneva", pointSize: 9) else {
		fatalError("Can't use Geneva font! -- Exiting.\n");
		//exit(255);
	}
	screen.queueBlit(x: pt.h, y: pt.v, src: gKeyIcon);
	screen.update();
	
	drawText(x: pt.h+14, y: pt.v+20, text: key, font: geneva, style: .Bold, R: 0xFF, G: 0xFF, B: 0xFF);
	drawText(x: pt.h+13, y: pt.v+19, text: key, font: geneva, style: .Bold, R: 0x00, G: 0x00, B: 0x00);
	drawText(x: pt.h+gKeyIcon.memory.w+3, y: pt.v+19, text: text,
	font: geneva, style: .Bold, R: 0xFF, G: 0xFF, B: 0x00);
	
	buttons.addButton(x: UInt16(pt.h), y: UInt16(pt.v), width: UInt16(gKeyIcon.memory.w), height: UInt16(gKeyIcon.memory.h), callback: callback);
}

private let xOff = (SCREEN_WIDTH - 512) / 2;
private let yOff = (SCREEN_HEIGHT - 384) / 2;
private var geneva9: FontServer.MFont! = nil
private var drawSoundLevelOnce: dispatch_once_t = 0

/// Draw the current sound volume
private func drawSoundLevel() {
	dispatch_once(&drawSoundLevelOnce) { () -> Void in
		guard let geneva = try? fontserv.newFont("Geneva", pointSize: 9) else {
			fatalError("Can't use Geneva font! -- Exiting.");
		}
		geneva9 = geneva
	}
	let text = String(gSoundLevel)
	drawText(x: xOff+309-7, y: yOff+240-6, text: text, font: geneva9, style: .Bold,
		R: UInt8(30000>>8), G: UInt8(30000>>8), B: 0xFF);
	screen.update();
}

private func incrementSound() {
	if gSoundLevel < 8 {
		gSoundLevel += 1
		sound.volume = gSoundLevel
		sound.playSound(.NewLife, priority: 5);
		
		/* -- Draw the new sound level */
		drawSoundLevel();
	}
}

private func decrementSound() {
	if gSoundLevel > 0 {
		gSoundLevel -= 1
		sound.volume = gSoundLevel;
		sound.playSound(.NewLife, priority: 5);
		
		/* -- Draw the new sound level */
		drawSoundLevel();
	}
}
