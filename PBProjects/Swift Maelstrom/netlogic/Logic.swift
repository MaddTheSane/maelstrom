//
//  Logic.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/10/15.
//
//

import Foundation

let VERSION = "3.0.6"
let VERSION_STRING = VERSION + ".N"


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
	return false
}

func logicUsage() {
	print("\t-player N[@host][:port]\t# Designate player N (at host and/or port)")
	print("\t-server N@host[:port]\t# Play with N players using server at host")
	print("\t-deathmatch [N]\t\t# Play deathmatch to N frags (default = 8)")
}

func logicParseArgs(inout argvptr: UnsafeMutablePointer<UnsafeMutablePointer<CChar>>, inout _ argcptr: Int32) -> Bool {
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
