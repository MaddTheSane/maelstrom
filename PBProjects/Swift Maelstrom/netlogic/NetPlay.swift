//
//  NetPlay.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/11/15.
//
//

import Foundation
import SDL2
import SDL2_net

struct Shot {
	var damage: Int32 = 0
	var x: Int32 = 0
	var y: Int32 = 0
	var xvel: Int32 = 0
	var yvel: Int32 = 0
	var ttl: Int32 = 0
	var hitRect = Rect()
}

#if MULTIPLAYER_SUPPORT

var gNumPlayers: Int32 = 0
var gOurPlayer: Int32 = 0
var gDeathMatch: Int32 = 0
var gNetFD = UDPsocket()

private var gotPlayer = [Bool](count: Int(MAX_PLAYERS), repeatedValue: false)
private var playAddr = [IPaddress](count: Int(MAX_PLAYERS), repeatedValue: IPaddress())
private var servAddr = IPaddress()
private var foundUs = false
private var useSerer = false
private var nextFrame: UInt32 = 0

var outBound = (UnsafeMutablePointer<UDPpacket>(), UnsafeMutablePointer<UDPpacket>())
private var currOut: Int32 = 0
/* This is the data offset of a SYNC packet */
//#define PDATA_OFFSET	(1+1+sizeof(Uint32)+sizeof(Uint32))
let PDATA_OFFSET = 1 + 1 + sizeof(UInt32) + sizeof(UInt32)

private var otherOut: Int32 {
	if currOut == 1 {
		return 0
	} else {
		return 1
	}
}

/* We keep one packet backlogged for retransmission */
private var outBuf: UnsafeMutablePointer<UInt8> {
get {
	if currOut == 0 {
		return outBound.0.memory.data
	} else {
		return outBound.1.memory.data
	}
}
set {
	if currOut == 0 {
		outBound.0.memory.data = newValue
	} else {
		outBound.1.memory.data = newValue
	}
	
}
}

private var outLen: Int32 {
get {
	if currOut == 0 {
		return outBound.0.memory.len
	} else {
		return outBound.1.memory.len
	}
}
set {
	if currOut == 0 {
		outBound.0.memory.len = newValue
	} else {
		outBound.1.memory.len = newValue
	}
}
}

private var lastBuf: UnsafeMutablePointer<UInt8> {
get {
	if currOut == 1 {
		return outBound.0.memory.data
	} else {
		return outBound.1.memory.data
	}
}
set {
	if currOut == 1 {
		outBound.0.memory.data = newValue
	} else {
		outBound.1.memory.data = newValue
	}
	
}
}

private var lastLen: Int32 {
get {
	if currOut == 1 {
		return outBound.0.memory.len
	} else {
		return outBound.1.memory.len
	}
}
set {
	if currOut == 1 {
		outBound.0.memory.len = newValue
	} else {
		outBound.1.memory.len = newValue
	}
}
}

/*
static unsigned char *SyncPtrs[2][MAX_PLAYERS];
static unsigned char  SyncBufs[2][MAX_PLAYERS][BUFSIZ];
static int            SyncLens[2][MAX_PLAYERS];
static int            ThisSyncs[2];
static int            CurrIn;*/
private var currIn: Int32 = 0
private var socketSet = SDLNet_SocketSet()

/* We cache one packet if the other player is ahead of us */
/*
#define SyncPtr		SyncPtrs[CurrIn]
#define SyncBuf		SyncBufs[CurrIn]
#define SyncLen		SyncLens[CurrIn]
#define ThisSync	ThisSyncs[CurrIn]
#define NextPtr		SyncPtrs[!CurrIn]
#define NextBuf		SyncBufs[!CurrIn]
#define NextLen		SyncLens[!CurrIn]
#define NextSync	ThisSyncs[!CurrIn]
*/
//#define TOGGLE(var)	var = !var


func initNetData() -> Bool  {	
	/* Initialize the networking subsystem */
	if ( SDLNet_Init() < 0 ) {
		print("NetLogic: Couldn't initialize networking!");
		return false;
	}
	atexit(SDLNet_Quit);
	
	/* Create the outbound packets */
	outBound.0 = SDLNet_AllocPacket(BUFSIZ);
	if ( outBound.0 == nil ) {
		print("Out of memory (creating network buffers)");
		return false;
	}
	outBound.1 = SDLNet_AllocPacket(BUFSIZ);
	if ( outBound.1 == nil ) {
		print("Out of memory (creating network buffers)");
		return false;
	}
	
	/* Initialize network game variables */
	foundUs   = false
	gOurPlayer  = -1;
	gDeathMatch = 0;
	/*
	useServer = false
	for i in 0..<Int(MAX_PLAYERS) {
	GotPlayer[i] = 0;
	SyncPtrs[0][i] = NULL;
	SyncPtrs[1][i] = NULL;
	}*/
	outBound.0.memory.data[0] = UInt8(SYNC_MSG)
	outBound.1.memory.data[0] = UInt8(SYNC_MSG)
	/* Type field, frame sequence, current random seed */
	outBound.0.memory.len = Int32(PDATA_OFFSET)
	outBound.1.memory.len = Int32(PDATA_OFFSET)
	currOut = 0;
	
	//ThisSyncs[0] = 0;
	//ThisSyncs[1] = 0;
	currIn = 0;
	return true;
}

func haltNetData() {
	SDLNet_Quit();
}

#else
let gNumPlayers: Int32 = 1

#endif
