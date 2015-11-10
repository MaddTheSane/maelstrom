//
//  mainClass.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/3/15.
//
//

import Foundation


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

let SCREEN_WIDTH = 640
let SCREEN_HEIGHT = 480

let SOUND_DELAY = 6
let FADE_STEPS = 40

/// Time in 60'th of second between frames
let FRAME_DELAY = 2


let MAX_SPRITES		= 100
let MAX_STARS		= 30
let SHIP_FRAMES		= 48
let SPRITES_WIDTH	= 32
///internal <--> screen precision
let SPRITE_PRECISION	= 4
let VEL_FACTOR			= 4
let VEL_MAX				= 8 << SPRITE_PRECISION
let SCALE_FACTOR		= 16
let SHAKE_FACTOR		= 256
let MIN_BAD_DISTANCE	= 64

/// Sprite doesn't change phase
let NO_PHASE_CHANGE: Int32 = -1

let MAX_SHOTS			= 18
let SHOT_SIZE			= 4
let SHOT_SCALE_FACTOR	= 4

let STATUS_HEIGHT	= 14
let SHIELD_WIDTH	= 55
let INITIAL_BONUS	= 2000

let ENEMY_HITS		= 3
let HOMING_HITS		= 9
let STEEL_SPECIAL	= 10
let DEFAULT_HITS	= 1

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
	var xCoord: Int32 = 0
	var yCoord: Int32 = 0
	var color: UInt32 = 0
}

typealias StarPtr = UnsafeMutablePointer<Star>

///Sprite blitting information structure
class Blit {
	typealias BitMask = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
	typealias Surfaces = (SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface)
	var numFrames: Int32 = 0
	var isSmall: Bool = false
	var hitRect: Rect = Rect()
	var mask: [BitMask] = []
	var sprite = [SDL_Surface]()
	//SDL_Surface *sprite[MAX_SPRITE_FRAMES];
}

extension Sound {
	func playSound(sndID: SoundResource, priority: UInt8, callback: ((channel: UInt8) -> ())? = nil) -> Bool {
		return self.playSound(sndID.rawValue, priority: priority, callback: callback)
	}
}

/// The Font Server :)
var fontserv: FontServ!

/// The Sound Server *grin*
var sound: Sound!

/// The SCREEN!! :)
var screen: FrameBuf!

func SDL_main(argc: Int32, _ argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>>) -> Int32 {
	return 0
}


