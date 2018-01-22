//
//  Logic.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/10/15.
//
//

import Foundation
import SDL2

let VERSION = "3.0.6"
let VERSION_STRING = VERSION + ".N"


let ENEMY_SHOT_DELAY = (10/FRAME_DELAY)

let INITIAL_SHIELD = ((60/FRAME_DELAY) * 3)
let SAFE_TIME = (120/FRAME_DELAY)
let MAX_SHIELD = ((60/FRAME_DELAY) * 5)
let DISPLAY_DELAY = (60/FRAME_DELAY)
let BONUS_DELAY = (30/FRAME_DELAY)
let STAR_DELAY = (30/FRAME_DELAY)
let DEAD_DELAY = (3 * (60/FRAME_DELAY))
let BOOM_MIN = (20/FRAME_DELAY)
let PLAYER_HITS: Int32 = 3
let VAPOROUS = 0

let PLAYER_PTS: Int32 = 1000
let DEFAULT_POINTS: Int32 = 0
let PRIZE_DURATION: Int32 = (10 * Int32(60/FRAME_DELAY))
let MULT_DURATION = (6 * (60/FRAME_DELAY))
let BONUS_DURATION = (10 * (60/FRAME_DELAY))
let SHOT_DURATION = (1 * (60/FRAME_DELAY))
let POINT_DURATION = (2 * (60/FRAME_DELAY))
let	DAMAGED_DURATION = Int32(10 * (60/FRAME_DELAY))
let FREEZE_DURATION = (10 * (60/FRAME_DELAY))
let SHAKE_DURATION = (5 * (60/FRAME_DELAY))

func initLogicData() -> Bool {
	#if MULTIPLAYER_SUPPORT
	/* Initialize network player data */
	guard initNetData() else {
		return false;
	}
	gDeathMatch = 0;
		#endif
	return true;
}

func initLogic() -> Bool {
	#if MULTIPLAYER_SUPPORT
	return false
	#else
	return true
	#endif
}

func logicUsage() {
	print("\t-player N[@host][:port]\t# Designate player N (at host and/or port)")
	print("\t-server N@host[:port]\t# Play with N players using server at host")
	print("\t-deathmatch [N]\t\t# Play deathmatch to N frags (default = 8)")
}

func logicParseArgs(_ argvptr: inout UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>, _ argcptr: inout Int32) -> Bool {
	// TODO: implement
	return false
}

func haltLogic() {
	#if MULTIPLAYER_SUPPORT
	haltNetData();
	#endif
}


func getScore() -> Int32 {
	#if MULTIPLAYER_SUPPORT
		return(OurShip.GetScore());
		#else
	return 0
	#endif
	
	//
}

func initPlayerSprites() -> Bool {
	// TODO: implement
	
	return true
}

