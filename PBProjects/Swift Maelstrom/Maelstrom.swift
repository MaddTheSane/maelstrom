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

func SDL_main(argc: Int32, _ argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>>) -> Int32 {
	return 0
}

let MAX_SPRITE_FRAMES = 60


/*
#define SCREEN_WIDTH		640
#define SCREEN_HEIGHT		480

#define	SOUND_DELAY		6
#define	FADE_STEPS		40

/* Time in 60'th of second between frames */
#define FRAME_DELAY		2

#define MAX_SPRITES		100
#define	MAX_STARS		30
#define	SHIP_FRAMES		48
#define	SPRITES_WIDTH		32
#define SPRITE_PRECISION	4	/* internal <--> screen precision */
#define	VEL_FACTOR		4
#define	VEL_MAX			(8<<SPRITE_PRECISION)
#define	SCALE_FACTOR		16
#define	SHAKE_FACTOR		256
#define	MIN_BAD_DISTANCE	64

#define NO_PHASE_CHANGE		-1	/* Sprite doesn't change phase */

#define	MAX_SHOTS		18
#define	SHOT_SIZE		4
#define	SHOT_SCALE_FACTOR	4

#define	STATUS_HEIGHT		14
#define	SHIELD_WIDTH		55
#define	INITIAL_BONUS		2000

#define	ENEMY_HITS		3
#define	HOMING_HITS		9
#define	STEEL_SPECIAL		10
#define DEFAULT_HITS		1

#define	NEW_LIFE		50000
#define	SMALL_ROID_PTS		300
#define	MEDIUM_ROID_PTS		100
#define	BIG_ROID_PTS		50
#define	GRAVITY_PTS		500
#define	HOMING_PTS		700
#define	NOVA_PTS		1000
#define	STEEL_PTS		100
#define	ENEMY_PTS		1000

#define	HOMING_MOVE		6
#define GRAVITY_MOVE		3

#define	BLUE_MOON		50
#define	MOON_FACTOR		4
#define	NUM_PRIZES		8
#define	LUCK_ODDS		3

*/

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
struct Blit {
	typealias BitMask = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
	typealias Surfaces = (SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface, SDL_Surface)
	var numFrames: Int32 = 0
	var isSmall: Bool = false
	var hitRect: Rect = Rect()
	var mask: [BitMask] = []
	//SDL_Surface *sprite[MAX_SPRITE_FRAMES];
}

///Sprite blitting information structure pointer
typealias BlitPtr = UnsafeMutablePointer<Blit>
